import Foundation
import CoreData
import os.log

/// Core Data-backed replay protection service with atomic operations
class ReplayProtectionService: ReplayProtector {
    private let persistentContainer: NSPersistentContainer
    private let logger = Logger(subsystem: "com.whisper.app", category: "ReplayProtection")
    
    // Configuration constants
    private let maxEntries = 10_000
    private let retentionDays = 30
    private let freshnessWindowHours = 48
    
    // Background context for cleanup operations
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        
        // Schedule periodic cleanup
        schedulePeriodicCleanup()
    }
    
    /// Atomically checks message uniqueness and commits if valid
    func checkAndCommit(msgId: Data, timestamp: Int64) async -> Bool {
        return await withCheckedContinuation { continuation in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                do {
                    // First check freshness - don't commit expired messages
                    guard self.isWithinFreshnessWindow(timestamp) else {
                        self.logger.debug("Message rejected: expired timestamp \(timestamp)")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    // Check for existing message ID (replay detection)
                    let fetchRequest: NSFetchRequest<ReplayProtectionEntity> = ReplayProtectionEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "messageId == %@", msgId as NSData)
                    fetchRequest.fetchLimit = 1
                    
                    let existingEntries = try context.fetch(fetchRequest)
                    
                    if !existingEntries.isEmpty {
                        self.logger.debug("Message rejected: replay detected")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    // Check cache size and cleanup if needed
                    let countRequest: NSFetchRequest<ReplayProtectionEntity> = ReplayProtectionEntity.fetchRequest()
                    let currentCount = try context.count(for: countRequest)
                    
                    if currentCount >= self.maxEntries {
                        // Perform immediate cleanup of oldest entries
                        try self.performCleanup(in: context, targetCount: self.maxEntries - 1000)
                    }
                    
                    // Create new entry
                    let entity = ReplayProtectionEntity(context: context)
                    entity.messageId = msgId
                    entity.timestamp = timestamp
                    entity.receivedAt = Date()
                    
                    // Atomic save
                    try context.save()
                    
                    self.logger.debug("Message committed to replay cache")
                    continuation.resume(returning: true)
                    
                } catch {
                    self.logger.error("Replay protection error: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    /// Checks if timestamp is within freshness window (±48 hours)
    func isWithinFreshnessWindow(_ timestamp: Int64) -> Bool {
        let now = Int64(Date().timeIntervalSince1970)
        let windowSeconds: Int64 = Int64(freshnessWindowHours * 60 * 60)
        let timeDifference = abs(now - timestamp)
        
        return timeDifference <= windowSeconds
    }
    
    /// Performs cleanup of expired entries
    func cleanup() async {
        await withCheckedContinuation { continuation in
            backgroundContext.perform {
                do {
                    try self.performCleanup(in: self.backgroundContext)
                    self.logger.info("Replay cache cleanup completed")
                } catch {
                    self.logger.error("Cleanup failed: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }
    
    /// Gets current cache size
    var cacheSize: Int {
        get async {
            return await withCheckedContinuation { continuation in
                backgroundContext.perform {
                    do {
                        let fetchRequest: NSFetchRequest<ReplayProtectionEntity> = ReplayProtectionEntity.fetchRequest()
                        let count = try self.backgroundContext.count(for: fetchRequest)
                        continuation.resume(returning: count)
                    } catch {
                        self.logger.error("Failed to get cache size: \(error.localizedDescription)")
                        continuation.resume(returning: 0)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Performs cleanup in the given context
    private func performCleanup(in context: NSManagedObjectContext, targetCount: Int? = nil) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        
        // First, delete entries older than retention period
        let expiredFetchRequest: NSFetchRequest<NSFetchRequestResult> = ReplayProtectionEntity.fetchRequest()
        expiredFetchRequest.predicate = NSPredicate(format: "receivedAt < %@", cutoffDate as NSDate)
        
        let expiredDeleteRequest = NSBatchDeleteRequest(fetchRequest: expiredFetchRequest)
        expiredDeleteRequest.resultType = .resultTypeCount
        
        let expiredResult = try context.execute(expiredDeleteRequest) as? NSBatchDeleteResult
        let expiredDeleted = expiredResult?.result as? Int ?? 0
        
        logger.debug("Deleted \(expiredDeleted) expired entries")
        
        // If we still exceed limits, delete oldest entries
        if let targetCount = targetCount {
            let countRequest: NSFetchRequest<ReplayProtectionEntity> = ReplayProtectionEntity.fetchRequest()
            let currentCount = try context.count(for: countRequest)
            
            if currentCount > targetCount {
                let excessCount = currentCount - targetCount
                
                // Fetch oldest entries to delete
                let oldestFetchRequest: NSFetchRequest<NSFetchRequestResult> = ReplayProtectionEntity.fetchRequest()
                oldestFetchRequest.sortDescriptors = [NSSortDescriptor(key: "receivedAt", ascending: true)]
                oldestFetchRequest.fetchLimit = excessCount
                
                let oldestDeleteRequest = NSBatchDeleteRequest(fetchRequest: oldestFetchRequest)
                oldestDeleteRequest.resultType = .resultTypeCount
                
                let oldestResult = try context.execute(oldestDeleteRequest) as? NSBatchDeleteResult
                let oldestDeleted = oldestResult?.result as? Int ?? 0
                
                logger.debug("Deleted \(oldestDeleted) oldest entries to maintain size limit")
            }
        }
        
        try context.save()
    }
    
    /// Schedules periodic cleanup using background tasks
    private func schedulePeriodicCleanup() {
        // Schedule cleanup every 24 hours
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            Task {
                await self.cleanup()
            }
        }
        
        // Perform initial cleanup
        Task {
            await cleanup()
        }
    }
}

// MARK: - Core Data Extensions

extension ReplayProtectionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReplayProtectionEntity> {
        return NSFetchRequest<ReplayProtectionEntity>(entityName: "ReplayProtectionEntity")
    }
}