import XCTest
import CoreData
import CryptoKit
@testable import WhisperApp

class ContactManagerTests: XCTestCase {
    var contactManager: ContactManager!
    var persistentContainer: NSPersistentContainer!
    var testContact: Contact!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack for testing
        persistentContainer = NSPersistentContainer(name: "WhisperDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        contactManager = CoreDataContactManager(persistentContainer: persistentContainer)
        
        // Create test contact
        let publicKey = Data(repeating: 0x01, count: 32)
        testContact = try Contact(
            displayName: "Test Contact",
            x25519PublicKey: publicKey
        )
    }
    
    override func tearDownWithError() throws {
        contactManager = nil
        persistentContainer = nil
        testContact = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Contact Management Tests
    
    func testAddContact() throws {
        // Test adding a new contact
        try contactManager.addContact(testContact)
        
        let retrievedContact = contactManager.getContact(id: testContact.id)
        XCTAssertNotNil(retrievedContact)
        XCTAssertEqual(retrievedContact?.displayName, testContact.displayName)
        XCTAssertEqual(retrievedContact?.x25519PublicKey, testContact.x25519PublicKey)
        XCTAssertEqual(retrievedContact?.trustLevel, .unverified)
        XCTAssertFalse(retrievedContact?.isBlocked ?? true)
    }
    
    func testAddDuplicateContact() throws {
        // Add contact first time
        try contactManager.addContact(testContact)
        
        // Try to add same contact again
        XCTAssertThrowsError(try contactManager.addContact(testContact)) { error in
            XCTAssertTrue(error is ContactManagerError)
            if case ContactManagerError.contactAlreadyExists = error {
                // Expected error
            } else {
                XCTFail("Expected contactAlreadyExists error")
            }
        }
    }
    
    func testUpdateContact() throws {
        // Add contact
        try contactManager.addContact(testContact)
        
        // Update contact
        let updatedContact = testContact.withUpdatedTrustLevel(.verified)
        try contactManager.updateContact(updatedContact)
        
        // Verify update
        let retrievedContact = contactManager.getContact(id: testContact.id)
        XCTAssertEqual(retrievedContact?.trustLevel, .verified)
    }
    
    func testDeleteContact() throws {
        // Add contact
        try contactManager.addContact(testContact)
        
        // Verify contact exists
        XCTAssertNotNil(contactManager.getContact(id: testContact.id))
        
        // Delete contact
        try contactManager.deleteContact(id: testContact.id)
        
        // Verify contact is deleted
        XCTAssertNil(contactManager.getContact(id: testContact.id))
    }
    
    func testGetContactByRkid() throws {
        // Add contact
        try contactManager.addContact(testContact)
        
        // Retrieve by rkid
        let retrievedContact = contactManager.getContact(byRkid: testContact.rkid)
        XCTAssertNotNil(retrievedContact)
        XCTAssertEqual(retrievedContact?.id, testContact.id)
    }
    
    func testListContacts() throws {
        // Add multiple contacts
        let publicKey2 = Data(repeating: 0x02, count: 32)
        let contact2 = try Contact(displayName: "Contact 2", x25519PublicKey: publicKey2)
        
        try contactManager.addContact(testContact)
        try contactManager.addContact(contact2)
        
        // List contacts
        let contacts = contactManager.listContacts()
        XCTAssertEqual(contacts.count, 2)
        
        // Verify sorting by display name
        XCTAssertEqual(contacts[0].displayName, "Contact 2")
        XCTAssertEqual(contacts[1].displayName, "Test Contact")
    }
    
    func testSearchContacts() throws {
        // Add contacts
        let publicKey2 = Data(repeating: 0x02, count: 32)
        let contact2 = try Contact(displayName: "Alice Smith", x25519PublicKey: publicKey2)
        
        try contactManager.addContact(testContact)
        try contactManager.addContact(contact2)
        
        // Search by name
        let searchResults = contactManager.searchContacts(query: "Alice")
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults[0].displayName, "Alice Smith")
        
        // Search by partial name
        let partialResults = contactManager.searchContacts(query: "test")
        XCTAssertEqual(partialResults.count, 1)
        XCTAssertEqual(partialResults[0].displayName, "Test Contact")
    }
    
    // MARK: - Trust Management Tests
    
    func testVerifyContact() throws {
        // Add contact
        try contactManager.addContact(testContact)
        
        // Verify contact with SAS confirmation
        try contactManager.verifyContact(id: testContact.id, sasConfirmed: true)
        
        let verifiedContact = contactManager.getContact(id: testContact.id)
        XCTAssertEqual(verifiedContact?.trustLevel, .verified)
        
        // Unverify contact
        try contactManager.verifyContact(id: testContact.id, sasConfirmed: false)
        
        let unverifiedContact = contactManager.getContact(id: testContact.id)
        XCTAssertEqual(unverifiedContact?.trustLevel, .unverified)
    }
    
    func testBlockContact() throws {
        // Add contact
        try contactManager.addContact(testContact)
        
        // Block contact
        try contactManager.blockContact(id: testContact.id)
        
        let blockedContact = contactManager.getContact(id: testContact.id)
        XCTAssertTrue(blockedContact?.isBlocked ?? false)
        
        // Unblock contact
        try contactManager.unblockContact(id: testContact.id)
        
        let unblockedContact = contactManager.getContact(id: testContact.id)
        XCTAssertFalse(unblockedContact?.isBlocked ?? true)
    }
    
    // MARK: - Key Rotation Tests
    
    func testKeyRotationDetection() throws {
        // Add contact
        try contactManager.addContact(testContact)
        
        // Check with same key (no rotation)
        let noRotation = contactManager.checkForKeyRotation(
            contact: testContact,
            currentX25519Key: testContact.x25519PublicKey
        )
        XCTAssertFalse(noRotation)
        
        // Check with different key (rotation detected)
        let newKey = Data(repeating: 0x99, count: 32)
        let rotationDetected = contactManager.checkForKeyRotation(
            contact: testContact,
            currentX25519Key: newKey
        )
        XCTAssertTrue(rotationDetected)
    }
    
    func testHandleKeyRotation() throws {
        // Add contact and verify
        try contactManager.addContact(testContact)
        try contactManager.verifyContact(id: testContact.id, sasConfirmed: true)
        
        // Verify contact is verified
        var contact = contactManager.getContact(id: testContact.id)!
        XCTAssertEqual(contact.trustLevel, .verified)
        
        // Rotate key
        let newX25519Key = Data(repeating: 0x99, count: 32)
        let newEd25519Key = Data(repeating: 0x88, count: 32)
        
        try contactManager.handleKeyRotation(
            for: contact,
            newX25519Key: newX25519Key,
            newEd25519Key: newEd25519Key
        )
        
        // Verify key rotation effects
        contact = contactManager.getContact(id: testContact.id)!
        XCTAssertEqual(contact.trustLevel, .unverified) // Trust reset
        XCTAssertEqual(contact.keyHistory.count, 1) // Old key in history
        
        // Verify old key is in history
        let historyEntry = contact.keyHistory[0]
        XCTAssertEqual(historyEntry.x25519PublicKey, testContact.x25519PublicKey)
    }
    
    // MARK: - Export Tests
    
    func testExportPublicKeybook() throws {
        // Add multiple contacts
        let publicKey2 = Data(repeating: 0x02, count: 32)
        let contact2 = try Contact(displayName: "Contact 2", x25519PublicKey: publicKey2)
        
        try contactManager.addContact(testContact)
        try contactManager.addContact(contact2)
        
        // Export keybook
        let exportData = try contactManager.exportPublicKeybook()
        XCTAssertFalse(exportData.isEmpty)
        
        // Verify export can be decoded
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let publicBundles = try decoder.decode([PublicKeyBundle].self, from: exportData)
        
        XCTAssertEqual(publicBundles.count, 2)
        XCTAssertTrue(publicBundles.contains { $0.displayName == "Test Contact" })
        XCTAssertTrue(publicBundles.contains { $0.displayName == "Contact 2" })
    }
    
    // MARK: - Contact Model Tests
    
    func testContactInitialization() throws {
        let publicKey = Data(repeating: 0x42, count: 32)
        let contact = try Contact(
            displayName: "Alice",
            x25519PublicKey: publicKey
        )
        
        XCTAssertEqual(contact.displayName, "Alice")
        XCTAssertEqual(contact.x25519PublicKey, publicKey)
        XCTAssertEqual(contact.trustLevel, .unverified)
        XCTAssertFalse(contact.isBlocked)
        XCTAssertEqual(contact.keyVersion, 1)
        XCTAssertEqual(contact.rkid.count, 8)
        XCTAssertEqual(contact.fingerprint.count, 32)
        XCTAssertEqual(contact.shortFingerprint.count, 12)
        XCTAssertEqual(contact.sasWords.count, 6)
    }
    
    func testFingerprintGeneration() throws {
        let publicKey = Data(repeating: 0x42, count: 32)
        let fingerprint = try Contact.generateFingerprint(from: publicKey)
        
        XCTAssertEqual(fingerprint.count, 32)
        
        // Test deterministic generation
        let fingerprint2 = try Contact.generateFingerprint(from: publicKey)
        XCTAssertEqual(fingerprint, fingerprint2)
        
        // Test different keys produce different fingerprints
        let publicKey2 = Data(repeating: 0x43, count: 32)
        let fingerprint3 = try Contact.generateFingerprint(from: publicKey2)
        XCTAssertNotEqual(fingerprint, fingerprint3)
    }
    
    func testShortFingerprintGeneration() {
        let fingerprint = Data(repeating: 0x42, count: 32)
        let shortFingerprint = Contact.generateShortFingerprint(from: fingerprint)
        
        XCTAssertEqual(shortFingerprint.count, 12)
        XCTAssertTrue(shortFingerprint.allSatisfy { char in
            "0123456789ABCDEFGHJKMNPQRSTVWXYZ".contains(char)
        })
    }
    
    func testSASWordsGeneration() {
        let fingerprint = Data(repeating: 0x42, count: 32)
        let sasWords = Contact.generateSASWords(from: fingerprint)
        
        XCTAssertEqual(sasWords.count, 6)
        
        // Verify all words are from the SAS word list
        for word in sasWords {
            XCTAssertTrue(SASWordList.words.contains(word))
        }
        
        // Test deterministic generation
        let sasWords2 = Contact.generateSASWords(from: fingerprint)
        XCTAssertEqual(sasWords, sasWords2)
    }
    
    // MARK: - Base32 Crockford Tests
    
    func testBase32CrockfordEncoding() {
        let testData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
        let encoded = testData.base32CrockfordEncoded()
        
        XCTAssertFalse(encoded.isEmpty)
        XCTAssertTrue(encoded.allSatisfy { char in
            "0123456789ABCDEFGHJKMNPQRSTVWXYZ".contains(char)
        })
        
        // Test round-trip
        let decoded = Data(base32CrockfordEncoded: encoded)
        XCTAssertEqual(decoded, testData)
    }
    
    func testBase32CrockfordDecoding() {
        // Test valid encoding
        let validEncoded = "91JPRV3F"
        let decoded = Data(base32CrockfordEncoded: validEncoded)
        XCTAssertNotNil(decoded)
        
        // Test invalid encoding
        let invalidEncoded = "INVALID!"
        let invalidDecoded = Data(base32CrockfordEncoded: invalidEncoded)
        XCTAssertNil(invalidDecoded)
        
        // Test case insensitive
        let lowercaseEncoded = "91jprv3f"
        let lowercaseDecoded = Data(base32CrockfordEncoded: lowercaseEncoded)
        XCTAssertEqual(decoded, lowercaseDecoded)
    }
    
    // MARK: - Trust Level Tests
    
    func testTrustLevelTransitions() {
        XCTAssertEqual(TrustLevel.unverified.displayName, "Unverified")
        XCTAssertEqual(TrustLevel.verified.displayName, "Verified")
        XCTAssertEqual(TrustLevel.revoked.displayName, "Revoked")
        
        XCTAssertEqual(TrustLevel.unverified.badgeColor, "orange")
        XCTAssertEqual(TrustLevel.verified.badgeColor, "green")
        XCTAssertEqual(TrustLevel.revoked.badgeColor, "red")
    }
    
    // MARK: - Error Handling Tests
    
    func testContactNotFoundError() {
        let nonExistentId = UUID()
        
        XCTAssertThrowsError(try contactManager.updateContact(testContact)) { error in
            if case ContactManagerError.contactNotFound = error {
                // Expected error
            } else {
                XCTFail("Expected contactNotFound error")
            }
        }
        
        XCTAssertThrowsError(try contactManager.deleteContact(id: nonExistentId)) { error in
            if case ContactManagerError.contactNotFound = error {
                // Expected error
            } else {
                XCTFail("Expected contactNotFound error")
            }
        }
    }
}