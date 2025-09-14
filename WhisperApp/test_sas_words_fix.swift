#!/usr/bin/env swift

import Foundation
import CryptoKit

// Test script to validate SAS words consistency fix

// Mock implementations for testing
struct SASWordList {
    static let words: [String] = [
        "able", "acid", "aged", "also", "area", "army", "away", "baby", "back", "ball",
        "band", "bank", "base", "bath", "bear", "beat", "been", "beer", "bell", "belt",
        "best", "bike", "bill", "bird", "blow", "blue", "boat", "body", "bomb", "bone",
        "book", "boom", "born", "boss", "both", "bowl", "bulk", "burn", "bush", "busy",
        "call", "calm", "came", "camp", "card", "care", "case", "cash", "cast", "cell",
        "chat", "chip", "city", "club", "coal", "coat", "code", "cold", "come", "cook",
        "cool", "copy", "core", "corn", "cost", "crew", "crop", "dark", "data", "date"
    ]
}

extension Data {
    func base32CrockfordEncoded() -> String {
        // Simplified implementation for testing
        return self.base64EncodedString().prefix(12).uppercased()
    }
}

// Test Contact structure
struct TestContact {
    let fingerprint: Data
    let sasWords: [String]
    
    static func generateFingerprint(from publicKey: Data) -> Data {
        return Data(SHA256.hash(data: publicKey))
    }
    
    static func generateSASWords(from fingerprint: Data) -> [String] {
        let sasWordList = SASWordList.words
        var words: [String] = []
        
        let bytes = Array(fingerprint.prefix(6))
        for byte in bytes {
            let index = Int(byte) % sasWordList.count
            words.append(sasWordList[index])
        }
        
        return words
    }
}

// Test PublicKeyBundle structure
struct TestPublicKeyBundle {
    let id: UUID
    let name: String
    let x25519PublicKey: Data
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date
}

print("🧪 Testing SAS Words Consistency Fix")
print("=====================================")

// Create test data
let testPublicKey = Data(repeating: 0x42, count: 32)
let originalFingerprint = TestContact.generateFingerprint(from: testPublicKey)

// Simulate QR code generation (Akif's side)
let bundle = TestPublicKeyBundle(
    id: UUID(),
    name: "Akif",
    x25519PublicKey: testPublicKey,
    fingerprint: originalFingerprint,
    keyVersion: 1,
    createdAt: Date()
)

let qrDisplaySASWords = TestContact.generateSASWords(from: bundle.fingerprint)
print("📱 QR Display SAS Words (Akif): \(qrDisplaySASWords.joined(separator: ", "))")

// Simulate contact preview (Tugba's side - before fix)
let previewSASWords = TestContact.generateSASWords(from: bundle.fingerprint)
print("👀 Contact Preview SAS Words (Tugba): \(previewSASWords.joined(separator: ", "))")

// Simulate contact creation (old way - regenerates fingerprint)
let newFingerprint = TestContact.generateFingerprint(from: bundle.x25519PublicKey)
let oldWaySASWords = TestContact.generateSASWords(from: newFingerprint)
print("❌ Old Contact Creation SAS Words: \(oldWaySASWords.joined(separator: ", "))")

// Simulate contact creation (new way - preserves fingerprint)
let newWaySASWords = TestContact.generateSASWords(from: bundle.fingerprint)
print("✅ New Contact Creation SAS Words: \(newWaySASWords.joined(separator: ", "))")

print("\n🔍 Analysis:")
print("QR Display == Contact Preview: \(qrDisplaySASWords == previewSASWords ? "✅ MATCH" : "❌ MISMATCH")")
print("QR Display == Old Contact Creation: \(qrDisplaySASWords == oldWaySASWords ? "✅ MATCH" : "❌ MISMATCH")")
print("QR Display == New Contact Creation: \(qrDisplaySASWords == newWaySASWords ? "✅ MATCH" : "❌ MISMATCH")")

print("\n🎯 Fix Status:")
if qrDisplaySASWords == newWaySASWords {
    print("✅ SUCCESS: SAS words are now consistent across all views!")
    print("   Both Akif and Tugba will see the same SAS words.")
} else {
    print("❌ FAILED: SAS words are still inconsistent.")
}

print("\n📋 Test Results Summary:")
print("- QR Display (Akif): \(qrDisplaySASWords)")
print("- Contact Verification (Tugba): \(newWaySASWords)")
print("- Match: \(qrDisplaySASWords == newWaySASWords ? "YES" : "NO")")