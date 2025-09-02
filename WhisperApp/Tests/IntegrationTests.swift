import XCTest
import CryptoKit
@testable import WhisperApp

class IntegrationTests: XCTestCase {
    
    var identityManager: IdentityManager!
    var contactManager: ContactManager!
    var policyManager: PolicyManager!
    var biometricService: MockBiometricService!
    var replayProtector: ReplayProtectionService!
    var whisperService: WhisperService!
    var cryptoEngine: CryptoEngine!
    
    override func setUp() {
        super.setUp()
        
        // Initialize all components
        identityManager = IdentityManager()
        contactManager = ContactManager()
        policyManager = PolicyManager()
        biometricService = MockBiometricService()
        replayProtector = ReplayProtectionService()
        cryptoEngine = CryptoEngine()
        
        whisperService = WhisperService(
            identityManager: identityManager,
            contactManager: contactManager,
            policyManager: policyManager,
            biometricService: biometricService,
            replayProtector: replayProtector,
            cryptoEngine: cryptoEngine
        )
        
        // Reset all policies to default state
        policyManager.contactRequiredToSend = false
        policyManager.requireSignatureForVerified = false
        policyManager.autoArchiveOnRotation = false
        policyManager.biometricGatedSigning = false
    }
    
    override func tearDown() {
        // Clean up test data
        try? identityManager.deleteAllIdentities()
        try? contactManager.deleteAllContacts()
        replayProtector.clearCache()
        biometricService.reset()
        
        super.tearDown()
    }
    
    // MARK: - Full Encrypt/Decrypt Cycle Tests
    
    func testBasicEncryptDecryptCycle() throws {
        // Create sender and receiver identities
        let senderIdentity = try identityManager.createIdentity(name: "Alice")
        let receiverIdentity = try identityManager.createIdentity(name: "Bob")
        
        // Set Alice as active identity
        try identityManager.setActiveIdentity(senderIdentity)
        
        // Add Bob as contact for Alice
        let bobContact = Contact(
            id: UUID(),
            displayName: "Bob",
            x25519PublicKey: receiverIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: receiverIdentity.ed25519KeyPair?.publicKey,
            fingerprint: receiverIdentity.fingerprint,
            shortFingerprint: receiverIdentity.shortFingerprint,
            sasWords: receiverIdentity.sasWords,
            rkid: receiverIdentity.rkid,
            trustLevel: .unverified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(bobContact)
        
        // Encrypt message from Alice to Bob
        let plaintext = "Hello Bob, this is a test message from Alice!"
        let envelope = try whisperService.encrypt(
            plaintext.data(using: .utf8)!,
            from: senderIdentity,
            to: bobContact,
            authenticity: false
        )
        
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
        
        // Switch to Bob's identity for decryption
        try identityManager.setActiveIdentity(receiverIdentity)
        
        // Add Alice as contact for Bob
        let aliceContact = Contact(
            id: UUID(),
            displayName: "Alice",
            x25519PublicKey: senderIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: senderIdentity.ed25519KeyPair?.publicKey,
            fingerprint: senderIdentity.fingerprint,
            shortFingerprint: senderIdentity.shortFingerprint,
            sasWords: senderIdentity.sasWords,
            rkid: senderIdentity.rkid,
            trustLevel: .unverified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(aliceContact)
        
        // Decrypt message as Bob
        let result = try whisperService.decrypt(envelope)
        
        XCTAssertEqual(String(data: result.plaintext, encoding: .utf8), plaintext)
        XCTAssertEqual(result.senderAttribution, "From: Alice")
        XCTAssertFalse(result.isSigned)
    }
    
    func testEncryptDecryptWithSignature() throws {
        // Create identities with signing keys
        let senderIdentity = try identityManager.createIdentity(name: "Alice")
        let receiverIdentity = try identityManager.createIdentity(name: "Bob")
        
        try identityManager.setActiveIdentity(senderIdentity)
        
        // Add Bob as verified contact
        let bobContact = Contact(
            id: UUID(),
            displayName: "Bob",
            x25519PublicKey: receiverIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: receiverIdentity.ed25519KeyPair?.publicKey,
            fingerprint: receiverIdentity.fingerprint,
            shortFingerprint: receiverIdentity.shortFingerprint,
            sasWords: receiverIdentity.sasWords,
            rkid: receiverIdentity.rkid,
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(bobContact)
        
        // Encrypt with signature
        let plaintext = "Signed message from Alice to Bob"
        let envelope = try whisperService.encrypt(
            plaintext.data(using: .utf8)!,
            from: senderIdentity,
            to: bobContact,
            authenticity: true
        )
        
        // Switch to Bob for decryption
        try identityManager.setActiveIdentity(receiverIdentity)
        
        let aliceContact = Contact(
            id: UUID(),
            displayName: "Alice",
            x25519PublicKey: senderIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: senderIdentity.ed25519KeyPair?.publicKey,
            fingerprint: senderIdentity.fingerprint,
            shortFingerprint: senderIdentity.shortFingerprint,
            sasWords: senderIdentity.sasWords,
            rkid: senderIdentity.rkid,
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(aliceContact)
        
        let result = try whisperService.decrypt(envelope)
        
        XCTAssertEqual(String(data: result.plaintext, encoding: .utf8), plaintext)
        XCTAssertEqual(result.senderAttribution, "From: Alice (Verified, Signed)")
        XCTAssertTrue(result.isSigned)
    }
    
    // MARK: - Cross-Identity Communication Tests
    
    func testMultipleIdentityCommunication() throws {
        // Create three identities
        let alice = try identityManager.createIdentity(name: "Alice")
        let bob = try identityManager.createIdentity(name: "Bob")
        let charlie = try identityManager.createIdentity(name: "Charlie")
        
        // Test Alice -> Bob -> Charlie message chain
        try identityManager.setActiveIdentity(alice)
        
        let bobContact = Contact(
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
        try contactManager.addContact(bobContact)
        
        // Alice sends to Bob
        let message1 = "Message from Alice to Bob"
        let envelope1 = try whisperService.encrypt(
            message1.data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        
        // Bob receives and forwards to Charlie
        try identityManager.setActiveIdentity(bob)
        
        let aliceContact = Contact(
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
        try contactManager.addContact(aliceContact)
        
        let charlieContact = Contact(
            id: UUID(),
            displayName: "Charlie",
            x25519PublicKey: charlie.x25519KeyPair.publicKey,
            ed25519PublicKey: charlie.ed25519KeyPair?.publicKey,
            fingerprint: charlie.fingerprint,
            shortFingerprint: charlie.shortFingerprint,
            sasWords: charlie.sasWords,
            rkid: charlie.rkid,
            trustLevel: .unverified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(charlieContact)
        
        let result1 = try whisperService.decrypt(envelope1)
        XCTAssertEqual(String(data: result1.plaintext, encoding: .utf8), message1)
        
        // Bob forwards to Charlie
        let message2 = "Forwarded: \(message1)"
        let envelope2 = try whisperService.encrypt(
            message2.data(using: .utf8)!,
            from: bob,
            to: charlieContact,
            authenticity: false
        )
        
        // Charlie receives
        try identityManager.setActiveIdentity(charlie)
        
        let bobContactForCharlie = Contact(
            id: UUID(),
            displayName: "Bob",
            x25519PublicKey: bob.x25519KeyPair.publicKey,
            ed25519PublicKey: bob.ed25519KeyPair?.publicKey,
            fingerprint: bob.fingerprint,
            shortFingerprint: bob.shortFingerprint,
            sasWords: bob.sasWords,
            rkid: bob.rkid,
            trustLevel: .unverified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(bobContactForCharlie)
        
        let result2 = try whisperService.decrypt(envelope2)
        XCTAssertEqual(String(data: result2.plaintext, encoding: .utf8), message2)
        XCTAssertEqual(result2.senderAttribution, "From: Bob")
    }
    
    func testWrongIdentityDecryption() throws {
        let alice = try identityManager.createIdentity(name: "Alice")
        let bob = try identityManager.createIdentity(name: "Bob")
        let charlie = try identityManager.createIdentity(name: "Charlie")
        
        try identityManager.setActiveIdentity(alice)
        
        let bobContact = Contact(
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
        try contactManager.addContact(bobContact)
        
        // Alice encrypts for Bob
        let envelope = try whisperService.encrypt(
            "Secret message for Bob".data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        
        // Charlie tries to decrypt (should fail)
        try identityManager.setActiveIdentity(charlie)
        
        XCTAssertThrowsError(try whisperService.decrypt(envelope)) { error in
            XCTAssertEqual(error as? WhisperError, .messageNotForMe)
        }
    }
}  
  
    // MARK: - Policy Matrix Tests (16 combinations)
    
    func testPolicyMatrix() throws {
        let alice = try identityManager.createIdentity(name: "Alice")
        let bob = try identityManager.createIdentity(name: "Bob")
        
        try identityManager.setActiveIdentity(alice)
        
        let bobContact = Contact(
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
        try contactManager.addContact(bobContact)
        
        let testMessage = "Policy test message".data(using: .utf8)!
        
        // Test all 16 combinations of 4 boolean policies
        let policies = [false, true]
        
        for contactRequired in policies {
            for signatureRequired in policies {
                for autoArchive in policies {
                    for biometricGated in policies {
                        
                        // Set policy combination
                        policyManager.contactRequiredToSend = contactRequired
                        policyManager.requireSignatureForVerified = signatureRequired
                        policyManager.autoArchiveOnRotation = autoArchive
                        policyManager.biometricGatedSigning = biometricGated
                        
                        // Configure biometric service for this test
                        biometricService.isAvailable = biometricGated
                        biometricService.shouldSucceed = true
                        
                        let policyDescription = "CR:\(contactRequired) SR:\(signatureRequired) AA:\(autoArchive) BG:\(biometricGated)"
                        
                        do {
                            // Test encryption to contact
                            let envelope = try whisperService.encrypt(
                                testMessage,
                                from: alice,
                                to: bobContact,
                                authenticity: signatureRequired
                            )
                            
                            XCTAssertTrue(envelope.hasPrefix("whisper1:"), "Failed for policy: \(policyDescription)")
                            
                            // Test raw key encryption (should fail if contact required)
                            if contactRequired {
                                XCTAssertThrowsError(
                                    try whisperService.encryptToRawKey(
                                        testMessage,
                                        from: alice,
                                        to: bob.x25519KeyPair.publicKey,
                                        authenticity: false
                                    )
                                ) { error in
                                    XCTAssertEqual(error as? WhisperError, .policyViolation(.rawKeyBlocked))
                                }
                            } else {
                                let rawEnvelope = try whisperService.encryptToRawKey(
                                    testMessage,
                                    from: alice,
                                    to: bob.x25519KeyPair.publicKey,
                                    authenticity: false
                                )
                                XCTAssertTrue(rawEnvelope.hasPrefix("whisper1:"))
                            }
                            
                        } catch {
                            // Some policy combinations might legitimately fail
                            if signatureRequired && biometricGated && !biometricService.shouldSucceed {
                                XCTAssertEqual(error as? WhisperError, .policyViolation(.biometricRequired))
                            } else {
                                XCTFail("Unexpected error for policy \(policyDescription): \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testContactRequiredPolicy() throws {
        let alice = try identityManager.createIdentity(name: "Alice")
        let bob = try identityManager.createIdentity(name: "Bob")
        
        try identityManager.setActiveIdentity(alice)
        policyManager.contactRequiredToSend = true
        
        let testMessage = "Test message".data(using: .utf8)!
        
        // Should fail to encrypt to raw key
        XCTAssertThrowsError(
            try whisperService.encryptToRawKey(
                testMessage,
                from: alice,
                to: bob.x25519KeyPair.publicKey,
                authenticity: false
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.rawKeyBlocked))
        }
        
        // Should succeed with contact
        let bobContact = Contact(
            id: UUID(),
            displayName: "Bob",
            x25519PublicKey: bob.x25519KeyPair.publicKey,
            ed25519PublicKey: bob.ed25519KeyPair?.publicKey,
            fingerprint: bob.fingerprint,
            shortFingerprint: bob.shortFingerprint,
            sasWords: bob.sasWords,
            rkid: bob.rkid,
            trustLevel: .unverified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(bobContact)
        
        let envelope = try whisperService.encrypt(
            testMessage,
            from: alice,
            to: bobContact,
            authenticity: false
        )
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
    }
    
    func testSignatureRequiredPolicy() throws {
        let alice = try identityManager.createIdentity(name: "Alice")
        let bob = try identityManager.createIdentity(name: "Bob")
        
        try identityManager.setActiveIdentity(alice)
        policyManager.requireSignatureForVerified = true
        
        let bobContact = Contact(
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
        try contactManager.addContact(bobContact)
        
        let testMessage = "Test message".data(using: .utf8)!
        
        // Should fail without signature for verified contact
        XCTAssertThrowsError(
            try whisperService.encrypt(
                testMessage,
                from: alice,
                to: bobContact,
                authenticity: false
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.signatureRequired))
        }
        
        // Should succeed with signature
        let envelope = try whisperService.encrypt(
            testMessage,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
    }
    
    func testAutoArchivePolicy() throws {
        policyManager.autoArchiveOnRotation = true
        
        let alice = try identityManager.createIdentity(name: "Alice")
        try identityManager.setActiveIdentity(alice)
        
        XCTAssertEqual(alice.status, .active)
        
        // Rotate identity
        let newAlice = try identityManager.rotateActiveIdentity()
        
        // Old identity should be archived
        let identities = identityManager.listIdentities()
        let oldAlice = identities.first { $0.id == alice.id }
        
        XCTAssertEqual(oldAlice?.status, .archived)
        XCTAssertEqual(newAlice.status, .active)
    }
    
    func testBiometricGatedPolicy() throws {
        let alice = try identityManager.createIdentity(name: "Alice")
        let bob = try identityManager.createIdentity(name: "Bob")
        
        try identityManager.setActiveIdentity(alice)
        policyManager.biometricGatedSigning = true
        
        let bobContact = Contact(
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
        try contactManager.addContact(bobContact)
        
        let testMessage = "Test message".data(using: .utf8)!
        
        // Configure biometric service to fail
        biometricService.isAvailable = true
        biometricService.shouldSucceed = false
        
        // Should fail when biometric authentication fails
        XCTAssertThrowsError(
            try whisperService.encrypt(
                testMessage,
                from: alice,
                to: bobContact,
                authenticity: true
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.biometricRequired))
        }
        
        // Should succeed when biometric authentication succeeds
        biometricService.shouldSucceed = true
        
        let envelope = try whisperService.encrypt(
            testMessage,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
    }
    
    // MARK: - Biometric Authentication Mock Tests
    
    func testBiometricAuthenticationFlow() throws {
        let alice = try identityManager.createIdentity(name: "Alice")
        
        // Test biometric availability
        biometricService.isAvailable = true
        XCTAssertTrue(biometricService.isAvailable())
        
        // Test key enrollment
        let signingKey = alice.ed25519KeyPair!.privateKey
        try biometricService.enrollSigningKey(signingKey, id: alice.id.uuidString)
        
        XCTAssertTrue(biometricService.enrolledKeys.contains(alice.id.uuidString))
        
        // Test successful signing
        biometricService.shouldSucceed = true
        let testData = "Test data to sign".data(using: .utf8)!
        
        let signature = try biometricService.sign(data: testData, keyId: alice.id.uuidString)
        XCTAssertFalse(signature.isEmpty)
        
        // Test failed authentication
        biometricService.shouldSucceed = false
        
        XCTAssertThrowsError(
            try biometricService.sign(data: testData, keyId: alice.id.uuidString)
        ) { error in
            XCTAssertEqual(error as? WhisperError, .biometricAuthenticationFailed)
        }
        
        // Test cancelled authentication
        biometricService.shouldCancel = true
        
        XCTAssertThrowsError(
            try biometricService.sign(data: testData, keyId: alice.id.uuidString)
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.biometricRequired))
        }
    }
    
    func testBiometricUnavailable() throws {
        biometricService.isAvailable = false
        
        XCTAssertFalse(biometricService.isAvailable())
        
        let alice = try identityManager.createIdentity(name: "Alice")
        let signingKey = alice.ed25519KeyPair!.privateKey
        
        XCTAssertThrowsError(
            try biometricService.enrollSigningKey(signingKey, id: alice.id.uuidString)
        ) { error in
            XCTAssertEqual(error as? WhisperError, .biometricAuthenticationFailed)
        }
    }
    
    // MARK: - Replay Protection and Freshness Tests
    
    func testReplayProtection() throws {
        let alice = try identityManager.createIdentity(name: "Alice")
        let bob = try identityManager.createIdentity(name: "Bob")
        
        try identityManager.setActiveIdentity(alice)
        
        let bobContact = Contact(
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
        try contactManager.addContact(bobContact)
        
        // Encrypt message
        let envelope = try whisperService.encrypt(
            "Test message".data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        
        // Switch to Bob for decryption
        try identityManager.setActiveIdentity(bob)
        
        let aliceContact = Contact(
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
        try contactManager.addContact(aliceContact)
        
        // First decryption should succeed
        let result1 = try whisperService.decrypt(envelope)
        XCTAssertEqual(String(data: result1.plaintext, encoding: .utf8), "Test message")
        
        // Second decryption should fail (replay)
        XCTAssertThrowsError(try whisperService.decrypt(envelope)) { error in
            XCTAssertEqual(error as? WhisperError, .replayDetected)
        }
    }
    
    func testFreshnessValidation() throws {
        let alice = try identityManager.createIdentity(name: "Alice")
        let bob = try identityManager.createIdentity(name: "Bob")
        
        // Create an envelope with expired timestamp
        let expiredTimestamp = Int64(Date().timeIntervalSince1970) - (49 * 60 * 60) // 49 hours ago
        
        // Create envelope components manually with expired timestamp
        let envelopeProcessor = EnvelopeProcessor(cryptoEngine: cryptoEngine)
        
        let ephemeralKeyPair = try cryptoEngine.generateEphemeralKeyPair()
        let salt = try cryptoEngine.generateRandomData(length: 16)
        let msgId = try cryptoEngine.generateRandomData(length: 16)
        
        let envelope = "whisper1:v1.c20p.\(bob.rkid.base64URLEncoded).0.\(ephemeralKeyPair.publicKey.base64URLEncoded).\(salt.base64URLEncoded).\(msgId.base64URLEncoded).\(expiredTimestamp).dGVzdA.c2lnbmF0dXJl"
        
        try identityManager.setActiveIdentity(bob)
        
        // Should fail due to expired timestamp
        XCTAssertThrowsError(try whisperService.decrypt(envelope)) { error in
            XCTAssertEqual(error as? WhisperError, .messageExpired)
        }
    }
    
    func testFreshnessWindow() throws {
        let now = Int64(Date().timeIntervalSince1970)
        
        // Test valid timestamps (within ±48 hours)
        let validTimestamps = [
            now,
            now - (47 * 60 * 60), // 47 hours ago
            now + (47 * 60 * 60), // 47 hours in future
            now - (24 * 60 * 60), // 24 hours ago
            now + (24 * 60 * 60)  // 24 hours in future
        ]
        
        for timestamp in validTimestamps {
            XCTAssertTrue(
                replayProtector.isWithinFreshnessWindow(timestamp),
                "Timestamp \(timestamp) should be within freshness window"
            )
        }
        
        // Test invalid timestamps (outside ±48 hours)
        let invalidTimestamps = [
            now - (49 * 60 * 60), // 49 hours ago
            now + (49 * 60 * 60), // 49 hours in future
            now - (72 * 60 * 60), // 72 hours ago
            now + (72 * 60 * 60)  // 72 hours in future
        ]
        
        for timestamp in invalidTimestamps {
            XCTAssertFalse(
                replayProtector.isWithinFreshnessWindow(timestamp),
                "Timestamp \(timestamp) should be outside freshness window"
            )
        }
    }
    
    func testReplayCacheManagement() throws {
        let msgId1 = try cryptoEngine.generateRandomData(length: 16)
        let msgId2 = try cryptoEngine.generateRandomData(length: 16)
        let now = Int64(Date().timeIntervalSince1970)
        
        // First message should be accepted
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: msgId1, timestamp: now))
        
        // Same message should be rejected (replay)
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: msgId1, timestamp: now))
        
        // Different message should be accepted
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: msgId2, timestamp: now))
        
        // Expired message should not be committed
        let expiredTimestamp = now - (49 * 60 * 60)
        let msgId3 = try cryptoEngine.generateRandomData(length: 16)
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: msgId3, timestamp: expiredTimestamp))
        
        // Verify expired message is not in cache (can be "sent" again with valid timestamp)
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: msgId3, timestamp: now))
    }
}

// MARK: - Mock Biometric Service

class MockBiometricService: BiometricService {
    var isAvailable = true
    var shouldSucceed = true
    var shouldCancel = false
    var enrolledKeys: Set<String> = []
    var signatures: [String: Data] = [:]
    
    func isAvailable() -> Bool {
        return isAvailable
    }
    
    func enrollSigningKey(_ key: Curve25519.Signing.PrivateKey, id: String) throws {
        guard isAvailable else {
            throw WhisperError.biometricAuthenticationFailed
        }
        
        enrolledKeys.insert(id)
        // Store a mock signature for this key
        signatures[id] = Data("mock_signature_\(id)".utf8)
    }
    
    func sign(data: Data, keyId: String) async throws -> Data {
        guard isAvailable else {
            throw WhisperError.biometricAuthenticationFailed
        }
        
        guard enrolledKeys.contains(keyId) else {
            throw WhisperError.keyNotFound
        }
        
        if shouldCancel {
            throw WhisperError.policyViolation(.biometricRequired)
        }
        
        guard shouldSucceed else {
            throw WhisperError.biometricAuthenticationFailed
        }
        
        // Return mock signature
        return signatures[keyId] ?? Data("mock_signature".utf8)
    }
    
    func reset() {
        isAvailable = true
        shouldSucceed = true
        shouldCancel = false
        enrolledKeys.removeAll()
        signatures.removeAll()
    }
}