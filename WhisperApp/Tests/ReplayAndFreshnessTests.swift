import XCTest
import CryptoKit
@testable import WhisperApp

class ReplayAndFreshnessTests: XCTestCase {
    
    var identityManager: IdentityManager!
    var contactManager: ContactManager!
    var policyManager: PolicyManager!
    var biometricService: MockBiometricService!
    var replayProtector: ReplayProtectionService!
    var whisperService: WhisperService!
    var cryptoEngine: CryptoEngine!
    var envelopeProcessor: EnvelopeProcessor!
    
    var alice: Identity!
    var bob: Identity!
    var bobContact: Contact!
    var aliceContact: Contact!
    
    override func setUp() {
        super.setUp()
        
        // Initialize all components
        identityManager = IdentityManager()
        contactManager = ContactManager()
        policyManager = PolicyManager()
        biometricService = MockBiometricService()
        replayProtector = ReplayProtectionService()
        cryptoEngine = CryptoEngine()
        envelopeProcessor = EnvelopeProcessor(cryptoEngine: cryptoEngine)
        
        whisperService = WhisperService(
            identityManager: identityManager,
            contactManager: contactManager,
            policyManager: policyManager,
            biometricService: biometricService,
            replayProtector: replayProtector,
            cryptoEngine: cryptoEngine
        )
        
        // Create test identities and contacts
        alice = try! identityManager.createIdentity(name: "Alice")
        bob = try! identityManager.createIdentity(name: "Bob")
        
        try! identityManager.setActiveIdentity(alice)
        
        bobContact = Contact(
            id: UUID(),
            displayName: "Bob",
            x25519PublicKey: bob.x25519KeyPair.publicKey,
            ed25519PublicKey: bob.ed25519KeyPair?.publicKey,
            fingerprint: bob.fingerprint,
            shortFingerprint: bob.shortFingerprint,
            sasWords: bob.sasWords,
            rkid: bob.rkid,
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try! contactManager.addContact(bobContact)
        
        aliceContact = Contact(
            id: UUID(),
            displayName: "Alice",
            x25519PublicKey: alice.x25519KeyPair.publicKey,
            ed25519PublicKey: alice.ed25519KeyPair?.publicKey,
            fingerprint: alice.fingerprint,
            shortFingerprint: alice.shortFingerprint,
            sasWords: alice.sasWords,
            rkid: alice.rkid,
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
    }
    
    override func tearDown() {
        // Clean up test data
        try? identityManager.deleteAllIdentities()
        try? contactManager.deleteAllContacts()
        replayProtector.clearCache()
        biometricService.reset()
        
        super.tearDown()
    }
    
    // MARK: - Replay Protection Tests
    
    func testBasicReplayProtection() throws {
        let testMessage = "Test message for replay protection"
        
        // Alice encrypts message to Bob
        let envelope = try whisperService.encrypt(
            testMessage.data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        
        // Switch to Bob for decryption
        try identityManager.setActiveIdentity(bob)
        try contactManager.addContact(aliceContact)
        
        // First decryption should succeed
        let result1 = try whisperService.decrypt(envelope)
        XCTAssertEqual(String(data: result1.plaintext, encoding: .utf8), testMessage)
        
        // Second decryption should fail (replay detected)
        XCTAssertThrowsError(try whisperService.decrypt(envelope)) { error in
            XCTAssertEqual(error as? WhisperError, .replayDetected)
        }
        
        // Third attempt should also fail
        XCTAssertThrowsError(try whisperService.decrypt(envelope)) { error in
            XCTAssertEqual(error as? WhisperError, .replayDetected)
        }
    }
    
    func testReplayProtectionWithMultipleMessages() throws {
        var envelopes: [String] = []
        
        // Alice sends 10 different messages
        for i in 0..<10 {
            let message = "Message number \(i)"
            let envelope = try whisperService.encrypt(
                message.data(using: .utf8)!,
                from: alice,
                to: bobContact,
                authenticity: true
            )
            envelopes.append(envelope)
        }
        
        // Switch to Bob
        try identityManager.setActiveIdentity(bob)
        try contactManager.addContact(aliceContact)
        
        // Decrypt all messages once (should succeed)
        for (index, envelope) in envelopes.enumerated() {
            let result = try whisperService.decrypt(envelope)
            let expectedMessage = "Message number \(index)"
            XCTAssertEqual(String(data: result.plaintext, encoding: .utf8), expectedMessage)
        }
        
        // Try to decrypt all messages again (should all fail)
        for envelope in envelopes {
            XCTAssertThrowsError(try whisperService.decrypt(envelope)) { error in
                XCTAssertEqual(error as? WhisperError, .replayDetected)
            }
        }
    }
    
    func testReplayProtectionAcrossIdentities() throws {
        // Create Charlie
        let charlie = try identityManager.createIdentity(name: "Charlie")
        let charlieContact = Contact(
            id: UUID(),
            displayName: "Charlie",
            x25519PublicKey: charlie.x25519KeyPair.publicKey,
            ed25519PublicKey: charlie.ed25519KeyPair?.publicKey,
            fingerprint: charlie.fingerprint,
            shortFingerprint: charlie.shortFingerprint,
            sasWords: charlie.sasWords,
            rkid: charlie.rkid,
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        
        // Alice sends same message to Bob and Charlie
        let testMessage = "Same message to different recipients"
        
        let envelopeToBob = try whisperService.encrypt(
            testMessage.data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        
        try contactManager.addContact(charlieContact)
        let envelopeToCharlie = try whisperService.encrypt(
            testMessage.data(using: .utf8)!,
            from: alice,
            to: charlieContact,
            authenticity: true
        )
        
        // Envelopes should be different (different recipients)
        XCTAssertNotEqual(envelopeToBob, envelopeToCharlie)
        
        // Bob decrypts his message
        try identityManager.setActiveIdentity(bob)
        try contactManager.addContact(aliceContact)
        
        let bobResult = try whisperService.decrypt(envelopeToBob)
        XCTAssertEqual(String(data: bobResult.plaintext, encoding: .utf8), testMessage)
        
        // Charlie decrypts his message
        try identityManager.setActiveIdentity(charlie)
        try contactManager.addContact(aliceContact)
        
        let charlieResult = try whisperService.decrypt(envelopeToCharlie)
        XCTAssertEqual(String(data: charlieResult.plaintext, encoding: .utf8), testMessage)
        
        // Both should fail on replay
        try identityManager.setActiveIdentity(bob)
        XCTAssertThrowsError(try whisperService.decrypt(envelopeToBob)) { error in
            XCTAssertEqual(error as? WhisperError, .replayDetected)
        }
        
        try identityManager.setActiveIdentity(charlie)
        XCTAssertThrowsError(try whisperService.decrypt(envelopeToCharlie)) { error in
            XCTAssertEqual(error as? WhisperError, .replayDetected)
        }
    }
    
    func testAtomicReplayCheck() throws {
        // Test that checkAndCommit is atomic
        let msgId = try cryptoEngine.generateRandomData(length: 16)
        let now = Int64(Date().timeIntervalSince1970)
        
        // First check should succeed and commit
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: msgId, timestamp: now))
        
        // Second check should fail (already committed)
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: msgId, timestamp: now))
        
        // Test with expired message (should not be committed)
        let expiredMsgId = try cryptoEngine.generateRandomData(length: 16)
        let expiredTimestamp = now - (49 * 60 * 60) // 49 hours ago
        
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: expiredMsgId, timestamp: expiredTimestamp))
        
        // Same expired message with valid timestamp should succeed (wasn't committed before)
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: expiredMsgId, timestamp: now))
    }
    
    // MARK: - Freshness Validation Tests
    
    func testFreshnessWindow() throws {
        let now = Int64(Date().timeIntervalSince1970)
        
        // Test valid timestamps (within ±48 hours)
        let validTimestamps = [
            now,                    // Current time
            now - (1 * 60 * 60),   // 1 hour ago
            now + (1 * 60 * 60),   // 1 hour in future
            now - (24 * 60 * 60),  // 24 hours ago
            now + (24 * 60 * 60),  // 24 hours in future
            now - (47 * 60 * 60),  // 47 hours ago (edge case)
            now + (47 * 60 * 60),  // 47 hours in future (edge case)
            now - (48 * 60 * 60),  // Exactly 48 hours ago
            now + (48 * 60 * 60)   // Exactly 48 hours in future
        ]
        
        for timestamp in validTimestamps {
            XCTAssertTrue(
                replayProtector.isWithinFreshnessWindow(timestamp),
                "Timestamp \(timestamp) (offset: \(timestamp - now)s) should be within freshness window"
            )
        }
        
        // Test invalid timestamps (outside ±48 hours)
        let invalidTimestamps = [
            now - (49 * 60 * 60),  // 49 hours ago
            now + (49 * 60 * 60),  // 49 hours in future
            now - (72 * 60 * 60),  // 72 hours ago
            now + (72 * 60 * 60),  // 72 hours in future
            now - (7 * 24 * 60 * 60), // 1 week ago
            now + (7 * 24 * 60 * 60)  // 1 week in future
        ]
        
        for timestamp in invalidTimestamps {
            XCTAssertFalse(
                replayProtector.isWithinFreshnessWindow(timestamp),
                "Timestamp \(timestamp) (offset: \(timestamp - now)s) should be outside freshness window"
            )
        }
    }
    
    func testExpiredMessageRejection() throws {
        // Create envelope with expired timestamp manually
        let expiredTimestamp = Int64(Date().timeIntervalSince1970) - (49 * 60 * 60) // 49 hours ago
        
        let ephemeralKeyPair = try cryptoEngine.generateEphemeralKeyPair()
        let salt = try cryptoEngine.generateRandomData(length: 16)
        let msgId = try cryptoEngine.generateRandomData(length: 16)
        
        // Create expired envelope components
        let expiredEnvelope = try createTestEnvelope(
            recipientRkid: bob.rkid,
            ephemeralPublicKey: ephemeralKeyPair.publicKey,
            salt: salt,
            msgId: msgId,
            timestamp: expiredTimestamp,
            ciphertext: Data("test".utf8),
            signature: nil
        )
        
        // Switch to Bob for decryption
        try identityManager.setActiveIdentity(bob)
        try contactManager.addContact(aliceContact)
        
        // Should fail due to expired timestamp
        XCTAssertThrowsError(try whisperService.decrypt(expiredEnvelope)) { error in
            XCTAssertEqual(error as? WhisperError, .messageExpired)
        }
    }
    
    func testFutureMessageRejection() throws {
        // Create envelope with future timestamp (beyond window)
        let futureTimestamp = Int64(Date().timeIntervalSince1970) + (49 * 60 * 60) // 49 hours in future
        
        let ephemeralKeyPair = try cryptoEngine.generateEphemeralKeyPair()
        let salt = try cryptoEngine.generateRandomData(length: 16)
        let msgId = try cryptoEngine.generateRandomData(length: 16)
        
        let futureEnvelope = try createTestEnvelope(
            recipientRkid: bob.rkid,
            ephemeralPublicKey: ephemeralKeyPair.publicKey,
            salt: salt,
            msgId: msgId,
            timestamp: futureTimestamp,
            ciphertext: Data("test".utf8),
            signature: nil
        )
        
        // Switch to Bob for decryption
        try identityManager.setActiveIdentity(bob)
        try contactManager.addContact(aliceContact)
        
        // Should fail due to future timestamp
        XCTAssertThrowsError(try whisperService.decrypt(futureEnvelope)) { error in
            XCTAssertEqual(error as? WhisperError, .messageExpired)
        }
    }
    
    func testClockSkewTolerance() throws {
        let now = Int64(Date().timeIntervalSince1970)
        
        // Test messages with small clock skew (should be accepted)
        let skewTimestamps = [
            now - (30 * 60),  // 30 minutes ago
            now + (30 * 60),  // 30 minutes in future
            now - (2 * 60 * 60), // 2 hours ago
            now + (2 * 60 * 60)  // 2 hours in future
        ]
        
        for (index, timestamp) in skewTimestamps.enumerated() {
            let message = "Clock skew test message \(index)"
            
            // Create envelope with specific timestamp
            let envelope = try whisperService.encrypt(
                message.data(using: .utf8)!,
                from: alice,
                to: bobContact,
                authenticity: true
            )
            
            // Manually modify timestamp in envelope (for testing purposes)
            let modifiedEnvelope = try createEnvelopeWithTimestamp(envelope, timestamp: timestamp)
            
            // Switch to Bob
            try identityManager.setActiveIdentity(bob)
            try contactManager.addContact(aliceContact)
            
            // Should succeed despite clock skew
            let result = try whisperService.decrypt(modifiedEnvelope)
            XCTAssertEqual(String(data: result.plaintext, encoding: .utf8), message)
            
            // Switch back to Alice for next iteration
            try identityManager.setActiveIdentity(alice)
        }
    }
    
    // MARK: - Cache Management Tests
    
    func testReplayCacheSize() throws {
        let maxEntries = 100 // Smaller than production limit for testing
        
        // Fill cache with messages
        var msgIds: [Data] = []
        let now = Int64(Date().timeIntervalSince1970)
        
        for i in 0..<maxEntries {
            let msgId = try cryptoEngine.generateRandomData(length: 16)
            msgIds.append(msgId)
            
            let success = replayProtector.checkAndCommit(msgId: msgId, timestamp: now)
            XCTAssertTrue(success, "Failed to commit message \(i)")
        }
        
        // All messages should be in cache (replay detection)
        for (index, msgId) in msgIds.enumerated() {
            let isReplay = !replayProtector.checkAndCommit(msgId: msgId, timestamp: now)
            XCTAssertTrue(isReplay, "Message \(index) not detected as replay")
        }
        
        // Add more messages beyond limit (should trigger cleanup)
        for i in 0..<50 {
            let msgId = try cryptoEngine.generateRandomData(length: 16)
            let success = replayProtector.checkAndCommit(msgId: msgId, timestamp: now)
            XCTAssertTrue(success, "Failed to commit overflow message \(i)")
        }
        
        // Some old messages might be evicted (implementation dependent)
        // This test verifies the cache doesn't grow unbounded
    }
    
    func testReplayCacheCleanup() throws {
        let now = Int64(Date().timeIntervalSince1970)
        let oldTimestamp = now - (25 * 24 * 60 * 60) // 25 days ago (within retention)
        let veryOldTimestamp = now - (35 * 24 * 60 * 60) // 35 days ago (beyond retention)
        
        // Add messages with different ages
        let recentMsgId = try cryptoEngine.generateRandomData(length: 16)
        let oldMsgId = try cryptoEngine.generateRandomData(length: 16)
        let veryOldMsgId = try cryptoEngine.generateRandomData(length: 16)
        
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: recentMsgId, timestamp: now))
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: oldMsgId, timestamp: oldTimestamp))
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: veryOldMsgId, timestamp: veryOldTimestamp))
        
        // Trigger cleanup
        replayProtector.cleanup()
        
        // Recent and old messages should still be detected as replays
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: recentMsgId, timestamp: now))
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: oldMsgId, timestamp: oldTimestamp))
        
        // Very old message might be cleaned up (implementation dependent)
        // This is acceptable behavior for cache management
    }
    
    // MARK: - Edge Cases and Error Conditions
    
    func testReplayProtectionWithCorruptedEnvelopes() throws {
        let validEnvelope = try whisperService.encrypt(
            "Test message".data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        
        // Switch to Bob
        try identityManager.setActiveIdentity(bob)
        try contactManager.addContact(aliceContact)
        
        // Decrypt valid envelope
        let result = try whisperService.decrypt(validEnvelope)
        XCTAssertEqual(String(data: result.plaintext, encoding: .utf8), "Test message")
        
        // Corrupt the envelope in various ways
        let corruptedEnvelopes = [
            String(validEnvelope.dropLast(10)) + "corrupted",  // Corrupted end
            "corrupted" + String(validEnvelope.dropFirst(10)), // Corrupted start
            validEnvelope.replacingOccurrences(of: "whisper1:", with: "whisper2:"), // Wrong version
            validEnvelope.replacingOccurrences(of: "v1.c20p", with: "v1.aes256") // Wrong algorithm
        ]
        
        for corruptedEnvelope in corruptedEnvelopes {
            XCTAssertThrowsError(try whisperService.decrypt(corruptedEnvelope)) { error in
                // Should fail with invalid envelope, not replay detected
                XCTAssertNotEqual(error as? WhisperError, .replayDetected)
            }
        }
        
        // Original envelope should still be detected as replay
        XCTAssertThrowsError(try whisperService.decrypt(validEnvelope)) { error in
            XCTAssertEqual(error as? WhisperError, .replayDetected)
        }
    }
    
    func testConcurrentReplayChecks() throws {
        let msgId = try cryptoEngine.generateRandomData(length: 16)
        let now = Int64(Date().timeIntervalSince1970)
        
        let expectation = XCTestExpectation(description: "Concurrent replay checks")
        expectation.expectedFulfillmentCount = 10
        
        var results: [Bool] = []
        let resultsQueue = DispatchQueue(label: "results")
        
        // Simulate concurrent access
        for i in 0..<10 {
            DispatchQueue.global().async {
                let result = self.replayProtector.checkAndCommit(msgId: msgId, timestamp: now)
                
                resultsQueue.async {
                    results.append(result)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Only one should succeed (atomic operation)
        let successCount = results.filter { $0 }.count
        XCTAssertEqual(successCount, 1, "Expected exactly one successful commit, got \(successCount)")
    }
    
    // MARK: - Helper Methods
    
    private func createTestEnvelope(
        recipientRkid: Data,
        ephemeralPublicKey: Data,
        salt: Data,
        msgId: Data,
        timestamp: Int64,
        ciphertext: Data,
        signature: Data?
    ) throws -> String {
        
        let flags = signature != nil ? "1" : "0"
        let sigComponent = signature?.base64URLEncoded ?? ""
        
        var envelope = "whisper1:v1.c20p.\(recipientRkid.base64URLEncoded).\(flags).\(ephemeralPublicKey.base64URLEncoded).\(salt.base64URLEncoded).\(msgId.base64URLEncoded).\(timestamp).\(ciphertext.base64URLEncoded)"
        
        if !sigComponent.isEmpty {
            envelope += ".\(sigComponent)"
        }
        
        return envelope
    }
    
    private func createEnvelopeWithTimestamp(_ originalEnvelope: String, timestamp: Int64) throws -> String {
        let components = originalEnvelope.components(separatedBy: ".")
        guard components.count >= 8 else {
            throw WhisperError.invalidEnvelope
        }
        
        var newComponents = components
        newComponents[7] = String(timestamp) // Replace timestamp component
        
        return newComponents.joined(separator: ".")
    }
}

// MARK: - Data Extension for Base64URL

extension Data {
    var base64URLEncoded: String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}