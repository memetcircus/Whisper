import XCTest
@testable import WhisperApp

/// Tests for QR code generation and parsing functionality
/// Validates QR code creation, size warnings, and content parsing
class QRCodeServiceTests: XCTestCase {
    
    var qrService: QRCodeService!
    
    override func setUp() {
        super.setUp()
        qrService = QRCodeService()
    }
    
    override func tearDown() {
        qrService = nil
        super.tearDown()
    }
    
    // MARK: - QR Code Generation Tests
    
    func testGenerateQRCodeForPublicKeyBundle() throws {
        // Given
        let bundle = createSamplePublicKeyBundle()
        
        // When
        let result = try qrService.generateQRCode(for: bundle)
        
        // Then
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.type, .publicKeyBundle)
        XCTAssertTrue(result.content.hasPrefix("whisper-bundle:"))
        
        // Verify the content can be decoded back
        let parsedContent = try qrService.parseQRCode(result.content)
        if case .publicKeyBundle(let parsedBundle) = parsedContent {
            XCTAssertEqual(parsedBundle.name, bundle.name)
            XCTAssertEqual(parsedBundle.x25519PublicKey, bundle.x25519PublicKey)
            XCTAssertEqual(parsedBundle.ed25519PublicKey, bundle.ed25519PublicKey)
        } else {
            XCTFail("Expected public key bundle content")
        }
    }
    
    func testGenerateQRCodeForEncryptedMessage() throws {
        // Given
        let envelope = "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT.SIGNATURE"
        
        // When
        let result = try qrService.generateQRCode(for: envelope)
        
        // Then
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.type, .encryptedMessage)
        XCTAssertEqual(result.content, envelope)
    }
    
    func testGenerateQRCodeForContact() throws {
        // Given
        let contact = try createSampleContact()
        
        // When
        let result = try qrService.generateQRCode(for: contact)
        
        // Then
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.type, .publicKeyBundle)
        XCTAssertTrue(result.content.hasPrefix("whisper-bundle:"))
    }
    
    func testQRCodeSizeWarning() throws {
        // Given - Create a large bundle that exceeds recommended size
        let largeBundle = createLargePublicKeyBundle()
        
        // When
        let result = try qrService.generateQRCode(for: largeBundle)
        
        // Then
        XCTAssertNotNil(result.sizeWarning)
        XCTAssertGreaterThan(result.sizeWarning!.actualSize, QRCodeService.maxRecommendedSize)
        XCTAssertEqual(result.sizeWarning!.recommendedSize, QRCodeService.maxRecommendedSize)
    }
    
    func testQRCodeNoSizeWarningForSmallContent() throws {
        // Given
        let smallBundle = createSamplePublicKeyBundle()
        
        // When
        let result = try qrService.generateQRCode(for: smallBundle)
        
        // Then
        XCTAssertNil(result.sizeWarning)
    }
    
    // MARK: - QR Code Parsing Tests
    
    func testParsePublicKeyBundleQRCode() throws {
        // Given
        let bundle = createSamplePublicKeyBundle()
        let bundleData = try JSONEncoder().encode(bundle)
        let bundleString = bundleData.base64EncodedString()
        let qrContent = "whisper-bundle:\(bundleString)"
        
        // When
        let parsedContent = try qrService.parseQRCode(qrContent)
        
        // Then
        if case .publicKeyBundle(let parsedBundle) = parsedContent {
            XCTAssertEqual(parsedBundle.name, bundle.name)
            XCTAssertEqual(parsedBundle.x25519PublicKey, bundle.x25519PublicKey)
            XCTAssertEqual(parsedBundle.ed25519PublicKey, bundle.ed25519PublicKey)
        } else {
            XCTFail("Expected public key bundle content")
        }
    }
    
    func testParseEncryptedMessageQRCode() throws {
        // Given
        let envelope = "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT"
        
        // When
        let parsedContent = try qrService.parseQRCode(envelope)
        
        // Then
        if case .encryptedMessage(let parsedEnvelope) = parsedContent {
            XCTAssertEqual(parsedEnvelope, envelope)
        } else {
            XCTFail("Expected encrypted message content")
        }
    }
    
    func testParseInvalidQRCodeThrowsError() {
        // Given
        let invalidContent = "invalid-qr-content"
        
        // When & Then
        XCTAssertThrowsError(try qrService.parseQRCode(invalidContent)) { error in
            XCTAssertEqual(error as? QRCodeError, .unsupportedFormat)
        }
    }
    
    func testParseInvalidBundleDataThrowsError() {
        // Given
        let invalidBundleContent = "whisper-bundle:invalid-base64-data"
        
        // When & Then
        XCTAssertThrowsError(try qrService.parseQRCode(invalidBundleContent)) { error in
            XCTAssertEqual(error as? QRCodeError, .invalidBundleData)
        }
    }
    
    func testParseInvalidEnvelopeFormatThrowsError() {
        // Given
        let invalidEnvelope = "whisper1:invalid.format"
        
        // When & Then
        XCTAssertThrowsError(try qrService.parseQRCode(invalidEnvelope)) { error in
            XCTAssertEqual(error as? QRCodeError, .invalidEnvelopeFormat)
        }
    }
    
    // MARK: - Camera Permission Tests
    
    func testCheckCameraPermission() {
        // When
        let status = qrService.checkCameraPermission()
        
        // Then
        // We can't control the actual permission status in tests,
        // but we can verify the method returns a valid status
        XCTAssertTrue([.authorized, .denied, .restricted, .notDetermined].contains(status))
    }
    
    // MARK: - Error Handling Tests
    
    func testGenerateQRCodeWithInvalidEnvelopeThrowsError() {
        // Given
        let invalidEnvelope = "not-a-whisper-envelope"
        
        // When & Then
        XCTAssertThrowsError(try qrService.generateQRCode(for: invalidEnvelope)) { error in
            XCTAssertEqual(error as? QRCodeError, .invalidEnvelopeFormat)
        }
    }
    
    // MARK: - Integration Tests
    
    func testRoundTripPublicKeyBundle() throws {
        // Given
        let originalBundle = createSamplePublicKeyBundle()
        
        // When - Generate QR code and parse it back
        let qrResult = try qrService.generateQRCode(for: originalBundle)
        let parsedContent = try qrService.parseQRCode(qrResult.content)
        
        // Then
        if case .publicKeyBundle(let parsedBundle) = parsedContent {
            XCTAssertEqual(parsedBundle.name, originalBundle.name)
            XCTAssertEqual(parsedBundle.x25519PublicKey, originalBundle.x25519PublicKey)
            XCTAssertEqual(parsedBundle.ed25519PublicKey, originalBundle.ed25519PublicKey)
            XCTAssertEqual(parsedBundle.fingerprint, originalBundle.fingerprint)
            XCTAssertEqual(parsedBundle.keyVersion, originalBundle.keyVersion)
        } else {
            XCTFail("Expected public key bundle content")
        }
    }
    
    func testRoundTripEncryptedMessage() throws {
        // Given
        let originalEnvelope = "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT.SIGNATURE"
        
        // When - Generate QR code and parse it back
        let qrResult = try qrService.generateQRCode(for: originalEnvelope)
        let parsedContent = try qrService.parseQRCode(qrResult.content)
        
        // Then
        if case .encryptedMessage(let parsedEnvelope) = parsedContent {
            XCTAssertEqual(parsedEnvelope, originalEnvelope)
        } else {
            XCTFail("Expected encrypted message content")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSamplePublicKeyBundle() -> PublicKeyBundle {
        return PublicKeyBundle(
            id: UUID(),
            name: "Test Contact",
            x25519PublicKey: Data(repeating: 0x01, count: 32),
            ed25519PublicKey: Data(repeating: 0x02, count: 32),
            fingerprint: Data(repeating: 0x03, count: 32),
            keyVersion: 1,
            createdAt: Date()
        )
    }
    
    private func createLargePublicKeyBundle() -> PublicKeyBundle {
        // Create a bundle with a very long name to exceed size limits
        let longName = String(repeating: "A", count: 1000)
        return PublicKeyBundle(
            id: UUID(),
            name: longName,
            x25519PublicKey: Data(repeating: 0x01, count: 32),
            ed25519PublicKey: Data(repeating: 0x02, count: 32),
            fingerprint: Data(repeating: 0x03, count: 32),
            keyVersion: 1,
            createdAt: Date()
        )
    }
    
    private func createSampleContact() throws -> Contact {
        return try Contact(
            displayName: "Test Contact",
            x25519PublicKey: Data(repeating: 0x01, count: 32),
            ed25519PublicKey: Data(repeating: 0x02, count: 32),
            note: "Test note"
        )
    }
}

// MARK: - QRCodeError Equatable Extension

extension QRCodeError: Equatable {
    public static func == (lhs: QRCodeError, rhs: QRCodeError) -> Bool {
        switch (lhs, rhs) {
        case (.generationFailed(let lhsReason), .generationFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.invalidEnvelopeFormat, .invalidEnvelopeFormat),
             (.invalidBundleData, .invalidBundleData),
             (.unsupportedFormat, .unsupportedFormat),
             (.scanningNotAvailable, .scanningNotAvailable),
             (.cameraPermissionDenied, .cameraPermissionDenied):
            return true
        case (.invalidBundleFormat, .invalidBundleFormat):
            return true // We can't easily compare the underlying errors
        default:
            return false
        }
    }
}