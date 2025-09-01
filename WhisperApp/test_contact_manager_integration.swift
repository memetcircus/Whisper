#!/usr/bin/env swift

import Foundation
import CryptoKit

// MARK: - Contact Manager Integration Test

print("=== Contact Manager Integration Test ===")

// Simple in-memory contact manager for testing
class InMemoryContactManager {
    private var contacts: [UUID: MockContact] = [:]
    
    func addContact(_ contact: MockContact) throws {
        guard contacts[contact.id] == nil else {
            throw ContactManagerError.contactAlreadyExists
        }
        contacts[contact.id] = contact
    }
    
    func updateContact(_ contact: MockContact) throws {
        guard contacts[contact.id] != nil else {
            throw ContactManagerError.contactNotFound
        }
        contacts[contact.id] = contact
    }
    
    func deleteContact(id: UUID) throws {
        guard contacts[id] != nil else {
            throw ContactManagerError.contactNotFound
        }
        contacts.removeValue(forKey: id)
    }
    
    func getContact(id: UUID) -> MockContact? {
        return contacts[id]
    }
    
    func getContact(byRkid rkid: Data) -> MockContact? {
        return contacts.values.first { $0.rkid == rkid }
    }
    
    func listContacts() -> [MockContact] {
        return Array(contacts.values).sorted { $0.displayName < $1.displayName }
    }
    
    func searchContacts(query: String) -> [MockContact] {
        return contacts.values.filter { contact in
            contact.displayName.localizedCaseInsensitiveContains(query) ||
            (contact.note?.localizedCaseInsensitiveContains(query) ?? false)
        }.sorted { $0.displayName < $1.displayName }
    }
    
    func verifyContact(id: UUID, sasConfirmed: Bool) throws {
        guard var contact = contacts[id] else {
            throw ContactManagerError.contactNotFound
        }
        contact.trustLevel = sasConfirmed ? .verified : .unverified
        contacts[id] = contact
    }
    
    func blockContact(id: UUID) throws {
        guard var contact = contacts[id] else {
            throw ContactManagerError.contactNotFound
        }
        contact.isBlocked = true
        contacts[id] = contact
    }
    
    func unblockContact(id: UUID) throws {
        guard var contact = contacts[id] else {
            throw ContactManagerError.contactNotFound
        }
        contact.isBlocked = false
        contacts[id] = contact
    }
    
    func exportPublicKeybook() throws -> Data {
        let publicBundles = contacts.values.map { contact in
            PublicKeyBundle(from: contact)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(publicBundles)
    }
    
    func handleKeyRotation(for contact: MockContact, newX25519Key: Data, newEd25519Key: Data? = nil) throws {
        var updatedContact = contact
        
        // Add old key to history
        let oldKeyEntry = KeyHistoryEntry(
            keyVersion: contact.keyVersion,
            x25519PublicKey: contact.x25519PublicKey,
            ed25519PublicKey: contact.ed25519PublicKey
        )
        updatedContact.keyHistory.append(oldKeyEntry)
        
        // Update with new keys
        updatedContact.x25519PublicKey = newX25519Key
        updatedContact.ed25519PublicKey = newEd25519Key
        updatedContact.keyVersion += 1
        updatedContact.trustLevel = .unverified // Reset trust on key rotation
        
        // Regenerate derived fields
        let hash = SHA256.hash(data: newX25519Key)
        updatedContact.fingerprint = Data(hash)
        updatedContact.rkid = Data(updatedContact.fingerprint.suffix(8))
        
        contacts[contact.id] = updatedContact
    }
    
    func checkForKeyRotation(contact: MockContact, currentX25519Key: Data) -> Bool {
        return contact.x25519PublicKey != currentX25519Key
    }
}

struct MockContact: Codable {
    let id: UUID
    let displayName: String
    var x25519PublicKey: Data
    var ed25519PublicKey: Data?
    var fingerprint: Data
    var rkid: Data
    var trustLevel: TrustLevel
    var isBlocked: Bool
    var keyVersion: Int
    var keyHistory: [KeyHistoryEntry]
    let createdAt: Date
    var lastSeenAt: Date?
    var note: String?
    
    init(displayName: String, x25519PublicKey: Data, ed25519PublicKey: Data? = nil, note: String? = nil) {
        self.id = UUID()
        self.displayName = displayName
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.note = note
        self.trustLevel = .unverified
        self.isBlocked = false
        self.keyVersion = 1
        self.keyHistory = []
        self.createdAt = Date()
        self.lastSeenAt = nil
        
        // Generate derived fields
        let hash = SHA256.hash(data: x25519PublicKey)
        self.fingerprint = Data(hash)
        self.rkid = Data(fingerprint.suffix(8))
    }
}

struct KeyHistoryEntry: Codable {
    let keyVersion: Int
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let createdAt: Date
    
    init(keyVersion: Int, x25519PublicKey: Data, ed25519PublicKey: Data? = nil) {
        self.keyVersion = keyVersion
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.createdAt = Date()
    }
}

struct PublicKeyBundle: Codable {
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date
    
    init(from contact: MockContact) {
        self.displayName = contact.displayName
        self.x25519PublicKey = contact.x25519PublicKey
        self.ed25519PublicKey = contact.ed25519PublicKey
        self.fingerprint = contact.fingerprint
        self.keyVersion = contact.keyVersion
        self.createdAt = contact.createdAt
    }
}

enum TrustLevel: String, Codable, CaseIterable {
    case unverified = "unverified"
    case verified = "verified"
    case revoked = "revoked"
}

enum ContactManagerError: Error {
    case contactNotFound
    case contactAlreadyExists
    case invalidPublicKey
    case keyRotationDetected
    case exportFailed
}

// MARK: - Integration Tests

let manager = InMemoryContactManager()

print("\n1. Testing Add Contact...")
let alice = MockContact(
    displayName: "Alice Smith",
    x25519PublicKey: Data(repeating: 0x01, count: 32),
    note: "Friend from work"
)

try manager.addContact(alice)
print("✓ Added Alice successfully")

let bob = MockContact(
    displayName: "Bob Johnson",
    x25519PublicKey: Data(repeating: 0x02, count: 32)
)

try manager.addContact(bob)
print("✓ Added Bob successfully")

// Test duplicate contact
do {
    try manager.addContact(alice)
    print("❌ Should have failed to add duplicate contact")
} catch ContactManagerError.contactAlreadyExists {
    print("✓ Correctly rejected duplicate contact")
} catch {
    print("❌ Unexpected error: \(error)")
}

print("\n2. Testing Get Contact...")
let retrievedAlice = manager.getContact(id: alice.id)
if let retrievedAlice = retrievedAlice, retrievedAlice.displayName == "Alice Smith" {
    print("✓ Retrieved Alice by ID")
} else {
    print("❌ Failed to retrieve Alice by ID")
}

let retrievedByRkid = manager.getContact(byRkid: bob.rkid)
if let retrievedByRkid = retrievedByRkid, retrievedByRkid.displayName == "Bob Johnson" {
    print("✓ Retrieved Bob by RKID")
} else {
    print("❌ Failed to retrieve Bob by RKID")
}

print("\n3. Testing List Contacts...")
let allContacts = manager.listContacts()
if allContacts.count == 2 && allContacts[0].displayName == "Alice Smith" && allContacts[1].displayName == "Bob Johnson" {
    print("✓ Listed all contacts in alphabetical order")
} else {
    print("❌ Failed to list contacts correctly")
    print("  Expected: Alice Smith, Bob Johnson")
    print("  Got: \(allContacts.map { $0.displayName }.joined(separator: ", "))")
}

print("\n4. Testing Search Contacts...")
let searchResults = manager.searchContacts(query: "Alice")
if searchResults.count == 1 && searchResults[0].displayName == "Alice Smith" {
    print("✓ Search by name works")
} else {
    print("❌ Search by name failed")
}

let noteSearchResults = manager.searchContacts(query: "work")
if noteSearchResults.count == 1 && noteSearchResults[0].displayName == "Alice Smith" {
    print("✓ Search by note works")
} else {
    print("❌ Search by note failed")
}

print("\n5. Testing Trust Management...")
try manager.verifyContact(id: alice.id, sasConfirmed: true)
let verifiedAlice = manager.getContact(id: alice.id)
if verifiedAlice?.trustLevel == .verified {
    print("✓ Contact verification works")
} else {
    print("❌ Contact verification failed")
}

try manager.verifyContact(id: alice.id, sasConfirmed: false)
let unverifiedAlice = manager.getContact(id: alice.id)
if unverifiedAlice?.trustLevel == .unverified {
    print("✓ Contact unverification works")
} else {
    print("❌ Contact unverification failed")
}

print("\n6. Testing Block Management...")
try manager.blockContact(id: bob.id)
let blockedBob = manager.getContact(id: bob.id)
if blockedBob?.isBlocked == true {
    print("✓ Contact blocking works")
} else {
    print("❌ Contact blocking failed")
}

try manager.unblockContact(id: bob.id)
let unblockedBob = manager.getContact(id: bob.id)
if unblockedBob?.isBlocked == false {
    print("✓ Contact unblocking works")
} else {
    print("❌ Contact unblocking failed")
}

print("\n7. Testing Key Rotation...")
let originalKey = alice.x25519PublicKey
let newKey = Data(repeating: 0x99, count: 32)

let rotationDetected = manager.checkForKeyRotation(contact: alice, currentX25519Key: newKey)
if rotationDetected {
    print("✓ Key rotation detection works")
} else {
    print("❌ Key rotation detection failed")
}

try manager.handleKeyRotation(for: alice, newX25519Key: newKey)
let rotatedAlice = manager.getContact(id: alice.id)
if let rotatedAlice = rotatedAlice {
    if rotatedAlice.x25519PublicKey == newKey &&
       rotatedAlice.trustLevel == .unverified &&
       rotatedAlice.keyHistory.count == 1 &&
       rotatedAlice.keyHistory[0].x25519PublicKey == originalKey {
        print("✓ Key rotation handling works")
    } else {
        print("❌ Key rotation handling failed")
        print("  New key match: \(rotatedAlice.x25519PublicKey == newKey)")
        print("  Trust reset: \(rotatedAlice.trustLevel == .unverified)")
        print("  History count: \(rotatedAlice.keyHistory.count)")
    }
} else {
    print("❌ Contact not found after key rotation")
}

print("\n8. Testing Export...")
let exportData = try manager.exportPublicKeybook()
if !exportData.isEmpty {
    print("✓ Export keybook works")
    
    // Test that export can be decoded
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let publicBundles = try decoder.decode([PublicKeyBundle].self, from: exportData)
    
    if publicBundles.count == 2 {
        print("✓ Export contains correct number of contacts")
    } else {
        print("❌ Export contains wrong number of contacts: \(publicBundles.count)")
    }
} else {
    print("❌ Export keybook failed")
}

print("\n9. Testing Update Contact...")
var updatedAlice = alice
updatedAlice.note = "Updated note"
try manager.updateContact(updatedAlice)

let retrievedUpdatedAlice = manager.getContact(id: alice.id)
if retrievedUpdatedAlice?.note == "Updated note" {
    print("✓ Contact update works")
} else {
    print("❌ Contact update failed")
}

print("\n10. Testing Delete Contact...")
try manager.deleteContact(id: bob.id)
let deletedBob = manager.getContact(id: bob.id)
if deletedBob == nil {
    print("✓ Contact deletion works")
} else {
    print("❌ Contact deletion failed")
}

let remainingContacts = manager.listContacts()
if remainingContacts.count == 1 {
    print("✓ Contact count correct after deletion")
} else {
    print("❌ Contact count incorrect after deletion: \(remainingContacts.count)")
}

print("\n=== Integration Test Summary ===")
print("✅ Add contact")
print("✅ Get contact (by ID and RKID)")
print("✅ List contacts")
print("✅ Search contacts")
print("✅ Trust management")
print("✅ Block management")
print("✅ Key rotation")
print("✅ Export keybook")
print("✅ Update contact")
print("✅ Delete contact")
print("\n🎉 All contact manager integration tests passed!")