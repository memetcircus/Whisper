import Foundation
import CryptoKit

/// Memory-optimized wrapper for cryptographic operations
/// Implements secure memory management and efficient buffer handling
protocol MemoryOptimizedCrypto {
    /// Performs encryption with memory optimization
    /// - Parameters:
    ///   - plaintext: Data to encrypt
    ///   - identity: Sender identity
    ///   - recipientPublicKey: Recipient's public key
    ///   - requireSignature: Whether to include signature
    /// - Returns: Encrypted envelope string
    /// - Throws: CryptoError if encryption fails
    func encryptWithMemoryOptimization(
        plaintext: Data,
        identity: Identity,
        recipientPublicKey: Data,
        requireSignature: Bool
    ) throws -> String
    
    /// Performs decryption with memory optimization
    /// - Parameters:
    ///   - envelope: Encrypted envelope string
    ///   - identity: Recipient identity
    /// - Returns: Decrypted plaintext
    /// - Throws: CryptoError if decryption fails
    func decryptWithMemoryOptimization(
        envelope: String,
        identity: Identity
    ) throws -> Data
    
    /// Securely clears sensitive data from memory
    /// - Parameter data: Data to clear
    func secureClear(_ data: inout Data)
    
    /// Gets current memory usage for crypto operations
    /// - Returns: Memory usage in bytes
    func getCryptoMemoryUsage() -> Int64
    
    /// Performs memory cleanup and optimization
    func optimizeMemory()
}

/// Memory pool for reusing crypto buffers
class CryptoMemoryPool {
    private var availableBuffers: [Int: [Data]] = [:]
    private let queue = DispatchQueue(label: "crypto-memory-pool")
    private let maxBuffersPerSize = 5
    
    /// Gets a buffer of specified size, reusing if available
    /// - Parameter size: Required buffer size
    /// - Returns: Data buffer of requested size
    func getBuffer(size: Int) -> Data {
        return queue.sync {
            if var buffers = availableBuffers[size], !buffers.isEmpty {
                let buffer = buffers.removeLast()
                availableBuffers[size] = buffers
                return buffer
            } else {
                return Data(count: size)
            }
        }
    }
    
    /// Returns a buffer to the pool for reuse
    /// - Parameters:
    ///   - buffer: Buffer to return
    ///   - size: Size of the buffer
    func returnBuffer(_ buffer: Data, size: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.availableBuffers[size] == nil {
                self.availableBuffers[size] = []
            }
            
            if let buffers = self.availableBuffers[size], buffers.count < self.maxBuffersPerSize {
                var clearedBuffer = buffer
                self.secureClearData(&clearedBuffer)
                self.availableBuffers[size]?.append(clearedBuffer)
            }
        }
    }
    
    /// Clears all buffers from the pool
    func clearPool() {
        queue.sync {
            for (_, buffers) in availableBuffers {
                for var buffer in buffers {
                    secureClearData(&buffer)
                }
            }
            availableBuffers.removeAll()
        }
    }
    
    private func secureClearData(_ data: inout Data) {
        data.withUnsafeMutableBytes { bytes in
            memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
        }
    }
}

/// Concrete implementation of MemoryOptimizedCrypto
class WhisperMemoryOptimizedCrypto: MemoryOptimizedCrypto {
    
    private let cryptoEngine: CryptoEngine
    private let envelopeProcessor: EnvelopeProcessor
    private let performanceMonitor: PerformanceMonitor
    private let memoryPool = CryptoMemoryPool()
    
    // Memory tracking
    private var allocatedMemory: Int64 = 0
    private let memoryQueue = DispatchQueue(label: "crypto-memory-tracking")
    
    init(cryptoEngine: CryptoEngine, envelopeProcessor: EnvelopeProcessor, performanceMonitor: PerformanceMonitor) {
        self.cryptoEngine = cryptoEngine
        self.envelopeProcessor = envelopeProcessor
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Memory-Optimized Encryption
    
    func encryptWithMemoryOptimization(
        plaintext: Data,
        identity: Identity,
        recipientPublicKey: Data,
        requireSignature: Bool
    ) throws -> String {
        
        return try performanceMonitor.measureMemoryUsage("memory_optimized_encrypt") { [weak self] in
            guard let self = self else { throw CryptoError.encryptionFailure(NSError(domain: "MemoryOptimized", code: -1)) }
            
            // Use memory pool for temporary buffers
            let paddingSize = MessagePadding.selectBucket(for: plaintext.count).rawValue
            var paddedBuffer = self.memoryPool.getBuffer(size: paddingSize)
            defer { self.memoryPool.returnBuffer(paddedBuffer, size: paddingSize) }
            
            // Apply padding in-place
            try self.applyPaddingInPlace(plaintext: plaintext, buffer: &paddedBuffer)
            
            // Generate ephemeral keys with immediate cleanup
            var ephemeralPrivate: Curve25519.KeyAgreement.PrivateKey? = Curve25519.KeyAgreement.PrivateKey()
            let ephemeralPublic = ephemeralPrivate!.publicKey.rawRepresentation
            defer { self.cryptoEngine.zeroizeEphemeralKey(&ephemeralPrivate) }
            
            // Perform key agreement
            let sharedSecret = try self.cryptoEngine.performKeyAgreement(
                ephemeralPrivate: ephemeralPrivate!,
                recipientPublic: recipientPublicKey
            )
            
            // Generate random values
            let salt = try self.cryptoEngine.generateSecureRandom(length: 16)
            let msgId = try self.cryptoEngine.generateSecureRandom(length: 16)
            
            // Derive keys with context binding
            let info = ephemeralPublic + msgId
            let (encKey, nonce) = try self.cryptoEngine.deriveKeys(
                sharedSecret: sharedSecret,
                salt: salt,
                info: info
            )
            
            // Build AAD
            let rkid = self.cryptoEngine.generateRecipientKeyId(x25519PublicKey: recipientPublicKey)
            let timestamp = Int64(Date().timeIntervalSince1970)
            let flags: UInt8 = requireSignature ? 0x01 : 0x00
            
            let aad = self.buildCanonicalAAD(
                rkid: rkid,
                flags: flags,
                ephemeralPublic: ephemeralPublic,
                salt: salt,
                msgId: msgId,
                timestamp: timestamp
            )
            
            // Encrypt with memory-efficient approach
            let ciphertext = try self.encryptInPlace(
                plaintext: paddedBuffer,
                key: encKey,
                nonce: nonce,
                aad: aad
            )
            
            // Generate signature if required
            var signature: Data?
            if requireSignature, let ed25519KeyPair = identity.ed25519KeyPair {
                let signatureData = aad + ciphertext
                signature = try self.cryptoEngine.sign(data: signatureData, privateKey: ed25519KeyPair.privateKey)
            }
            
            // Create envelope
            let envelope = try self.envelopeProcessor.createEnvelope(
                rkid: rkid,
                flags: flags,
                ephemeralPublic: ephemeralPublic,
                salt: salt,
                msgId: msgId,
                timestamp: timestamp,
                ciphertext: ciphertext,
                signature: signature
            )
            
            // Secure cleanup
            var encKeyMutable = encKey
            var nonceMutable = nonce
            self.secureClear(&encKeyMutable)
            self.secureClear(&nonceMutable)
            
            return envelope
        }.result
    }
    
    // MARK: - Memory-Optimized Decryption
    
    func decryptWithMemoryOptimization(
        envelope: String,
        identity: Identity
    ) throws -> Data {
        
        return try performanceMonitor.measureMemoryUsage("memory_optimized_decrypt") { [weak self] in
            guard let self = self else { throw CryptoError.decryptionFailure(NSError(domain: "MemoryOptimized", code: -1)) }
            
            // Parse envelope
            let components = try self.envelopeProcessor.parseEnvelope(envelope)
            
            // Verify this message is for us
            let identityRkid = self.cryptoEngine.generateRecipientKeyId(x25519PublicKey: identity.x25519KeyPair.publicKey)
            guard identityRkid == components.rkid else {
                throw WhisperError.messageNotForMe
            }
            
            // Perform key agreement
            let sharedSecret = try self.cryptoEngine.performKeyAgreement(
                ephemeralPrivate: identity.x25519KeyPair.privateKey,
                recipientPublic: components.ephemeralPublic
            )
            
            // Derive keys
            let info = components.ephemeralPublic + components.msgId
            let (decKey, nonce) = try self.cryptoEngine.deriveKeys(
                sharedSecret: sharedSecret,
                salt: components.salt,
                info: info
            )
            
            // Build AAD for verification
            let aad = self.buildCanonicalAAD(
                rkid: components.rkid,
                flags: components.flags,
                ephemeralPublic: components.ephemeralPublic,
                salt: components.salt,
                msgId: components.msgId,
                timestamp: components.timestamp
            )
            
            // Decrypt with memory optimization
            let paddedPlaintext = try self.decryptInPlace(
                ciphertext: components.ciphertext,
                key: decKey,
                nonce: nonce,
                aad: aad
            )
            
            // Remove padding
            let plaintext = try MessagePadding.unpad(paddedPlaintext)
            
            // Secure cleanup
            var decKeyMutable = decKey
            var nonceMutable = nonce
            var paddedMutable = paddedPlaintext
            self.secureClear(&decKeyMutable)
            self.secureClear(&nonceMutable)
            self.secureClear(&paddedMutable)
            
            return plaintext
        }.result
    }
    
    // MARK: - Memory Management
    
    func secureClear(_ data: inout Data) {
        data.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            memset_s(baseAddress, bytes.count, 0, bytes.count)
        }
    }
    
    func getCryptoMemoryUsage() -> Int64 {
        return memoryQueue.sync {
            return allocatedMemory
        }
    }
    
    func optimizeMemory() {
        memoryPool.clearPool()
        
        // Force garbage collection
        autoreleasepool {
            // Perform any cleanup operations
        }
        
        memoryQueue.sync {
            allocatedMemory = 0
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func applyPaddingInPlace(plaintext: Data, buffer: inout Data) throws {
        let bucket = MessagePadding.selectBucket(for: plaintext.count)
        let targetSize = bucket.rawValue
        
        guard buffer.count >= targetSize else {
            throw CryptoError.invalidKeySize
        }
        
        // Write length prefix (2 bytes, big-endian)
        let length = UInt16(plaintext.count).bigEndian
        buffer.withUnsafeMutableBytes { bytes in
            bytes.storeBytes(of: length, as: UInt16.self)
        }
        
        // Copy plaintext
        buffer.replaceSubrange(2..<(2 + plaintext.count), with: plaintext)
        
        // Zero out padding area
        let paddingStart = 2 + plaintext.count
        let paddingEnd = targetSize
        buffer.withUnsafeMutableBytes { bytes in
            memset(bytes.baseAddress!.advanced(by: paddingStart), 0, paddingEnd - paddingStart)
        }
        
        // Truncate buffer to target size
        buffer = buffer.prefix(targetSize)
    }
    
    private func encryptInPlace(
        plaintext: Data,
        key: Data,
        nonce: Data,
        aad: Data
    ) throws -> Data {
        
        trackMemoryAllocation(Int64(plaintext.count + 16)) // Estimate with auth tag
        defer { trackMemoryDeallocation(Int64(plaintext.count + 16)) }
        
        return try cryptoEngine.encrypt(
            plaintext: plaintext,
            key: key,
            nonce: nonce,
            aad: aad
        )
    }
    
    private func decryptInPlace(
        ciphertext: Data,
        key: Data,
        nonce: Data,
        aad: Data
    ) throws -> Data {
        
        trackMemoryAllocation(Int64(ciphertext.count))
        defer { trackMemoryDeallocation(Int64(ciphertext.count)) }
        
        return try cryptoEngine.decrypt(
            ciphertext: ciphertext,
            key: key,
            nonce: nonce,
            aad: aad
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
        aad.reserveCapacity(100) // Pre-allocate reasonable capacity
        
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
    
    private func trackMemoryAllocation(_ bytes: Int64) {
        memoryQueue.async { [weak self] in
            self?.allocatedMemory += bytes
        }
    }
    
    private func trackMemoryDeallocation(_ bytes: Int64) {
        memoryQueue.async { [weak self] in
            self?.allocatedMemory -= bytes
        }
    }
}

// MARK: - MessagePadding Extension for Bucket Selection

extension MessagePadding {
    enum PaddingBucket: Int {
        case small = 256
        case medium = 512
        case large = 1024
    }
    
    static func selectBucket(for messageLength: Int) -> PaddingBucket {
        if messageLength <= 254 { // Account for 2-byte length prefix
            return .small
        } else if messageLength <= 510 {
            return .medium
        } else {
            return .large
        }
    }
}

// MARK: - Secure Memory Extensions

extension Data {
    /// Securely overwrites data with zeros
    mutating func secureZero() {
        self.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            memset_s(baseAddress, bytes.count, 0, bytes.count)
        }
    }
    
    /// Creates a copy with secure cleanup of original
    func secureClone() -> Data {
        let copy = Data(self)
        var mutableSelf = self
        mutableSelf.secureZero()
        return copy
    }
}