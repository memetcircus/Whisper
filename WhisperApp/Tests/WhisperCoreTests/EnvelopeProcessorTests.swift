import XCTest
@testable import WhisperApp
import CryptoKit

class EnvelopeProcessorTests: XCTestCase {
    
    var cryptoEngine: CryptoEngine!
    var envelopeProcessor: EnvelopeProcessor!
    var testIdentity: Identity!
    var recipientPublicKey: Data!
    
    override func setUp() {
        super.setUp()
        cryptoEngine = CryptoKitEngine()
        envelopeProcessor = WhisperEnvelopeProcessor(cryptoEngine: cryptoEngine)
        
        // Create test identity
        testIdentity = try! cryptoEngine.generateIdentity()
        
        // Generate recipient key pair
        let recipientPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        recipientPublicKey = recipientPrivateKey.publicKey.rawRepresentation
    }
    
    override func tearDown() {
        cryptoEngine = nil
        envelopeProcessor = nil
        testIdentity = nil
        recipientPublicKey = nil
        super.tearDown()
    }
    
    // MARK: - Envelope Creation Tests
    
    func testCreateEnvelopeWithoutSignature() throws {
        let plaintext = "Hello, World!".data(using: .utf8)!
        
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: false
        )
        
        // Verify envelope format
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
        
        // Parse and validate
        let components = try envelopeProcessor.parseEnvelope(envelope)
        XCTAssertEqual(components.version, "v1.c20p")
        XCTAssertFalse(components.hasSignature)
        XCTAssertNil(components.signature)
        XCTAssertEqual(components.rkid.count, 8)
        XCTAssertEqual(components.epk.count, 32)
        XCTAssertEqual(components.salt.count, 16)
        XCTAssertEqual(components.msgid.count, 16)
    }
    
    func testCreateEnvelopeWithSignature() throws {
        let plaintext = "Hello, World!".data(using: .utf8)!
        
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: true
        )
        
        // Parse and validate
        let components = try envelopeProcessor.parseEnvelope(envelope)
        XCTAssertEqual(components.version, "v1.c20p")
        XCTAssertTrue(components.hasSignature)
        XCTAssertNotNil(components.signature)
        XCTAssertEqual(components.signature?.count, 64)
    }
    
    func testEnvelopeDeterminism() throws {
        let plaintext = "Test message".data(using: .utf8)!
        
        let envelope1 = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: false
        )
        
        let envelope2 = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: false
        )
        
        // Same plaintext should produce different envelopes due to random epk/salt/msgid
        XCTAssertNotEqual(envelope1, envelope2)
    }
    
    // MARK: - Envelope Parsing Tests
    
    func testParseValidEnvelopeWithoutSignature() throws {
        let plaintext = "Test message".data(using: .utf8)!
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: false
        )
        
        let components = try envelopeProcessor.parseEnvelope(envelope)
        
        XCTAssertEqual(components.version, "v1.c20p")
        XCTAssertEqual(components.rkid.count, 8)
        XCTAssertEqual(components.epk.count, 32)
        XCTAssertEqual(components.salt.count, 16)
        XCTAssertEqual(components.msgid.count, 16)
        XCTAssertFalse(components.hasSignature)
        XCTAssertNil(components.signature)
    }
    
    func testParseValidEnvelopeWithSignature() throws {
        let plaintext = "Test message".data(using: .utf8)!
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: true
        )
        
        let components = try envelopeProcessor.parseEnvelope(envelope)
        
        XCTAssertEqual(components.version, "v1.c20p")
        XCTAssertTrue(components.hasSignature)
        XCTAssertNotNil(components.signature)
        XCTAssertEqual(components.signature?.count, 64)
    }
    
    func testParseInvalidPrefix() {
        let invalidEnvelope = "kiro1:v1.c20p.rkid.flags.epk.salt.msgid.ts.ct"
        
        XCTAssertThrowsError(try envelopeProcessor.parseEnvelope(invalidEnvelope)) { error in
            XCTAssertTrue(error is EnvelopeError)
            if case EnvelopeError.invalidFormat = error {
                // Expected error
            } else {
                XCTFail("Expected invalidFormat error")
            }
        }
    }
    
    func testParseInvalidComponentCount() {
        let invalidEnvelope = "whisper1:v1.c20p.rkid.flags.epk.salt.msgid" // Missing components
        
        XCTAssertThrowsError(try envelopeProcessor.parseEnvelope(invalidEnvelope)) { error in
            XCTAssertTrue(error is EnvelopeError)
        }
    }
    
    // MARK: - Algorithm Validation Tests
    
    func testStrictAlgorithmValidation() {
        let invalidAlgorithms = [
            "whisper1:v2.c20p.rkid.flags.epk.salt.msgid.ts.ct",
            "whisper1:v1.aes.rkid.flags.epk.salt.msgid.ts.ct",
            "whisper1:v1.c20p1.rkid.flags.epk.salt.msgid.ts.ct"
        ]
        
        for invalidEnvelope in invalidAlgorithms {
            XCTAssertThrowsError(try envelopeProcessor.parseEnvelope(invalidEnvelope)) { error in
                if case EnvelopeError.unsupportedAlgorithm(let algorithm) = error {
                    XCTAssertNotEqual(algorithm, "v1.c20p")
                } else {
                    XCTFail("Expected unsupportedAlgorithm error for \(invalidEnvelope)")
                }
            }
        }
    }
    
    func testValidAlgorithmAccepted() throws {
        let plaintext = "Test".data(using: .utf8)!
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: false
        )
        
        let components = try envelopeProcessor.parseEnvelope(envelope)
        XCTAssertEqual(components.version, "v1.c20p")
        
        // Should not throw
        XCTAssertTrue(try envelopeProcessor.validateEnvelope(components))
    }
    
    // MARK: - Base64URL Encoding Tests
    
    func testBase64URLEncoding() {
        let encoder = Base64URLEncoder()
        
        // Test basic encoding
        let testData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
        let encoded = encoder.encode(testData)
        
        // Should not contain padding or standard Base64 characters
        XCTAssertFalse(encoded.contains("="))
        XCTAssertFalse(encoded.contains("+"))
        XCTAssertFalse(encoded.contains("/"))
        
        // Should be decodable
        let decoded = try! encoder.decode(encoded)
        XCTAssertEqual(decoded, testData)
    }
    
    func testBase64URLDecoding() {
        let encoder = Base64URLEncoder()
        
        // Test with URL-safe characters
        let testString = "SGVsbG8gV29ybGQ" // "Hello World" without padding
        let decoded = try! encoder.decode(testString)
        let expected = "Hello World".data(using: .utf8)!
        XCTAssertEqual(decoded, expected)
    }
    
    func testBase64URLRoundTrip() {
        let encoder = Base64URLEncoder()
        let testData = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
        
        let encoded = encoder.encode(testData)
        let decoded = try! encoder.decode(encoded)
        
        XCTAssertEqual(decoded, testData)
    }
    
    // MARK: - Canonical Context Tests
    
    func testCanonicalContextBuilding() {
        let senderFingerprint = Data(repeating: 0x01, count: 32)
        let recipientFingerprint = Data(repeating: 0x02, count: 32)
        let rkid = Data(repeating: 0x03, count: 8)
        let epk = Data(repeating: 0x04, count: 32)
        let salt = Data(repeating: 0x05, count: 16)
        let msgid = Data(repeating: 0x06, count: 16)
        
        let context1 = envelopeProcessor.buildCanonicalContext(
            appId: "whisper",
            version: "v1",
            senderFingerprint: senderFingerprint,
            recipientFingerprint: recipientFingerprint,
            policyFlags: 0x01,
            rkid: rkid,
            epk: epk,
            salt: salt,
            msgid: msgid,
            ts: 1234567890
        )
        
        let context2 = envelopeProcessor.buildCanonicalContext(
            appId: "whisper",
            version: "v1",
            senderFingerprint: senderFingerprint,
            recipientFingerprint: recipientFingerprint,
            policyFlags: 0x01,
            rkid: rkid,
            epk: epk,
            salt: salt,
            msgid: msgid,
            ts: 1234567890
        )
        
        // Same inputs should produce identical context
        XCTAssertEqual(context1, context2)
        
        // Different inputs should produce different context
        let context3 = envelopeProcessor.buildCanonicalContext(
            appId: "whisper",
            version: "v1",
            senderFingerprint: senderFingerprint,
            recipientFingerprint: recipientFingerprint,
            policyFlags: 0x02, // Different flags
            rkid: rkid,
            epk: epk,
            salt: salt,
            msgid: msgid,
            ts: 1234567890
        )
        
        XCTAssertNotEqual(context1, context3)
    }
    
    // MARK: - Validation Tests
    
    func testValidateValidEnvelope() throws {
        let plaintext = "Test".data(using: .utf8)!
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: false
        )
        
        let components = try envelopeProcessor.parseEnvelope(envelope)
        XCTAssertTrue(try envelopeProcessor.validateEnvelope(components))
    }
    
    func testValidateInvalidComponentLengths() throws {
        let plaintext = "Test".data(using: .utf8)!
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: false
        )
        
        var components = try envelopeProcessor.parseEnvelope(envelope)
        
        // Test invalid rkid length
        components = EnvelopeComponents(
            version: components.version,
            rkid: Data(repeating: 0x00, count: 7), // Invalid length
            flags: components.flags,
            epk: components.epk,
            salt: components.salt,
            msgid: components.msgid,
            timestamp: components.timestamp,
            ciphertext: components.ciphertext,
            signature: components.signature
        )
        
        XCTAssertThrowsError(try envelopeProcessor.validateEnvelope(components)) { error in
            if case EnvelopeError.invalidRkidLength = error {
                // Expected
            } else {
                XCTFail("Expected invalidRkidLength error")
            }
        }
    }
    
    func testValidateTimestampRange() throws {
        let plaintext = "Test".data(using: .utf8)!
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: false
        )
        
        var components = try envelopeProcessor.parseEnvelope(envelope)
        
        // Set timestamp too far in the past
        let farPast = Int64(Date().timeIntervalSince1970) - (50 * 60 * 60) // 50 hours ago
        components = EnvelopeComponents(
            version: components.version,
            rkid: components.rkid,
            flags: components.flags,
            epk: components.epk,
            salt: components.salt,
            msgid: components.msgid,
            timestamp: farPast,
            ciphertext: components.ciphertext,
            signature: components.signature
        )
        
        XCTAssertThrowsError(try envelopeProcessor.validateEnvelope(components)) { error in
            if case EnvelopeError.timestampOutOfRange = error {
                // Expected
            } else {
                XCTFail("Expected timestampOutOfRange error")
            }
        }
    }
    
    func testValidateSignatureFlagConsistency() throws {
        let plaintext = "Test".data(using: .utf8)!
        let envelope = try envelopeProcessor.createEnvelope(
            plaintext: plaintext,
            senderIdentity: testIdentity,
            recipientPublic: recipientPublicKey,
            requireSignature: true
        )
        
        var components = try envelopeProcessor.parseEnvelope(envelope)
        
        // Remove signature but keep flag set
        components = EnvelopeComponents(
            version: components.version,
            rkid: components.rkid,
            flags: components.flags, // Still has signature flag
            epk: components.epk,
            salt: components.salt,
            msgid: components.msgid,
            timestamp: components.timestamp,
            ciphertext: components.ciphertext,
            signature: nil // But no signature
        )
        
        XCTAssertThrowsError(try envelopeProcessor.validateEnvelope(components)) { error in
            if case EnvelopeError.signatureFlagMismatch = error {
                // Expected
            } else {
                XCTFail("Expected signatureFlagMismatch error")
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessagesInRelease() {
        // In release builds, errors should show generic messages
        let error = EnvelopeError.invalidFormat
        
        #if DEBUG
        XCTAssertNotEqual(error.errorDescription, "Invalid envelope")
        #else
        XCTAssertEqual(error.errorDescription, "Invalid envelope")
        #endif
    }
    
    func testRecipientKeyIdGeneration() {
        let publicKey1 = Data(repeating: 0x01, count: 32)
        let publicKey2 = Data(repeating: 0x02, count: 32)
        
        let rkid1 = cryptoEngine.generateRecipientKeyId(x25519PublicKey: publicKey1)
        let rkid2 = cryptoEngine.generateRecipientKeyId(x25519PublicKey: publicKey2)
        
        // Should be 8 bytes
        XCTAssertEqual(rkid1.count, 8)
        XCTAssertEqual(rkid2.count, 8)
        
        // Different keys should produce different rkids
        XCTAssertNotEqual(rkid1, rkid2)
        
        // Same key should produce same rkid
        let rkid1_again = cryptoEngine.generateRecipientKeyId(x25519PublicKey: publicKey1)
        XCTAssertEqual(rkid1, rkid1_again)
    }
}