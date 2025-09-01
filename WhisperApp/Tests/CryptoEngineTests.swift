import XCTest
import CryptoKit
@testable import WhisperApp

/// Comprehensive tests for the CryptoEngine implementation
/// Verifies all cryptographic operations meet security requirements
class CryptoEngineTests: XCTestCase {
    
    var cryptoEngine: CryptoEngine!
    
    override func setUp() {
        super.setUp()
        cryptoEngine = CryptoKitEngine()
    }
    
    override func tearDown() {
        cryptoEngine = nil
        super.tearDown()
    }
    
    // MARK: - Identity Generation Tests
    
    func testGenerateIdentity() throws {
        let identity = try cryptoEngine.generateIdentity()
        
        // Verify identity has required components
        XCTAssertNotNil(identity.id)
        XCTAssertFalse(identity.name.isEmpty)
        XCTAssertEqual(identity.x25519KeyPair.publicKey.count, 32)
        XCTAssertEqual(identity.ed25519KeyPair?.publicKey.count, 32)
        XCTAssertEqual(identity.fingerprint.count, 32)
        XCTAssertEqual(identity.status, .active)
        XCTAssertEqual(identity.keyVersion, 1)
    }
    
    func testIdentityUniqueness() throws {
        let identity1 = try cryptoEngine.generateIdentity()
        let identity2 = try cryptoEngine.generateIdentity()
        
        // Verify identities are unique
        XCTAssertNotEqual(identity1.id, identity2.id)
        XCTAssertNotEqual(identity1.x25519KeyPair.publicKey, identity2.x25519KeyPair.publicKey)
        XCTAssertNotEqual(identity1.ed25519KeyPair?.publicKey, identity2.ed25519KeyPair?.publicKey)
        XCTAssertNotEqual(identity1.fingerprint, identity2.fingerprint)
    }
    
    // MARK: - Ephemeral Key Tests
    
    func testGenerateEphemeralKeyPair() throws {
        let (privateKey, publicKey) = try cryptoEngine.generateEphemeralKeyPair()
        
        // Verify key pair properties
        XCTAssertEqual(publicKey.count, 32)
        XCTAssertEqual(privateKey.publicKey.rawRepresentation, publicKey)
    }
    
    func testEphemeralKeyUniqueness() throws {
        let (_, publicKey1) = try cryptoEngine.generateEphemeralKeyPair()
        let (_, publicKey2) = try cryptoEngine.generateEphemeralKeyPair()
        
        // Verify ephemeral keys are unique
        XCTAssertNotEqual(publicKey1, publicKey2)
    }
    
    func testZeroizeEphemeralKey() throws {
        var (privateKey, _) = try cryptoEngine.generateEphemeralKeyPair()
        var optionalKey: Curve25519.KeyAgreement.PrivateKey? = privateKey
        
        cryptoEngine.zeroizeEphemeralKey(&optionalKey)
        
        // Verify key is zeroized
        XCTAssertNil(optionalKey)
    }
    
    // MARK: - Key Agreement Tests
    
    func testKeyAgreement() throws {
        // Generate two key pairs
        let (alicePrivate, _) = try cryptoEngine.generateEphemeralKeyPair()
        let (bobPrivate, bobPublic) = try cryptoEngine.generateEphemeralKeyPair()
        
        // Perform key agreement from Alice's side
        let sharedSecret1 = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: alicePrivate,
            recipientPublic: bobPublic
        )
        
        // Perform key agreement from Bob's side
        let sharedSecret2 = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: bobPrivate,
            recipientPublic: alicePrivate.publicKey.rawRepresentation
        )
        
        // Verify shared secrets match
        XCTAssertEqual(
            sharedSecret1.withUnsafeBytes { Data($0) },
            sharedSecret2.withUnsafeBytes { Data($0) }
        )
    }
    
    func testKeyAgreementWithInvalidPublicKey() {
        let (privateKey, _) = try! cryptoEngine.generateEphemeralKeyPair()
        let invalidPublicKey = Data(repeating: 0, count: 32)
        
        XCTAssertThrowsError(try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: privateKey,
            recipientPublic: invalidPublicKey
        )) { error in
            XCTAssertTrue(error is CryptoError)
        }
    }
    
    // MARK: - Key Derivation Tests
    
    func testKeyDerivation() throws {
        let (privateKey, publicKey) = try cryptoEngine.generateEphemeralKeyPair()
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: privateKey,
            recipientPublic: publicKey
        )
        
        let salt = try cryptoEngine.generateSecureRandom(length: 16)
        let info = "whisper-v1".data(using: .utf8)!
        
        let (encKey, nonce) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: salt,
            info: info
        )
        
        // Verify derived key sizes
        XCTAssertEqual(encKey.count, 32)
        XCTAssertEqual(nonce.count, 12)
    }
    
    func testKeyDerivationDeterminism() throws {
        let (privateKey, publicKey) = try cryptoEngine.generateEphemeralKeyPair()
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: privateKey,
            recipientPublic: publicKey
        )
        
        let salt = Data(repeating: 0x42, count: 16)
        let info = "test-info".data(using: .utf8)!
        
        // Derive keys twice with same inputs
        let (encKey1, nonce1) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: salt,
            info: info
        )
        
        let (encKey2, nonce2) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: salt,
            info: info
        )
        
        // Verify deterministic results
        XCTAssertEqual(encKey1, encKey2)
        XCTAssertEqual(nonce1, nonce2)
    }
    
    func testKeyDerivationWithDifferentLabels() throws {
        let (privateKey, publicKey) = try cryptoEngine.generateEphemeralKeyPair()
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: privateKey,
            recipientPublic: publicKey
        )
        
        let salt = Data(repeating: 0x42, count: 16)
        let info = "test-info".data(using: .utf8)!
        
        let (encKey, nonce) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: salt,
            info: info
        )
        
        // Verify key and nonce are different (due to different HKDF labels)
        XCTAssertNotEqual(encKey.prefix(12), nonce)
    }
    
    // MARK: - AEAD Encryption/Decryption Tests
    
    func testEncryptDecryptRoundTrip() throws {
        let plaintext = "Hello, Whisper!".data(using: .utf8)!
        let key = try cryptoEngine.generateSecureRandom(length: 32)
        let nonce = try cryptoEngine.generateSecureRandom(length: 12)
        let aad = "additional-data".data(using: .utf8)!
        
        // Encrypt
        let ciphertext = try cryptoEngine.encrypt(
            plaintext: plaintext,
            key: key,
            nonce: nonce,
            aad: aad
        )
        
        // Decrypt
        let decrypted = try cryptoEngine.decrypt(
            ciphertext: ciphertext,
            key: key,
            nonce: nonce,
            aad: aad
        )
        
        // Verify round trip
        XCTAssertEqual(plaintext, decrypted)
    }
    
    func testEncryptionWithDifferentAAD() throws {
        let plaintext = "Test message".data(using: .utf8)!
        let key = try cryptoEngine.generateSecureRandom(length: 32)
        let nonce = try cryptoEngine.generateSecureRandom(length: 12)
        let aad1 = "aad1".data(using: .utf8)!
        let aad2 = "aad2".data(using: .utf8)!
        
        // Encrypt with first AAD
        let ciphertext = try cryptoEngine.encrypt(
            plaintext: plaintext,
            key: key,
            nonce: nonce,
            aad: aad1
        )
        
        // Try to decrypt with different AAD (should fail)
        XCTAssertThrowsError(try cryptoEngine.decrypt(
            ciphertext: ciphertext,
            key: key,
            nonce: nonce,
            aad: aad2
        )) { error in
            XCTAssertTrue(error is CryptoError)
        }
    }
    
    func testEncryptionWithInvalidKeySize() {
        let plaintext = "Test".data(using: .utf8)!
        let invalidKey = Data(repeating: 0, count: 16) // Wrong size
        let nonce = Data(repeating: 0, count: 12)
        let aad = Data()
        
        XCTAssertThrowsError(try cryptoEngine.encrypt(
            plaintext: plaintext,
            key: invalidKey,
            nonce: nonce,
            aad: aad
        )) { error in
            if case CryptoError.invalidKeySize = error {
                // Expected error
            } else {
                XCTFail("Expected invalidKeySize error")
            }
        }
    }
    
    func testEncryptionWithInvalidNonceSize() {
        let plaintext = "Test".data(using: .utf8)!
        let key = Data(repeating: 0, count: 32)
        let invalidNonce = Data(repeating: 0, count: 8) // Wrong size
        let aad = Data()
        
        XCTAssertThrowsError(try cryptoEngine.encrypt(
            plaintext: plaintext,
            key: key,
            nonce: invalidNonce,
            aad: aad
        )) { error in
            if case CryptoError.invalidNonceSize = error {
                // Expected error
            } else {
                XCTFail("Expected invalidNonceSize error")
            }
        }
    }
    
    // MARK: - Digital Signature Tests
    
    func testSignAndVerify() throws {
        let identity = try cryptoEngine.generateIdentity()
        let data = "Message to sign".data(using: .utf8)!
        
        guard let ed25519KeyPair = identity.ed25519KeyPair else {
            XCTFail("Identity should have Ed25519 key pair")
            return
        }
        
        // Sign data
        let signature = try cryptoEngine.sign(data: data, privateKey: ed25519KeyPair.privateKey)
        
        // Verify signature
        let isValid = try cryptoEngine.verify(
            signature: signature,
            data: data,
            publicKey: ed25519KeyPair.publicKey
        )
        
        XCTAssertTrue(isValid)
        XCTAssertEqual(signature.count, 64) // Ed25519 signature size
    }
    
    func testVerifyWithWrongData() throws {
        let identity = try cryptoEngine.generateIdentity()
        let originalData = "Original message".data(using: .utf8)!
        let tamperedData = "Tampered message".data(using: .utf8)!
        
        guard let ed25519KeyPair = identity.ed25519KeyPair else {
            XCTFail("Identity should have Ed25519 key pair")
            return
        }
        
        // Sign original data
        let signature = try cryptoEngine.sign(data: originalData, privateKey: ed25519KeyPair.privateKey)
        
        // Try to verify with tampered data
        let isValid = try cryptoEngine.verify(
            signature: signature,
            data: tamperedData,
            publicKey: ed25519KeyPair.publicKey
        )
        
        XCTAssertFalse(isValid)
    }
    
    func testVerifyWithWrongPublicKey() throws {
        let identity1 = try cryptoEngine.generateIdentity()
        let identity2 = try cryptoEngine.generateIdentity()
        let data = "Message to sign".data(using: .utf8)!
        
        guard let keyPair1 = identity1.ed25519KeyPair,
              let keyPair2 = identity2.ed25519KeyPair else {
            XCTFail("Identities should have Ed25519 key pairs")
            return
        }
        
        // Sign with identity1's key
        let signature = try cryptoEngine.sign(data: data, privateKey: keyPair1.privateKey)
        
        // Try to verify with identity2's public key
        let isValid = try cryptoEngine.verify(
            signature: signature,
            data: data,
            publicKey: keyPair2.publicKey
        )
        
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Secure Random Generation Tests
    
    func testGenerateSecureRandom() throws {
        let randomData1 = try cryptoEngine.generateSecureRandom(length: 32)
        let randomData2 = try cryptoEngine.generateSecureRandom(length: 32)
        
        // Verify properties
        XCTAssertEqual(randomData1.count, 32)
        XCTAssertEqual(randomData2.count, 32)
        XCTAssertNotEqual(randomData1, randomData2) // Should be different
    }
    
    func testGenerateSecureRandomWithDifferentLengths() throws {
        let lengths = [1, 16, 32, 64, 128]
        
        for length in lengths {
            let randomData = try cryptoEngine.generateSecureRandom(length: length)
            XCTAssertEqual(randomData.count, length)
        }
    }
    
    func testGenerateSecureRandomWithInvalidLength() {
        XCTAssertThrowsError(try cryptoEngine.generateSecureRandom(length: 0)) { error in
            if case CryptoError.invalidRandomLength = error {
                // Expected error
            } else {
                XCTFail("Expected invalidRandomLength error")
            }
        }
        
        XCTAssertThrowsError(try cryptoEngine.generateSecureRandom(length: -1)) { error in
            if case CryptoError.invalidRandomLength = error {
                // Expected error
            } else {
                XCTFail("Expected invalidRandomLength error")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullEncryptionFlow() throws {
        // Generate sender and recipient identities
        let sender = try cryptoEngine.generateIdentity()
        let recipient = try cryptoEngine.generateIdentity()
        
        // Generate ephemeral key pair
        let (ephemeralPrivate, ephemeralPublic) = try cryptoEngine.generateEphemeralKeyPair()
        
        // Perform key agreement
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: ephemeralPrivate,
            recipientPublic: recipient.x25519KeyPair.publicKey
        )
        
        // Generate salt and message ID
        let salt = try cryptoEngine.generateSecureRandom(length: 16)
        let msgId = try cryptoEngine.generateSecureRandom(length: 16)
        
        // Create context info with ephemeral public key and message ID
        let info = ephemeralPublic + msgId
        
        // Derive keys
        let (encKey, nonce) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: salt,
            info: info
        )
        
        // Prepare message and AAD
        let plaintext = "Secret message for integration test".data(using: .utf8)!
        let aad = "canonical-header-data".data(using: .utf8)!
        
        // Encrypt
        let ciphertext = try cryptoEngine.encrypt(
            plaintext: plaintext,
            key: encKey,
            nonce: nonce,
            aad: aad
        )
        
        // Sign the message (optional)
        guard let senderKeyPair = sender.ed25519KeyPair else {
            XCTFail("Sender should have Ed25519 key pair")
            return
        }
        
        let signature = try cryptoEngine.sign(data: ciphertext + aad, privateKey: senderKeyPair.privateKey)
        
        // Verify signature
        let signatureValid = try cryptoEngine.verify(
            signature: signature,
            data: ciphertext + aad,
            publicKey: senderKeyPair.publicKey
        )
        XCTAssertTrue(signatureValid)
        
        // Decrypt
        let decrypted = try cryptoEngine.decrypt(
            ciphertext: ciphertext,
            key: encKey,
            nonce: nonce,
            aad: aad
        )
        
        // Verify round trip
        XCTAssertEqual(plaintext, decrypted)
        
        // Clean up ephemeral key
        var ephemeralKey: Curve25519.KeyAgreement.PrivateKey? = ephemeralPrivate
        cryptoEngine.zeroizeEphemeralKey(&ephemeralKey)
        XCTAssertNil(ephemeralKey)
    }
    
    // MARK: - Security Tests
    
    func testNonceUniqueness() throws {
        let (privateKey, publicKey) = try cryptoEngine.generateEphemeralKeyPair()
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: privateKey,
            recipientPublic: publicKey
        )
        
        var nonces: Set<Data> = []
        let iterations = 1000
        
        for _ in 0..<iterations {
            let salt = try cryptoEngine.generateSecureRandom(length: 16)
            let info = try cryptoEngine.generateSecureRandom(length: 32)
            
            let (_, nonce) = try cryptoEngine.deriveKeys(
                sharedSecret: sharedSecret,
                salt: salt,
                info: info
            )
            
            XCTAssertFalse(nonces.contains(nonce), "Nonce collision detected")
            nonces.insert(nonce)
        }
        
        XCTAssertEqual(nonces.count, iterations)
    }
    
    func testEncryptionDeterminism() throws {
        // Same plaintext with different ephemeral keys should produce different ciphertexts
        let plaintext = "Test message for determinism".data(using: .utf8)!
        let recipient = try cryptoEngine.generateIdentity()
        
        // First encryption
        let (ephemeral1, _) = try cryptoEngine.generateEphemeralKeyPair()
        let sharedSecret1 = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: ephemeral1,
            recipientPublic: recipient.x25519KeyPair.publicKey
        )
        let salt1 = try cryptoEngine.generateSecureRandom(length: 16)
        let info1 = try cryptoEngine.generateSecureRandom(length: 32)
        let (key1, nonce1) = try cryptoEngine.deriveKeys(sharedSecret: sharedSecret1, salt: salt1, info: info1)
        let ciphertext1 = try cryptoEngine.encrypt(plaintext: plaintext, key: key1, nonce: nonce1, aad: Data())
        
        // Second encryption
        let (ephemeral2, _) = try cryptoEngine.generateEphemeralKeyPair()
        let sharedSecret2 = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: ephemeral2,
            recipientPublic: recipient.x25519KeyPair.publicKey
        )
        let salt2 = try cryptoEngine.generateSecureRandom(length: 16)
        let info2 = try cryptoEngine.generateSecureRandom(length: 32)
        let (key2, nonce2) = try cryptoEngine.deriveKeys(sharedSecret: sharedSecret2, salt: salt2, info: info2)
        let ciphertext2 = try cryptoEngine.encrypt(plaintext: plaintext, key: key2, nonce: nonce2, aad: Data())
        
        // Verify different ciphertexts for same plaintext
        XCTAssertNotEqual(ciphertext1, ciphertext2)
    }
}