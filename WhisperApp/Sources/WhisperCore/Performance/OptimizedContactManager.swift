import Foundation
import CoreData
import Combine

/// Performance-optimized contact manager with lazy loading and efficient search
/// Reduces memory usage and improves response times for contact operations
class OptimizedContactManager: ContactManager {
    
    private let baseManager: CoreDataContactManager
    private let lazyLoadingService: LazyLoadingService
    private let performanceMonitor: PerformanceMonitor
    
    // Caching for frequently accessed data
    private var contactMetadataCache: [ContactMetadata] = []
    private var searchCache: [String: [ContactMetadata]] = [:]
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 180 // 3 minutes
    private let maxSearchCacheSize = 20
    
    private let queue = DispatchQueue(label: "optimized-contact-manager", qos: .userInitiated)
    
    init(
        baseManager: CoreDataContactManager,
        lazyLoadingService: LazyLoadingService,
        performanceMonitor: PerformanceMonitor
    ) {
        self.baseManager = baseManager
        self.lazyLoadingService = lazyLoadingService
        self.performanceMonitor = performanceMonitor
        
        // Preload frequently used contacts
        loadContactMetadataCache()
    }
    
    // MARK: - Optimized Contact Operations
    
    func addContact(_ contact: Contact) throws {
        try performanceMonitor.measureMemoryUsage("optimized_add_contact") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.addContact(contact)
            
            // Update cache
            self.invalidateCaches()
            self.loadContactMetadataCache()
        }.result
    }
    
    func updateContact(_ contact: Contact) throws {
        try performanceMonitor.measureCryptoOperation("optimized_update_contact") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.updateContact(contact)
            
            // Update cache
            self.invalidateCaches()
            self.loadContactMetadataCache()
        }.result
    }
    
    func deleteContact(id: UUID) throws {
        try performanceMonitor.measureCryptoOperation("optimized_delete_contact") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.deleteContact(id: id)
            
            // Update cache
            self.invalidateCaches()
            self.loadContactMetadataCache()
        }.result
    }
    
    func getContact(id: UUID) -> Contact? {
        return performanceMonitor.measureCryptoOperation("optimized_get_contact") { [weak self] in
            guard let self = self else { return nil }
            
            // Try lazy loading service first (uses its own cache)
            return self.lazyLoadingService.loadFullContact(id: id)
        }.result
    }
    
    func getContact(byRkid rkid: Data) -> Contact? {
        return performanceMonitor.measureCryptoOperation("optimized_get_contact_by_rkid") { [weak self] in
            guard let self = self else { return nil }
            
            // Check metadata cache first
            if let metadata = self.getContactMetadataByRkid(rkid) {
                return self.lazyLoadingService.loadFullContact(id: metadata.id)
            }
            
            // Fall back to base manager
            return self.baseManager.getContact(byRkid: rkid)
        }.result
    }
    
    func listContacts() -> [Contact] {
        return performanceMonitor.measureCryptoOperation("optimized_list_contacts") { [weak self] in
            guard let self = self else { return [] }
            
            // Get metadata from cache
            let metadata = self.getContactMetadataList()
            
            // Load full contacts only for visible/needed ones
            // For UI lists, we might only need metadata
            return metadata.compactMap { meta in
                self.lazyLoadingService.loadFullContact(id: meta.id)
            }
        }.result
    }
    
    // MARK: - Optimized Search Operations
    
    func searchContacts(query: String) -> [Contact] {
        return performanceMonitor.measureCryptoOperation("optimized_search_contacts") { [weak self] in
            guard let self = self else { return [] }
            
            let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check search cache first
            if let cachedResults = self.getCachedSearchResults(query: normalizedQuery) {
                return cachedResults.compactMap { meta in
                    self.lazyLoadingService.loadFullContact(id: meta.id)
                }
            }
            
            // Perform search on metadata first (much faster)
            let metadataResults = self.searchContactMetadata(query: normalizedQuery)
            
            // Cache the metadata results
            self.cacheSearchResults(query: normalizedQuery, results: metadataResults)
            
            // Load full contacts for results
            return metadataResults.compactMap { meta in
                self.lazyLoadingService.loadFullContact(id: meta.id)
            }
        }.result
    }
    
    // MARK: - Metadata-Only Operations (Fast)
    
    func getContactMetadataList() -> [ContactMetadata] {
        return queue.sync { [weak self] in
            guard let self = self else { return [] }
            
            if !self.contactMetadataCache.isEmpty && self.isCacheValid() {
                return self.contactMetadataCache
            }
            
            self.loadContactMetadataCache()
            return self.contactMetadataCache
        }
    }
    
    func getContactMetadata(id: UUID) -> ContactMetadata? {
        return lazyLoadingService.loadContactMetadata(id: id)
    }
    
    func getContactMetadataByRkid(_ rkid: Data) -> ContactMetadata? {
        return getContactMetadataList().first { metadata in
            // Would need to calculate rkid from metadata
            // For now, fall back to full contact lookup
            if let contact = lazyLoadingService.loadFullContact(id: metadata.id) {
                return contact.rkid == rkid
            }
            return false
        }
    }
    
    // MARK: - Trust Management (Optimized)
    
    func verifyContact(id: UUID, sasConfirmed: Bool) throws {
        try performanceMonitor.measureCryptoOperation("optimized_verify_contact") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.verifyContact(id: id, sasConfirmed: sasConfirmed)
            
            // Update specific contact in cache
            self.updateContactInCache(id: id)
        }.result
    }
    
    func blockContact(id: UUID) throws {
        try performanceMonitor.measureCryptoOperation("optimized_block_contact") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.blockContact(id: id)
            
            // Update specific contact in cache
            self.updateContactInCache(id: id)
        }.result
    }
    
    func unblockContact(id: UUID) throws {
        try performanceMonitor.measureCryptoOperation("optimized_unblock_contact") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.unblockContact(id: id)
            
            // Update specific contact in cache
            self.updateContactInCache(id: id)
        }.result
    }
    
    // MARK: - Key Rotation (Optimized)
    
    func handleKeyRotation(for contact: Contact, newX25519Key: Data, newEd25519Key: Data?) throws {
        try performanceMonitor.measureMemoryUsage("optimized_key_rotation") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.handleKeyRotation(for: contact, newX25519Key: newX25519Key, newEd25519Key: newEd25519Key)
            
            // Update cache
            self.updateContactInCache(id: contact.id)
        }.result
    }
    
    func checkForKeyRotation(contact: Contact, currentX25519Key: Data) -> Bool {
        return baseManager.checkForKeyRotation(contact: contact, currentX25519Key: currentX25519Key)
    }
    
    // MARK: - Export Operations
    
    func exportPublicKeybook() throws -> Data {
        return try performanceMonitor.measureMemoryUsage("optimized_export_keybook") { [weak self] in
            guard let self = self else { throw ContactManagerError.exportFailed }
            return try self.baseManager.exportPublicKeybook()
        }.result
    }
    
    // MARK: - Private Cache Management
    
    private func loadContactMetadataCache() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let (contacts, _) = self.performanceMonitor.measureCryptoOperation("load_contact_metadata_cache") {
                return self.baseManager.listContacts()
            }
            
            self.contactMetadataCache = contacts.map { contact in
                ContactMetadata(
                    id: contact.id,
                    displayName: contact.displayName,
                    fingerprint: contact.fingerprint,
                    shortFingerprint: contact.shortFingerprint,
                    trustLevel: contact.trustLevel,
                    isBlocked: contact.isBlocked,
                    keyVersion: contact.keyVersion,
                    createdAt: contact.createdAt,
                    lastSeenAt: contact.lastSeenAt
                )
            }
            
            self.cacheTimestamp = Date()
        }
    }
    
    private func updateContactInCache(id: UUID) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Load updated contact metadata
            if let updatedMetadata = self.lazyLoadingService.loadContactMetadata(id: id) {
                // Update in cache
                if let index = self.contactMetadataCache.firstIndex(where: { $0.id == id }) {
                    self.contactMetadataCache[index] = updatedMetadata
                } else {
                    self.contactMetadataCache.append(updatedMetadata)
                }
            }
            
            // Invalidate search cache as contact data changed
            self.searchCache.removeAll()
        }
    }
    
    private func invalidateCaches() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.contactMetadataCache.removeAll()
            self.searchCache.removeAll()
            self.cacheTimestamp = nil
        }
    }
    
    private func isCacheValid() -> Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheValidityDuration
    }
    
    // MARK: - Search Optimization
    
    private func searchContactMetadata(query: String) -> [ContactMetadata] {
        let metadata = getContactMetadataList()
        
        return metadata.filter { contact in
            contact.displayName.lowercased().contains(query) ||
            contact.shortFingerprint.lowercased().contains(query)
        }.sorted { $0.displayName < $1.displayName }
    }
    
    private func getCachedSearchResults(query: String) -> [ContactMetadata]? {
        return queue.sync {
            return searchCache[query]
        }
    }
    
    private func cacheSearchResults(query: String, results: [ContactMetadata]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.searchCache[query] = results
            
            // Limit cache size
            if self.searchCache.count > self.maxSearchCacheSize {
                // Remove oldest entries (simple FIFO)
                let keysToRemove = Array(self.searchCache.keys.prefix(self.searchCache.count - self.maxSearchCacheSize))
                for key in keysToRemove {
                    self.searchCache.removeValue(forKey: key)
                }
            }
        }
    }
    
    // MARK: - Performance Monitoring
    
    func getPerformanceStatistics() -> [String: PerformanceStatistics] {
        let operations = [
            "optimized_add_contact",
            "optimized_update_contact",
            "optimized_delete_contact",
            "optimized_get_contact",
            "optimized_get_contact_by_rkid",
            "optimized_list_contacts",
            "optimized_search_contacts",
            "optimized_verify_contact",
            "optimized_block_contact",
            "optimized_unblock_contact",
            "optimized_key_rotation",
            "optimized_export_keybook",
            "load_contact_metadata_cache"
        ]
        
        var statistics: [String: PerformanceStatistics] = [:]
        for operation in operations {
            if let stats = performanceMonitor.getStatistics(for: operation) {
                statistics[operation] = stats
            }
        }
        
        return statistics
    }
    
    func getCacheStatistics() -> ContactCacheStatistics {
        return queue.sync {
            let cacheStats = lazyLoadingService.getCacheStatistics()
            
            return ContactCacheStatistics(
                metadataCacheSize: contactMetadataCache.count,
                searchCacheSize: searchCache.count,
                lazyLoadingStats: cacheStats,
                cacheHitRate: cacheStats.hitRate,
                lastCacheUpdate: cacheTimestamp
            )
        }
    }
    
    func optimizeMemory() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Clear local caches
            self.invalidateCaches()
            
            // Clear lazy loading caches
            self.lazyLoadingService.clearCache()
            
            // Reload essential data
            self.loadContactMetadataCache()
            self.lazyLoadingService.preloadFrequentlyUsed()
        }
    }
}

// MARK: - Supporting Types

struct ContactCacheStatistics {
    let metadataCacheSize: Int
    let searchCacheSize: Int
    let lazyLoadingStats: CacheStatistics
    let cacheHitRate: Double
    let lastCacheUpdate: Date?
}

// MARK: - Publisher Extensions

extension OptimizedContactManager {
    /// Publisher for contact list changes
    var contactListPublisher: AnyPublisher<[ContactMetadata], Never> {
        return NotificationCenter.default
            .publisher(for: .contactListChanged)
            .map { _ in self.getContactMetadataList() }
            .prepend(getContactMetadataList())
            .eraseToAnyPublisher()
    }
    
    /// Publisher for contact updates
    func contactPublisher(id: UUID) -> AnyPublisher<Contact?, Never> {
        return NotificationCenter.default
            .publisher(for: .contactUpdated)
            .compactMap { notification in
                guard let contactId = notification.userInfo?["contactId"] as? UUID,
                      contactId == id else { return nil }
                return self.getContact(id: id)
            }
            .prepend(getContact(id: id))
            .eraseToAnyPublisher()
    }
    
    /// Publisher for search results
    func searchPublisher(query: String) -> AnyPublisher<[Contact], Never> {
        return Just(query)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { query in
                query.isEmpty ? [] : self.searchContacts(query: query)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let contactListChanged = Notification.Name("contactListChanged")
    static let contactUpdated = Notification.Name("contactUpdated")
}

// MARK: - Batch Operations

extension OptimizedContactManager {
    /// Batch update multiple contacts efficiently
    func batchUpdateContacts(_ updates: [(UUID, (Contact) -> Contact)]) throws {
        try performanceMonitor.measureMemoryUsage("optimized_batch_update_contacts") { [weak self] in
            guard let self = self else { return }
            
            for (id, updateBlock) in updates {
                if let contact = self.getContact(id: id) {
                    let updatedContact = updateBlock(contact)
                    try self.baseManager.updateContact(updatedContact)
                }
            }
            
            // Invalidate caches once after all updates
            self.invalidateCaches()
            self.loadContactMetadataCache()
        }.result
    }
    
    /// Get multiple contacts efficiently
    func getContacts(ids: [UUID]) -> [Contact] {
        return performanceMonitor.measureCryptoOperation("optimized_get_multiple_contacts") { [weak self] in
            guard let self = self else { return [] }
            
            return ids.compactMap { id in
                self.lazyLoadingService.loadFullContact(id: id)
            }
        }.result
    }
}