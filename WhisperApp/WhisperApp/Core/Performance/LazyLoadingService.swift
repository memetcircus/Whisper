import Foundation
import CoreData

/// Service for implementing lazy loading of identities and contacts
/// Reduces memory footprint by loading data only when needed
protocol LazyLoadingService {
    /// Loads identity metadata without private keys
    /// - Parameter id: Identity UUID
    /// - Returns: Identity metadata or nil if not found
    func loadIdentityMetadata(id: UUID) -> IdentityMetadata?
    
    /// Loads full identity with private keys from Keychain
    /// - Parameter id: Identity UUID
    /// - Returns: Complete identity or nil if not found
    func loadFullIdentity(id: UUID) -> Identity?
    
    /// Loads contact metadata without full key history
    /// - Parameter id: Contact UUID
    /// - Returns: Contact metadata or nil if not found
    func loadContactMetadata(id: UUID) -> ContactMetadata?
    
    /// Loads full contact with complete key history
    /// - Parameter id: Contact UUID
    /// - Returns: Complete contact or nil if not found
    func loadFullContact(id: UUID) -> Contact?
    
    /// Preloads frequently accessed data into cache
    func preloadFrequentlyUsed()
    
    /// Clears cached data to free memory
    func clearCache()
    
    /// Gets cache statistics
    /// - Returns: Cache usage information
    func getCacheStatistics() -> CacheStatistics
}

/// Lightweight identity metadata for lazy loading
struct IdentityMetadata {
    let id: UUID
    let name: String
    let fingerprint: Data
    let shortFingerprint: String
    let createdAt: Date
    let status: IdentityStatus
    let keyVersion: Int
    let isActive: Bool
}

/// Lightweight contact metadata for lazy loading
struct ContactMetadata {
    let id: UUID
    let displayName: String
    let fingerprint: Data
    let shortFingerprint: String
    let trustLevel: TrustLevel
    let isBlocked: Bool
    let keyVersion: Int
    let createdAt: Date
    let lastSeenAt: Date?
}

/// Cache usage statistics
struct CacheStatistics {
    let identityCacheSize: Int
    let contactCacheSize: Int
    let totalMemoryUsage: Int64
    let hitRate: Double
    let missRate: Double
}

/// Concrete implementation of LazyLoadingService
class WhisperLazyLoadingService: LazyLoadingService {
    
    private let context: NSManagedObjectContext
    private let performanceMonitor: PerformanceMonitor
    
    // Caches for frequently accessed data
    private var identityMetadataCache: [UUID: IdentityMetadata] = [:]
    private var contactMetadataCache: [UUID: ContactMetadata] = [:]
    private var fullIdentityCache: [UUID: Identity] = [:]
    private var fullContactCache: [UUID: Contact] = [:]
    
    // Cache statistics
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    // Cache limits to prevent memory bloat
    private let maxIdentityCache = 50
    private let maxContactCache = 200
    
    private let queue = DispatchQueue(label: "lazy-loading", qos: .userInitiated)
    
    init(context: NSManagedObjectContext, performanceMonitor: PerformanceMonitor) {
        self.context = context
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Identity Lazy Loading
    
    func loadIdentityMetadata(id: UUID) -> IdentityMetadata? {
        return queue.sync {
            // Check cache first
            if let cached = identityMetadataCache[id] {
                cacheHits += 1
                return cached
            }
            
            cacheMisses += 1
            
            // Load from Core Data
            let (metadata, _) = performanceMonitor.measureCryptoOperation("load_identity_metadata") {
                return fetchIdentityMetadata(id: id)
            }
            
            // Cache the result
            if let metadata = metadata {
                cacheIdentityMetadata(metadata)
            }
            
            return metadata
        }
    }
    
    func loadFullIdentity(id: UUID) -> Identity? {
        return queue.sync {
            // Check cache first
            if let cached = fullIdentityCache[id] {
                cacheHits += 1
                return cached
            }
            
            cacheMisses += 1
            
            // Load from Core Data and Keychain
            let (identity, _) = performanceMonitor.measureMemoryUsage("load_full_identity") {
                return fetchFullIdentity(id: id)
            }
            
            // Cache the result (but limit cache size)
            if let identity = identity {
                cacheFullIdentity(identity)
            }
            
            return identity
        }
    }
    
    // MARK: - Contact Lazy Loading
    
    func loadContactMetadata(id: UUID) -> ContactMetadata? {
        return queue.sync {
            // Check cache first
            if let cached = contactMetadataCache[id] {
                cacheHits += 1
                return cached
            }
            
            cacheMisses += 1
            
            // Load from Core Data
            let (metadata, _) = performanceMonitor.measureCryptoOperation("load_contact_metadata") {
                return fetchContactMetadata(id: id)
            }
            
            // Cache the result
            if let metadata = metadata {
                cacheContactMetadata(metadata)
            }
            
            return metadata
        }
    }
    
    func loadFullContact(id: UUID) -> Contact? {
        return queue.sync {
            // Check cache first
            if let cached = fullContactCache[id] {
                cacheHits += 1
                return cached
            }
            
            cacheMisses += 1
            
            // Load from Core Data with key history
            let (contact, _) = performanceMonitor.measureMemoryUsage("load_full_contact") {
                return fetchFullContact(id: id)
            }
            
            // Cache the result (but limit cache size)
            if let contact = contact {
                cacheFullContact(contact)
            }
            
            return contact
        }
    }
    
    // MARK: - Cache Management
    
    func preloadFrequentlyUsed() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let (_, _) = self.performanceMonitor.measureMemoryUsage("preload_frequently_used") {
                // Load active identity
                if let activeIdentity = self.fetchActiveIdentity() {
                    self.cacheFullIdentity(activeIdentity)
                }
                
                // Load recently used contacts (last 30 days)
                let recentContacts = self.fetchRecentlyUsedContacts()
                for contact in recentContacts.prefix(20) { // Limit to 20 most recent
                    self.cacheContactMetadata(contact)
                }
            }
        }
    }
    
    func clearCache() {
        queue.sync {
            identityMetadataCache.removeAll()
            contactMetadataCache.removeAll()
            fullIdentityCache.removeAll()
            fullContactCache.removeAll()
            
            // Reset statistics
            cacheHits = 0
            cacheMisses = 0
        }
    }
    
    func getCacheStatistics() -> CacheStatistics {
        return queue.sync {
            let totalRequests = cacheHits + cacheMisses
            let hitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
            let missRate = totalRequests > 0 ? Double(cacheMisses) / Double(totalRequests) : 0.0
            
            // Estimate memory usage (rough calculation)
            let identityMemory = identityMetadataCache.count * 200 + fullIdentityCache.count * 1000
            let contactMemory = contactMetadataCache.count * 150 + fullContactCache.count * 800
            
            return CacheStatistics(
                identityCacheSize: identityMetadataCache.count + fullIdentityCache.count,
                contactCacheSize: contactMetadataCache.count + fullContactCache.count,
                totalMemoryUsage: Int64(identityMemory + contactMemory),
                hitRate: hitRate,
                missRate: missRate
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchIdentityMetadata(id: UUID) -> IdentityMetadata? {
        let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            
            return IdentityMetadata(
                id: entity.id!,
                name: entity.name!,
                fingerprint: entity.fingerprint!,
                shortFingerprint: entity.fingerprint!.base32CrockfordEncoded().prefix(12).description,
                createdAt: entity.createdAt!,
                status: IdentityStatus(rawValue: entity.status!) ?? .active,
                keyVersion: Int(entity.keyVersion),
                isActive: entity.isActive
            )
        } catch {
            return nil
        }
    }
    
    private func fetchFullIdentity(id: UUID) -> Identity? {
        guard let metadata = fetchIdentityMetadata(id: id) else { return nil }
        
        do {
            // Load private keys from Keychain
            let x25519PrivateKey = try KeychainManager.retrieveX25519PrivateKey(
                identifier: id.uuidString
            )
            
            let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            
            var ed25519KeyPair: Ed25519KeyPair?
            if let ed25519PublicKey = entity.ed25519PublicKey {
                let ed25519PrivateKey = try KeychainManager.retrieveEd25519PrivateKey(
                    identifier: id.uuidString
                )
                ed25519KeyPair = Ed25519KeyPair(
                    privateKey: ed25519PrivateKey,
                    publicKey: ed25519PublicKey
                )
            }
            
            return Identity(
                id: metadata.id,
                name: metadata.name,
                x25519KeyPair: X25519KeyPair(
                    privateKey: x25519PrivateKey,
                    publicKey: entity.x25519PublicKey!
                ),
                ed25519KeyPair: ed25519KeyPair,
                fingerprint: metadata.fingerprint,
                createdAt: metadata.createdAt,
                status: metadata.status,
                keyVersion: metadata.keyVersion
            )
        } catch {
            return nil
        }
    }
    
    private func fetchContactMetadata(id: UUID) -> ContactMetadata? {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            
            return ContactMetadata(
                id: entity.id!,
                displayName: entity.displayName!,
                fingerprint: entity.fingerprint!,
                shortFingerprint: entity.shortFingerprint!,
                trustLevel: TrustLevel(rawValue: entity.trustLevel!) ?? .unverified,
                isBlocked: entity.isBlocked,
                keyVersion: Int(entity.keyVersion),
                createdAt: entity.createdAt!,
                lastSeenAt: entity.lastSeenAt
            )
        } catch {
            return nil
        }
    }
    
    private func fetchFullContact(id: UUID) -> Contact? {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            
            // Load key history
            var keyHistory: [KeyHistoryEntry] = []
            if let historyEntities = entity.keyHistory {
                for historyEntity in historyEntities {
                    if let historyEntity = historyEntity as? KeyHistoryEntity,
                       let historyId = historyEntity.id,
                       let historyX25519Key = historyEntity.x25519PublicKey,
                       let historyFingerprint = historyEntity.fingerprint,
                       let historyCreatedAt = historyEntity.createdAt {
                        
                        let entry = KeyHistoryEntry(
                            id: historyId,
                            keyVersion: Int(historyEntity.keyVersion),
                            x25519PublicKey: historyX25519Key,
                            ed25519PublicKey: historyEntity.ed25519PublicKey,
                            fingerprint: historyFingerprint,
                            createdAt: historyCreatedAt
                        )
                        keyHistory.append(entry)
                    }
                }
            }
            
            // Generate SAS words from fingerprint
            let sasWords = Contact.generateSASWords(from: entity.fingerprint!)
            
            return Contact(
                id: entity.id!,
                displayName: entity.displayName!,
                x25519PublicKey: entity.x25519PublicKey!,
                ed25519PublicKey: entity.ed25519PublicKey,
                fingerprint: entity.fingerprint!,
                shortFingerprint: entity.shortFingerprint!,
                sasWords: sasWords,
                rkid: entity.rkid!,
                trustLevel: TrustLevel(rawValue: entity.trustLevel!) ?? .unverified,
                isBlocked: entity.isBlocked,
                keyVersion: Int(entity.keyVersion),
                keyHistory: keyHistory,
                createdAt: entity.createdAt!,
                lastSeenAt: entity.lastSeenAt,
                note: entity.note
            )
        } catch {
            return nil
        }
    }
    
    private func fetchActiveIdentity() -> Identity? {
        let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            return fetchFullIdentity(id: entity.id!)
        } catch {
            return nil
        }
    }
    
    private func fetchRecentlyUsedContacts() -> [ContactMetadata] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "lastSeenAt >= %@", thirtyDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "lastSeenAt", ascending: false)]
        request.fetchLimit = 50
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id else { return nil }
                return fetchContactMetadata(id: id)
            }
        } catch {
            return []
        }
    }
    
    // MARK: - Cache Management Helpers
    
    private func cacheIdentityMetadata(_ metadata: IdentityMetadata) {
        identityMetadataCache[metadata.id] = metadata
        
        // Enforce cache size limit
        if identityMetadataCache.count > maxIdentityCache {
            let oldestKey = identityMetadataCache.min { $0.value.createdAt < $1.value.createdAt }?.key
            if let key = oldestKey {
                identityMetadataCache.removeValue(forKey: key)
            }
        }
    }
    
    private func cacheContactMetadata(_ metadata: ContactMetadata) {
        contactMetadataCache[metadata.id] = metadata
        
        // Enforce cache size limit
        if contactMetadataCache.count > maxContactCache {
            let oldestKey = contactMetadataCache.min { $0.value.createdAt < $1.value.createdAt }?.key
            if let key = oldestKey {
                contactMetadataCache.removeValue(forKey: key)
            }
        }
    }
    
    private func cacheFullIdentity(_ identity: Identity) {
        fullIdentityCache[identity.id] = identity
        
        // Keep only a few full identities in cache
        if fullIdentityCache.count > 5 {
            let oldestKey = fullIdentityCache.min { $0.value.createdAt < $1.value.createdAt }?.key
            if let key = oldestKey {
                fullIdentityCache.removeValue(forKey: key)
            }
        }
    }
    
    private func cacheFullContact(_ contact: Contact) {
        fullContactCache[contact.id] = contact
        
        // Keep only recent contacts in cache
        if fullContactCache.count > 20 {
            let oldestKey = fullContactCache.min { 
                ($0.value.lastSeenAt ?? $0.value.createdAt) < ($1.value.lastSeenAt ?? $1.value.createdAt) 
            }?.key
            if let key = oldestKey {
                fullContactCache.removeValue(forKey: key)
            }
        }
    }
}