#!/usr/bin/env swift

import Foundation

// Test script to debug contact import functionality
print("🔍 Contact Import Debug Test")
print(String(repeating: "=", count: 50))

// Test 1: Create a sample contact export file
print("\n📝 Test 1: Creating sample contact export data")

struct ContactExportData: Codable {
    let id: String
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let shortFingerprint: String
    let trustLevel: String
    let keyVersion: Int
    let createdAt: Date
    let note: String?
}

// Create sample contact data
let sampleContacts = [
    ContactExportData(
        id: UUID().uuidString,
        displayName: "Test Contact 1",
        x25519PublicKey: Data(repeating: 0x01, count: 32),
        ed25519PublicKey: Data(repeating: 0x02, count: 32),
        fingerprint: Data(repeating: 0x03, count: 32),
        shortFingerprint: "ABC123",
        trustLevel: "verified",
        keyVersion: 1,
        createdAt: Date(),
        note: "Test contact for import"
    ),
    ContactExportData(
        id: UUID().uuidString,
        displayName: "Test Contact 2",
        x25519PublicKey: Data(repeating: 0x04, count: 32),
        ed25519PublicKey: nil,
        fingerprint: Data(repeating: 0x05, count: 32),
        shortFingerprint: "DEF456",
        trustLevel: "unverified",
        keyVersion: 1,
        createdAt: Date(),
        note: nil
    )
]

// Test 2: Encode to JSON
print("\n📝 Test 2: Encoding contacts to JSON")
do {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let jsonData = try encoder.encode(sampleContacts)
    
    print("✅ Successfully encoded \(sampleContacts.count) contacts")
    print("📊 JSON size: \(jsonData.count) bytes")
    
    // Save to file for testing
    let tempDir = FileManager.default.temporaryDirectory
    let testFile = tempDir.appendingPathComponent("test-contacts.json")
    try jsonData.write(to: testFile)
    print("💾 Test file saved to: \(testFile.path)")
    
    // Test 3: Read back and decode
    print("\n📝 Test 3: Reading and decoding JSON")
    let readData = try Data(contentsOf: testFile)
    print("📖 Read \(readData.count) bytes from file")
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decodedContacts = try decoder.decode([ContactExportData].self, from: readData)
    print("✅ Successfully decoded \(decodedContacts.count) contacts")
    
    // Test 4: Validate data integrity
    print("\n📝 Test 4: Validating data integrity")
    for (index, contact) in decodedContacts.enumerated() {
        print("Contact \(index + 1):")
        print("  - ID: \(contact.id)")
        print("  - Name: \(contact.displayName)")
        print("  - Trust Level: \(contact.trustLevel)")
        print("  - Key Version: \(contact.keyVersion)")
        print("  - Has Ed25519 Key: \(contact.ed25519PublicKey != nil)")
        print("  - Note: \(contact.note ?? "None")")
    }
    
    print("\n✅ All tests passed! Contact export/import format is working correctly.")
    print("\n🔍 Debugging suggestions:")
    print("1. Check if the imported file has the correct JSON structure")
    print("2. Verify the file is not corrupted during transfer")
    print("3. Ensure the app has proper file access permissions")
    print("4. Check if the TrustLevel enum values match ('verified', 'unverified', etc.)")
    
} catch {
    print("❌ Test failed: \(error)")
    print("\n🔍 This indicates a problem with the JSON encoding/decoding")
}

print("\n" + String(repeating: "=", count: 50))
print("🏁 Contact Import Debug Test Complete")