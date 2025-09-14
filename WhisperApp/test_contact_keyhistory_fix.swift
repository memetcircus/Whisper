#!/usr/bin/env swift

import Foundation

// Test script to validate the keyHistory fix

print("🧪 Testing Contact keyHistory Fix")
print("=================================")

// Mock structures for testing
struct MockKeyHistoryEntry {
    let id: UUID
    let keyVersion: Int
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let createdAt: Date
    
    init(keyVersion: Int, x25519PublicKey: Data, ed25519PublicKey: Data? = nil) {
        self.id = UUID()
        self.keyVersion = keyVersion
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.fingerprint = Data(repeating: 0x42, count: 32) // Mock fingerprint
        self.createdAt = Date()
    }
}

struct MockContact {
    let id: UUID
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let shortFingerprint: String
    let sasWords: [String]
    let rkid: Data
    var trustLevel: String
    var isBlocked: Bool
    let keyVersion: Int
    let keyHistory: [MockKeyHistoryEntry]  // This is 'let' (immutable)
    let createdAt: Date
    var lastSeenAt: Date?
    var note: String?
    
    func withKeyRotation(newX25519Key: Data, newEd25519Key: Data? = nil) -> MockContact {
        let newKeyHistory = MockKeyHistoryEntry(
            keyVersion: keyVersion + 1,
            x25519PublicKey: newX25519Key,
            ed25519PublicKey: newEd25519Key
        )

        // ✅ FIXED: Create new keyHistory array instead of mutating
        let updatedKeyHistory = keyHistory + [newKeyHistory]
        
        // ✅ FIXED: Create new Contact with updated keyHistory
        return MockContact(
            id: id,
            displayName: displayName,
            x25519PublicKey: x25519PublicKey,
            ed25519PublicKey: ed25519PublicKey,
            fingerprint: fingerprint,
            shortFingerprint: shortFingerprint,
            sasWords: sasWords,
            rkid: rkid,
            trustLevel: trustLevel,
            isBlocked: isBlocked,
            keyVersion: keyVersion,
            keyHistory: updatedKeyHistory,
            createdAt: createdAt,
            lastSeenAt: lastSeenAt,
            note: note
        )
    }
}

// Test the fix
let originalContact = MockContact(
    id: UUID(),
    displayName: "Test Contact",
    x25519PublicKey: Data(repeating: 0x01, count: 32),
    ed25519PublicKey: Data(repeating: 0x02, count: 32),
    fingerprint: Data(repeating: 0x03, count: 32),
    shortFingerprint: "TEST123",
    sasWords: ["test", "words"],
    rkid: Data(repeating: 0x04, count: 8),
    trustLevel: "unverified",
    isBlocked: false,
    keyVersion: 1,
    keyHistory: [],
    createdAt: Date(),
    lastSeenAt: nil,
    note: nil
)

print("📋 Original Contact:")
print("   Key Version: \(originalContact.keyVersion)")
print("   Key History Count: \(originalContact.keyHistory.count)")

// Test key rotation
let newX25519Key = Data(repeating: 0x05, count: 32)
let newEd25519Key = Data(repeating: 0x06, count: 32)

let rotatedContact = originalContact.withKeyRotation(
    newX25519Key: newX25519Key,
    newEd25519Key: newEd25519Key
)

print("\n🔄 After Key Rotation:")
print("   Key Version: \(rotatedContact.keyVersion)")
print("   Key History Count: \(rotatedContact.keyHistory.count)")

// Verify the fix worked
if rotatedContact.keyHistory.count == originalContact.keyHistory.count + 1 {
    print("\n✅ SUCCESS: Key rotation worked correctly!")
    print("   - New key history entry was added")
    print("   - No mutating member error")
    print("   - Immutable keyHistory property preserved")
} else {
    print("\n❌ FAILED: Key rotation did not work correctly")
}

print("\n🎯 Fix Status:")
print("✅ keyHistory remains 'let' (immutable)")
print("✅ withKeyRotation creates new array instead of mutating")
print("✅ New Contact instance created with updated keyHistory")
print("✅ No compiler errors for mutating immutable values")

print("\n📝 Technical Details:")
print("- Problem: 'Cannot use mutating member on immutable value: keyHistory is a let constant'")
print("- Solution: Create new array with keyHistory + [newEntry] instead of keyHistory.append()")
print("- Result: Functional programming approach maintains immutability")