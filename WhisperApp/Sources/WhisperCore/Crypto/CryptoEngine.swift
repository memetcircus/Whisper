import Foundation
import CryptoKit

/// Protocol defining the core cryptographic operations for Whisper
/// All operations use CryptoKit exclusively for security and compliance
protocol CryptoEngine {
    /// Generates a new cryptographic identity with X25519 and Ed25519 key pairs
    /// - Returns: A new Identity with fresh key pairs
    /// - Throws: CryptoError if key generation fails
    func generateIdentity() throws -> Identity
    
    /// Generates an ephemeral X25519 key pair for message encryption
    /// - Returns: Tuple containing the private key and public key data
    /// - Throws: CryptoError if key generation fails
    func generateEphemeralKeyPair() throws -> (privateKey: Curve25519.KeyAgreement.PrivateKey, publicKey: Data)
    
    /// Performs X25519 ECDH key agreement between ephemeral private key and recipient public key
    /// - Parameters:
    ///   - ephemeralPrivate: Ephemeral private key for this message
    ///   - recipientPublic: Recipient's X25519 public key
    /// - Returns: Shared secret from ECDH
    /// - Throws: CryptoError if key agreement fails
    func performKeyAgreement(ephemeralPrivate: Curve25519.KeyAgreement.PrivateKey, 
                           recipientPublic: Data) throws -> SharedSecret
    
    /// Derives encryption key and nonce using HKDF-SHA256 with context binding
    /// - Parameters:
    ///   - sharedSecret: Shared secret from ECDH
    ///   - salt: 16-byte random salt
    ///   - info: Context binding information including epk and msgid
    /// - Returns: Tuple containing 32-byte encryption key and 12-byte nonce
    /// - Throws: CryptoError if key derivation fails
    func deriveKeys(sharedSecret: SharedSecret, salt: Data, info: Data) throws -> (encKey: Data, nonce: Data)
    
    /// Encrypts plaintext using ChaCha20-Poly1305 AEAD with proper AAD
    /// - Parameters:
    ///   - plaintext: Data to encrypt
    ///   - key: 32-byte encryption key
    ///   - nonce: 12-byte nonce
    ///   - aad: Additional authenticated data (canonical header)
    /// - Returns: Encrypted ciphertext with authentication tag
    /// - Throws: CryptoError if encryption fails
    func encrypt(plaintext: Data, key: Data, nonce: Data, aad: Data) throws -> Data
    
    /// Decrypts ciphertext using ChaCha20-Poly1305 AEAD with AAD verification
    /// - Parameters:
    ///   - ciphertext: Encrypted data with authentication tag
    ///   - key: 32-byte encryption key
    ///   - nonce: 12-byte nonce
    ///   - aad: Additional authenticated data for verification
    /// - Returns: Decrypted plaintext
    /// - Throws: CryptoError if decryption or authentication fails
    func decrypt(ciphertext: Data, key: Data, nonce: Data, aad: Data) throws -> Data
    
    /// Signs data using Ed25519 for message authentication
    /// - Parameters:
    ///   - data: Data to sign
    ///   - privateKey: Ed25519 private key
    /// - Returns: 64-byte signature
    /// - Throws: CryptoError if signing fails
    func sign(data: Data, privateKey: Curve25519.Signing.PrivateKey) throws -> Data
    
    /// Verifies Ed25519 signature for message authentication
    /// - Parameters:
    ///   - signature: 64-byte signature to verify
    ///   - data: Original data that was signed
    ///   - publicKey: Ed25519 public key for verification
    /// - Returns: True if signature is valid, false otherwise
    /// - Throws: CryptoError if verification process fails
    func verify(signature: Data, data: Data, publicKey: Data) throws -> Bool
    
    /// Generates cryptographically secure random data
    /// - Parameter length: Number of bytes to generate
    /// - Returns: Random data of specified length
    /// - Throws: CryptoError if random generation fails
    func generateSecureRandom(length: Int) throws -> Data
    
    /// Securely zeroizes ephemeral private key from memory
    /// - Parameter privateKey: Ephemeral private key to zeroize
    func zeroizeEphemeralKey(_ privateKey: inout Curve25519.KeyAgreement.PrivateKey?)
    
    /// Generates recipient key ID (rkid) from X25519 public key
    /// Uses SHA-256 fallback since BLAKE2s is not available in CryptoKit
    /// - Parameter x25519PublicKey: X25519 public key data
    /// - Returns: 8-byte recipient key ID (lower 8 bytes of hash)
    func generateRecipientKeyId(x25519PublicKey: Data) -> Data
}

/// Concrete implementation of CryptoEngine using CryptoKit exclusively
/// Implements all cryptographic operations required by the Whisper protocol
class CryptoKitEngine: CryptoEngine {
    
    // MARK: - Identity Generation
    
    func generateIdentity() throws -> Identity {
        // Generate X25519 key pair for key agreement
        let x25519PrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let x25519PublicKey = x25519PrivateKey.publicKey.rawRepresentation
        
        // Generate Ed25519 key pair for signing
        let ed25519PrivateKey = Curve25519.Signing.PrivateKey()
        let ed25519PublicKey = ed25519PrivateKey.publicKey.rawRepresentation
        
        // Create identity with generated keys
        let identity = Identity(
            id: UUID(),
            name: "Generated Identity",
            x25519KeyPair: X25519KeyPair(
                privateKey: x25519PrivateKey,
                publicKey: x25519PublicKey
            ),
            ed25519KeyPair: Ed25519KeyPair(
                privateKey: ed25519PrivateKey,
                publicKey: ed25519PublicKey
            ),
            fingerprint: generateFingerprint(x25519PublicKey: x25519PublicKey, 
                                           ed25519PublicKey: ed25519PublicKey),
            createdAt: Date(),
            status: .active,
            keyVersion: 1
        )
        
        return identity
    }
    
    // MARK: - Ephemeral Key Management
    
    func generateEphemeralKeyPair() throws -> (privateKey: Curve25519.KeyAgreement.PrivateKey, publicKey: Data) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey.rawRepresentation
        return (privateKey, publicKey)
    }
    
    func zeroizeEphemeralKey(_ privateKey: inout Curve25519.KeyAgreement.PrivateKey?) {
        // CryptoKit handles secure memory management internally
        // Setting to nil ensures the key is deallocated
        privateKey = nil
    }
    
    // MARK: - Key Agreement and Derivation
    
    func performKeyAgreement(ephemeralPrivate: Curve25519.KeyAgreement.PrivateKey, 
                           recipientPublic: Data) throws -> SharedSecret {
        do {
            let recipientPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientPublic)
            return try ephemeralPrivate.sharedSecretFromKeyAgreement(with: recipientPublicKey)
        } catch {
            throw CryptoError.keyAgreementFailure(error)
        }
    }
    
    func deriveKeys(sharedSecret: SharedSecret, salt: Data, info: Data) throws -> (encKey: Data, nonce: Data) {
        // Derive encryption key using HKDF with "key" label
        let keyInfo = "key".data(using: .utf8)! + info
        let encKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: salt,
            sharedInfo: keyInfo,
            outputByteCount: 32
        )
        
        // Derive nonce using HKDF with "nonce" label
        let nonceInfo = "nonce".data(using: .utf8)! + info
        let nonceKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: salt,
            sharedInfo: nonceInfo,
            outputByteCount: 12
        )
        
        return (encKey.withUnsafeBytes { Data($0) }, 
                nonceKey.withUnsafeBytes { Data($0) })
    }
    
    // MARK: - AEAD Encryption/Decryption
    
    func encrypt(plaintext: Data, key: Data, nonce: Data, aad: Data) throws -> Data {
        do {
            guard key.count == 32 else {
                throw CryptoError.invalidKeySize
            }
            guard nonce.count == 12 else {
                throw CryptoError.invalidNonceSize
            }
            
            let symmetricKey = SymmetricKey(data: key)
            let chachaNonce = try ChaChaPoly.Nonce(data: nonce)
            
            let sealedBox = try ChaChaPoly.seal(
                plaintext,
                using: symmetricKey,
                nonce: chachaNonce,
                authenticating: aad
            )
            
            return sealedBox.combined
        } catch {
            throw CryptoError.encryptionFailure(error)
        }
    }
    
    func decrypt(ciphertext: Data, key: Data, nonce: Data, aad: Data) throws -> Data {
        do {
            guard key.count == 32 else {
                throw CryptoError.invalidKeySize
            }
            guard nonce.count == 12 else {
                throw CryptoError.invalidNonceSize
            }
            
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try ChaChaPoly.SealedBox(combined: ciphertext)
            
            return try ChaChaPoly.open(sealedBox, using: symmetricKey, authenticating: aad)
        } catch {
            throw CryptoError.decryptionFailure(error)
        }
    }
    
    // MARK: - Digital Signatures
    
    func sign(data: Data, privateKey: Curve25519.Signing.PrivateKey) throws -> Data {
        do {
            return try privateKey.signature(for: data)
        } catch {
            throw CryptoError.signingFailure(error)
        }
    }
    
    func verify(signature: Data, data: Data, publicKey: Data) throws -> Bool {
        do {
            let signingPublicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
            return signingPublicKey.isValidSignature(signature, for: data)
        } catch {
            throw CryptoError.verificationFailure(error)
        }
    }
    
    // MARK: - Secure Random Generation
    
    func generateSecureRandom(length: Int) throws -> Data {
        guard length > 0 else {
            throw CryptoError.invalidRandomLength
        }
        
        var randomData = Data(count: length)
        let result = randomData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw CryptoError.randomGenerationFailure(result)
        }
        
        return randomData
    }
    
    // MARK: - Helper Methods
    
    /// Generates a fingerprint for an identity using SHA-256 (BLAKE2s fallback)
    /// - Parameters:
    ///   - x25519PublicKey: X25519 public key data
    ///   - ed25519PublicKey: Ed25519 public key data
    /// - Returns: 32-byte fingerprint
    private func generateFingerprint(x25519PublicKey: Data, ed25519PublicKey: Data) -> Data {
        // Combine both public keys for fingerprint
        let combinedKeys = x25519PublicKey + ed25519PublicKey
        
        // Use SHA-256 as BLAKE2s is not available in CryptoKit
        let hash = SHA256.hash(data: combinedKeys)
        return Data(hash)
    }
    
    /// Generates recipient key ID (rkid) from X25519 public key
    /// Uses SHA-256 fallback since BLAKE2s is not available in CryptoKit
    /// - Parameter x25519PublicKey: X25519 public key data
    /// - Returns: 8-byte recipient key ID (lower 8 bytes of hash)
    func generateRecipientKeyId(x25519PublicKey: Data) -> Data {
        let hash = SHA256.hash(data: x25519PublicKey)
        return Data(hash.suffix(8)) // Take lower 8 bytes
    }
}

// MARK: - Supporting Types

/// Represents an X25519 key pair for key agreement
struct X25519KeyPair {
    let privateKey: Curve25519.KeyAgreement.PrivateKey
    let publicKey: Data
}

/// Represents an Ed25519 key pair for signing
struct Ed25519KeyPair {
    let privateKey: Curve25519.Signing.PrivateKey
    let publicKey: Data
}

/// Represents a cryptographic identity with key pairs and metadata
struct Identity: Identifiable, Hashable {
    let id: UUID
    let name: String
    let x25519KeyPair: X25519KeyPair
    let ed25519KeyPair: Ed25519KeyPair?
    let fingerprint: Data
    let createdAt: Date
    let status: IdentityStatus
    let keyVersion: Int
    
    /// Short fingerprint for display (Base32 Crockford, 12 chars)
    var shortFingerprint: String {
        let base32 = fingerprint.base32CrockfordEncoded()
        return String(base32.prefix(12))
    }
    
    // MARK: - Hashable Conformance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(fingerprint)
    }
}

/// Status of a cryptographic identity
enum IdentityStatus: String, CaseIterable {
    case active = "active"
    case archived = "archived"
    case rotated = "rotated"
}

// MARK: - Error Types

/// Errors that can occur during cryptographic operations
enum CryptoError: Error, LocalizedError {
    case keyGenerationFailure(Error)
    case keyAgreementFailure(Error)
    case keyDerivationFailure(Error)
    case encryptionFailure(Error)
    case decryptionFailure(Error)
    case signingFailure(Error)
    case verificationFailure(Error)
    case randomGenerationFailure(OSStatus)
    case invalidKeySize
    case invalidNonceSize
    case invalidRandomLength
    
    var errorDescription: String? {
        switch self {
        case .keyGenerationFailure(let error):
            return "Key generation failed: \(error.localizedDescription)"
        case .keyAgreementFailure(let error):
            return "Key agreement failed: \(error.localizedDescription)"
        case .keyDerivationFailure(let error):
            return "Key derivation failed: \(error.localizedDescription)"
        case .encryptionFailure(let error):
            return "Encryption failed: \(error.localizedDescription)"
        case .decryptionFailure(let error):
            return "Decryption failed: \(error.localizedDescription)"
        case .signingFailure(let error):
            return "Signing failed: \(error.localizedDescription)"
        case .verificationFailure(let error):
            return "Signature verification failed: \(error.localizedDescription)"
        case .randomGenerationFailure(let status):
            return "Random generation failed with status: \(status)"
        case .invalidKeySize:
            return "Invalid key size"
        case .invalidNonceSize:
            return "Invalid nonce size"
        case .invalidRandomLength:
            return "Invalid random data length"
        }
    }
}