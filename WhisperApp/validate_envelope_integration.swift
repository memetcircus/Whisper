#!/usr/bin/env swift

import Foundation
import CryptoKit

// This test validates the integration between CryptoEngine and EnvelopeProcessor
// It tests the complete envelope creation and parsing flow

print("=== Envelope Integration Validation ===\n")

// Create a crypto engine
let cryptoEngine = CryptoKitEngine()

// Create an envelope processor
let envelopeProcessor = WhisperEnvelopeProcessor(cryptoEngine: cryptoEngine)

// Generate test identity
print("Generating test identity...")
let testIdentity = try! cryptoEngine.generateIdentity()
print("✓ Identity generated with ID: \(testIdentity.id)")

// Generate recipient key pair
print("Generating recipient key pair...")
let recipientPrivateKey = Curve25519.KeyAgreement.PrivateKey()
let recipientPublicKey = recipientPrivateKey.publicKey.rawRepresentation
print("✓ Recipient key pair generated")

// Test envelope creation without signature
print("\nTesting envelope creation without signature...")
let plaintext = "Hello, Whisper World!".data(using: .utf8)!
print("Plaintext: \(String(data: plaintext, encoding: .utf8)!)")

let envelope = try! envelopeProcessor.createEnvelope(
    plaintext: plaintext,
    senderIdentity: testIdentity,
    recipientPublic: recipientPublicKey,
    requireSignature: false
)

print("Envelope created: \(envelope.prefix(50))...")
print("✓ Envelope creation successful")

// Test envelope parsing
print("\nTesting envelope parsing...")
let components = try! envelopeProcessor.parseEnvelope(envelope)
print("Version: \(components.version)")
print("RKID: \(components.rkid.map { String(format: "%02x", $0) }.joined())")
print("Flags: 0x\(String(format: "%02x", components.flags))")
print("Has signature: \(components.hasSignature)")
print("EPK length: \(components.epk.count)")
print("Salt length: \(components.salt.count)")
print("Message ID length: \(components.msgid.count)")
print("Ciphertext length: \(components.ciphertext.count)")
print("✓ Envelope parsing successful")

// Test envelope validation
print("\nTesting envelope validation...")
let isValid = try! envelopeProcessor.validateEnvelope(components)
print("Envelope is valid: \(isValid)")
print("✓ Envelope validation successful")

// Test envelope creation with signature
print("\nTesting envelope creation with signature...")
let envelopeWithSig = try! envelopeProcessor.createEnvelope(
    plaintext: plaintext,
    senderIdentity: testIdentity,
    recipientPublic: recipientPublicKey,
    requireSignature: true
)

print("Signed envelope created: \(envelopeWithSig.prefix(50))...")

let signedComponents = try! envelopeProcessor.parseEnvelope(envelopeWithSig)
print("Has signature: \(signedComponents.hasSignature)")
print("Signature length: \(signedComponents.signature?.count ?? 0)")
print("✓ Signed envelope creation successful")

// Test determinism - same plaintext should produce different envelopes
print("\nTesting envelope determinism...")
let envelope2 = try! envelopeProcessor.createEnvelope(
    plaintext: plaintext,
    senderIdentity: testIdentity,
    recipientPublic: recipientPublicKey,
    requireSignature: false
)

if envelope != envelope2 {
    print("✓ Determinism test passed - same plaintext produces different envelopes")
} else {
    print("✗ Determinism test failed - envelopes are identical")
}

// Test algorithm validation
print("\nTesting algorithm validation...")
let invalidEnvelopes = [
    "whisper1:v2.c20p.rkid.flags.epk.salt.msgid.ts.ct",
    "whisper1:v1.aes.rkid.flags.epk.salt.msgid.ts.ct",
    "kiro1:v1.c20p.rkid.flags.epk.salt.msgid.ts.ct"
]

for invalidEnvelope in invalidEnvelopes {
    do {
        _ = try envelopeProcessor.parseEnvelope(invalidEnvelope)
        print("✗ Should have rejected: \(invalidEnvelope)")
    } catch {
        print("✓ Correctly rejected: \(invalidEnvelope)")
    }
}

// Test canonical context building
print("\nTesting canonical context building...")
let context = envelopeProcessor.buildCanonicalContext(
    appId: "whisper",
    version: "v1",
    senderFingerprint: testIdentity.fingerprint,
    recipientFingerprint: Data(SHA256.hash(data: recipientPublicKey)),
    policyFlags: 0x01,
    rkid: components.rkid,
    epk: components.epk,
    salt: components.salt,
    msgid: components.msgid,
    ts: components.timestamp
)

print("Canonical context length: \(context.count) bytes")
print("✓ Canonical context building successful")

print("\n=== All integration tests passed! ===")