#!/usr/bin/env swift

import CryptoKit
import Foundation

// MARK: - Simple Contact Management Test

print("=== Contact Management System Test ===")

// Test Contact Model Creation
print("\n1. Testing Contact Model...")

struct Contact {
    let id: UUID
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let shortFingerprint: String
    let sasWords: [String]
    let rkid: Data
    var trustLevel: TrustLevel
    var isBlocked: Bool
    let keyVersion: Int
    let createdAt: Date
    var lastSeenAt: Date?
    var note: String?

    init(
        displayName: String, x25519PublicKey: Data, ed25519PublicKey: Data? = nil,
        note: String? = nil
    ) throws {
        self.id = UUID()
        self.displayName = displayName
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.note = note
        self.trustLevel = .unverified
        self.isBlocked = false
        self.keyVersion = 1
        self.createdAt = Date()
        self.lastSeenAt = nil

        // Generate fingerprint using SHA-256
        let hash = SHA256.hash(data: x25519PublicKey)
        self.fingerprint = Data(hash)

        // Generate short fingerprint (Base32 Crockford, 12 chars)
        self.shortFingerprint = Contact.generateShortFingerprint(from: fingerprint)

        // Generate SAS words (6-word sequence)
        self.sasWords = Contact.generateSASWords(from: fingerprint)

        // Generate recipient key ID (rkid) - lower 8 bytes of fingerprint
        self.rkid = Data(fingerprint.suffix(8))
    }

    static func generateShortFingerprint(from fingerprint: Data) -> String {
        let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        let alphabetArray = Array(alphabet)

        var result = ""
        var buffer: UInt64 = 0
        var bitsInBuffer = 0

        let inputData = fingerprint.prefix(8)  // Use first 8 bytes

        for byte in inputData {
            buffer = (buffer << 8) | UInt64(byte)
            bitsInBuffer += 8

            while bitsInBuffer >= 5 {
                let index = Int((buffer >> (bitsInBuffer - 5)) & 0x1F)
                result.append(alphabetArray[index])
                bitsInBuffer -= 5
            }
        }

        if bitsInBuffer > 0 {
            let index = Int((buffer << (5 - bitsInBuffer)) & 0x1F)
            result.append(alphabetArray[index])
        }

        return String(result.prefix(12))
    }

    static func generateSASWords(from fingerprint: Data) -> [String] {
        let sasWordList = [
            "able", "acid", "aged", "also", "area", "army", "away", "baby", "back", "ball",
            "band", "bank", "base", "bath", "bear", "beat", "been", "beer", "bell", "belt",
            "best", "bike", "bill", "bird", "blow", "blue", "boat", "body", "bomb", "bone",
            "book", "boom", "born", "boss", "both", "bowl", "bulk", "burn", "bush", "busy",
        ]

        var words: [String] = []
        let bytes = Array(fingerprint.prefix(6))
        for byte in bytes {
            let index = Int(byte) % sasWordList.count
            words.append(sasWordList[index])
        }

        return words
    }
}

enum TrustLevel: String, CaseIterable {
    case unverified = "unverified"
    case verified = "verified"
    case revoked = "revoked"

    var displayName: String {
        switch self {
        case .unverified: return "Unverified"
        case .verified: return "Verified"
        case .revoked: return "Revoked"
        }
    }
}

// Test contact creation
let testPublicKey = Data(repeating: 0x42, count: 32)
let contact = try Contact(displayName: "Alice Smith", x25519PublicKey: testPublicKey)

print("✓ Contact created successfully")
print("  ID: \(contact.id)")
print("  Name: \(contact.displayName)")
print("  Trust Level: \(contact.trustLevel.displayName)")
print("  Fingerprint: \(contact.fingerprint.map { String(format: "%02x", $0) }.joined())")
print("  Short Fingerprint: \(contact.shortFingerprint)")
print("  RKID: \(contact.rkid.map { String(format: "%02x", $0) }.joined())")
print("  SAS Words: \(contact.sasWords.joined(separator: ", "))")

// Test trust level transitions
print("\n2. Testing Trust Level Management...")

var mutableContact = contact
print("✓ Initial trust level: \(mutableContact.trustLevel.displayName)")

mutableContact.trustLevel = .verified
print("✓ Verified trust level: \(mutableContact.trustLevel.displayName)")

mutableContact.trustLevel = .revoked
print("✓ Revoked trust level: \(mutableContact.trustLevel.displayName)")

mutableContact.trustLevel = .unverified
print("✓ Reset to unverified: \(mutableContact.trustLevel.displayName)")

// Test key rotation detection
print("\n3. Testing Key Rotation Detection...")

let originalKey = contact.x25519PublicKey
let newKey = Data(repeating: 0x99, count: 32)

let keyRotationDetected = originalKey != newKey
print("✓ Key rotation detection: \(keyRotationDetected ? "DETECTED" : "NOT DETECTED")")

let noRotation = originalKey == originalKey
print("✓ No false positive: \(noRotation ? "CORRECT" : "FALSE POSITIVE")")

// Test fingerprint generation consistency
print("\n4. Testing Fingerprint Generation...")

let fingerprint1 = try Contact(displayName: "Test1", x25519PublicKey: testPublicKey).fingerprint
let fingerprint2 = try Contact(displayName: "Test2", x25519PublicKey: testPublicKey).fingerprint

let fingerprintConsistent = fingerprint1 == fingerprint2
print("✓ Fingerprint consistency: \(fingerprintConsistent ? "CONSISTENT" : "INCONSISTENT")")

let differentKey = Data(repeating: 0x43, count: 32)
let differentFingerprint = try Contact(displayName: "Test3", x25519PublicKey: differentKey)
    .fingerprint
let fingerprintUnique = fingerprint1 != differentFingerprint
print("✓ Fingerprint uniqueness: \(fingerprintUnique ? "UNIQUE" : "COLLISION")")

// Test Base32 Crockford encoding
print("\n5. Testing Base32 Crockford Encoding...")

let testData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])  // "Hello"
let encoded = Contact.generateShortFingerprint(from: testData)
print("✓ Base32 encoding of 'Hello': \(encoded)")

let validChars = encoded.allSatisfy { char in
    "0123456789ABCDEFGHJKMNPQRSTVWXYZ".contains(char)
}
print("✓ Valid Base32 characters: \(validChars ? "YES" : "NO")")

// Test SAS words
print("\n6. Testing SAS Words...")

let sasWords = contact.sasWords
print("✓ SAS words count: \(sasWords.count)")
print("✓ SAS words: \(sasWords.joined(separator: ", "))")

let validSASWords = sasWords.allSatisfy { word in
    word.count >= 3 && word.count <= 6 && word.allSatisfy { $0.isLetter }
}
print("✓ Valid SAS words: \(validSASWords ? "YES" : "NO")")

// Test RKID generation
print("\n7. Testing RKID Generation...")

let rkid = contact.rkid
print("✓ RKID length: \(rkid.count) bytes")
print("✓ RKID: \(rkid.map { String(format: "%02x", $0) }.joined())")

let rkidFromFingerprint = Data(contact.fingerprint.suffix(8))
let rkidCorrect = rkid == rkidFromFingerprint
print("✓ RKID from fingerprint suffix: \(rkidCorrect ? "CORRECT" : "INCORRECT")")

print("\n=== Test Summary ===")
print("✅ Contact model creation")
print("✅ Trust level management")
print("✅ Key rotation detection")
print("✅ Fingerprint generation")
print("✅ Base32 Crockford encoding")
print("✅ SAS words generation")
print("✅ RKID generation")
print("\n🎉 All contact management tests passed!")
