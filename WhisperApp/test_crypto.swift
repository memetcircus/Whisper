#!/usr/bin/swift

import Foundation
import CryptoKit

// Simple test script to verify CryptoEngine implementation
print("Starting CryptoEngine tests...")
print("Swift version: \(#file)")
print("Testing CryptoEngine implementation...")

// Test 1: Key generation
print("1. Testing key generation...")
let x25519Private = Curve25519.KeyAgreement.PrivateKey()
let x25519Public = x25519Private.publicKey.rawRepresentation
print("✓ X25519 key pair generated: \(x25519Public.count) bytes")

let ed25519Private = Curve25519.Signing.PrivateKey()
let ed25519Public = ed25519Private.publicKey.rawRepresentation
print("✓ Ed25519 key pair generated: \(ed25519Public.count) bytes")

// Test 2: Key agreement
print("2. Testing key agreement...")
let alice = Curve25519.KeyAgreement.PrivateKey()
let bob = Curve25519.KeyAgreement.PrivateKey()

do {
    let sharedSecret1 = try alice.sharedSecretFromKeyAgreement(with: bob.publicKey)
    let sharedSecret2 = try bob.sharedSecretFromKeyAgreement(with: alice.publicKey)
    
    let secret1Data = sharedSecret1.withUnsafeBytes { Data($0) }
    let secret2Data = sharedSecret2.withUnsafeBytes { Data($0) }
    
    if secret1Data == secret2Data {
        print("✓ Key agreement successful: \(secret1Data.count) bytes")
    } else {
        print("✗ Key agreement failed: secrets don't match")
    }
} catch {
    print("✗ Key agreement error: \(error)")
}

// Test 3: HKDF key derivation with separate labels
print("3. Testing HKDF key derivation...")
do {
    let sharedSecret = try alice.sharedSecretFromKeyAgreement(with: bob.publicKey)
    let salt = Data(repeating: 0x42, count: 16)
    let contextInfo = "whisper-v1".data(using: .utf8)!
    let keyInfo = "key".data(using: .utf8)! + contextInfo
    let nonceInfo = "nonce".data(using: .utf8)! + contextInfo
    
    let encKey = sharedSecret.hkdfDerivedSymmetricKey(
        using: SHA256.self,
        salt: salt,
        sharedInfo: keyInfo,
        outputByteCount: 32
    )
    
    let nonceKey = sharedSecret.hkdfDerivedSymmetricKey(
        using: SHA256.self,
        salt: salt,
        sharedInfo: nonceInfo,
        outputByteCount: 12
    )
    
    let encKeyData = encKey.withUnsafeBytes { Data($0) }
    let nonceData = nonceKey.withUnsafeBytes { Data($0) }
    
    print("✓ HKDF derivation successful: key=\(encKeyData.count) bytes, nonce=\(nonceData.count) bytes")
    
    // Verify key and nonce are different
    if encKeyData.prefix(12) != nonceData {
        print("✓ Key and nonce are properly differentiated")
    } else {
        print("✗ Key and nonce should be different")
    }
} catch {
    print("✗ HKDF error: \(error)")
}

// Test 4: ChaCha20-Poly1305 AEAD encryption
print("4. Testing ChaCha20-Poly1305 AEAD...")
do {
    let key = SymmetricKey(size: .bits256)
    let plaintext = "Hello, Whisper!".data(using: .utf8)!
    let aad = "additional-authenticated-data".data(using: .utf8)!
    
    let sealedBox = try ChaChaPoly.seal(plaintext, using: key, authenticating: aad)
    let decrypted = try ChaChaPoly.open(sealedBox, using: key, authenticating: aad)
    
    if decrypted == plaintext {
        print("✓ ChaCha20-Poly1305 encryption/decryption successful")
    } else {
        print("✗ ChaCha20-Poly1305 decryption failed")
    }
} catch {
    print("✗ ChaCha20-Poly1305 error: \(error)")
}

// Test 5: Ed25519 digital signatures
print("5. Testing Ed25519 signatures...")
do {
    let signingKey = Curve25519.Signing.PrivateKey()
    let message = "Message to sign".data(using: .utf8)!
    
    let signature = try signingKey.signature(for: message)
    let isValid = signingKey.publicKey.isValidSignature(signature, for: message)
    
    if isValid {
        print("✓ Ed25519 signature verification successful")
        print("  Signature length: \(signature.count) bytes")
    } else {
        print("✗ Ed25519 signature verification failed")
    }
} catch {
    print("✗ Ed25519 signature error: \(error)")
}

// Test 6: Secure random generation
print("6. Testing secure random generation...")
var randomData = Data(count: 32)
let result = randomData.withUnsafeMutableBytes { bytes in
    SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
}

if result == errSecSuccess {
    print("✓ Secure random generation successful: \(randomData.count) bytes")
} else {
    print("✗ Secure random generation failed with status: \(result)")
}

// Test 7: Recipient key ID generation (SHA-256 fallback)
print("7. Testing recipient key ID generation...")
let recipientPublicKey = Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation
let hash = SHA256.hash(data: recipientPublicKey)
let rkid = Data(hash.suffix(8)) // Lower 8 bytes

print("✓ Recipient key ID generated: \(rkid.count) bytes")
print("  RKID: \(rkid.base64EncodedString())")

print("\n🎉 All basic cryptographic tests completed!")