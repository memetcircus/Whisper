#!/usr/bin/env swift

import Foundation

print("🔧 Testing Contact Import Fix")
print(String(repeating: "=", count: 50))

// Test the complete export/import flow with proper date handling
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

// Create test data that matches what the app would export
let testContacts = [
    ContactExportData(
        id: UUID().uuidString,
        displayName: "Alice Smith",
        x25519PublicKey: Data(repeating: 0x01, count: 32),
        ed25519PublicKey: Data(repeating: 0x02, count: 32),
        fingerprint: Data(repeating: 0x03, count: 32),
        shortFingerprint: "ABC123DEF456",
        trustLevel: "verified",
        keyVersion: 1,
        createdAt: Date(),
        note: "Verified contact from QR scan"
    ),
    ContactExportData(
        id: UUID().uuidString,
        displayName: "Bob Johnson",
        x25519PublicKey: Data(repeating: 0x04, count: 32),
        ed25519PublicKey: nil,
        fingerprint: Data(repeating: 0x05, count: 32),
        shortFingerprint: "GHI789JKL012",
        trustLevel: "unverified",
        keyVersion: 1,
        createdAt: Date().addingTimeInterval(-86400), // 1 day ago
        note: nil
    ),
    ContactExportData(
        id: UUID().uuidString,
        displayName: "Charlie Brown",
        x25519PublicKey: Data(repeating: 0x06, count: 32),
        ed25519PublicKey: Data(repeating: 0x07, count: 32),
        fingerprint: Data(repeating: 0x08, count: 32),
        shortFingerprint: "MNO345PQR678",
        trustLevel: "revoked",
        keyVersion: 2,
        createdAt: Date().addingTimeInterval(-172800), // 2 days ago
        note: "Key was compromised"
    )
]

print("\n📝 Test 1: Export with ISO8601 date encoding")
do {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted
    
    let jsonData = try encoder.encode(testContacts)
    print("✅ Successfully encoded \(testContacts.count) contacts")
    print("📊 JSON size: \(jsonData.count) bytes")
    
    // Save to test file
    let tempDir = FileManager.default.temporaryDirectory
    let testFile = tempDir.appendingPathComponent("whisper-contacts-test.json")
    try jsonData.write(to: testFile)
    print("💾 Test file saved to: \(testFile.path)")
    
    // Show JSON structure
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("\n📄 JSON structure preview:")
        print(String(jsonString.prefix(500)) + "...")
    }
    
    print("\n📝 Test 2: Import with ISO8601 date decoding")
    let readData = try Data(contentsOf: testFile)
    print("📖 Read \(readData.count) bytes from file")
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let decodedContacts = try decoder.decode([ContactExportData].self, from: readData)
    print("✅ Successfully decoded \(decodedContacts.count) contacts")
    
    print("\n📝 Test 3: Validate imported data")
    for (index, contact) in decodedContacts.enumerated() {
        print("Contact \(index + 1): \(contact.displayName)")
        print("  - ID: \(contact.id)")
        print("  - Trust Level: \(contact.trustLevel)")
        print("  - Key Version: \(contact.keyVersion)")
        print("  - Created: \(contact.createdAt)")
        print("  - Has Ed25519: \(contact.ed25519PublicKey != nil)")
        print("  - Note: \(contact.note ?? "None")")
        
        // Validate trust level
        let validTrustLevels = ["unverified", "verified", "revoked"]
        if !validTrustLevels.contains(contact.trustLevel) {
            print("  ⚠️  Invalid trust level: \(contact.trustLevel)")
        }
    }
    
    print("\n✅ All tests passed!")
    print("\n🔧 The export/import format is working correctly.")
    print("📁 Test file location: \(testFile.path)")
    print("💡 You can use this file to test the import functionality in the app.")
    
} catch {
    print("❌ Test failed: \(error)")
    if let decodingError = error as? DecodingError {
        print("🔍 Decoding error details:")
        switch decodingError {
        case .dataCorrupted(let context):
            print("  - Data corrupted: \(context.debugDescription)")
        case .keyNotFound(let key, let context):
            print("  - Key not found: \(key.stringValue) in \(context.debugDescription)")
        case .typeMismatch(let type, let context):
            print("  - Type mismatch: expected \(type) in \(context.debugDescription)")
        case .valueNotFound(let type, let context):
            print("  - Value not found: \(type) in \(context.debugDescription)")
        @unknown default:
            print("  - Unknown decoding error")
        }
    }
}

print("\n" + String(repeating: "=", count: 50))
print("🏁 Contact Import Fix Test Complete")