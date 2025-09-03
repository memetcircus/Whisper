import Foundation
import CryptoKit

/// Protocol defining envelope processing operations for Whisper messages
/// Handles the whisper1: format parsing, generation, and validation
protocol EnvelopeProcessor {
    /// Creates a whisper1: envelope from plaintext and cryptographic parameters
    /// - Parameters:
    ///   - plaintext: Message data to encrypt
    ///   - senderIdentity: Sender's cryptographic identity
    ///   - recipientPublic: Recipient's X25519 public key
    ///   - requireSignature: Whether to include Ed25519 signature
    /// - Returns: Complete whisper1: envelope string
    /// - Throws: EnvelopeError if envelope creation fails
    func createEnvelope(plaintext: Data,
                       senderIdentity: Identity,
                       recipientPublic: Data,
                       requireSignature: Bool) throws -> String
    
    /// Parses a whisper1: envelope string into its components
    /// - Parameter envelope: Complete whisper1: envelope string
    /// - Returns: Parsed envelope components
    /// - Throws: EnvelopeError if parsing fails or format is invalid
    func parseEnvelope(_ envelope: String) throws -> EnvelopeComponents
    
    /// Validates envelope components for correctness and security
    /// - Parameter components: Parsed envelope components
    /// - Returns: True if envelope is valid
    /// - Throws: EnvelopeError if validation fails
    func validateEnvelope(_ components: EnvelopeComponents) throws -> Bool
    
    /// Builds canonical context for AAD and HKDF info binding
    /// - Parameters:
    ///   - appId: Application identifier ("whisper")
    ///   - version: Protocol version ("v1")
    ///   - senderFingerprint: Sender's 32-byte fingerprint
    ///   - recipientFingerprint: Recipient's 32-byte fingerprint
    ///   - policyFlags: Security policy flags
    ///   - rkid: 8-byte recipient key ID
    ///   - epk: 32-byte ephemeral public key
    ///   - salt: 16-byte random salt
    ///   - msgid: 16-byte message ID
    ///   - ts: Unix timestamp
    /// - Returns: Canonical context bytes for cryptographic binding
    func buildCanonicalContext(appId: String,
                              version: String,
                              senderFingerprint: Data,
                              recipientFingerprint: Data,
                              policyFlags: UInt32,
                              rkid: Data,
                              epk: Data,
                              salt: Data,
                              msgid: Data,
                              ts: Int64) -> Data
}

/// Represents the parsed components of a whisper1: envelope
struct EnvelopeComponents {
    let version: String          // "v1.c20p"
    let rkid: Data              // 8-byte recipient key ID
    let flags: UInt8            // Flags byte (bit0 = signature present)
    let epk: Data               // 32-byte ephemeral public key
    let salt: Data              // 16-byte random salt
    let msgid: Data             // 16-byte message ID
    let timestamp: Int64        // Unix timestamp
    let ciphertext: Data        // Encrypted message
    let signature: Data?        // Optional 64-byte Ed25519 signature
    
    /// Whether this envelope includes a signature
    var hasSignature: Bool {
        return (flags & 0x01) != 0
    }
}

/// Concrete implementation of EnvelopeProcessor
/// Handles all envelope operations according to Whisper protocol specification
class WhisperEnvelopeProcessor: EnvelopeProcessor {
    
    private let cryptoEngine: CryptoEngine
    private let base64URLEncoder = Base64URLEncoder()
    
    init(cryptoEngine: CryptoEngine) {
        self.cryptoEngine = cryptoEngine
    }
    
    // MARK: - Envelope Creation
    
    func createEnvelope(plaintext: Data,
                       senderIdentity: Identity,
                       recipientPublic: Data,
                       requireSignature: Bool) throws -> String {
        
        // Generate ephemeral key pair for this message
        let (ephemeralPrivate, ephemeralPublic) = try cryptoEngine.generateEphemeralKeyPair()
        var ephemeralPrivateKey: Curve25519.KeyAgreement.PrivateKey? = ephemeralPrivate
        
        defer {
            // Zeroize ephemeral private key after use
            cryptoEngine.zeroizeEphemeralKey(&ephemeralPrivateKey)
        }
        
        // Generate random salt and message ID
        let salt = try cryptoEngine.generateSecureRandom(length: 16)
        let msgid = try cryptoEngine.generateSecureRandom(length: 16)
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        // Generate recipient key ID
        let rkid = cryptoEngine.generateRecipientKeyId(x25519PublicKey: recipientPublic)
        
        // Set flags
        var flags: UInt8 = 0
        if requireSignature {
            flags |= 0x01 // Set bit 0 for signature presence
        }
        
        // Build canonical context for cryptographic binding
        let canonicalContext = buildCanonicalContext(
            appId: "whisper",
            version: "v1",
            senderFingerprint: senderIdentity.fingerprint,
            recipientFingerprint: generateRecipientFingerprint(recipientPublic),
            policyFlags: UInt32(flags),
            rkid: rkid,
            epk: ephemeralPublic,
            salt: salt,
            msgid: msgid,
            ts: timestamp
        )
        
        // Perform key agreement and derive encryption materials
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: ephemeralPrivate,
            recipientPublic: recipientPublic
        )
        
        // Build HKDF info with ephemeral public key and message ID for context binding
        let hkdfInfo = "whisper-v1".data(using: .utf8)! + ephemeralPublic + msgid
        
        let (encKey, nonce) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: salt,
            info: hkdfInfo
        )
        
        // Encrypt the plaintext with canonical context as AAD
        let ciphertext = try cryptoEngine.encrypt(
            plaintext: plaintext,
            key: encKey,
            nonce: nonce,
            aad: canonicalContext
        )
        
        // Generate signature if required
        var signature: Data? = nil
        if requireSignature, let ed25519KeyPair = senderIdentity.ed25519KeyPair {
            // Sign the canonical context + ciphertext
            let signatureData = canonicalContext + ciphertext
            signature = try cryptoEngine.sign(data: signatureData, privateKey: ed25519KeyPair.privateKey)
        }
        
        // Build envelope string
        return try buildEnvelopeString(
            version: "v1.c20p",
            rkid: rkid,
            flags: flags,
            epk: ephemeralPublic,
            salt: salt,
            msgid: msgid,
            timestamp: timestamp,
            ciphertext: ciphertext,
            signature: signature
        )
    }
    
    // MARK: - Envelope Parsing
    
    func parseEnvelope(_ envelope: String) throws -> EnvelopeComponents {
        // Validate envelope prefix
        guard envelope.hasPrefix("whisper1:") else {
            throw EnvelopeError.invalidFormat
        }
        
        // Remove prefix and split components
        let envelopeBody = String(envelope.dropFirst(9)) // Remove "whisper1:"
        let allComponents = envelopeBody.split(separator: ".")
        
        // Validate component count (9 without signature, 10 with signature)
        // The version "v1.c20p" gets split into "v1" and "c20p"
        guard allComponents.count == 9 || allComponents.count == 10 else {
            throw EnvelopeError.invalidFormat
        }
        
        // Reconstruct version from first two components
        let version = String(allComponents[0]) + "." + String(allComponents[1])
        guard version == "v1.c20p" else {
            throw EnvelopeError.unsupportedAlgorithm(version)
        }
        
        // Get the actual envelope components (skip the version parts)
        let components = Array(allComponents.dropFirst(2))
        
        // Parse and decode components (now 0-based since we dropped version parts)
        let rkid = try base64URLEncoder.decode(String(components[0]))
        guard rkid.count == 8 else {
            throw EnvelopeError.invalidRkidLength
        }
        
        let flagsData = try base64URLEncoder.decode(String(components[1]))
        guard flagsData.count == 1 else {
            throw EnvelopeError.invalidFlagsLength
        }
        let flags = flagsData[0]
        
        let epk = try base64URLEncoder.decode(String(components[2]))
        guard epk.count == 32 else {
            throw EnvelopeError.invalidEpkLength
        }
        
        let salt = try base64URLEncoder.decode(String(components[3]))
        guard salt.count == 16 else {
            throw EnvelopeError.invalidSaltLength
        }
        
        let msgid = try base64URLEncoder.decode(String(components[4]))
        guard msgid.count == 16 else {
            throw EnvelopeError.invalidMsgidLength
        }
        
        let timestampData = try base64URLEncoder.decode(String(components[5]))
        guard timestampData.count == 8 else {
            throw EnvelopeError.invalidTimestampLength
        }
        let timestamp = timestampData.withUnsafeBytes { $0.load(as: Int64.self).bigEndian }
        
        let ciphertext = try base64URLEncoder.decode(String(components[6]))
        
        // Parse signature if present
        var signature: Data? = nil
        if components.count == 8 { // 8 components means signature is present (7 + signature)
            signature = try base64URLEncoder.decode(String(components[7]))
            guard signature?.count == 64 else {
                throw EnvelopeError.invalidSignatureLength
            }
        }
        
        // Validate signature flag consistency
        let hasSignature = (flags & 0x01) != 0
        if hasSignature && signature == nil {
            throw EnvelopeError.signatureFlagMismatch
        }
        if !hasSignature && signature != nil {
            throw EnvelopeError.signatureFlagMismatch
        }
        
        return EnvelopeComponents(
            version: version,
            rkid: rkid,
            flags: flags,
            epk: epk,
            salt: salt,
            msgid: msgid,
            timestamp: timestamp,
            ciphertext: ciphertext,
            signature: signature
        )
    }
    
    // MARK: - Envelope Validation
    
    func validateEnvelope(_ components: EnvelopeComponents) throws -> Bool {
        // Validate algorithm (strict algorithm lock)
        guard components.version == "v1.c20p" else {
            throw EnvelopeError.unsupportedAlgorithm(components.version)
        }
        
        // Validate component lengths
        guard components.rkid.count == 8 else {
            throw EnvelopeError.invalidRkidLength
        }
        
        guard components.epk.count == 32 else {
            throw EnvelopeError.invalidEpkLength
        }
        
        guard components.salt.count == 16 else {
            throw EnvelopeError.invalidSaltLength
        }
        
        guard components.msgid.count == 16 else {
            throw EnvelopeError.invalidMsgidLength
        }
        
        // Validate signature consistency
        let hasSignature = (components.flags & 0x01) != 0
        if hasSignature {
            guard let signature = components.signature, signature.count == 64 else {
                throw EnvelopeError.invalidSignatureLength
            }
        } else {
            guard components.signature == nil else {
                throw EnvelopeError.signatureFlagMismatch
            }
        }
        
        // Validate timestamp is reasonable (not too far in past/future)
        let now = Int64(Date().timeIntervalSince1970)
        let timeDiff = abs(now - components.timestamp)
        let maxTimeDiff: Int64 = 48 * 60 * 60 // 48 hours
        guard timeDiff <= maxTimeDiff else {
            throw EnvelopeError.timestampOutOfRange
        }
        
        return true
    }
    
    // MARK: - Canonical Context Building
    
    func buildCanonicalContext(appId: String,
                              version: String,
                              senderFingerprint: Data,
                              recipientFingerprint: Data,
                              policyFlags: UInt32,
                              rkid: Data,
                              epk: Data,
                              salt: Data,
                              msgid: Data,
                              ts: Int64) -> Data {
        
        // Use length-prefixed encoding for deterministic serialization
        var context = Data()
        
        // Add each field with length prefix
        context.append(encodeLengthPrefixed(appId.data(using: .utf8)!))
        context.append(encodeLengthPrefixed(version.data(using: .utf8)!))
        context.append(encodeLengthPrefixed(senderFingerprint))
        context.append(encodeLengthPrefixed(recipientFingerprint))
        
        // Add policy flags as big-endian UInt32
        var policyFlagsBE = policyFlags.bigEndian
        context.append(Data(bytes: &policyFlagsBE, count: 4))
        
        context.append(encodeLengthPrefixed(rkid))
        context.append(encodeLengthPrefixed(epk))
        context.append(encodeLengthPrefixed(salt))
        context.append(encodeLengthPrefixed(msgid))
        
        // Add timestamp as big-endian Int64
        var timestampBE = ts.bigEndian
        context.append(Data(bytes: &timestampBE, count: 8))
        
        return context
    }
    
    // MARK: - Helper Methods
    
    /// Builds the complete envelope string from components
    private func buildEnvelopeString(version: String,
                                   rkid: Data,
                                   flags: UInt8,
                                   epk: Data,
                                   salt: Data,
                                   msgid: Data,
                                   timestamp: Int64,
                                   ciphertext: Data,
                                   signature: Data?) throws -> String {
        
        var components = [version]
        
        // Encode all components using Base64URL
        components.append(base64URLEncoder.encode(rkid))
        components.append(base64URLEncoder.encode(Data([flags])))
        components.append(base64URLEncoder.encode(epk))
        components.append(base64URLEncoder.encode(salt))
        components.append(base64URLEncoder.encode(msgid))
        
        // Encode timestamp as big-endian Int64
        var timestampBE = timestamp.bigEndian
        let timestampData = Data(bytes: &timestampBE, count: 8)
        components.append(base64URLEncoder.encode(timestampData))
        
        components.append(base64URLEncoder.encode(ciphertext))
        
        // Add signature if present
        if let signature = signature {
            components.append(base64URLEncoder.encode(signature))
        }
        
        return "whisper1:" + components.joined(separator: ".")
    }
    
    /// Generates a recipient fingerprint from X25519 public key
    private func generateRecipientFingerprint(_ recipientPublic: Data) -> Data {
        // Use SHA-256 hash of public key as fingerprint (32 bytes)
        let hash = SHA256.hash(data: recipientPublic)
        return Data(hash)
    }
    
    /// Encodes data with length prefix for canonical context
    private func encodeLengthPrefixed(_ data: Data) -> Data {
        var result = Data()
        var length = UInt32(data.count).bigEndian
        result.append(Data(bytes: &length, count: 4))
        result.append(data)
        return result
    }
}

// MARK: - Base64URL Encoder

/// Base64URL encoder/decoder without padding as required by Whisper protocol
class Base64URLEncoder {
    
    /// Encodes data to Base64URL string without padding
    func encode(_ data: Data) -> String {
        let base64 = data.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Decodes Base64URL string to data
    func decode(_ string: String) throws -> Data {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64) else {
            throw EnvelopeError.invalidBase64URL
        }
        
        return data
    }
}

// MARK: - Error Types

/// Errors that can occur during envelope processing
enum EnvelopeError: Error, LocalizedError {
    case invalidFormat
    case unsupportedAlgorithm(String)
    case invalidRkidLength
    case invalidFlagsLength
    case invalidEpkLength
    case invalidSaltLength
    case invalidMsgidLength
    case invalidTimestampLength
    case invalidSignatureLength
    case signatureFlagMismatch
    case timestampOutOfRange
    case invalidBase64URL
    case cryptographicFailure(Error)
    
    var errorDescription: String? {
        // Generic user-facing messages for security
        #if DEBUG
        return debugDescription
        #else
        return "Invalid envelope"
        #endif
    }
    
    var debugDescription: String {
        switch self {
        case .invalidFormat:
            return "Invalid envelope format"
        case .unsupportedAlgorithm(let algorithm):
            return "Unsupported algorithm: \(algorithm)"
        case .invalidRkidLength:
            return "Invalid recipient key ID length"
        case .invalidFlagsLength:
            return "Invalid flags length"
        case .invalidEpkLength:
            return "Invalid ephemeral public key length"
        case .invalidSaltLength:
            return "Invalid salt length"
        case .invalidMsgidLength:
            return "Invalid message ID length"
        case .invalidTimestampLength:
            return "Invalid timestamp length"
        case .invalidSignatureLength:
            return "Invalid signature length"
        case .signatureFlagMismatch:
            return "Signature flag mismatch"
        case .timestampOutOfRange:
            return "Timestamp out of range"
        case .invalidBase64URL:
            return "Invalid Base64URL encoding"
        case .cryptographicFailure(let error):
            return "Cryptographic failure: \(error.localizedDescription)"
        }
    }
}