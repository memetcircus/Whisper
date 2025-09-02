import XCTest
import CryptoKit
@testable import WhisperApp

class CryptographicValidationTests: XCTestCase {
    
    var cryptoEngine: CryptoEngine!
    
    override func setUp() {
        super.setUp()
        cryptoEngine = DefaultCryptoEngine()
    }
    
    override func tearDown() {
        cryptoEngine = nil
        super.tearDown()
    }
    
    // MARK: - Key Generation Validation
    
    func testX25519KeyGeneration() {
        // Test that X25519 keys are generated correctly
        do {
            let identity = try cryptoEngine.generateIdentity()
            
            // Verify key lengths
            XCTAssertEqual(identity.x25519KeyPair.publicKey.count, 32, "X25519 public key should be 32 bytes")
            XCTAssertEqual(identity.x25519KeyPair.privateKey.count, 32, "X25519 private key should be 32 bytes")
            
            // Verify keys are not all zeros
            XCTAssertNotEqual(identity.x25519KeyPair.publicKey, Data(repeating: 0, count: 32))
            XCTAssertNotEqual(identity.x25519KeyPair.privateKey, Data(repeating: 0, count: 32))
            
            // Verify keys are different
            XCTAssertNotEqual(identity.x25519KeyPair.publicKey, identity.x25519KeyPair.privateKey)
            
        } catch {
            XCTFail("X25519 key generation failed: \(error)")
        }
    }
    
    func testEd25519KeyGeneration() {
        // Test that Ed25519 keys are generated correctly
        do {
            let identity = try cryptoEngine.generateIdentity()
            
            guard let ed25519KeyPair = identity.ed25519KeyPair else {
                XCTFail("Ed25519 key pair should be generated")
                return
            }
            
            // Verify key lengths
            XCTAssertEqual(ed25519KeyPair.publicKey.count, 32, "Ed25519 public key should be 32 bytes")
            XCTAssertEqual(ed25519KeyPair.privateKey.count, 32, "Ed25519 private key should be 32 bytes")
            
            // Verify keys are not all zeros
            XCTAssertNotEqual(ed25519KeyPair.publicKey, Data(repeating: 0, count: 32))
            XCTAssertNotEqual(ed25519KeyPair.privateKey, Data(repeating: 0, count: 32))
            
            // Verify keys are different
            XCTAssertNotEqual(ed25519KeyPair.publicKey, ed25519KeyPair.privateKey)
            
        } catch {
            XCTFail("Ed25519 key generation failed: \(error)")
        }
    }
    
    func testKeyGenerationUniqueness() {
        // Test that multiple key generations produce unique keys
        var publicKeys: Set<Data> = []
        var privateKeys: Set<Data> = []
        
        for _ in 0..<100 {
            do {
                let identity = try cryptoEngine.generateIdentity()
                
                XCTAssertFalse(publicKeys.contains(identity.x25519KeyPair.publicKey), 
                              "Duplicate X25519 public key generated")
                XCTAssertFalse(privateKeys.contains(identity.x25519KeyPair.privateKey),
                              "Duplicate X25519 private key generated")
                
                publicKeys.insert(identity.x25519KeyPair.publicKey)
                privateKeys.insert(identity.x25519KeyPair.privateKey)
                
            } catch {
                XCTFail("Key generation failed: \(error)")
            }
        }
        
        XCTAssertEqual(publicKeys.count, 100, "All public keys should be unique")
        XCTAssertEqual(privateKeys.count, 100, "All private keys should be unique")
    }
    
    // MARK: - Key Agreement Validation
    
    func testX25519KeyAgreement() {
        do {
            let alice = try cryptoEngine.generateIdentity()
            let bob = try cryptoEngine.generateIdentity()
            
            // Perform key agreement from both sides
            let alicePrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: alice.x25519KeyPair.privateKey)
            let bobPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: bob.x25519KeyPair.privateKey)
            let alicePublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: alice.x25519KeyPair.publicKey)
            let bobPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: bob.x25519KeyPair.publicKey)
            
            let sharedFromAlice = try alicePrivateKey.sharedSecretFromKeyAgreement(with: bobPublicKey)
            let sharedFromBob = try bobPrivateKey.sharedSecretFromKeyAgreement(with: alicePublicKey)
            
            // Shared secrets should be identical
            XCTAssertEqual(
                sharedFromAlice.withUnsafeBytes { Data($0) },
                sharedFromBob.withUnsafeBytes { Data($0) },
                "Shared secrets should match"
            )
            
            // Shared secret should not be all zeros
            let sharedData = sharedFromAlice.withUnsafeBytes { Data($0) }
            XCTAssertNotEqual(sharedData, Data(repeating: 0, count: sharedData.count))
            
        } catch {
            XCTFail("X25519 key agreement failed: \(error)")
        }
    }
    
    func testKeyAgreementDeterminism() {
        // Same keys should always produce same shared secret
        do {
            let alice = try cryptoEngine.generateIdentity()
            let bob = try cryptoEngine.generateIdentity()
            
            let alicePrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: alice.x25519KeyPair.privateKey)
            let bobPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: bob.x25519KeyPair.publicKey)
            
            let shared1 = try alicePrivateKey.sharedSecretFromKeyAgreement(with: bobPublicKey)
            let shared2 = try alicePrivateKey.sharedSecretFromKeyAgreement(with: bobPublicKey)
            
            XCTAssertEqual(
                shared1.withUnsafeBytes { Data($0) },
                shared2.withUnsafeBytes { Data($0) },
                "Key agreement should be deterministic"
            )
            
        } catch {
            XCTFail("Key agreement determinism test failed: \(error)")
        }
    }
    
    // MARK: - HKDF Validation
    
    func testHKDFKeyDerivation() {
        let sharedSecret = SymmetricKey(size: .bits256)
        let salt = Data(repeating: 0x42, count: 16)
        let info = "whisper-v1".data(using: .utf8)!
        
        do {
            let (encKey, nonce) = try cryptoEngine.deriveKeys(sharedSecret: sharedSecret, salt: salt, info: info)
            
            // Verify key lengths
            XCTAssertEqual(encKey.count, 32, "Encryption key should be 32 bytes")
            XCTAssertEqual(nonce.count, 12, "Nonce should be 12 bytes")
            
            // Verify keys are not all zeros
            XCTAssertNotEqual(encKey, Data(repeating: 0, count: 32))
            XCTAssertNotEqual(nonce, Data(repeating: 0, count: 12))
            
            // Verify keys are different
            XCTAssertNotEqual(encKey.prefix(12), nonce)
            
        } catch {
            XCTFail("HKDF key derivation failed: \(error)")
        }
    }
    
    func testHKDFDeterminism() {
        // Same inputs should produce same outputs
        let sharedSecret = SymmetricKey(size: .bits256)
        let salt = Data(repeating: 0x42, count: 16)
        let info = "whisper-v1".data(using: .utf8)!
        
        do {
            let (encKey1, nonce1) = try cryptoEngine.deriveKeys(sharedSecret: sharedSecret, salt: salt, info: info)
            let (encKey2, nonce2) = try cryptoEngine.deriveKeys(sharedSecret: sharedSecret, salt: salt, info: info)
            
            XCTAssertEqual(encKey1, encKey2, "HKDF should be deterministic for encryption key")
            XCTAssertEqual(nonce1, nonce2, "HKDF should be deterministic for nonce")
            
        } catch {
            XCTFail("HKDF determinism test failed: \(error)")
        }
    }
    
    func testHKDFSaltSensitivity() {
        // Different salts should produce different outputs
        let sharedSecret = SymmetricKey(size: .bits256)
        let salt1 = Data(repeating: 0x42, count: 16)
        let salt2 = Data(repeating: 0x43, count: 16)
        let info = "whisper-v1".data(using: .utf8)!
        
        do {
            let (encKey1, nonce1) = try cryptoEngine.deriveKeys(sharedSecret: sharedSecret, salt: salt1, info: info)
            let (encKey2, nonce2) = try cryptoEngine.deriveKeys(sharedSecret: sharedSecret, salt: salt2, info: info)
            
            XCTAssertNotEqual(encKey1, encKey2, "Different salts should produce different encryption keys")
            XCTAssertNotEqual(nonce1, nonce2, "Different salts should produce different nonces")
            
        } catch {
            XCTFail("HKDF salt sensitivity test failed: \(error)")
        }
    }
    
    // MARK: - ChaCha20-Poly1305 Validation
    
    func testChaCha20Poly1305Encryption() {
        let key = SymmetricKey(size: .bits256)
        let nonce = Data(repeating: 0x42, count: 12)
        let plaintext = "Hello, World!".data(using: .utf8)!
        let aad = "additional data".data(using: .utf8)!
        
        do {
            let ciphertext = try cryptoEngine.encrypt(plaintext: plaintext, key: key.withUnsafeBytes { Data($0) }, nonce: nonce, aad: aad)
            
            // Ciphertext should be different from plaintext
            XCTAssertNotEqual(ciphertext, plaintext)
            
            // Ciphertext should include authentication tag (16 bytes longer than plaintext)
            XCTAssertEqual(ciphertext.count, plaintext.count + 16, "Ciphertext should include 16-byte auth tag")
            
            // Decrypt and verify
            let decrypted = try cryptoEngine.decrypt(ciphertext: ciphertext, key: key.withUnsafeBytes { Data($0) }, nonce: nonce, aad: aad)
            XCTAssertEqual(decrypted, plaintext, "Decryption should recover original plaintext")
            
        } catch {
            XCTFail("ChaCha20-Poly1305 encryption failed: \(error)")
        }
    }
    
    func testChaCha20Poly1305AADValidation() {
        let key = SymmetricKey(size: .bits256)
        let nonce = Data(repeating: 0x42, count: 12)
        let plaintext = "Hello, World!".data(using: .utf8)!
        let aad1 = "additional data".data(using: .utf8)!
        let aad2 = "different data".data(using: .utf8)!
        
        do {
            let ciphertext = try cryptoEngine.encrypt(plaintext: plaintext, key: key.withUnsafeBytes { Data($0) }, nonce: nonce, aad: aad1)
            
            // Decryption with correct AAD should succeed
            let decrypted1 = try cryptoEngine.decrypt(ciphertext: ciphertext, key: key.withUnsafeBytes { Data($0) }, nonce: nonce, aad: aad1)
            XCTAssertEqual(decrypted1, plaintext)
            
            // Decryption with wrong AAD should fail
            XCTAssertThrowsError(try cryptoEngine.decrypt(ciphertext: ciphertext, key: key.withUnsafeBytes { Data($0) }, nonce: nonce, aad: aad2)) {
                // Should throw authentication failure
            }
            
        } catch {
            XCTFail("ChaCha20-Poly1305 AAD validation failed: \(error)")
        }
    }
    
    func testChaCha20Poly1305NonceUniqueness() {
        // Same key with different nonces should produce different ciphertexts
        let key = SymmetricKey(size: .bits256)
        let nonce1 = Data(repeating: 0x42, count: 12)
        let nonce2 = Data(repeating: 0x43, count: 12)
        let plaintext = "Hello, World!".data(using: .utf8)!
        let aad = Data()
        
        do {
            let ciphertext1 = try cryptoEngine.encrypt(plaintext: plaintext, key: key.withUnsafeBytes { Data($0) }, nonce: nonce1, aad: aad)
            let ciphertext2 = try cryptoEngine.encrypt(plaintext: plaintext, key: key.withUnsafeBytes { Data($0) }, nonce: nonce2, aad: aad)
            
            XCTAssertNotEqual(ciphertext1, ciphertext2, "Different nonces should produce different ciphertexts")
            
            // Both should decrypt correctly
            let decrypted1 = try cryptoEngine.decrypt(ciphertext: ciphertext1, key: key.withUnsafeBytes { Data($0) }, nonce: nonce1, aad: aad)
            let decrypted2 = try cryptoEngine.decrypt(ciphertext: ciphertext2, key: key.withUnsafeBytes { Data($0) }, nonce: nonce2, aad: aad)
            
            XCTAssertEqual(decrypted1, plaintext)
            XCTAssertEqual(decrypted2, plaintext)
            
        } catch {
            XCTFail("ChaCha20-Poly1305 nonce uniqueness test failed: \(error)")
        }
    }
    
    // MARK: - Ed25519 Signature Validation
    
    func testEd25519Signing() {
        do {
            let identity = try cryptoEngine.generateIdentity()
            guard let ed25519KeyPair = identity.ed25519KeyPair else {
                XCTFail("Ed25519 key pair should be generated")
                return
            }
            
            let message = "Test message for signing".data(using: .utf8)!
            let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: ed25519KeyPair.privateKey)
            
            let signature = try cryptoEngine.sign(data: message, privateKey: privateKey)
            
            // Signature should be 64 bytes
            XCTAssertEqual(signature.count, 64, "Ed25519 signature should be 64 bytes")
            
            // Signature should not be all zeros
            XCTAssertNotEqual(signature, Data(repeating: 0, count: 64))
            
            // Verify signature
            let isValid = try cryptoEngine.verify(signature: signature, data: message, publicKey: ed25519KeyPair.publicKey)
            XCTAssertTrue(isValid, "Signature should be valid")
            
        } catch {
            XCTFail("Ed25519 signing failed: \(error)")
        }
    }
    
    func testEd25519SignatureDeterminism() {
        // Ed25519 signatures should be deterministic (same message, same key = same signature)
        do {
            let identity = try cryptoEngine.generateIdentity()
            guard let ed25519KeyPair = identity.ed25519KeyPair else {
                XCTFail("Ed25519 key pair should be generated")
                return
            }
            
            let message = "Test message".data(using: .utf8)!
            let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: ed25519KeyPair.privateKey)
            
            let signature1 = try cryptoEngine.sign(data: message, privateKey: privateKey)
            let signature2 = try cryptoEngine.sign(data: message, privateKey: privateKey)
            
            XCTAssertEqual(signature1, signature2, "Ed25519 signatures should be deterministic")
            
        } catch {
            XCTFail("Ed25519 signature determinism test failed: \(error)")
        }
    }
    
    func testEd25519SignatureValidation() {
        do {
            let identity = try cryptoEngine.generateIdentity()
            guard let ed25519KeyPair = identity.ed25519KeyPair else {
                XCTFail("Ed25519 key pair should be generated")
                return
            }
            
            let message = "Test message".data(using: .utf8)!
            let wrongMessage = "Wrong message".data(using: .utf8)!
            let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: ed25519KeyPair.privateKey)
            
            let signature = try cryptoEngine.sign(data: message, privateKey: privateKey)
            
            // Valid signature should verify
            let isValid = try cryptoEngine.verify(signature: signature, data: message, publicKey: ed25519KeyPair.publicKey)
            XCTAssertTrue(isValid, "Valid signature should verify")
            
            // Wrong message should not verify
            let isInvalid = try cryptoEngine.verify(signature: signature, data: wrongMessage, publicKey: ed25519KeyPair.publicKey)
            XCTAssertFalse(isInvalid, "Signature should not verify for wrong message")
            
            // Corrupted signature should not verify
            var corruptedSignature = signature
            corruptedSignature[0] ^= 0x01
            let isCorrupted = try cryptoEngine.verify(signature: corruptedSignature, data: message, publicKey: ed25519KeyPair.publicKey)
            XCTAssertFalse(isCorrupted, "Corrupted signature should not verify")
            
        } catch {
            XCTFail("Ed25519 signature validation failed: \(error)")
        }
    }
}