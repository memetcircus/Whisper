import Foundation
import CryptoKit

// MARK: - WhisperService Protocol

/// High-level encryption service that integrates all Whisper components
/// Provides encrypt/decrypt operations with contact/raw key support and comprehensive error handling
protocol WhisperService {
    /// Encrypts data to a contact with optional signature
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - identity: Sender's identity
    ///   - peer: Recipient contact
    ///   - authenticity: Whether to include signature
    /// - Returns: Whisper envelope string
    /// - Throws: WhisperError for various failure conditions
    func encrypt(_ data: Data,
                from identity: Identity,
                to peer: Contact,
                authenticity: Bool) async throws -> String
    
    /// Encrypts data to a raw public key with optional signature
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - identity: Sender's identity
    ///   - publicKey: Recipient's X25519 public key
    ///   - authenticity: Whether to include signature
    /// - Returns: Whisper envelope string
    /// - Throws: WhisperError for various failure conditions
    func encryptToRawKey(_ data: Data,
                        from identity: Identity,
                        to publicKey: Data,
                        authenticity: Bool) async throws -> String
    
    /// Decrypts a whisper envelope
    /// - Parameter envelope: Whisper envelope string
    /// - Returns: Decryption result with plaintext and attribution
    /// - Throws: WhisperError for various failure conditions
    func decrypt(_ envelope: String) async throws -> DecryptionResult
    
    /// Detects if text contains a whisper envelope
    /// - Parameter text: Text to check
    /// - Returns: True if text contains whisper1: prefix
    func detect(_ text: String) -> Bool
}

// MARK: - Decryption Result

/// Result of decrypting a whisper envelope
struct DecryptionResult {
    let plaintext: Data
    let attribution: AttributionResult
    let senderIdentity: Identity?
    let timestamp: Date
}

// MARK: - Attribution Result

/// Result of signature attribution for decrypted messages
enum AttributionResult {
    case signed(String, String) // name, trust status
    case signedUnknown
    case unsigned(String) // name or "Unknown"
    case invalidSignature
    
    var displayString: String {
        switch self {
        case .signed(let name, let trust):
            return "From: \(name) (\(trust), Signed)"
        case .signedUnknown:
            return "From: Unknown (Signed)"
        case .unsigned(let name):
            return "From: \(name)"
        case .invalidSignature:
            return "From: Unknown (Invalid Signature)"
        }
    }
}

// MARK: - WhisperService Implementation

/// Concrete implementation of WhisperService integrating all components
class DefaultWhisperService: WhisperService {
    
    private let cryptoEngine: CryptoEngine
    private let envelopeProcessor: EnvelopeProcessor
    private let identityManager: IdentityManager
    private let contactManager: ContactManager
    private let policyManager: PolicyManager
    private let biometricService: BiometricService
    private let replayProtector: ReplayProtector
    private let messagePadding: MessagePadding
    
    init(cryptoEngine: CryptoEngine,
         envelopeProcessor: EnvelopeProcessor,
         identityManager: IdentityManager,
         contactManager: ContactManager,
         policyManager: PolicyManager,
         biometricService: BiometricService,
         replayProtector: ReplayProtector,
         messagePadding: MessagePadding) {
        
        self.cryptoEngine = cryptoEngine
        self.envelopeProcessor = envelopeProcessor
        self.identityManager = identityManager
        self.contactManager = contactManager
        self.policyManager = policyManager
        self.biometricService = biometricService
        self.replayProtector = replayProtector
        self.messagePadding = messagePadding
    }
    
    // MARK: - Encryption Operations
    
    func encrypt(_ data: Data,
                from identity: Identity,
                to peer: Contact,
                authenticity: Bool) async throws -> String {
        
        // Validate send policy
        try policyManager.validateSendPolicy(recipient: peer)
        
        // Validate signature policy
        try policyManager.validateSignaturePolicy(recipient: peer, hasSignature: authenticity)
        
        // Check if contact is blocked
        if peer.isBlocked {
            throw WhisperError.policyViolation(.contactRequired)
        }
        
        // Pad the message
        let paddedData = messagePadding.pad(data)
        
        // Handle biometric signing if required
        var requireSignature = authenticity
        if policyManager.requiresBiometricForSigning() && authenticity {
            // This will be handled in envelope creation
            requireSignature = true
        }
        
        // Create envelope
        let envelope = try await createEnvelopeWithBiometric(
            plaintext: paddedData,
            senderIdentity: identity,
            recipientPublic: peer.x25519PublicKey,
            requireSignature: requireSignature
        )
        
        return envelope
    }
    
    func encryptToRawKey(_ data: Data,
                        from identity: Identity,
                        to publicKey: Data,
                        authenticity: Bool) async throws -> String {
        
        // Validate send policy (this will throw if contact required)
        try policyManager.validateSendPolicy(recipient: nil)
        
        // Pad the message
        let paddedData = messagePadding.pad(data)
        
        // Handle biometric signing if required
        var requireSignature = authenticity
        if policyManager.requiresBiometricForSigning() && authenticity {
            requireSignature = true
        }
        
        // Create envelope
        let envelope = try await createEnvelopeWithBiometric(
            plaintext: paddedData,
            senderIdentity: identity,
            recipientPublic: publicKey,
            requireSignature: requireSignature
        )
        
        return envelope
    }
    
    // MARK: - Decryption Operations
    
    func decrypt(_ envelope: String) async throws -> DecryptionResult {
        // Parse envelope
        let components = try envelopeProcessor.parseEnvelope(envelope)
        
        // Validate envelope
        _ = try envelopeProcessor.validateEnvelope(components)
        
        // Check freshness
        guard replayProtector.isWithinFreshnessWindow(components.timestamp) else {
            throw WhisperError.messageExpired
        }
        
        // Find matching identity by rkid
        guard let recipientIdentity = identityManager.getIdentity(byRkid: components.rkid) else {
            throw WhisperError.messageNotForMe
        }
        
        // Check and commit replay protection atomically
        let isUnique = await replayProtector.checkAndCommit(
            msgId: components.msgid,
            timestamp: components.timestamp
        )
        
        guard isUnique else {
            throw WhisperError.replayDetected
        }
        
        // Perform key agreement and derive keys
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: recipientIdentity.x25519KeyPair.privateKey,
            recipientPublic: components.epk
        )
        
        // Build HKDF info with ephemeral public key and message ID
        let hkdfInfo = "whisper-v1".data(using: .utf8)! + components.epk + components.msgid
        
        let (encKey, nonce) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: components.salt,
            info: hkdfInfo
        )
        
        // Build canonical context for AAD
        let senderFingerprint = try findSenderFingerprint(components: components)
        let canonicalContext = envelopeProcessor.buildCanonicalContext(
            appId: "whisper",
            version: "v1",
            senderFingerprint: senderFingerprint,
            recipientFingerprint: recipientIdentity.fingerprint,
            policyFlags: UInt32(components.flags),
            rkid: components.rkid,
            epk: components.epk,
            salt: components.salt,
            msgid: components.msgid,
            ts: components.timestamp
        )
        
        // Decrypt the message
        let paddedPlaintext = try cryptoEngine.decrypt(
            ciphertext: components.ciphertext,
            key: encKey,
            nonce: nonce,
            aad: canonicalContext
        )
        
        // Unpad the message
        let plaintext = try messagePadding.unpad(paddedPlaintext)
        
        // Verify signature and determine attribution
        let attribution = try await attributeMessage(
            components: components,
            canonicalContext: canonicalContext
        )
        
        return DecryptionResult(
            plaintext: plaintext,
            attribution: attribution,
            senderIdentity: recipientIdentity,
            timestamp: Date(timeIntervalSince1970: TimeInterval(components.timestamp))
        )
    }
    
    // MARK: - Detection
    
    func detect(_ text: String) -> Bool {
        return text.contains("whisper1:")
    }
    
    // MARK: - Private Helper Methods
    
    private func createEnvelopeWithBiometric(plaintext: Data,
                                           senderIdentity: Identity,
                                           recipientPublic: Data,
                                           requireSignature: Bool) async throws -> String {
        
        if requireSignature && policyManager.requiresBiometricForSigning() {
            // Use biometric service for signing
            guard let ed25519KeyPair = senderIdentity.ed25519KeyPair else {
                throw WhisperError.keyNotFound
            }
            
            // Store signing key in biometric service if not already enrolled
            let keyId = senderIdentity.id.uuidString
            
            do {
                // Try to enroll the key (will fail silently if already enrolled)
                try biometricService.enrollSigningKey(ed25519KeyPair.privateKey, id: keyId)
            } catch {
                // Key might already be enrolled, continue
            }
            
            // Create envelope with biometric signing
            return try await createEnvelopeWithBiometricSigning(
                plaintext: plaintext,
                senderIdentity: senderIdentity,
                recipientPublic: recipientPublic,
                keyId: keyId
            )
        } else {
            // Regular envelope creation
            return try envelopeProcessor.createEnvelope(
                plaintext: plaintext,
                senderIdentity: senderIdentity,
                recipientPublic: recipientPublic,
                requireSignature: requireSignature
            )
        }
    }
    
    private func createEnvelopeWithBiometricSigning(plaintext: Data,
                                                  senderIdentity: Identity,
                                                  recipientPublic: Data,
                                                  keyId: String) async throws -> String {
        
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
        
        // Set flags for signature
        let flags: UInt8 = 0x01 // Set bit 0 for signature presence
        
        // Build canonical context for cryptographic binding
        let recipientFingerprint = try generateRecipientFingerprint(recipientPublic)
        let canonicalContext = envelopeProcessor.buildCanonicalContext(
            appId: "whisper",
            version: "v1",
            senderFingerprint: senderIdentity.fingerprint,
            recipientFingerprint: recipientFingerprint,
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
        
        // Build HKDF info with ephemeral public key and message ID
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
        
        // Sign using biometric service
        let signatureData = canonicalContext + ciphertext
        let signature: Data
        
        do {
            signature = try await biometricService.sign(data: signatureData, keyId: keyId)
        } catch let error as BiometricError {
            throw error.asWhisperError
        }
        
        // Build envelope string manually since we used biometric signing
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
    
    private func findSenderFingerprint(components: EnvelopeComponents) throws -> Data {
        // Try to find sender in contacts first
        if let signature = components.signature {
            // Look through contacts to find matching signing key
            let contacts = contactManager.listContacts()
            for contact in contacts {
                if let ed25519PublicKey = contact.ed25519PublicKey {
                    // Verify signature to check if this is the sender
                    let signatureData = try buildSignatureData(components: components)
                    if (try? cryptoEngine.verify(signature: signature, data: signatureData, publicKey: ed25519PublicKey)) == true {
                        return contact.fingerprint
                    }
                }
            }
        }
        
        // If not found in contacts, generate fingerprint from ephemeral key
        // This is a fallback - in practice we might not have the sender's identity key
        let hash = SHA256.hash(data: components.epk)
        return Data(hash)
    }
    
    private func buildSignatureData(components: EnvelopeComponents) throws -> Data {
        // Reconstruct the canonical context + ciphertext that was signed
        let senderFingerprint = try findSenderFingerprint(components: components)
        
        // Find recipient identity
        guard let recipientIdentity = identityManager.getIdentity(byRkid: components.rkid) else {
            throw WhisperError.messageNotForMe
        }
        
        let canonicalContext = envelopeProcessor.buildCanonicalContext(
            appId: "whisper",
            version: "v1",
            senderFingerprint: senderFingerprint,
            recipientFingerprint: recipientIdentity.fingerprint,
            policyFlags: UInt32(components.flags),
            rkid: components.rkid,
            epk: components.epk,
            salt: components.salt,
            msgid: components.msgid,
            ts: components.timestamp
        )
        
        return canonicalContext + components.ciphertext
    }
    
    private func attributeMessage(components: EnvelopeComponents,
                                canonicalContext: Data) async throws -> AttributionResult {
        
        guard let signature = components.signature else {
            return .unsigned("Unknown")
        }
        
        // Build signature data
        let signatureData = canonicalContext + components.ciphertext
        
        // Look through contacts to find matching signing key
        let contacts = contactManager.listContacts()
        for contact in contacts {
            if let ed25519PublicKey = contact.ed25519PublicKey {
                do {
                    if try cryptoEngine.verify(signature: signature, data: signatureData, publicKey: ed25519PublicKey) {
                        let trustStatus = contact.trustLevel == .verified ? "Verified" : "Unverified"
                        return .signed(contact.displayName, trustStatus)
                    }
                } catch {
                    // Continue checking other contacts
                    continue
                }
            }
        }
        
        // Valid signature but unknown sender
        return .signedUnknown
    }
    
    private func generateRecipientFingerprint(_ recipientPublic: Data) throws -> Data {
        // Use SHA-256 hash of public key as fingerprint (32 bytes)
        let hash = SHA256.hash(data: recipientPublic)
        return Data(hash)
    }
    
    private func buildEnvelopeString(version: String,
                                   rkid: Data,
                                   flags: UInt8,
                                   epk: Data,
                                   salt: Data,
                                   msgid: Data,
                                   timestamp: Int64,
                                   ciphertext: Data,
                                   signature: Data?) throws -> String {
        
        let base64URLEncoder = Base64URLEncoder()
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
}

// MARK: - Error Extensions

extension WhisperError {
    /// Generic user-facing error messages for security
    var userFacingMessage: String {
        switch self {
        case .invalidEnvelope:
            return "Invalid envelope"
        case .replayDetected:
            return "Replay detected"
        case .messageExpired:
            return "Message expired"
        case .messageNotForMe:
            return "This message is not addressed to you"
        case .policyViolation(let type):
            return type.userFacingMessage
        case .biometricAuthenticationFailed:
            return "Signature cancelled"
        default:
            return "Invalid envelope"
        }
    }
}

// MARK: - Supporting Types



/// Protocol for message padding operations
protocol MessagePadding {
    func pad(_ data: Data) -> Data
    func unpad(_ paddedData: Data) throws -> Data
}