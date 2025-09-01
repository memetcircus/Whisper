#!/usr/bin/env swift

import Foundation
import CryptoKit

// Test envelope parsing logic specifically

print("=== Envelope Parsing Validation ===\n")

// Base64URL encoder
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

func testEnvelopeParsing() {
    let encoder = Base64URLEncoder()
    
    // Create a test envelope manually
    let version = "v1.c20p"
    let rkid = Data(repeating: 0x01, count: 8)
    let flags: UInt8 = 0x00
    let epk = Data(repeating: 0x02, count: 32)
    let salt = Data(repeating: 0x03, count: 16)
    let msgid = Data(repeating: 0x04, count: 16)
    let timestamp: Int64 = 1234567890
    let ciphertext = Data(repeating: 0x05, count: 48)
    
    // Build envelope components
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
    print("Test envelope: \(envelope)")
    
    // Parse the envelope using the same logic as EnvelopeProcessor
    guard envelope.hasPrefix("whisper1:") else {
        print("✗ Invalid prefix")
        return
    }
    
    let envelopeBody = String(envelope.dropFirst(9))
    let allComponents = envelopeBody.split(separator: ".")
    
    print("All components count: \(allComponents.count)")
    
    // Should have 9 components (v1, c20p, rkid, flags, epk, salt, msgid, ts, ct)
    guard allComponents.count == 9 else {
        print("✗ Invalid component count: \(allComponents.count)")
        return
    }
    
    // Reconstruct version
    let parsedVersion = String(allComponents[0]) + "." + String(allComponents[1])
    guard parsedVersion == "v1.c20p" else {
        print("✗ Invalid version: \(parsedVersion)")
        return
    }
    
    print("✓ Version parsed correctly: \(parsedVersion)")
    
    // Parse remaining components
    let envelopeComponents = Array(allComponents.dropFirst(2))
    
    // Decode and validate
    let decodedRkid = try! encoder.decode(String(envelopeComponents[0]))
    assert(decodedRkid.count == 8, "RKID should be 8 bytes")
    print("✓ RKID decoded: \(decodedRkid.count) bytes")
    
    let decodedFlags = try! encoder.decode(String(envelopeComponents[1]))
    assert(decodedFlags.count == 1, "Flags should be 1 byte")
    print("✓ Flags decoded: 0x\(String(format: "%02x", decodedFlags[0]))")
    
    let decodedEpk = try! encoder.decode(String(envelopeComponents[2]))
    assert(decodedEpk.count == 32, "EPK should be 32 bytes")
    print("✓ EPK decoded: \(decodedEpk.count) bytes")
    
    let decodedSalt = try! encoder.decode(String(envelopeComponents[3]))
    assert(decodedSalt.count == 16, "Salt should be 16 bytes")
    print("✓ Salt decoded: \(decodedSalt.count) bytes")
    
    let decodedMsgid = try! encoder.decode(String(envelopeComponents[4]))
    assert(decodedMsgid.count == 16, "Message ID should be 16 bytes")
    print("✓ Message ID decoded: \(decodedMsgid.count) bytes")
    
    let decodedTimestamp = try! encoder.decode(String(envelopeComponents[5]))
    assert(decodedTimestamp.count == 8, "Timestamp should be 8 bytes")
    let parsedTimestamp = decodedTimestamp.withUnsafeBytes { $0.load(as: Int64.self).bigEndian }
    assert(parsedTimestamp == timestamp, "Timestamp should match")
    print("✓ Timestamp decoded: \(parsedTimestamp)")
    
    let decodedCiphertext = try! encoder.decode(String(envelopeComponents[6]))
    assert(decodedCiphertext.count == 48, "Ciphertext should be 48 bytes")
    print("✓ Ciphertext decoded: \(decodedCiphertext.count) bytes")
    
    print("\n✓ All envelope parsing tests passed!")
}

func testInvalidEnvelopes() {
    print("\nTesting invalid envelope rejection...")
    
    let invalidEnvelopes = [
        "kiro1:v1.c20p.rkid.flags.epk.salt.msgid.ts.ct",  // Wrong prefix
        "whisper1:v2.c20p.rkid.flags.epk.salt.msgid.ts.ct",  // Wrong version
        "whisper1:v1.aes.rkid.flags.epk.salt.msgid.ts.ct",   // Wrong algorithm
        "whisper1:v1.c20p.rkid.flags.epk.salt.msgid",        // Too few components
    ]
    
    for envelope in invalidEnvelopes {
        // Test prefix validation
        if !envelope.hasPrefix("whisper1:") {
            print("✓ Correctly rejected invalid prefix: \(envelope.prefix(20))...")
            continue
        }
        
        // Test component count
        let envelopeBody = String(envelope.dropFirst(9))
        let allComponents = envelopeBody.split(separator: ".")
        
        if allComponents.count < 9 {
            print("✓ Correctly rejected insufficient components: \(envelope.prefix(30))...")
            continue
        }
        
        // Test version
        let version = String(allComponents[0]) + "." + String(allComponents[1])
        if version != "v1.c20p" {
            print("✓ Correctly rejected invalid version \(version): \(envelope.prefix(30))...")
            continue
        }
    }
}

// Run tests
testEnvelopeParsing()
testInvalidEnvelopes()

print("\n=== All parsing tests completed! ===")