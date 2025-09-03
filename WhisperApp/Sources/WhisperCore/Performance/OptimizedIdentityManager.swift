import Foundation
import CoreData
import CryptoKit

/// Performance-optimized identity manager with lazy loading and caching
/// Reduces memory footprint and improves response times for identity operations
class OptimizedIdentityManager: IdentityManager {
    
    private let baseManager: CoreDataIdentityManager
    private let lazyLoadingService: LazyLoadingService
    private let performanceMonitor: PerformanceMonitor
    private let backgroundProcessor: BackgroundCryptoProcessor
    
    // Cache for frequently accessed data
    private var activeIdentityCache: Identity?
    private var identityListCache: [IdentityMetadata]?
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    private let queue = DispatchQueue(label: "optimized-identity-manager", qos: .userInitiated)
    
    init(
        baseManager: CoreDataIdentityManager,
        lazyLoadingService: LazyLoadingService,
        performanceMonitor: PerformanceMonitor,
        backgroundProcessor: BackgroundCryptoProcessor
    ) {
        self.baseManager = baseManager
        self.lazyLoadingService = lazyLoadingService
        self.performanceMonitor = performanceMonitor
        self.backgroundProcessor = backgroundProcessor
        
        // Preload frequently used data
        lazyLoadingService.preloadFrequentlyUsed()
    }
    
    // MARK: - Optimized Identity Operations
    
    func createIdentity(name: String) throws -> Identity {
        return try performanceMonitor.measureMemoryUsage("optimized_create_identity") { [weak self] in
            guard let self = self else { throw IdentityError.noActiveIdentity }
            
            let identity = try self.baseManager.createIdentity(name: name)
            
            // Invalidate caches
            self.invalidateCaches()
            
            return identity
        }.result
    }
    
    func listIdentities() -> [Identity] {
        return queue.sync { [weak self] in
            guard let self = self else { return [] }
            
            // Check if we can use cached metadata
            if let cached = self.identityListCache, self.isCacheValid() {
                // Convert metadata to full identities only when needed
                return cached.compactMap { metadata in
                    self.lazyLoadingService.loadFullIdentity(id: metadata.id)
                }
            }
            
            // Load fresh data
            let (identities, _) = self.performanceMonitor.measureCryptoOperation("optimized_list_identities") {
                return self.baseManager.listIdentities()
            }
            
            // Update cache with metadata only
            self.identityListCache = identities.map { identity in
                IdentityMetadata(
                    id: identity.id,
                    name: identity.name,
                    fingerprint: identity.fingerprint,
                    shortFingerprint: identity.shortFingerprint,
                    createdAt: identity.createdAt,
                    status: identity.status,
                    keyVersion: identity.keyVersion,
                    isActive: false // Will be updated when needed
                )
            }
            self.cacheTimestamp = Date()
            
            return identities
        }
    }
    
    func getActiveIdentity() -> Identity? {
        return queue.sync { [weak self] in
            guard let self = self else { return nil }
            
            // Check cache first
            if let cached = self.activeIdentityCache, self.isCacheValid() {
                return cached
            }
            
            // Load from base manager
            let (identity, _) = self.performanceMonitor.measureCryptoOperation("optimized_get_active_identity") {
                return self.baseManager.getActiveIdentity()
            }
            
            // Cache the result
            self.activeIdentityCache = identity
            self.cacheTimestamp = Date()
            
            return identity
        }
    }
    
    func setActiveIdentity(_ identity: Identity) throws {
        try performanceMonitor.measureCryptoOperation("optimized_set_active_identity") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.setActiveIdentity(identity)
            
            // Update cache
            self.activeIdentityCache = identity
            self.cacheTimestamp = Date()
        }.result
    }
    
    func archiveIdentity(_ identity: Identity) throws {
        try performanceMonitor.measureCryptoOperation("optimized_archive_identity") { [weak self] in
            guard let self = self else { return }
            
            try self.baseManager.archiveIdentity(identity)
            
            // Invalidate caches
            self.invalidateCaches()
        }.result
    }
    
    func rotateActiveIdentity() throws -> Identity {
        return try performanceMonitor.measureMemoryUsage("optimized_rotate_identity") { [weak self] in
            guard let self = self else { throw IdentityError.noActiveIdentity }
            
            let newIdentity = try self.baseManager.rotateActiveIdentity()
            
            // Update cache with new active identity
            self.activeIdentityCache = newIdentity
            self.cacheTimestamp = Date()
            
            // Invalidate list cache
            self.identityListCache = nil
            
            return newIdentity
        }.result
    }
    
    // MARK: - Background Operations
    
    func createIdentityInBackground(name: String) -> AnyPublisher<Identity, Error> {
        return backgroundProcessor.generateIdentityInBackground(name: name)
            .handleEvents(receiveOutput: { [weak self] _ in
                // Invalidate caches when background operation completes
                self?.invalidateCaches()
            })
            .eraseToAnyPublisher()
    }
    
    func rotateIdentityInBackground() -> AnyPublisher<Identity, Error> {
        guard let currentIdentity = getActiveIdentity() else {
            return Fail(error: IdentityError.noActiveIdentity)
                .eraseToAnyPublisher()
        }
        
        return backgroundProcessor.rotateIdentityInBackground(currentIdentity: currentIdentity)
            .handleEvents(receiveOutput: { [weak self] newIdentity in
                // Update cache with new identity
                self?.queue.async {
                    self?.activeIdentityCache = newIdentity
                    self?.cacheTimestamp = Date()
                    self?.identityListCache = nil
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Lazy Loading Operations
    
    func getIdentityMetadata(id: UUID) -> IdentityMetadata? {
        return lazyLoadingService.loadIdentityMetadata(id: id)
    }
    
    func getIdentityMetadataList() -> [IdentityMetadata] {
        return queue.sync { [weak self] in
            guard let self = self else { return [] }
            
            if let cached = self.identityListCache, self.isCacheValid() {
                return cached
            }
            
            // Load metadata only (much faster than full identities)
            let fullIdentities = self.baseManager.listIdentities()
            let metadata = fullIdentities.map { identity in
                IdentityMetadata(
                    id: identity.id,
                    name: identity.name,
                    fingerprint: identity.fingerprint,
                    shortFingerprint: identity.shortFingerprint,
                    createdAt: identity.createdAt,
                    status: identity.status,
                    keyVersion: identity.keyVersion,
                    isActive: false // Would need to check active status
                )
            }
            
            self.identityListCache = metadata
            self.cacheTimestamp = Date()
            
            return metadata
        }
    }
    
    // MARK: - Delegated Operations (No Optimization Needed)
    
    func exportPublicBundle(_ identity: Identity) throws -> Data {
        return try baseManager.exportPublicBundle(identity)
    }
    
    func importPublicBundle(_ data: Data) throws -> PublicKeyBundle {
        return try baseManager.importPublicBundle(data)
    }
    
    func backupIdentity(_ identity: Identity, passphrase: String) throws -> Data {
        return try performanceMonitor.measureMemoryUsage("optimized_backup_identity") { [weak self] in
            guard let self = self else { throw IdentityError.noActiveIdentity }
            return try self.baseManager.backupIdentity(identity, passphrase: passphrase)
        }.result
    }
    
    func restoreIdentity(from backup: Data, passphrase: String) throws -> Identity {
        return try performanceMonitor.measureMemoryUsage("optimized_restore_identity") { [weak self] in
            guard let self = self else { throw IdentityError.noActiveIdentity }
            
            let identity = try self.baseManager.restoreIdentity(from: backup, passphrase: passphrase)
            
            // Invalidate caches
            self.invalidateCaches()
            
            return identity
        }.result
    }
    
    func getIdentity(byRkid rkid: Data) -> Identity? {
        return performanceMonitor.measureCryptoOperation("optimized_get_identity_by_rkid") { [weak self] in
            guard let self = self else { return nil }
            
            // First try to find in metadata cache
            if let metadata = self.identityListCache?.first(where: { _ in
                // Would need to calculate rkid for comparison
                // For now, fall back to base manager
                return false
            }) {
                return self.lazyLoadingService.loadFullIdentity(id: metadata.id)
            }
            
            return self.baseManager.getIdentity(byRkid: rkid)
        }.result
    }
    
    func getIdentitiesNeedingRotationWarning() -> [Identity] {
        return performanceMonitor.measureCryptoOperation("optimized_get_rotation_warnings") { [weak self] in
            guard let self = self else { return [] }
            return self.baseManager.getIdentitiesNeedingRotationWarning()
        }.result
    }
    
    // MARK: - Cache Management
    
    private func invalidateCaches() {
        queue.async { [weak self] in
            self?.activeIdentityCache = nil
            self?.identityListCache = nil
            self?.cacheTimestamp = nil
        }
    }
    
    private func isCacheValid() -> Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheValidityDuration
    }
    
    // MARK: - Performance Monitoring
    
    func getPerformanceStatistics() -> [String: PerformanceStatistics] {
        let operations = [
            "optimized_create_identity",
            "optimized_list_identities",
            "optimized_get_active_identity",
            "optimized_set_active_identity",
            "optimized_archive_identity",
            "optimized_rotate_identity",
            "optimized_backup_identity",
            "optimized_restore_identity",
            "optimized_get_identity_by_rkid",
            "optimized_get_rotation_warnings"
        ]
        
        var statistics: [String: PerformanceStatistics] = [:]
        for operation in operations {
            if let stats = performanceMonitor.getStatistics(for: operation) {
                statistics[operation] = stats
            }
        }
        
        return statistics
    }
    
    func getCacheStatistics() -> CacheStatistics {
        return lazyLoadingService.getCacheStatistics()
    }
    
    func optimizeMemory() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Clear local caches
            self.invalidateCaches()
            
            // Clear lazy loading caches
            self.lazyLoadingService.clearCache()
            
            // Preload only essential data
            self.lazyLoadingService.preloadFrequentlyUsed()
        }
    }
}

// MARK: - Publisher Extensions

import Combine

extension OptimizedIdentityManager {
    /// Publisher for active identity changes
    var activeIdentityPublisher: AnyPublisher<Identity?, Never> {
        return NotificationCenter.default
            .publisher(for: .activeIdentityChanged)
            .map { _ in self.getActiveIdentity() }
            .prepend(getActiveIdentity())
            .eraseToAnyPublisher()
    }
    
    /// Publisher for identity list changes
    var identityListPublisher: AnyPublisher<[IdentityMetadata], Never> {
        return NotificationCenter.default
            .publisher(for: .identityListChanged)
            .map { _ in self.getIdentityMetadataList() }
            .prepend(getIdentityMetadataList())
            .eraseToAnyPublisher()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let activeIdentityChanged = Notification.Name("activeIdentityChanged")
    static let identityListChanged = Notification.Name("identityListChanged")
}