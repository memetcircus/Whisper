import XCTest
import CoreData
import CryptoKit
@testable import WhisperApp

class IdentityManagerTests: XCTestCase {
    
    var identityManager: CoreDataIdentityManager!
    var context: NSManagedObjectContext!
    var cryptoEngine: CryptoEngine!
    var policyManager: PolicyManager!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        let container = NSPersistentContainer(name: "WhisperDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        context = container.viewContext
        cryptoEngine = CryptoKitEngine()
        policyManager = UserDefaultsPolicyManager()
        
        identityManager = CoreDataIdentityManager(
            context: context,
            cryptoEngine: cryptoEngine,
            policyManager: policyManager
        )
    }
    
    override func tearDown() {
        // Clean up any test identities from Keychain
        let identities = identityManager.listIdentities()
        for identity in identities {
            try? KeychainManager.deleteKey(keyType: "x25519", identifier: identity.id.uuidString)
            try? KeychainManager.deleteKey(keyType: "ed25519", identifier: identity.id.uuidString)
        }
        
        identityManager = nil
        context = nil
        cryptoEngine = nil
        policyManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Identity Creation Tests
    
    func testCreateIdentity() throws {
        let identity = try identityManager.createIdentity(name: "Test Identity")
        
        XCTAssertEqual(identity.name, "Test Identity")
        XCTAssertEqual(identity.status, .active)
        XCTAssertEqual(identity.keyVersion, 1)
        XCTAssertNotNil(identity.x25519KeyPair)
        XCTAssertNotNil(identity.ed25519KeyPair)
        XCTAssertEqual(identity.fingerprint.count, 32)
        
        // Verify keys are stored in Keychain
        let retrievedX25519 = try KeychainManager.retrieveX25519PrivateKey(
            identifier: identity.id.uuidString
        )
        XCTAssertEqual(
            retrievedX25519.publicKey.rawRepresentation,
            identity.x25519KeyPair.publicKey
        )
        
        let retrievedEd25519 = try KeychainManager.retrieveEd25519PrivateKey(
            identifier: identity.id.uuidString
        )
        XCTAssertEqual(
            retrievedEd25519.publicKey.rawRepresentation,
            identity.ed25519KeyPair?.publicKey
        )
    }
    
    func testListIdentities() throws {
        // Create multiple identities
        let identity1 = try identityManager.createIdentity(name: "Identity 1")
        let identity2 = try identityManager.createIdentity(name: "Identity 2")
        
        let identities = identityManager.listIdentities()
        
        XCTAssertEqual(identities.count, 2)
        XCTAssertTrue(identities.contains { $0.id == identity1.id })
        XCTAssertTrue(identities.contains { $0.id == identity2.id })
    }
    
    // MARK: - Active Identity Management Tests
    
    func testSetActiveIdentity() throws {
        let identity = try identityManager.createIdentity(name: "Test Identity")
        
        // Initially no active identity
        XCTAssertNil(identityManager.getActiveIdentity())
        
        // Set active identity
        try identityManager.setActiveIdentity(identity)
        
        let activeIdentity = identityManager.getActiveIdentity()
        XCTAssertNotNil(activeIdentity)
        XCTAssertEqual(activeIdentity?.id, identity.id)
    }
    
    func testSetActiveIdentityDeactivatesOthers() throws {
        let identity1 = try identityManager.createIdentity(name: "Identity 1")
        let identity2 = try identityManager.createIdentity(name: "Identity 2")
        
        // Set first identity as active
        try identityManager.setActiveIdentity(identity1)
        XCTAssertEqual(identityManager.getActiveIdentity()?.id, identity1.id)
        
        // Set second identity as active
        try identityManager.setActiveIdentity(identity2)
        XCTAssertEqual(identityManager.getActiveIdentity()?.id, identity2.id)
        
        // Verify only one active identity
        let identities = identityManager.listIdentities()
        let activeIdentities = identities.filter { identity in
            // Check Core Data entity directly
            let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@ AND isActive == YES", identity.id as CVarArg)
            let count = (try? context.fetch(request).count) ?? 0
            return count > 0
        }
        XCTAssertEqual(activeIdentities.count, 1)
    }
    
    // MARK: - Identity Archiving Tests
    
    func testArchiveIdentity() throws {
        let identity = try identityManager.createIdentity(name: "Test Identity")
        try identityManager.setActiveIdentity(identity)
        
        // Archive the identity
        try identityManager.archiveIdentity(identity)
        
        // Verify identity is archived and no longer active
        XCTAssertNil(identityManager.getActiveIdentity())
        
        let identities = identityManager.listIdentities()
        let archivedIdentity = identities.first { $0.id == identity.id }
        XCTAssertNotNil(archivedIdentity)
        XCTAssertEqual(archivedIdentity?.status, .archived)
    }
    
    // MARK: - Key Rotation Tests
    
    func testRotateActiveIdentity() throws {
        let originalIdentity = try identityManager.createIdentity(name: "Original Identity")
        try identityManager.setActiveIdentity(originalIdentity)
        
        // Rotate identity
        let newIdentity = try identityManager.rotateActiveIdentity()
        
        XCTAssertNotEqual(newIdentity.id, originalIdentity.id)
        XCTAssertEqual(newIdentity.name, originalIdentity.name)
        XCTAssertEqual(newIdentity.status, .active)
        
        // Verify new identity is active
        let activeIdentity = identityManager.getActiveIdentity()
        XCTAssertEqual(activeIdentity?.id, newIdentity.id)
    }
    
    func testRotateWithAutoArchivePolicy() throws {
        policyManager.autoArchiveOnRotation = true
        
        let originalIdentity = try identityManager.createIdentity(name: "Original Identity")
        try identityManager.setActiveIdentity(originalIdentity)
        
        // Rotate identity
        let newIdentity = try identityManager.rotateActiveIdentity()
        
        // Verify original identity is archived
        let identities = identityManager.listIdentities()
        let archivedIdentity = identities.first { $0.id == originalIdentity.id }
        XCTAssertNotNil(archivedIdentity)
        XCTAssertEqual(archivedIdentity?.status, .archived)
        
        // Verify new identity is active
        XCTAssertEqual(identityManager.getActiveIdentity()?.id, newIdentity.id)
    }
    
    func testRotateWithoutAutoArchivePolicy() throws {
        policyManager.autoArchiveOnRotation = false
        
        let originalIdentity = try identityManager.createIdentity(name: "Original Identity")
        try identityManager.setActiveIdentity(originalIdentity)
        
        // Rotate identity
        let newIdentity = try identityManager.rotateActiveIdentity()
        
        // Verify original identity is not archived
        let identities = identityManager.listIdentities()
        let originalIdentityAfterRotation = identities.first { $0.id == originalIdentity.id }
        XCTAssertNotNil(originalIdentityAfterRotation)
        XCTAssertEqual(originalIdentityAfterRotation?.status, .active)
        
        // Verify new identity is active
        XCTAssertEqual(identityManager.getActiveIdentity()?.id, newIdentity.id)
    }
    
    // MARK: - Export/Import Tests
    
    func testExportPublicBundle() throws {
        let identity = try identityManager.createIdentity(name: "Test Identity")
        
        let bundleData = try identityManager.exportPublicBundle(identity)
        let bundle = try identityManager.importPublicBundle(bundleData)
        
        XCTAssertEqual(bundle.id, identity.id)
        XCTAssertEqual(bundle.name, identity.name)
        XCTAssertEqual(bundle.x25519PublicKey, identity.x25519KeyPair.publicKey)
        XCTAssertEqual(bundle.ed25519PublicKey, identity.ed25519KeyPair?.publicKey)
        XCTAssertEqual(bundle.fingerprint, identity.fingerprint)
        XCTAssertEqual(bundle.keyVersion, identity.keyVersion)
    }
    
    func testBackupAndRestoreIdentity() throws {
        let originalIdentity = try identityManager.createIdentity(name: "Test Identity")
        let passphrase = "test-passphrase-123"
        
        // Create backup
        let backupData = try identityManager.backupIdentity(originalIdentity, passphrase: passphrase)
        XCTAssertGreaterThan(backupData.count, 0)
        
        // Delete original identity from Keychain (simulate loss)
        try KeychainManager.deleteKey(keyType: "x25519", identifier: originalIdentity.id.uuidString)
        try KeychainManager.deleteKey(keyType: "ed25519", identifier: originalIdentity.id.uuidString)
        
        // Restore identity
        let restoredIdentity = try identityManager.restoreIdentity(from: backupData, passphrase: passphrase)
        
        XCTAssertEqual(restoredIdentity.id, originalIdentity.id)
        XCTAssertEqual(restoredIdentity.name, originalIdentity.name)
        XCTAssertEqual(restoredIdentity.x25519KeyPair.publicKey, originalIdentity.x25519KeyPair.publicKey)
        XCTAssertEqual(restoredIdentity.ed25519KeyPair?.publicKey, originalIdentity.ed25519KeyPair?.publicKey)
        XCTAssertEqual(restoredIdentity.fingerprint, originalIdentity.fingerprint)
        XCTAssertEqual(restoredIdentity.keyVersion, originalIdentity.keyVersion)
        
        // Verify keys are restored in Keychain
        let retrievedX25519 = try KeychainManager.retrieveX25519PrivateKey(
            identifier: restoredIdentity.id.uuidString
        )
        XCTAssertEqual(
            retrievedX25519.publicKey.rawRepresentation,
            restoredIdentity.x25519KeyPair.publicKey
        )
    }
    
    func testBackupWithWrongPassphrase() throws {
        let identity = try identityManager.createIdentity(name: "Test Identity")
        let correctPassphrase = "correct-passphrase"
        let wrongPassphrase = "wrong-passphrase"
        
        let backupData = try identityManager.backupIdentity(identity, passphrase: correctPassphrase)
        
        XCTAssertThrowsError(
            try identityManager.restoreIdentity(from: backupData, passphrase: wrongPassphrase)
        ) { error in
            XCTAssertTrue(error is IdentityError)
        }
    }
    
    // MARK: - Query Tests
    
    func testGetIdentityByRkid() throws {
        let identity = try identityManager.createIdentity(name: "Test Identity")
        let rkid = cryptoEngine.generateRecipientKeyId(x25519PublicKey: identity.x25519KeyPair.publicKey)
        
        let foundIdentity = identityManager.getIdentity(byRkid: rkid)
        
        XCTAssertNotNil(foundIdentity)
        XCTAssertEqual(foundIdentity?.id, identity.id)
    }
    
    func testGetIdentityByRkidNotFound() throws {
        let _ = try identityManager.createIdentity(name: "Test Identity")
        let randomRkid = Data(repeating: 0xFF, count: 8)
        
        let foundIdentity = identityManager.getIdentity(byRkid: randomRkid)
        
        XCTAssertNil(foundIdentity)
    }
    
    // MARK: - Expiration Warning Tests
    
    func testGetIdentitiesNeedingRotationWarning() throws {
        // Create identity that's 340 days old (within 30-day warning threshold)
        let oldDate = Calendar.current.date(byAdding: .day, value: -340, to: Date())!
        let identity = try identityManager.createIdentity(name: "Old Identity")
        
        // Manually update the creation date in Core Data
        let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", identity.id as CVarArg)
        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.createdAt = oldDate
            try context.save()
        }
        
        let warningIdentities = identityManager.getIdentitiesNeedingRotationWarning()
        
        XCTAssertEqual(warningIdentities.count, 1)
        XCTAssertEqual(warningIdentities.first?.id, identity.id)
    }
    
    func testGetIdentitiesNeedingRotationWarningEmpty() throws {
        // Create new identity (not needing warning)
        let _ = try identityManager.createIdentity(name: "New Identity")
        
        let warningIdentities = identityManager.getIdentitiesNeedingRotationWarning()
        
        XCTAssertEqual(warningIdentities.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testSetActiveIdentityNotFound() {
        let nonExistentIdentity = Identity(
            id: UUID(),
            name: "Non-existent",
            x25519KeyPair: X25519KeyPair(
                privateKey: Curve25519.KeyAgreement.PrivateKey(),
                publicKey: Data(repeating: 0x01, count: 32)
            ),
            ed25519KeyPair: nil,
            fingerprint: Data(repeating: 0x02, count: 32),
            createdAt: Date(),
            status: .active,
            keyVersion: 1
        )
        
        XCTAssertThrowsError(
            try identityManager.setActiveIdentity(nonExistentIdentity)
        ) { error in
            XCTAssertTrue(error is IdentityError)
            if case .identityNotFound = error as? IdentityError {
                // Expected error
            } else {
                XCTFail("Expected IdentityError.identityNotFound")
            }
        }
    }
    
    func testRotateActiveIdentityWithoutActive() {
        XCTAssertThrowsError(
            try identityManager.rotateActiveIdentity()
        ) { error in
            XCTAssertTrue(error is IdentityError)
            if case .noActiveIdentity = error as? IdentityError {
                // Expected error
            } else {
                XCTFail("Expected IdentityError.noActiveIdentity")
            }
        }
    }
}