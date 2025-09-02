import Foundation
import CoreData

/// Core Data implementation of ReplayProtector
/// Provides atomic replay protection with persistent storage
class CoreDataReplayProtector: ReplayProtector {
    
    private let context: NSManagedObjectContext
    private let maxEntries = 10_000
    private let retentionDays = 30
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func checkAndCommit(msgId: Data, timestamp: Int64) async -> Bool {
        return await withCheckedContinuation { continuation in
            context.perform {
                // Check freshness first (±48 hours)
                guard self.isWithinFreshnessWindow(timestamp) else {
                    continuation.resume(returning: false) // Don't commit expired messages
                    return
                }
                
                // Check for existing entry (replay detection)
                let request: NSFetchRequest<ReplayProtectionEntity> = ReplayProtectionEntity.fetchRequest()
                request.predicate = NSPredicate(format: "messageId == %@", msgId as NSData)
                request.fetchLimit = 1
                
                do {
                    let existingEntries = try self.context.fetch(request)
                    if !existingEntries.isEmpty {
                        continuation.resume(returning: false) // Replay detected
                        return
                    }
                    
                    // Create new entry
                    let entity = ReplayProtectionEntity(context: self.context)
                    entity.messageId = msgId
                    entity.timestamp = timestamp
                    entity.receivedAt = Date()
                    
                    // Save changes
                    try self.context.save()
                    
                    // Cleanup if needed
                    Task {
                        await self.cleanupIfNeeded()
                    }
                    
                    continuation.resume(returning: true)
                    
                } catch {
                    print("Replay protection error: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    func isWithinFreshnessWindow(_ timestamp: Int64) -> Bool {
        let now = Int64(Date().timeIntervalSince1970)
        let windowSeconds: Int64 = 48 * 60 * 60 // 48 hours
        return abs(now - timestamp) <= windowSeconds
    }
    
    func cleanup() async {
        await withCheckedContinuation { continuation in
            context.perform {
                do {
                    // Remove entries older than retention period
                    let cutoffDate = Calendar.current.date(byAdding: .day, value: -self.retentionDays, to: Date()) ?? Date()
                    
                    let request: NSFetchRequest<NSFetchRequestResult> = ReplayProtectionEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "receivedAt < %@", cutoffDate as NSDate)
                    
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                    try self.context.execute(deleteRequest)
                    try self.context.save()
                    
                    continuation.resume(returning: ())
                } catch {
                    print("Cleanup error: \(error)")
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func cleanupIfNeeded() async {
        let count = await getEntryCount()
        if count > maxEntries {
            await cleanup()
        }
    }
    
    private func getEntryCount() async -> Int {
        return await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<ReplayProtectionEntity> = ReplayProtectionEntity.fetchRequest()
                do {
                    let count = try self.context.count(for: request)
                    continuation.resume(returning: count)
                } catch {
                    continuation.resume(returning: 0)
                }
            }
        }
    }
}