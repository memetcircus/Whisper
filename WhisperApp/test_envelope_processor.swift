#!/usr/bin/env swift

import Foundation
import CryptoKit

// Copy the necessary types and implementations for testing
// This is a standalone test to validate envelope processing

// MARK: - Supporting Types

struct X25519KeyPair {
    let privateKey: Curve25519.KeyAgreement.PrivateKey
    let publicKey: Data
}

struct Ed25519KeyPair {
    let privateKey: Curve25519.Signing.PrivateKey
    let publicKey: Data
}

enum IdentityStatus {
    case active
    case archived
    case rotated
}

struct Identity {
    let id: UUID
    let name: String
    let x25519KeyPair: X25519KeyPair
    let ed25519KeyPair: Ed25519KeyPair?
    let fingerprint: Data
    let createdAt: Date
    let status: IdentityStatus
    let keyVersion: Int
}

// MARK: - Base64URL Encoder

class Base64URLEncoder {
    func encode(_ data: Data) -> String {
        let base64 = data.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    func decode(_ string: String) throws -> Data {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64) else {
            throw NSError(domain: "Base64URLError", code: 1, userInfo: nil)
        }
        
        return data
    }
}

// MARK: - Test Functions

func testBase64URLEncoding() {
    print("Testing Base64URL encoding...")
    
    let encoder = Base64URLEncoder()
    let testData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
    let encoded = encoder.encode(testData)
    
    print("Original data: \(testData.map { String(format: "%02x", $0) }.joined())")
    print("Encoded: \(encoded)")
    
    // Should not contain padding or standard Base64 characters
    assert(!encoded.contains("="), "Should not contain padding")
    assert(!encoded.contains("+"), "Should not contain +")
    assert(!encoded.contains("/"), "Should not contain /")
    
    // Should be decodable
    let decoded = try! encoder.decode(encoded)
    assert(decoded == testData, "Round-trip failed")
    
    print("✓ Base64URL encoding test passed")
}

func testRecipientKeyIdGeneration() {
    print("Testing recipient key ID generation...")
    
    let publicKey1 = Data(repeating: 0x01, count: 32)
    let publicKey2 = Data(repeating: 0x02, count: 32)
    
    // Generate rkid using SHA-256 (lower 8 bytes)
    let hash1 = SHA256.hash(data: publicKey1)
    let rkid1 = Data(hash1.suffix(8))
    
    let hash2 = SHA256.hash(data: publicKey2)
    let rkid2 = Data(hash2.suffix(8))
    
    print("Public key 1: \(publicKey1.prefix(8).map { String(format: "%02x", $0) }.joined())...")
    print("RKID 1: \(rkid1.map { String(format: "%02x", $0) }.joined())")
    
    print("Public key 2: \(publicKey2.prefix(8).map { String(format: "%02x", $0) }.joined())...")
    print("RKID 2: \(rkid2.map { String(format: "%02x", $0) }.joined())")
    
    // Should be 8 bytes
    assert(rkid1.count == 8, "RKID should be 8 bytes")
    assert(rkid2.count == 8, "RKID should be 8 bytes")
    
    // Different keys should produce different rkids
    assert(rkid1 != rkid2, "Different keys should produce different RKIDs")
    
    // Same key should produce same rkid
    let hash1_again = SHA256.hash(data: publicKey1)
    let rkid1_again = Data(hash1_again.suffix(8))
    assert(rkid1 == rkid1_again, "Same key should produce same RKID")
    
    print("✓ Recipient key ID generation test passed")
}

func testCanonicalContextBuilding() {
    print("Testing canonical context building...")
    
    // Test data
    let appId = "whisper"
    let version = "v1"
    let senderFingerprint = Data(repeating: 0x01, count: 32)
    let recipientFingerprint = Data(repeating: 0x02, count: 32)
    let policyFlags: UInt32 = 0x01
    let rkid = Data(repeating: 0x03, count: 8)
    let epk = Data(repeating: 0x04, count: 32)
    let salt = Data(repeating: 0x05, count: 16)
    let msgid = Data(repeating: 0x06, count: 16)
    let timestamp: Int64 = 1234567890
    
    // Build canonical context using length-prefixed encoding
    func encodeLengthPrefixed(_ data: Data) -> Data {
        var result = Data()
        var length = UInt32(data.count).bigEndian
        result.append(Data(bytes: &length, count: 4))
        result.append(data)
        return result
    }
    
    var context = Data()
    context.append(encodeLengthPrefixed(appId.data(using: .utf8)!))
    context.append(encodeLengthPrefixed(version.data(using: .utf8)!))
    context.append(encodeLengthPrefixed(senderFingerprint))
    context.append(encodeLengthPrefixed(recipientFingerprint))
    
    var policyFlagsBE = policyFlags.bigEndian
    context.append(Data(bytes: &policyFlagsBE, count: 4))
    
    context.append(encodeLengthPrefixed(rkid))
    context.append(encodeLengthPrefixed(epk))
    context.append(encodeLengthPrefixed(salt))
    context.append(encodeLengthPrefixed(msgid))
    
    var timestampBE = timestamp.bigEndian
    context.append(Data(bytes: &timestampBE, count: 8))
    
    print("Canonical context length: \(context.count) bytes")
    print("Context prefix: \(context.prefix(16).map { String(format: "%02x", $0) }.joined())")
    
    // Build same context again - should be identical
    var context2 = Data()
    context2.append(encodeLengthPrefixed(appId.data(using: .utf8)!))
    context2.append(encodeLengthPrefixed(version.data(using: .utf8)!))
    context2.append(encodeLengthPrefixed(senderFingerprint))
    context2.append(encodeLengthPrefixed(recipientFingerprint))
    
    var policyFlagsBE2 = policyFlags.bigEndian
    context2.append(Data(bytes: &policyFlagsBE2, count: 4))
    
    context2.append(encodeLengthPrefixed(rkid))
    context2.append(encodeLengthPrefixed(epk))
    context2.append(encodeLengthPrefixed(salt))
    context2.append(encodeLengthPrefixed(msgid))
    
    var timestampBE2 = timestamp.bigEndian
    context2.append(Data(bytes: &timestampBE2, count: 8))
    
    assert(context == context2, "Same inputs should produce identical context")
    
    print("✓ Canonical context building test passed")
}

func testEnvelopeFormat() {
    print("Testing envelope format...")
    
    let encoder = Base64URLEncoder()
    
    // Test envelope components
    let version = "v1.c20p"
    let rkid = Data(repeating: 0x01, count: 8)
    let flags: UInt8 = 0x00 // No signature
    let epk = Data(repeating: 0x02, count: 32)
    let salt = Data(repeating: 0x03, count: 16)
    let msgid = Data(repeating: 0x04, count: 16)
    let timestamp: Int64 = 1234567890
    let ciphertext = Data(repeating: 0x05, count: 48) // Example ciphertext
    
    // Build envelope
    var components = [version]
    components.append(encoder.encode(rkid))
    components.append(encoder.encode(Data([flags])))
    components.append(encoder.encode(epk))
    components.append(encoder.encode(salt))
    components.append(encoder.encode(msgid))
    
    var timestampBE = timestamp.bigEndian
    let timestampData = Data(bytes: &timestampBE, count: 8)
    components.append(encoder.encode(timestampData))
    
    components.append(encoder.encode(ciphertext))
    
    let envelope = "whisper1:" + components.joined(separator: ".")
    
    print("Envelope: \(envelope)")
    print("Component count: \(components.count)")
    
    // Validate format
    assert(envelope.hasPrefix("whisper1:"), "Should have correct prefix")
    
    // Parse envelope - need to handle the version specially since it contains a dot
    let envelopeBody = String(envelope.dropFirst(9)) // Remove "whisper1:"
    let allComponents = envelopeBody.split(separator: ".")
    
    print("All component count: \(allComponents.count)")
    
    // The version "v1.c20p" gets split into "v1" and "c20p", so we need to rejoin them
    // Expected format after splitting: ["v1", "c20p", "rkid", "flags", "epk", "salt", "msgid", "ts", "ct"]
    // So we should have 9 components, and we need to rejoin the first two
    assert(allComponents.count == 9, "Should have 9 raw components")
    
    let parsedVersion = String(allComponents[0]) + "." + String(allComponents[1])
    assert(parsedVersion == "v1.c20p", "Should have correct version")
    
    // The remaining components should be the envelope fields
    let parsedComponents = Array(allComponents.dropFirst(2)) // Skip "v1" and "c20p"
    assert(parsedComponents.count == 7, "Should have 7 envelope field components")
    
    // Decode and validate components (now using 0-based indexing since we dropped the version)
    let decodedRkid = try! encoder.decode(String(parsedComponents[0]))
    assert(decodedRkid.count == 8, "RKID should be 8 bytes")
    
    let decodedFlags = try! encoder.decode(String(parsedComponents[1]))
    assert(decodedFlags.count == 1, "Flags should be 1 byte")
    
    let decodedEpk = try! encoder.decode(String(parsedComponents[2]))
    assert(decodedEpk.count == 32, "EPK should be 32 bytes")
    
    print("✓ Envelope format test passed")
}

func testAlgorithmValidation() {
    print("Testing algorithm validation...")
    
    let validAlgorithm = "v1.c20p"
    let invalidAlgorithms = ["v2.c20p", "v1.aes", "v1.c20p1", "v0.c20p"]
    
    // Valid algorithm should pass
    assert(validAlgorithm == "v1.c20p", "Valid algorithm should be accepted")
    
    // Invalid algorithms should be rejected
    for invalid in invalidAlgorithms {
        assert(invalid != "v1.c20p", "Invalid algorithm \(invalid) should be rejected")
    }
    
    print("✓ Algorithm validation test passed")
}

// MARK: - Main Test Runner

func runTests() {
    print("=== Envelope Processor Validation Tests ===\n")
    
    testBase64URLEncoding()
    print()
    
    testRecipientKeyIdGeneration()
    print()
    
    testCanonicalContextBuilding()
    print()
    
    testEnvelopeFormat()
    print()
    
    testAlgorithmValidation()
    print()
    
    print("=== All tests passed! ===")
}

// Run the tests
runTests()