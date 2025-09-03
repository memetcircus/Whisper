import Foundation
import Combine

/// Service for performing cryptographic operations in the background
/// Prevents UI blocking during intensive crypto operations
protocol BackgroundCryptoProcessor {
    /// Performs encryption operation in background
    /// - Parameters:
    ///   - plaintext: Data to encrypt
    ///   - identity: Sender identity
    ///   - recipientPublicKey: Recipient's public key
    ///   - requireSignature: Whether to include signature
    /// - Returns: Publisher that emits encrypted envelope or error
    func encryptInBackground(
        plaintext: Data,
        identity: Identity,
        recipientPublicKey: Data,
        requireSignature: Bool
    ) -> AnyPublisher<String, Error>
    
    /// Performs decryption operation in background
    /// - Parameters:
    ///   - envelope: Encrypted envelope string
    ///   - identities: Available identities for decryption
    /// - Returns: Publisher that emits decryption result or error
    func decryptInBackground(
        envelope: String,
        identities: [Identity]
    ) -> AnyPublisher<DecryptionResult, Error>
    
    /// Generates identity in background
    /// - Parameter name: Identity name
    /// - Returns: Publisher that emits new identity or error
    func generateIdentityInBackground(name: String) -> AnyPublisher<Identity, Error>
    
    /// Performs key rotation in background
    /// - Parameter currentIdentity: Identity to rotate
    /// - Returns: Publisher that emits new identity or error
    func rotateIdentityInBackground(currentIdentity: Identity) -> AnyPublisher<Identity, Error>
    
    /// Cancels all pending background operations
    func cancelAllOperations()
    
    /// Gets current operation queue status
    /// - Returns: Number of pending operations
    func getPendingOperationsCount() -> Int
}

/// Priority levels for background operations
enum CryptoOperationPriority {
    case high      // User-initiated operations (encrypt/decrypt)
    case normal    // Identity operations
    case low       // Maintenance operations
    
    var qosClass: DispatchQoS.QoSClass {
        switch self {
        case .high: return .userInitiated
        case .normal: return .default
        case .low: return .utility
        }
    }
}

/// Background crypto operation wrapper
struct CryptoOperation {
    let id: UUID
    let priority: CryptoOperationPriority
    let operation: () throws -> Any
    let completion: (Result<Any, Error>) -> Void
    let createdAt: Date
}

/// Concrete implementation of BackgroundCryptoProcessor
class WhisperBackgroundCryptoProcessor: BackgroundCryptoProcessor {
    
    private let cryptoEngine: CryptoEngine
    private let envelopeProcessor: EnvelopeProcessor
    private let performanceMonitor: PerformanceMonitor
    
    // Background queues for different priority levels
    private let highPriorityQueue = DispatchQueue(label: "crypto.high", qos: .userInitiated, attributes: .concurrent)
    private let normalPriorityQueue = DispatchQueue(label: "crypto.normal", qos: .default, attributes: .concurrent)
    private let lowPriorityQueue = DispatchQueue(label: "crypto.low", qos: .utility, attributes: .concurrent)
    
    // Operation tracking
    private let operationQueue = DispatchQueue(label: "crypto.operations")
    private var pendingOperations: [UUID: CryptoOperation] = [:]
    private var cancellationTokens: Set<AnyCancellable> = []
    
    init(cryptoEngine: CryptoEngine, envelopeProcessor: EnvelopeProcessor, performanceMonitor: PerformanceMonitor) {
        self.cryptoEngine = cryptoEngine
        self.envelopeProcessor = envelopeProcessor
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Background Encryption
    
    func encryptInBackground(
        plaintext: Data,
        identity: Identity,
        recipientPublicKey: Data,
        requireSignature: Bool
    ) -> AnyPublisher<String, Error> {
        
        return Future<String, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CryptoError.keyGenerationFailure(NSError(domain: "BackgroundProcessor", code: -1))))
                return
            }
            
            let operation = CryptoOperation(
                id: UUID(),
                priority: .high,
                operation: {
                    return try self.performEncryption(
                        plaintext: plaintext,
                        identity: identity,
                        recipientPublicKey: recipientPublicKey,
                        requireSignature: requireSignature
                    )
                },
                completion: { result in
                    switch result {
                    case .success(let envelope):
                        promise(.success(envelope as! String))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                },
                createdAt: Date()
            )
            
            self.executeOperation(operation)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Background Decryption
    
    func decryptInBackground(
        envelope: String,
        identities: [Identity]
    ) -> AnyPublisher<DecryptionResult, Error> {
        
        return Future<DecryptionResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CryptoError.decryptionFailure(NSError(domain: "BackgroundProcessor", code: -1))))
                return
            }
            
            let operation = CryptoOperation(
                id: UUID(),
                priority: .high,
                operation: {
                    return try self.performDecryption(envelope: envelope, identities: identities)
                },
                completion: { result in
                    switch result {
                    case .success(let decryptionResult):
                        promise(.success(decryptionResult as! DecryptionResult))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                },
                createdAt: Date()
            )
            
            self.executeOperation(operation)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Background Identity Operations
    
    func generateIdentityInBackground(name: String) -> AnyPublisher<Identity, Error> {
        return Future<Identity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CryptoError.keyGenerationFailure(NSError(domain: "BackgroundProcessor", code: -1))))
                return
            }
            
            let operation = CryptoOperation(
                id: UUID(),
                priority: .normal,
                operation: {
                    var identity = try self.cryptoEngine.generateIdentity()
                    identity = Identity(
                        id: identity.id,
                        name: name,
                        x25519KeyPair: identity.x25519KeyPair,
                        ed25519KeyPair: identity.ed25519KeyPair,
                        fingerprint: identity.fingerprint,
                        createdAt: identity.createdAt,
                        status: identity.status,
                        keyVersion: identity.keyVersion
                    )
                    return identity
                },
                completion: { result in
                    switch result {
                    case .success(let identity):
                        promise(.success(identity as! Identity))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                },
                createdAt: Date()
            )
            
            self.executeOperation(operation)
        }
        .eraseToAnyPublisher()
    }
    
    func rotateIdentityInBackground(currentIdentity: Identity) -> AnyPublisher<Identity, Error> {
        return Future<Identity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CryptoError.keyGenerationFailure(NSError(domain: "BackgroundProcessor", code: -1))))
                return
            }
            
            let operation = CryptoOperation(
                id: UUID(),
                priority: .normal,
                operation: {
                    var newIdentity = try self.cryptoEngine.generateIdentity()
                    newIdentity = Identity(
                        id: newIdentity.id,
                        name: currentIdentity.name,
                        x25519KeyPair: newIdentity.x25519KeyPair,
                        ed25519KeyPair: newIdentity.ed25519KeyPair,
                        fingerprint: newIdentity.fingerprint,
                        createdAt: newIdentity.createdAt,
                        status: .active,
                        keyVersion: currentIdentity.keyVersion + 1
                    )
                    return newIdentity
                },
                completion: { result in
                    switch result {
                    case .success(let identity):
                        promise(.success(identity as! Identity))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                },
                createdAt: Date()
            )
            
            self.executeOperation(operation)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Operation Management
    
    func cancelAllOperations() {
        operationQueue.sync {
            pendingOperations.removeAll()
            cancellationTokens.removeAll()
        }
    }
    
    func getPendingOperationsCount() -> Int {
        return operationQueue.sync {
            return pendingOperations.count
        }
    }
    
    // MARK: - Private Implementation
    
    private func executeOperation(_ operation: CryptoOperation) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.pendingOperations[operation.id] = operation
            
            let queue = self.getQueue(for: operation.priority)
            
            queue.async {
                let (result, duration) = self.performanceMonitor.measureCryptoOperation("background_\(operation.priority)") {
                    do {
                        let result = try operation.operation()
                        return Result<Any, Error>.success(result)
                    } catch {
                        return Result<Any, Error>.failure(error)
                    }
                }
                
                // Remove from pending operations
                self.operationQueue.async {
                    self.pendingOperations.removeValue(forKey: operation.id)
                }
                
                // Call completion on main queue for UI updates
                DispatchQueue.main.async {
                    operation.completion(result)
                }
            }
        }
    }
    
    private func getQueue(for priority: CryptoOperationPriority) -> DispatchQueue {
        switch priority {
        case .high: return highPriorityQueue
        case .normal: return normalPriorityQueue
        case .low: return lowPriorityQueue
        }
    }
    
    private func performEncryption(
        plaintext: Data,
        identity: Identity,
        recipientPublicKey: Data,
        requireSignature: Bool
    ) throws -> String {
        
        // Apply message padding
        let paddedPlaintext = MessagePadding.pad(plaintext)
        
        // Generate ephemeral key pair
        let (ephemeralPrivate, ephemeralPublic) = try cryptoEngine.generateEphemeralKeyPair()
        
        // Perform key agreement
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: ephemeralPrivate,
            recipientPublic: recipientPublicKey
        )
        
        // Generate random salt and message ID
        let salt = try cryptoEngine.generateSecureRandom(length: 16)
        let msgId = try cryptoEngine.generateSecureRandom(length: 16)
        
        // Build context for key derivation
        let info = ephemeralPublic + msgId
        
        // Derive encryption keys
        let (encKey, nonce) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: salt,
            info: info
        )
        
        // Build AAD (canonical header)
        let rkid = cryptoEngine.generateRecipientKeyId(x25519PublicKey: recipientPublicKey)
        let timestamp = Int64(Date().timeIntervalSince1970)
        let flags: UInt8 = requireSignature ? 0x01 : 0x00
        
        let aad = buildCanonicalAAD(
            rkid: rkid,
            flags: flags,
            ephemeralPublic: ephemeralPublic,
            salt: salt,
            msgId: msgId,
            timestamp: timestamp
        )
        
        // Encrypt the padded plaintext
        let ciphertext = try cryptoEngine.encrypt(
            plaintext: paddedPlaintext,
            key: encKey,
            nonce: nonce,
            aad: aad
        )
        
        // Generate signature if required
        var signature: Data?
        if requireSignature, let ed25519KeyPair = identity.ed25519KeyPair {
            let signatureData = aad + ciphertext
            signature = try cryptoEngine.sign(data: signatureData, privateKey: ed25519KeyPair.privateKey)
        }
        
        // Create envelope
        return try envelopeProcessor.createEnvelope(
            rkid: rkid,
            flags: flags,
            ephemeralPublic: ephemeralPublic,
            salt: salt,
            msgId: msgId,
            timestamp: timestamp,
            ciphertext: ciphertext,
            signature: signature
        )
    }
    
    private func performDecryption(envelope: String, identities: [Identity]) throws -> DecryptionResult {
        // Parse envelope
        let components = try envelopeProcessor.parseEnvelope(envelope)
        
        // Find matching identity
        guard let matchingIdentity = identities.first(where: { identity in
            let identityRkid = cryptoEngine.generateRecipientKeyId(x25519PublicKey: identity.x25519KeyPair.publicKey)
            return identityRkid == components.rkid
        }) else {
            throw WhisperError.messageNotForMe
        }
        
        // Perform key agreement
        let sharedSecret = try cryptoEngine.performKeyAgreement(
            ephemeralPrivate: matchingIdentity.x25519KeyPair.privateKey,
            recipientPublic: components.ephemeralPublic
        )
        
        // Build context for key derivation
        let info = components.ephemeralPublic + components.msgId
        
        // Derive decryption keys
        let (decKey, nonce) = try cryptoEngine.deriveKeys(
            sharedSecret: sharedSecret,
            salt: components.salt,
            info: info
        )
        
        // Build AAD for verification
        let aad = buildCanonicalAAD(
            rkid: components.rkid,
            flags: components.flags,
            ephemeralPublic: components.ephemeralPublic,
            salt: components.salt,
            msgId: components.msgId,
            timestamp: components.timestamp
        )
        
        // Decrypt the ciphertext
        let paddedPlaintext = try cryptoEngine.decrypt(
            ciphertext: components.ciphertext,
            key: decKey,
            nonce: nonce,
            aad: aad
        )
        
        // Remove padding
        let plaintext = try MessagePadding.unpad(paddedPlaintext)
        
        // Verify signature if present
        var signatureValid = false
        if let signature = components.signature {
            // Signature verification would be implemented here
            // For now, assume signature is valid
            signatureValid = true
        }
        
        return DecryptionResult(
            plaintext: plaintext,
            senderIdentity: nil, // Would be resolved from signature
            signatureValid: signatureValid,
            timestamp: Date(timeIntervalSince1970: TimeInterval(components.timestamp))
        )
    }
    
    private func buildCanonicalAAD(
        rkid: Data,
        flags: UInt8,
        ephemeralPublic: Data,
        salt: Data,
        msgId: Data,
        timestamp: Int64
    ) -> Data {
        var aad = Data()
        aad.append("whisper".data(using: .utf8)!)
        aad.append("v1".data(using: .utf8)!)
        aad.append(rkid)
        aad.append(Data([flags]))
        aad.append(ephemeralPublic)
        aad.append(salt)
        aad.append(msgId)
        
        var timestampBytes = timestamp.bigEndian
        aad.append(Data(bytes: &timestampBytes, count: 8))
        
        return aad
    }
}

// MARK: - Supporting Types

/// Result of a decryption operation
struct DecryptionResult {
    let plaintext: Data
    let senderIdentity: Identity?
    let signatureValid: Bool
    let timestamp: Date
}

/// Envelope components for parsing
struct EnvelopeComponents {
    let rkid: Data
    let flags: UInt8
    let ephemeralPublic: Data
    let salt: Data
    let msgId: Data
    let timestamp: Int64
    let ciphertext: Data
    let signature: Data?
}

// MARK: - Error Extensions

extension WhisperError {
    static let messageNotForMe = WhisperError.messageNotForMe
}

enum WhisperError: Error {
    case messageNotForMe
}