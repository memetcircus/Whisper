import XCTest
import CryptoKit
@testable import WhisperApp

class EndToEndTests: XCTestCase {
    
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
    
    // MARK: - Complete User Workflows
    
    func testCompleteUserOnboardingAndMessaging() throws {
        // Simulate Alice's onboarding
        let alice = try identityManager.createIdentity(name: "Alice Smith")
        try identityManager.setActiveIdentity(alice)
        
        // Alice configures her security policies
        policyManager.contactRequiredToSend = true
        policyManager.requireSignatureForVerified = true
        policyManager.biometricGatedSigning = true
        
        // Alice sets up biometric authentication
        biometricService.isAvailable = true
        biometricService.shouldSucceed = true
        try biometricService.enrollSigningKey(alice.ed25519KeyPair!.privateKey, id: alice.id.uuidString)
        
        // Simulate Bob's onboarding
        let bob = try identityManager.createIdentity(name: "Bob Johnson")
        
        // Alice adds Bob as a contact (unverified initially)
        let bobContact = Contact(
            id: UUID(),
            displayName: "Bob Johnson",
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
        
        // Alice tries to send to unverified Bob (should work without signature requirement)
        let message1 = "Hello Bob! This is Alice."
        let envelope1 = try whisperService.encrypt(
            message1.data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: false
        )
        
        XCTAssertTrue(envelope1.hasPrefix("whisper1:"))
        
        // Alice verifies Bob's contact
        try contactManager.verifyContact(id: bobContact.id, sasConfirmed: true)
        let verifiedBob = try XCTUnwrap(contactManager.getContact(id: bobContact.id))
        XCTAssertEqual(verifiedBob.trustLevel, .verified)
        
        // Now Alice must sign messages to verified Bob
        let message2 = "This is a signed message to verified Bob."
        let envelope2 = try whisperService.encrypt(
            message2.data(using: .utf8)!,
            from: alice,
            to: verifiedBob,
            authenticity: true
        )
        
        XCTAssertTrue(envelope2.hasPrefix("whisper1:"))
        
        // Simulate Bob receiving and decrypting messages
        try identityManager.setActiveIdentity(bob)
        
        let aliceContact = Contact(
            id: UUID(),
            displayName: "Alice Smith",
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
        
        // Bob decrypts first message
        let result1 = try whisperService.decrypt(envelope1)
        XCTAssertEqual(String(data: result1.plaintext, encoding: .utf8), message1)
        XCTAssertEqual(result1.senderAttribution, "From: Alice Smith")
        
        // Bob decrypts signed message
        let result2 = try whisperService.decrypt(envelope2)
        XCTAssertEqual(String(data: result2.plaintext, encoding: .utf8), message2)
        XCTAssertEqual(result2.senderAttribution, "From: Alice Smith (Verified, Signed)")
        XCTAssertTrue(result2.isSigned)
    }
    
    func testKeyRotationWorkflow() throws {
        // Alice creates initial identity
        let alice = try identityManager.createIdentity(name: "Alice")
        try identityManager.setActiveIdentity(alice)
        
        // Bob creates identity and adds Alice as contact
        let bob = try identityManager.createIdentity(name: "Bob")
        
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
        
        // Alice sends message to Bob
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
        
        let message1 = "Message before key rotation"
        let envelope1 = try whisperService.encrypt(
            message1.data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        
        // Alice rotates her keys
        policyManager.autoArchiveOnRotation = true
        let newAlice = try identityManager.rotateActiveIdentity()
        
        // Verify old identity is archived
        let identities = identityManager.listIdentities()
        let oldAlice = identities.first { $0.id == alice.id }
        XCTAssertEqual(oldAlice?.status, .archived)
        XCTAssertEqual(newAlice.status, .active)
        
        // Alice sends message with new identity
        let newBobContact = Contact(
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
        try contactManager.addContact(newBobContact)
        
        let message2 = "Message after key rotation"
        let envelope2 = try whisperService.encrypt(
            message2.data(using: .utf8)!,
            from: newAlice,
            to: newBobContact,
            authenticity: true
        )
        
        // Bob should be able to decrypt both messages
        try identityManager.setActiveIdentity(bob)
        
        // Decrypt old message (should still work with archived identity)
        let result1 = try whisperService.decrypt(envelope1)
        XCTAssertEqual(String(data: result1.plaintext, encoding: .utf8), message1)
        
        // Bob needs to update Alice's contact for new key
        let newAliceContact = Contact(
            id: UUID(),
            displayName: "Alice",
            x25519PublicKey: newAlice.x25519KeyPair.publicKey,
            ed25519PublicKey: newAlice.ed25519KeyPair?.publicKey,
            fingerprint: newAlice.fingerprint,
            shortFingerprint: newAlice.shortFingerprint,
            sasWords: newAlice.sasWords,
            rkid: newAlice.rkid,
            trustLevel: .unverified, // Needs re-verification
            isBlocked: false,
            keyVersion: 2,
            keyHistory: [KeyHistoryEntry(publicKey: alice.x25519KeyPair.publicKey, version: 1, rotatedAt: Date())],
            createdAt: Date()
        )
        try contactManager.addContact(newAliceContact)
        
        // Decrypt new message
        let result2 = try whisperService.decrypt(envelope2)
        XCTAssertEqual(String(data: result2.plaintext, encoding: .utf8), message2)
        XCTAssertEqual(result2.senderAttribution, "From: Alice (Unverified, Signed)")
    }
    
    func testMultiDeviceScenario() throws {
        // Simulate Alice having multiple identities (devices)
        let alicePhone = try identityManager.createIdentity(name: "Alice (Phone)")
        let aliceLaptop = try identityManager.createIdentity(name: "Alice (Laptop)")
        let bob = try identityManager.createIdentity(name: "Bob")
        
        // Bob adds both of Alice's identities as separate contacts
        try identityManager.setActiveIdentity(bob)
        
        let alicePhoneContact = Contact(
            id: UUID(),
            displayName: "Alice (Phone)",
            x25519PublicKey: alicePhone.x25519KeyPair.publicKey,
            ed25519PublicKey: alicePhone.ed25519KeyPair?.publicKey,
            fingerprint: alicePhone.fingerprint,
            shortFingerprint: alicePhone.shortFingerprint,
            sasWords: alicePhone.sasWords,
            rkid: alicePhone.rkid,
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(alicePhoneContact)
        
        let aliceLaptopContact = Contact(
            id: UUID(),
            displayName: "Alice (Laptop)",
            x25519PublicKey: aliceLaptop.x25519KeyPair.publicKey,
            ed25519PublicKey: aliceLaptop.ed25519KeyPair?.publicKey,
            fingerprint: aliceLaptop.fingerprint,
            shortFingerprint: aliceLaptop.shortFingerprint,
            sasWords: aliceLaptop.sasWords,
            rkid: aliceLaptop.rkid,
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(aliceLaptopContact)
        
        // Alice sends messages from both devices
        try identityManager.setActiveIdentity(alicePhone)
        
        let bobContactForPhone = Contact(
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
        try contactManager.addContact(bobContactForPhone)
        
        let phoneMessage = "Message from Alice's phone"
        let phoneEnvelope = try whisperService.encrypt(
            phoneMessage.data(using: .utf8)!,
            from: alicePhone,
            to: bobContactForPhone,
            authenticity: true
        )
        
        try identityManager.setActiveIdentity(aliceLaptop)
        
        let bobContactForLaptop = Contact(
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
        try contactManager.addContact(bobContactForLaptop)
        
        let laptopMessage = "Message from Alice's laptop"
        let laptopEnvelope = try whisperService.encrypt(
            laptopMessage.data(using: .utf8)!,
            from: aliceLaptop,
            to: bobContactForLaptop,
            authenticity: true
        )
        
        // Bob receives and decrypts both messages
        try identityManager.setActiveIdentity(bob)
        
        let phoneResult = try whisperService.decrypt(phoneEnvelope)
        XCTAssertEqual(String(data: phoneResult.plaintext, encoding: .utf8), phoneMessage)
        XCTAssertEqual(phoneResult.senderAttribution, "From: Alice (Phone) (Verified, Signed)")
        
        let laptopResult = try whisperService.decrypt(laptopEnvelope)
        XCTAssertEqual(String(data: laptopResult.plaintext, encoding: .utf8), laptopMessage)
        XCTAssertEqual(laptopResult.senderAttribution, "From: Alice (Laptop) (Verified, Signed)")
    }
    
    func testErrorRecoveryScenarios() throws {
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
        
        // Test biometric failure recovery
        policyManager.biometricGatedSigning = true
        biometricService.isAvailable = true
        biometricService.shouldSucceed = false
        
        XCTAssertThrowsError(
            try whisperService.encrypt(
                "Test message".data(using: .utf8)!,
                from: alice,
                to: bobContact,
                authenticity: true
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.biometricRequired))
        }
        
        // Recovery: biometric succeeds on retry
        biometricService.shouldSucceed = true
        let envelope = try whisperService.encrypt(
            "Test message".data(using: .utf8)!,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
        
        // Test corrupted envelope recovery
        let corruptedEnvelope = envelope.dropLast(5) + "xxxxx"
        
        try identityManager.setActiveIdentity(bob)
        
        XCTAssertThrowsError(try whisperService.decrypt(String(corruptedEnvelope))) { error in
            XCTAssertEqual(error as? WhisperError, .invalidEnvelope)
        }
        
        // Recovery: original envelope still works
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
        
        let result = try whisperService.decrypt(envelope)
        XCTAssertEqual(String(data: result.plaintext, encoding: .utf8), "Test message")
    }
    
    func testHighVolumeMessaging() throws {
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
        
        // Send 100 messages rapidly
        var envelopes: [String] = []
        
        for i in 0..<100 {
            let message = "Message number \(i)"
            let envelope = try whisperService.encrypt(
                message.data(using: .utf8)!,
                from: alice,
                to: bobContact,
                authenticity: true
            )
            envelopes.append(envelope)
        }
        
        // Verify all envelopes are unique (due to random components)
        let uniqueEnvelopes = Set(envelopes)
        XCTAssertEqual(uniqueEnvelopes.count, 100)
        
        // Bob decrypts all messages
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
        
        for (index, envelope) in envelopes.enumerated() {
            let result = try whisperService.decrypt(envelope)
            let expectedMessage = "Message number \(index)"
            XCTAssertEqual(String(data: result.plaintext, encoding: .utf8), expectedMessage)
        }
        
        // Verify replay protection is working (try to decrypt first message again)
        XCTAssertThrowsError(try whisperService.decrypt(envelopes[0])) { error in
            XCTAssertEqual(error as? WhisperError, .replayDetected)
        }
    }
}