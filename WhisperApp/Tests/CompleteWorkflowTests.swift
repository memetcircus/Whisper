import XCTest
import CryptoKit
@testable import WhisperApp

class CompleteWorkflowTests: XCTestCase {
    var identityManager: IdentityManager!
    var contactManager: ContactManager!
    var whisperService: WhisperService!
    var policyManager: PolicyManager!
    var biometricService: BiometricService!
    
    override func setUp() {
        super.setUp()
        
        // Initialize all components
        identityManager = IdentityManager()
        contactManager = ContactManager()
        policyManager = PolicyManager()
        biometricService = DefaultBiometricService()
        whisperService = WhisperService(
            identityManager: identityManager,
            contactManager: contactManager,
            policyManager: policyManager,
            biometricService: biometricService
        )
        
        // Reset policies to defaults
        policyManager.contactRequiredToSend = false
        policyManager.requireSignatureForVerified = false
        policyManager.autoArchiveOnRotation = false
        policyManager.biometricGatedSigning = false
    }
    
    override func tearDown() {
        // Clean up test data
        try? identityManager.deleteAllIdentities()
        try? contactManager.deleteAllContacts()
        super.tearDown()
    }
    
    // MARK: - Complete User Workflow Tests
    
    func testCompleteEncryptionDecryptionWorkflow() throws {
        // 1. Create sender identity
        let senderIdentity = try identityManager.createIdentity(name: "Alice")
        try identityManager.setActiveIdentity(senderIdentity)
        
        // 2. Create recipient identity (simulating another user)
        let recipientIdentity = try identityManager.createIdentity(name: "Bob")
        
        // 3. Add recipient as contact
        let recipientContact = Contact(
            id: UUID(),
            displayName: "Bob",
            x25519PublicKey: recipientIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: recipientIdentity.ed25519KeyPair?.publicKey,
            fingerprint: recipientIdentity.fingerprint,
            shortFingerprint: String(recipientIdentity.fingerprint.base32EncodedString().prefix(12)),
            sasWords: SASWordList.generateWords(from: recipientIdentity.fingerprint),
            rkid: Data(recipientIdentity.fingerprint.suffix(8)),
            trustLevel: .unverified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date(),
            lastSeenAt: nil,
            note: nil
        )
        
        try contactManager.addContact(recipientContact)
        
        // 4. Encrypt message
        let plaintext = "Hello, this is a test message for complete workflow validation!"
        let envelope = try whisperService.encrypt(
            plaintext.data(using: .utf8)!,
            from: senderIdentity,
            to: recipientContact,
            authenticity: false
        )
        
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
        
        // 5. Switch to recipient identity for decryption
        try identityManager.setActiveIdentity(recipientIdentity)
        
        // 6. Decrypt message
        let decryptionResult = try whisperService.decrypt(envelope)
        let decryptedText = String(data: decryptionResult.plaintext, encoding: .utf8)
        
        XCTAssertEqual(decryptedText, plaintext)
        XCTAssertEqual(decryptionResult.senderAttribution, "From: Alice")
    }
    
    func testCompleteWorkflowWithSignatures() throws {
        // 1. Create identities with signing keys
        let senderIdentity = try identityManager.createIdentity(name: "Alice")
        try identityManager.setActiveIdentity(senderIdentity)
        
        let recipientIdentity = try identityManager.createIdentity(name: "Bob")
        
        // 2. Add recipient as verified contact
        var recipientContact = Contact(
            id: UUID(),
            displayName: "Bob",
            x25519PublicKey: recipientIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: recipientIdentity.ed25519KeyPair?.publicKey,
            fingerprint: recipientIdentity.fingerprint,
            shortFingerprint: String(recipientIdentity.fingerprint.base32EncodedString().prefix(12)),
            sasWords: SASWordList.generateWords(from: recipientIdentity.fingerprint),
            rkid: Data(recipientIdentity.fingerprint.suffix(8)),
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date(),
            lastSeenAt: nil,
            note: nil
        )
        
        try contactManager.addContact(recipientContact)
        
        // 3. Enable signature requirement policy
        policyManager.requireSignatureForVerified = true
        
        // 4. Encrypt with signature
        let plaintext = "Signed message test"
        let envelope = try whisperService.encrypt(
            plaintext.data(using: .utf8)!,
            from: senderIdentity,
            to: recipientContact,
            authenticity: true
        )
        
        // 5. Add sender as contact for recipient
        try identityManager.setActiveIdentity(recipientIdentity)
        
        let senderContact = Contact(
            id: UUID(),
            displayName: "Alice",
            x25519PublicKey: senderIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: senderIdentity.ed25519KeyPair?.publicKey,
            fingerprint: senderIdentity.fingerprint,
            shortFingerprint: String(senderIdentity.fingerprint.base32EncodedString().prefix(12)),
            sasWords: SASWordList.generateWords(from: senderIdentity.fingerprint),
            rkid: Data(senderIdentity.fingerprint.suffix(8)),
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date(),
            lastSeenAt: nil,
            note: nil
        )
        
        try contactManager.addContact(senderContact)
        
        // 6. Decrypt and verify signature
        let decryptionResult = try whisperService.decrypt(envelope)
        let decryptedText = String(data: decryptionResult.plaintext, encoding: .utf8)
        
        XCTAssertEqual(decryptedText, plaintext)
        XCTAssertEqual(decryptionResult.senderAttribution, "From: Alice (Verified, Signed)")
    }
    
    func testCompleteWorkflowWithAllPolicies() throws {
        // Enable all policies
        policyManager.contactRequiredToSend = true
        policyManager.requireSignatureForVerified = true
        policyManager.autoArchiveOnRotation = true
        // Note: biometricGatedSigning would require actual biometric hardware
        
        // Create and test workflow with all policies enabled
        let senderIdentity = try identityManager.createIdentity(name: "PolicyUser")
        try identityManager.setActiveIdentity(senderIdentity)
        
        let recipientIdentity = try identityManager.createIdentity(name: "PolicyRecipient")
        
        let recipientContact = Contact(
            id: UUID(),
            displayName: "PolicyRecipient",
            x25519PublicKey: recipientIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: recipientIdentity.ed25519KeyPair?.publicKey,
            fingerprint: recipientIdentity.fingerprint,
            shortFingerprint: String(recipientIdentity.fingerprint.base32EncodedString().prefix(12)),
            sasWords: SASWordList.generateWords(from: recipientIdentity.fingerprint),
            rkid: Data(recipientIdentity.fingerprint.suffix(8)),
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date(),
            lastSeenAt: nil,
            note: nil
        )
        
        try contactManager.addContact(recipientContact)
        
        // Test that raw key encryption is blocked
        XCTAssertThrowsError(try whisperService.encryptToRawKey(
            "test".data(using: .utf8)!,
            from: senderIdentity,
            to: recipientIdentity.x25519KeyPair.publicKey,
            authenticity: false
        )) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.rawKeyBlocked))
        }
        
        // Test successful encryption to contact with signature
        let envelope = try whisperService.encrypt(
            "Policy test message".data(using: .utf8)!,
            from: senderIdentity,
            to: recipientContact,
            authenticity: true
        )
        
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
        
        // Test key rotation with auto-archive
        let oldIdentityId = senderIdentity.id
        let newIdentity = try identityManager.rotateActiveIdentity()
        
        XCTAssertNotEqual(oldIdentityId, newIdentity.id)
        
        // Verify old identity is archived
        let identities = identityManager.listIdentities()
        let oldIdentity = identities.first { $0.id == oldIdentityId }
        XCTAssertEqual(oldIdentity?.status, .archived)
    }
    
    func testCompleteQRCodeWorkflow() throws {
        // 1. Create identity
        let identity = try identityManager.createIdentity(name: "QRUser")
        try identityManager.setActiveIdentity(identity)
        
        // 2. Generate QR code for public key
        let publicKeyBundle = try identityManager.exportPublicBundle(identity)
        let qrService = QRCodeService()
        let qrImage = try qrService.generateQRCode(for: publicKeyBundle)
        
        XCTAssertNotNil(qrImage)
        
        // 3. Encrypt message and generate QR
        let message = "Short message for QR"
        let recipientKey = try Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation
        
        let envelope = try whisperService.encryptToRawKey(
            message.data(using: .utf8)!,
            from: identity,
            to: recipientKey,
            authenticity: false
        )
        
        // Check QR size warning
        if envelope.count > 900 {
            print("Warning: Envelope size (\(envelope.count) bytes) exceeds recommended QR limit")
        }
        
        let messageQR = try qrService.generateQRCode(for: envelope.data(using: .utf8)!)
        XCTAssertNotNil(messageQR)
    }
    
    func testCompleteBackupRestoreWorkflow() throws {
        // 1. Create identity with data
        let originalIdentity = try identityManager.createIdentity(name: "BackupUser")
        try identityManager.setActiveIdentity(originalIdentity)
        
        // 2. Add some contacts
        let contact = Contact(
            id: UUID(),
            displayName: "TestContact",
            x25519PublicKey: Data(repeating: 1, count: 32),
            ed25519PublicKey: Data(repeating: 2, count: 32),
            fingerprint: Data(repeating: 3, count: 32),
            shortFingerprint: "TESTCONTACT1",
            sasWords: ["test", "contact", "words", "for", "backup", "restore"],
            rkid: Data(repeating: 4, count: 8),
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date(),
            lastSeenAt: nil,
            note: "Test contact for backup"
        )
        
        try contactManager.addContact(contact)
        
        // 3. Create backup
        let passphrase = "test-backup-passphrase-123"
        let backupData = try identityManager.backupIdentity(originalIdentity, passphrase: passphrase)
        
        XCTAssertFalse(backupData.isEmpty)
        
        // 4. Clear data and restore
        try identityManager.deleteAllIdentities()
        try contactManager.deleteAllContacts()
        
        XCTAssertTrue(identityManager.listIdentities().isEmpty)
        XCTAssertTrue(contactManager.listContacts().isEmpty)
        
        // 5. Restore from backup
        let restoredIdentity = try identityManager.restoreIdentity(from: backupData, passphrase: passphrase)
        
        XCTAssertEqual(restoredIdentity.name, originalIdentity.name)
        XCTAssertEqual(restoredIdentity.fingerprint, originalIdentity.fingerprint)
        
        // Note: In a real implementation, contacts might also be included in backup
    }
}