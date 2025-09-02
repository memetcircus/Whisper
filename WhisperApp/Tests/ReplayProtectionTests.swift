import XCTest
import CoreData
@testable import WhisperApp

class ReplayProtectionTests: XCTestCase {
    var replayProtector: ReplayProtectionService!
    var persistentContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        persistentContainer = NSPersistentContainer(name: "WhisperDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        
        replayProtector = ReplayProtectionService(persistentContainer: persistentContainer)
    }
    
    override func tearDown() {
        replayProtector = nil
        persistentContainer = nil
        super.tearDown()
    }
    
    // MARK: - Freshness Window Tests
    
    func testFreshnessWindowValidation() {
        let now = Int64(Date().timeIntervalSince1970)
        
        // Test valid timestamps within ±48 hours
        XCTAssertTrue(replayProtector.isWithinFreshnessWindow(now))
        XCTAssertTrue(replayProtector.isWithinFreshnessWindow(now - (47 * 60 * 60))) // 47 hours ago
        XCTAssertTrue(replayProtector.isWithinFreshnessWindow(now + (47 * 60 * 60))) // 47 hours future
        
        // Test invalid timestamps outside ±48 hours
        XCTAssertFalse(replayProtector.isWithinFreshnessWindow(now - (49 * 60 * 60))) // 49 hours ago
        XCTAssertFalse(replayProtector.isWithinFreshnessWindow(now + (49 * 60 * 60))) // 49 hours future
        
        // Test edge cases
        XCTAssertTrue(replayProtector.isWithinFreshnessWindow(now - (48 * 60 * 60))) // Exactly 48 hours ago
        XCTAssertTrue(replayProtector.isWithinFreshnessWindow(now + (48 * 60 * 60))) // Exactly 48 hours future
    }
    
    // MARK: - Atomic Check and Commit Tests
    
    func testFirstMessageAccepted() async {
        let msgId = generateRandomMessageId()
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: timestamp)
        
        XCTAssertTrue(result, "First message should be accepted")
        
        let cacheSize = await replayProtector.cacheSize
        XCTAssertEqual(cacheSize, 1, "Cache should contain one entry")
    }
    
    func testReplayDetection() async {
        let msgId = generateRandomMessageId()
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        // First message should be accepted
        let firstResult = await replayProtector.checkAndCommit(msgId: msgId, timestamp: timestamp)
        XCTAssertTrue(firstResult, "First message should be accepted")
        
        // Second message with same ID should be rejected
        let secondResult = await replayProtector.checkAndCommit(msgId: msgId, timestamp: timestamp)
        XCTAssertFalse(secondResult, "Replay message should be rejected")
        
        let cacheSize = await replayProtector.cacheSize
        XCTAssertEqual(cacheSize, 1, "Cache should still contain only one entry")
    }
    
    func testExpiredMessageRejection() async {
        let msgId = generateRandomMessageId()
        let expiredTimestamp = Int64(Date().timeIntervalSince1970) - (50 * 60 * 60) // 50 hours ago
        
        let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: expiredTimestamp)
        
        XCTAssertFalse(result, "Expired message should be rejected")
        
        let cacheSize = await replayProtector.cacheSize
        XCTAssertEqual(cacheSize, 0, "Expired message should not be committed to cache")
    }
    
    func testFutureExpiredMessageRejection() async {
        let msgId = generateRandomMessageId()
        let futureTimestamp = Int64(Date().timeIntervalSince1970) + (50 * 60 * 60) // 50 hours future
        
        let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: futureTimestamp)
        
        XCTAssertFalse(result, "Future expired message should be rejected")
        
        let cacheSize = await replayProtector.cacheSize
        XCTAssertEqual(cacheSize, 0, "Future expired message should not be committed to cache")
    }
    
    func testMultipleUniqueMessages() async {
        let timestamp = Int64(Date().timeIntervalSince1970)
        let messageCount = 100
        
        for i in 0..<messageCount {
            let msgId = generateRandomMessageId()
            let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: timestamp + Int64(i))
            XCTAssertTrue(result, "Unique message \(i) should be accepted")
        }
        
        let cacheSize = await replayProtector.cacheSize
        XCTAssertEqual(cacheSize, messageCount, "Cache should contain all unique messages")
    }
    
    // MARK: - Cache Size Management Tests
    
    func testCacheSizeLimit() async {
        let timestamp = Int64(Date().timeIntervalSince1970)
        let messageCount = 10_500 // Exceed the 10,000 limit
        
        // Add messages up to and beyond the limit
        for i in 0..<messageCount {
            let msgId = generateRandomMessageId()
            let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: timestamp + Int64(i))
            XCTAssertTrue(result, "Message \(i) should be accepted")
        }
        
        let cacheSize = await replayProtector.cacheSize
        XCTAssertLessThanOrEqual(cacheSize, 10_000, "Cache size should not exceed limit after cleanup")
    }
    
    // MARK: - Cleanup Tests
    
    func testPeriodicCleanup() async {
        // Add some old entries by manipulating the receivedAt date
        let context = persistentContainer.viewContext
        let oldDate = Calendar.current.date(byAdding: .day, value: -35, to: Date())!
        
        for i in 0..<10 {
            let entity = ReplayProtectionEntity(context: context)
            entity.messageId = generateRandomMessageId()
            entity.timestamp = Int64(Date().timeIntervalSince1970)
            entity.receivedAt = oldDate
        }
        
        try! context.save()
        
        // Add some recent entries
        let recentTimestamp = Int64(Date().timeIntervalSince1970)
        for i in 0..<5 {
            let msgId = generateRandomMessageId()
            let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: recentTimestamp + Int64(i))
            XCTAssertTrue(result, "Recent message should be accepted")
        }
        
        let initialSize = await replayProtector.cacheSize
        XCTAssertEqual(initialSize, 15, "Should have 15 total entries")
        
        // Perform cleanup
        await replayProtector.cleanup()
        
        let finalSize = await replayProtector.cacheSize
        XCTAssertEqual(finalSize, 5, "Should have only 5 recent entries after cleanup")
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentAccess() async {
        let timestamp = Int64(Date().timeIntervalSince1970)
        let taskCount = 50
        
        // Create concurrent tasks
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<taskCount {
                group.addTask {
                    let msgId = self.generateRandomMessageId()
                    return await self.replayProtector.checkAndCommit(msgId: msgId, timestamp: timestamp + Int64(i))
                }
            }
            
            var successCount = 0
            for await result in group {
                if result {
                    successCount += 1
                }
            }
            
            XCTAssertEqual(successCount, taskCount, "All concurrent unique messages should be accepted")
        }
        
        let cacheSize = await replayProtector.cacheSize
        XCTAssertEqual(cacheSize, taskCount, "Cache should contain all concurrent messages")
    }
    
    func testConcurrentReplayDetection() async {
        let msgId = generateRandomMessageId()
        let timestamp = Int64(Date().timeIntervalSince1970)
        let taskCount = 10
        
        // Create concurrent tasks with the same message ID
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    return await self.replayProtector.checkAndCommit(msgId: msgId, timestamp: timestamp)
                }
            }
            
            var successCount = 0
            for await result in group {
                if result {
                    successCount += 1
                }
            }
            
            XCTAssertEqual(successCount, 1, "Only one concurrent message with same ID should be accepted")
        }
        
        let cacheSize = await replayProtector.cacheSize
        XCTAssertEqual(cacheSize, 1, "Cache should contain only one entry")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyMessageId() async {
        let emptyMsgId = Data()
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        let result = await replayProtector.checkAndCommit(msgId: emptyMsgId, timestamp: timestamp)
        XCTAssertTrue(result, "Empty message ID should be accepted (though not recommended)")
    }
    
    func testLargeMessageId() async {
        let largeMsgId = Data(repeating: 0xFF, count: 1024) // Much larger than expected 16 bytes
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        let result = await replayProtector.checkAndCommit(msgId: largeMsgId, timestamp: timestamp)
        XCTAssertTrue(result, "Large message ID should be accepted")
    }
    
    func testZeroTimestamp() async {
        let msgId = generateRandomMessageId()
        let zeroTimestamp: Int64 = 0
        
        let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: zeroTimestamp)
        XCTAssertFalse(result, "Zero timestamp should be rejected as expired")
    }
    
    func testNegativeTimestamp() async {
        let msgId = generateRandomMessageId()
        let negativeTimestamp: Int64 = -1000
        
        let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: negativeTimestamp)
        XCTAssertFalse(result, "Negative timestamp should be rejected as expired")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeCache() async {
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        // Pre-populate cache with 5000 entries
        for i in 0..<5000 {
            let msgId = generateRandomMessageId()
            let result = await replayProtector.checkAndCommit(msgId: msgId, timestamp: timestamp + Int64(i))
            XCTAssertTrue(result)
        }
        
        // Measure performance of new message check
        let newMsgId = generateRandomMessageId()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = await replayProtector.checkAndCommit(msgId: newMsgId, timestamp: timestamp + 5000)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertTrue(result, "New message should be accepted")
        XCTAssertLessThan(timeElapsed, 0.1, "Check should complete within 100ms even with large cache")
    }
    
    // MARK: - Helper Methods
    
    private func generateRandomMessageId() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        XCTAssertEqual(result, errSecSuccess, "Failed to generate random bytes")
        return Data(bytes)
    }
}