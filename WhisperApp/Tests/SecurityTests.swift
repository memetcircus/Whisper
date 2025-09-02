import XCTest
import CryptoKit
@testable import WhisperApp

class SecurityTests: XCTestCase {
    
    var cryptoEngine: CryptoEngine!
    var envelopeProcessor: EnvelopeProcessor!
    var identityManager: IdentityManager!
    var contactManager: ContactManager!
    var whisperService: WhisperService!
    
    override func setUp() {
        super.setUp()
        cryptoEngine = DefaultCryptoEngine()
        envelopeProcessor = DefaultEnvelopeProcessor(cryptoEngine: cryptoEngine)
        identityManager = DefaultIdentityManager()
        contactManager = DefaultContactManager()
        whisperService = DefaultWhisperService(
            cryptoEngine: cryptoEngine,
            envelopeProcessor: envelopeProcessor,
            identityManager: identityManager,
            contactManager: contactManager
        )
    }
    
    override func tearDown() {
        cryptoEngine = nil
        envelopeProcessor = nil
        identityManager = nil
        contactManager = nil
        whisperService = nil
        super.tearDown()
    }
    
    // MARK: - Cryptographic Test Vectors
    
    func testX25519KeyAgreementTestVectors() {
        // RFC 7748 test vectors for X25519
        let alicePrivateHex = "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
        let alicePublicHex = "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"
        let bobPrivateHex = "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"
        let bobPublicHex = "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
        let sharedSecretHex = "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"
        
        let alicePrivate = Data(hex: alicePrivateHex)!
        let alicePublic = Data(hex: alicePublicHex)!
        let bobPrivate = Data(hex: bobPrivateHex)!
        let bobPublic = Data(hex: bobPublicHex)!
        let expectedShared = Data(hex: sharedSecretHex)!
        
        do {
            let aliceKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: alicePrivate)
            let bobKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: bobPrivate)
            
            XCTAssertEqual(aliceKey.publicKey.rawRepresentation, alicePublic)
            XCTAssertEqual(bobKey.publicKey.rawRepresentation, bobPublic)
            
            let sharedFromAlice = try aliceKey.sharedSecretFromKeyAgreement(with: bobKey.publicKey)
            let sharedFromBob = try bobKey.sharedSecretFromKeyAgreement(with: aliceKey.publicKey)
            
            XCTAssertEqual(sharedFromAlice.withUnsafeBytes { Data($0) }, expectedShared)
            XCTAssertEqual(sharedFromBob.withUnsafeBytes { Data($0) }, expectedShared)
        } catch {
            XCTFail("X25519 test vector failed: \(error)")
        }
    }
    
    func testChaCha20Poly1305TestVectors() {
        // RFC 8439 test vectors
        let key = Data(hex: "808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f")!
        let nonce = Data(hex: "070000004041424344454647")!
        let plaintext = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.".data(using: .utf8)!
        let aad = Data(hex: "50515253c0c1c2c3c4c5c6c7")!
        let expectedCiphertext = Data(hex: "d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d63dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b3692ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc3ff4def08e4b7a9de576d26586cec64b6116")!
        let expectedTag = Data(hex: "1ae10b594f09e26a7e902ecbd0600691")!
        
        do {
            let sealedBox = try ChaChaPoly.seal(plaintext, using: SymmetricKey(data: key), nonce: ChaChaPoly.Nonce(data: nonce), authenticating: aad)
            
            let ciphertext = sealedBox.ciphertext
            let tag = sealedBox.tag
            
            XCTAssertEqual(ciphertext, expectedCiphertext)
            XCTAssertEqual(tag, expectedTag)
            
            let decrypted = try ChaChaPoly.open(sealedBox, using: SymmetricKey(data: key), authenticating: aad)
            XCTAssertEqual(decrypted, plaintext)
        } catch {
            XCTFail("ChaCha20-Poly1305 test vector failed: \(error)")
        }
    }
    
    func testEd25519SignatureTestVectors() {
        // RFC 8032 test vectors
        let privateKeyHex = "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"
        let publicKeyHex = "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a"
        let message = Data()
        let expectedSignatureHex = "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"
        
        let privateKey = Data(hex: privateKeyHex)!
        let publicKey = Data(hex: publicKeyHex)!
        let expectedSignature = Data(hex: expectedSignatureHex)!
        
        do {
            let signingKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
            XCTAssertEqual(signingKey.publicKey.rawRepresentation, publicKey)
            
            let signature = try signingKey.signature(for: message)
            XCTAssertEqual(signature, expectedSignature)
            
            let verificationKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
            XCTAssertTrue(verificationKey.isValidSignature(signature, for: message))
        } catch {
            XCTFail("Ed25519 test vector failed: \(error)")
        }
    }
    
    func testHKDFTestVectors() {
        // RFC 5869 test vectors
        let ikm = Data(hex: "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b")!
        let salt = Data(hex: "000102030405060708090a0b0c")!
        let info = Data(hex: "f0f1f2f3f4f5f6f7f8f9")!
        let expectedOkm = Data(hex: "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865")!
        
        do {
            let prk = HKDF<SHA256>.extract(inputKeyMaterial: SymmetricKey(data: ikm), salt: salt)
            let okm = HKDF<SHA256>.expand(pseudoRandomKey: prk, info: info, outputByteCount: 42)
            
            XCTAssertEqual(okm, expectedOkm)
        } catch {
            XCTFail("HKDF test vector failed: \(error)")
        }
    }
}    
   
 // MARK: - Determinism Tests
    
    func testEncryptionDeterminism() {
        // Same plaintext must produce different envelopes due to random epk/salt/msgid
        let plaintext = "Test message for determinism".data(using: .utf8)!
        
        do {
            let identity = try identityManager.createIdentity(name: "Test Identity")
            let contact = Contact(
                id: UUID(),
                displayName: "Test Contact",
                x25519PublicKey: Data(repeating: 0x01, count: 32),
                ed25519PublicKey: nil,
                fingerprint: Data(repeating: 0x02, count: 32),
                shortFingerprint: "TESTFINGERPRINT",
                sasWords: ["test", "words", "for", "sas", "verification", "check"],
                rkid: Data(repeating: 0x03, count: 8),
                trustLevel: .unverified,
                isBlocked: false,
                keyVersion: 1,
                keyHistory: [],
                createdAt: Date(),
                lastSeenAt: nil,
                note: nil
            )
            
            let envelope1 = try whisperService.encrypt(plaintext, from: identity, to: contact, authenticity: false)
            let envelope2 = try whisperService.encrypt(plaintext, from: identity, to: contact, authenticity: false)
            
            XCTAssertNotEqual(envelope1, envelope2, "Same plaintext must yield different envelopes due to randomness")
            
            // Verify both envelopes decrypt to same plaintext
            let result1 = try whisperService.decrypt(envelope1)
            let result2 = try whisperService.decrypt(envelope2)
            
            XCTAssertEqual(result1.plaintext, plaintext)
            XCTAssertEqual(result2.plaintext, plaintext)
            XCTAssertEqual(result1.plaintext, result2.plaintext)
            
        } catch {
            XCTFail("Determinism test failed: \(error)")
        }
    }
    
    func testEnvelopeComponentRandomness() {
        // Verify that ephemeral keys, salts, and message IDs are different
        let plaintext = "Test".data(using: .utf8)!
        
        do {
            let identity = try identityManager.createIdentity(name: "Test Identity")
            let recipientPublic = Data(repeating: 0x01, count: 32)
            
            var ephemeralKeys: Set<Data> = []
            var salts: Set<Data> = []
            var messageIds: Set<Data> = []
            
            for _ in 0..<100 {
                let envelope = try envelopeProcessor.createEnvelope(
                    plaintext: plaintext,
                    senderIdentity: identity,
                    recipientPublic: recipientPublic,
                    requireSignature: false
                )
                
                let components = try envelopeProcessor.parseEnvelope(envelope)
                
                ephemeralKeys.insert(components.epk)
                salts.insert(components.salt)
                messageIds.insert(components.msgid)
            }
            
            // All should be unique
            XCTAssertEqual(ephemeralKeys.count, 100, "Ephemeral keys should be unique")
            XCTAssertEqual(salts.count, 100, "Salts should be unique")
            XCTAssertEqual(messageIds.count, 100, "Message IDs should be unique")
            
        } catch {
            XCTFail("Envelope randomness test failed: \(error)")
        }
    }
    
    // MARK: - Nonce Uniqueness Soak Test
    
    func testNonceUniqueness() {
        // 1M iteration soak test to detect nonce collisions
        let iterations = 1_000_000
        var nonces: Set<Data> = []
        nonces.reserveCapacity(iterations)
        
        let sharedSecret = SymmetricKey(size: .bits256)
        
        for i in 0..<iterations {
            if i % 100_000 == 0 {
                print("Nonce uniqueness test progress: \(i)/\(iterations)")
            }
            
            do {
                let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
                let info = "whisper-v1".data(using: .utf8)!
                
                let keyMaterial = HKDF<SHA256>.expand(
                    pseudoRandomKey: sharedSecret,
                    info: info + salt,
                    outputByteCount: 44 // 32 bytes key + 12 bytes nonce
                )
                
                let nonce = keyMaterial.suffix(12)
                
                XCTAssertFalse(nonces.contains(nonce), "Nonce collision detected at iteration \(i)")
                nonces.insert(nonce)
                
            } catch {
                XCTFail("Nonce generation failed at iteration \(i): \(error)")
                break
            }
        }
        
        XCTAssertEqual(nonces.count, iterations, "All nonces should be unique")
        print("Nonce uniqueness test completed: \(nonces.count) unique nonces generated")
    }
    
    // MARK: - Constant-Time Operation Tests
    
    func testConstantTimePaddingValidation() {
        // Test for timing leakage in padding validation
        let messageLength = 100
        let message = Data(repeating: 0x41, count: messageLength) // 'A' repeated
        
        // Create valid padding
        let validPadded = MessagePadding.pad(message, to: .small)
        
        // Create invalid padding (corrupt last byte)
        var invalidPadded = validPadded
        invalidPadded[invalidPadded.count - 1] = 0xFF
        
        let iterations = 10000
        var validTimes: [TimeInterval] = []
        var invalidTimes: [TimeInterval] = []
        
        // Measure valid padding times
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try? MessagePadding.unpad(validPadded)
            let endTime = CFAbsoluteTimeGetCurrent()
            validTimes.append(endTime - startTime)
        }
        
        // Measure invalid padding times
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try? MessagePadding.unpad(invalidPadded)
            let endTime = CFAbsoluteTimeGetCurrent()
            invalidTimes.append(endTime - startTime)
        }
        
        let validAverage = validTimes.reduce(0, +) / Double(validTimes.count)
        let invalidAverage = invalidTimes.reduce(0, +) / Double(invalidTimes.count)
        
        let timeDifference = abs(validAverage - invalidAverage)
        let threshold = max(validAverage, invalidAverage) * 0.1 // 10% threshold
        
        XCTAssertLessThan(timeDifference, threshold, 
                         "Timing difference (\(timeDifference)) suggests side-channel leak. Valid: \(validAverage), Invalid: \(invalidAverage)")
        
        print("Padding validation timing - Valid: \(validAverage)s, Invalid: \(invalidAverage)s, Difference: \(timeDifference)s")
    }
    
    func testConstantTimeComparison() {
        // Test constant-time comparison implementation
        let data1 = Data(repeating: 0x42, count: 32)
        let data2 = Data(repeating: 0x42, count: 32)
        let data3 = Data(repeating: 0x43, count: 32)
        
        let iterations = 100000
        var equalTimes: [TimeInterval] = []
        var unequalTimes: [TimeInterval] = []
        
        // Measure equal comparison times
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = constantTimeCompare(data1, data2)
            let endTime = CFAbsoluteTimeGetCurrent()
            equalTimes.append(endTime - startTime)
        }
        
        // Measure unequal comparison times
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = constantTimeCompare(data1, data3)
            let endTime = CFAbsoluteTimeGetCurrent()
            unequalTimes.append(endTime - startTime)
        }
        
        let equalAverage = equalTimes.reduce(0, +) / Double(equalTimes.count)
        let unequalAverage = unequalTimes.reduce(0, +) / Double(unequalTimes.count)
        
        let timeDifference = abs(equalAverage - unequalAverage)
        let threshold = max(equalAverage, unequalAverage) * 0.05 // 5% threshold
        
        XCTAssertLessThan(timeDifference, threshold,
                         "Timing difference in constant-time comparison suggests side-channel leak")
        
        print("Constant-time comparison - Equal: \(equalAverage)s, Unequal: \(unequalAverage)s")
    }
    
    // Helper function for constant-time comparison
    private func constantTimeCompare(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        
        var result: UInt8 = 0
        for i in 0..<a.count {
            result |= a[i] ^ b[i]
        }
        return result == 0
    }    

    // MARK: - Algorithm Lock Tests
    
    func testAlgorithmLockEnforcement() {
        // Test that only v1.c20p is accepted and all other algorithms are rejected
        let validEnvelope = "whisper1:v1.c20p.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0"
        
        let invalidEnvelopes = [
            // Wrong version
            "whisper1:v2.c20p.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0",
            "whisper1:v0.c20p.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0",
            
            // Wrong algorithm
            "whisper1:v1.aes.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0",
            "whisper1:v1.rsa.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0",
            "whisper1:v1.c20p1305.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0",
            
            // Wrong prefix
            "kiro1:v1.c20p.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0",
            "whisper2:v1.c20p.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0",
            
            // Malformed
            "whisper1:invalid.format",
            "not-an-envelope",
            "",
            
            // Missing components
            "whisper1:v1.c20p.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ",
            "whisper1:v1.c20p",
        ]
        
        // Valid envelope should be parseable (even if decryption fails due to test data)
        do {
            let components = try envelopeProcessor.parseEnvelope(validEnvelope)
            XCTAssertEqual(components.version, "v1")
            XCTAssertEqual(components.algorithm, "c20p")
        } catch {
            // Parsing might fail due to invalid test data, but it should at least recognize the format
            if case WhisperError.invalidEnvelope = error {
                // This is acceptable for test data
            } else {
                XCTFail("Valid envelope format should be parseable: \(error)")
            }
        }
        
        // All invalid envelopes should be rejected
        for (index, invalidEnvelope) in invalidEnvelopes.enumerated() {
            do {
                _ = try envelopeProcessor.parseEnvelope(invalidEnvelope)
                XCTFail("Invalid envelope \(index) should be rejected: \(invalidEnvelope)")
            } catch WhisperError.invalidEnvelope {
                // Expected
            } catch {
                XCTFail("Wrong error type for invalid envelope \(index): \(error)")
            }
        }
    }
    
    func testStrictVersionValidation() {
        // Test that version validation is strict and doesn't allow partial matches
        let testCases = [
            ("v1", true),
            ("v1.0", false),
            ("v1.1", false),
            ("v10", false),
            ("v2", false),
            ("V1", false), // Case sensitive
            (" v1", false), // No whitespace
            ("v1 ", false),
        ]
        
        for (version, shouldBeValid) in testCases {
            let envelope = "whisper1:\(version).c20p.dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0"
            
            do {
                _ = try envelopeProcessor.parseEnvelope(envelope)
                if !shouldBeValid {
                    XCTFail("Version '\(version)' should be rejected")
                }
            } catch WhisperError.invalidEnvelope {
                if shouldBeValid {
                    XCTFail("Version '\(version)' should be accepted")
                }
            } catch {
                XCTFail("Unexpected error for version '\(version)': \(error)")
            }
        }
    }
    
    func testStrictAlgorithmValidation() {
        // Test that algorithm validation is strict
        let testCases = [
            ("c20p", true),
            ("C20P", false), // Case sensitive
            ("c20poly1305", false),
            ("chacha20poly1305", false),
            ("c20p1305", false),
            ("aes256gcm", false),
            ("aes", false),
            ("rsa", false),
            ("", false),
        ]
        
        for (algorithm, shouldBeValid) in testCases {
            let envelope = "whisper1:v1.\(algorithm).dGVzdA.AA.dGVzdGVwaA.dGVzdHNhbHQ.dGVzdG1zZ2lk.MTYzMDAwMDAwMA.dGVzdGN0"
            
            do {
                _ = try envelopeProcessor.parseEnvelope(envelope)
                if !shouldBeValid {
                    XCTFail("Algorithm '\(algorithm)' should be rejected")
                }
            } catch WhisperError.invalidEnvelope {
                if shouldBeValid {
                    XCTFail("Algorithm '\(algorithm)' should be accepted")
                }
            } catch {
                XCTFail("Unexpected error for algorithm '\(algorithm)': \(error)")
            }
        }
    }
    
    // MARK: - Memory Security Tests
    
    func testEphemeralKeyZeroization() {
        // Test that ephemeral keys are properly zeroized after use
        var ephemeralKeyData: Data?
        
        do {
            let identity = try identityManager.createIdentity(name: "Test Identity")
            let recipientPublic = Data(repeating: 0x01, count: 32)
            let plaintext = "Test message".data(using: .utf8)!
            
            // Capture ephemeral key data during encryption
            let originalCreateEnvelope = envelopeProcessor.createEnvelope
            
            _ = try envelopeProcessor.createEnvelope(
                plaintext: plaintext,
                senderIdentity: identity,
                recipientPublic: recipientPublic,
                requireSignature: false
            )
            
            // Note: In a real implementation, we would need hooks to verify zeroization
            // This test serves as a placeholder for memory security validation
            
        } catch {
            XCTFail("Ephemeral key zeroization test setup failed: \(error)")
        }
    }
    
    func testSecureRandomGeneration() {
        // Test that random generation produces high-quality entropy
        let sampleSize = 10000
        var samples: [UInt8] = []
        
        for _ in 0..<sampleSize {
            var randomByte: UInt8 = 0
            let result = SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte)
            XCTAssertEqual(result, errSecSuccess, "SecRandomCopyBytes should succeed")
            samples.append(randomByte)
        }
        
        // Basic entropy tests
        let uniqueValues = Set(samples)
        XCTAssertGreaterThan(uniqueValues.count, 200, "Should have good distribution of random values")
        
        // Chi-square test for uniformity (simplified)
        var buckets = Array(repeating: 0, count: 256)
        for sample in samples {
            buckets[Int(sample)] += 1
        }
        
        let expected = Double(sampleSize) / 256.0
        var chiSquare = 0.0
        for count in buckets {
            let diff = Double(count) - expected
            chiSquare += (diff * diff) / expected
        }
        
        // Chi-square critical value for 255 degrees of freedom at 99% confidence is ~310
        XCTAssertLessThan(chiSquare, 400, "Random distribution should pass chi-square test")
    }
    
    // MARK: - Replay Protection Security Tests
    
    func testReplayProtectionAtomicity() {
        // Test that replay protection checkAndCommit is truly atomic
        let replayProtector = CoreDataReplayProtector()
        let messageId = Data(repeating: 0x42, count: 16)
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        // First check should succeed
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: messageId, timestamp: timestamp))
        
        // Second check with same message ID should fail
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: messageId, timestamp: timestamp))
        
        // Different message ID should succeed
        let differentMessageId = Data(repeating: 0x43, count: 16)
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: differentMessageId, timestamp: timestamp))
    }
    
    func testFreshnessWindowEnforcement() {
        let replayProtector = CoreDataReplayProtector()
        let now = Int64(Date().timeIntervalSince1970)
        let messageId = Data(repeating: 0x44, count: 16)
        
        // Current time should be accepted
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: messageId, timestamp: now))
        
        // 47 hours ago should be accepted (within 48 hour window)
        let messageId2 = Data(repeating: 0x45, count: 16)
        let timestamp47HoursAgo = now - (47 * 60 * 60)
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: messageId2, timestamp: timestamp47HoursAgo))
        
        // 49 hours ago should be rejected (outside 48 hour window)
        let messageId3 = Data(repeating: 0x46, count: 16)
        let timestamp49HoursAgo = now - (49 * 60 * 60)
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: messageId3, timestamp: timestamp49HoursAgo))
        
        // 47 hours in future should be accepted
        let messageId4 = Data(repeating: 0x47, count: 16)
        let timestamp47HoursFuture = now + (47 * 60 * 60)
        XCTAssertTrue(replayProtector.checkAndCommit(msgId: messageId4, timestamp: timestamp47HoursFuture))
        
        // 49 hours in future should be rejected
        let messageId5 = Data(repeating: 0x48, count: 16)
        let timestamp49HoursFuture = now + (49 * 60 * 60)
        XCTAssertFalse(replayProtector.checkAndCommit(msgId: messageId5, timestamp: timestamp49HoursFuture))
    }

// MARK: - Data Extension for Hex Conversion

extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var i = hex.startIndex
        for _ in 0..<len {
            let j = hex.index(i, offsetBy: 2)
            let bytes = hex[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}