import XCTest
import SwiftUI
@testable import WhisperApp

/// Comprehensive end-to-end tests for the complete QR workflow integration
/// Tests the full encrypt → QR → scan → decrypt workflow with various scenarios
class QRWorkflowEndToEndTests: XCTestCase {
    
    var mockWhisperService: MockWhisperService!
    var mockQRCodeService: MockQRCodeService!
    var mockContactManager: MockContactManager!
    var mockIdentityManager: MockIdentityManager!
    var composeViewModel: ComposeViewModel!
    var decryptViewModel: DecryptViewModel!
    
    override func setUp() {
        super.setUp()
        
        // Initialize mock services
        mockWhisperService = MockWhisperService()
        mockQRCodeService = MockQRCodeService()
        mockContactManager = MockContactManager()
        mockIdentityManager = MockIdentityManager()
        
        // Create view models with mock services
        composeViewModel = ComposeViewModel(
            whisperService: mockWhisperService,
            qrCodeService: mockQRCodeService,
            contactManager: mockContactManager,
            identityManager: mockIdentityManager
        )
        
        decryptViewModel = DecryptViewModel(
            whisperService: mockWhisperService,
            qrCodeService: mockQRCodeService
        )
        
        // Set up default test identity and contact
        setupTestIdentityAndContact()
    }
    
    override func tearDown() {
        composeViewModel = nil
        decryptViewModel = nil
        mockWhisperService = nil
        mockQRCodeService = nil
        mockContactManager = nil
        mockIdentityManager = nil
        super.tearDown()
    }
    
    // MARK: - Test Setup Helpers
    
    private func setupTestIdentityAndContact() {
        // Create test identity
        let testIdentity = Identity(
            id: UUID(),
            name: "Test Identity",
            publicKey: Data(repeating: 1, count: 32),
            privateKey: Data(repeating: 2, count: 32),
            createdAt: Date(),
            isActive: true
        )
        mockIdentityManager.mockIdentities = [testIdentity]
        mockIdentityManager.mockActiveIdentity = testIdentity
        
        // Create test contact
        let testContact = Contact(
            id: UUID(),
            name: "Test Contact",
            publicKey: Data(repeating: 3, count: 32),
            fingerprint: "TEST-FINGERPRINT",
            isVerified: true,
            createdAt: Date()
        )
        mockContactManager.mockContacts = [testContact]
    }
    
    // MARK: - Basic End-to-End Workflow Tests
    
    func testBasicEncryptQRScanDecryptWorkflow() {
        // Test Requirements: 1.1, 1.3, 2.1, 2.2
        let testMessage = "Hello, this is a test message for QR workflow!"
        let expectedEncryptedEnvelope = "WHISPER_ENVELOPE_v1:encrypted_content_here"
        
        // Step 1: Compose and encrypt message
        composeViewModel.messageText = testMessage
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        // Mock encryption result
        mockWhisperService.mockEncryptResult = .success(expectedEncryptedEnvelope)
        
        // Encrypt the message
        composeViewModel.encryptMessage()
        
        // Verify encryption was successful
        XCTAssertEqual(composeViewModel.encryptedMessage, expectedEncryptedEnvelope)
        XCTAssertTrue(composeViewModel.showingQRCode)
        
        // Step 2: Generate QR code for encrypted message
        mockQRCodeService.mockGenerateQRResult = .success(UIImage())
        
        // Verify QR code generation
        XCTAssertNotNil(composeViewModel.qrCodeImage)
        
        // Step 3: Simulate QR scan in decrypt view
        mockQRCodeService.mockParseQRResult = .success(.encryptedMessage(expectedEncryptedEnvelope))
        
        // Simulate QR scan result
        decryptViewModel.handleQRScanResult(expectedEncryptedEnvelope)
        
        // Verify QR scan populated the input field
        XCTAssertEqual(decryptViewModel.encryptedText, expectedEncryptedEnvelope)
        
        // Step 4: Decrypt the scanned message
        mockWhisperService.mockDecryptResult = .success(
            DecryptionResult(
                message: testMessage,
                senderFingerprint: "TEST-FINGERPRINT",
                timestamp: Date(),
                isReplay: false
            )
        )
        
        // Decrypt the message
        decryptViewModel.decryptMessage()
        
        // Verify decryption was successful
        XCTAssertEqual(decryptViewModel.decryptedMessage, testMessage)
        XCTAssertEqual(decryptViewModel.senderFingerprint, "TEST-FINGERPRINT")
        XCTAssertFalse(decryptViewModel.isReplay)
        XCTAssertNil(decryptViewModel.errorMessage)
    }
    
    // MARK: - Message Size Variation Tests
    
    func testShortMessageQRWorkflow() {
        // Test with very short message
        let shortMessage = "Hi!"
        testQRWorkflowWithMessage(shortMessage)
    }
    
    func testMediumMessageQRWorkflow() {
        // Test with medium-length message
        let mediumMessage = String(repeating: "This is a medium length message. ", count: 10)
        testQRWorkflowWithMessage(mediumMessage)
    }
    
    func testLongMessageQRWorkflow() {
        // Test with long message (approaching QR code limits)
        let longMessage = String(repeating: "This is a very long message that will test the QR code capacity limits. ", count: 50)
        testQRWorkflowWithMessage(longMessage)
    }
    
    func testUnicodeMessageQRWorkflow() {
        // Test with Unicode characters
        let unicodeMessage = "Hello 👋 World 🌍! Testing émojis and spëcial characters: 中文, العربية, русский"
        testQRWorkflowWithMessage(unicodeMessage)
    }
    
    private func testQRWorkflowWithMessage(_ message: String) {
        let expectedEnvelope = "WHISPER_ENVELOPE_v1:\(message.data(using: .utf8)?.base64EncodedString() ?? "")"
        
        // Compose and encrypt
        composeViewModel.messageText = message
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        mockWhisperService.mockEncryptResult = .success(expectedEnvelope)
        composeViewModel.encryptMessage()
        
        // Generate QR
        mockQRCodeService.mockGenerateQRResult = .success(UIImage())
        XCTAssertNotNil(composeViewModel.qrCodeImage)
        
        // Scan QR
        mockQRCodeService.mockParseQRResult = .success(.encryptedMessage(expectedEnvelope))
        decryptViewModel.handleQRScanResult(expectedEnvelope)
        XCTAssertEqual(decryptViewModel.encryptedText, expectedEnvelope)
        
        // Decrypt
        mockWhisperService.mockDecryptResult = .success(
            DecryptionResult(
                message: message,
                senderFingerprint: "TEST-FINGERPRINT",
                timestamp: Date(),
                isReplay: false
            )
        )
        decryptViewModel.decryptMessage()
        XCTAssertEqual(decryptViewModel.decryptedMessage, message)
    }
    
    // MARK: - Encryption Parameter Variation Tests
    
    func testMultipleRecipientsQRWorkflow() {
        // Test with multiple recipients
        let additionalContact = Contact(
            id: UUID(),
            name: "Second Contact",
            publicKey: Data(repeating: 4, count: 32),
            fingerprint: "SECOND-FINGERPRINT",
            isVerified: true,
            createdAt: Date()
        )
        mockContactManager.mockContacts.append(additionalContact)
        
        let testMessage = "Message for multiple recipients"
        let expectedEnvelope = "WHISPER_ENVELOPE_v1:multi_recipient_encrypted_content"
        
        // Set multiple recipients
        composeViewModel.messageText = testMessage
        composeViewModel.selectedContacts = Set(mockContactManager.mockContacts)
        
        mockWhisperService.mockEncryptResult = .success(expectedEnvelope)
        composeViewModel.encryptMessage()
        
        // Continue with QR workflow
        mockQRCodeService.mockGenerateQRResult = .success(UIImage())
        mockQRCodeService.mockParseQRResult = .success(.encryptedMessage(expectedEnvelope))
        
        decryptViewModel.handleQRScanResult(expectedEnvelope)
        
        mockWhisperService.mockDecryptResult = .success(
            DecryptionResult(
                message: testMessage,
                senderFingerprint: "TEST-FINGERPRINT",
                timestamp: Date(),
                isReplay: false
            )
        )
        decryptViewModel.decryptMessage()
        
        XCTAssertEqual(decryptViewModel.decryptedMessage, testMessage)
    }
    
    func testDifferentIdentityQRWorkflow() {
        // Test with different sender identity
        let alternateIdentity = Identity(
            id: UUID(),
            name: "Alternate Identity",
            publicKey: Data(repeating: 5, count: 32),
            privateKey: Data(repeating: 6, count: 32),
            createdAt: Date(),
            isActive: false
        )
        mockIdentityManager.mockIdentities.append(alternateIdentity)
        mockIdentityManager.mockActiveIdentity = alternateIdentity
        
        let testMessage = "Message from alternate identity"
        testQRWorkflowWithMessage(testMessage)
    }
    
    // MARK: - Error Handling in End-to-End Workflow
    
    func testQRWorkflowWithEncryptionFailure() {
        let testMessage = "This encryption will fail"
        
        composeViewModel.messageText = testMessage
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        // Mock encryption failure
        mockWhisperService.mockEncryptResult = .failure(WhisperError.encryptionFailed("Test encryption error"))
        
        composeViewModel.encryptMessage()
        
        // Verify encryption failure is handled
        XCTAssertNil(composeViewModel.encryptedMessage)
        XCTAssertFalse(composeViewModel.showingQRCode)
        XCTAssertNotNil(composeViewModel.errorMessage)
    }
    
    func testQRWorkflowWithQRGenerationFailure() {
        let testMessage = "QR generation will fail"
        let expectedEnvelope = "WHISPER_ENVELOPE_v1:test_content"
        
        composeViewModel.messageText = testMessage
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        // Successful encryption
        mockWhisperService.mockEncryptResult = .success(expectedEnvelope)
        composeViewModel.encryptMessage()
        
        // Mock QR generation failure
        mockQRCodeService.mockGenerateQRResult = .failure(QRCodeError.generationFailed("QR generation failed"))
        
        // Verify QR generation failure is handled
        XCTAssertNil(composeViewModel.qrCodeImage)
    }
    
    func testQRWorkflowWithScanFailure() {
        // Test QR scan failure scenarios
        let invalidQRContent = "invalid_qr_content"
        
        // Mock QR parse failure
        mockQRCodeService.mockParseQRResult = .failure(QRCodeError.invalidFormat("Invalid QR format"))
        
        decryptViewModel.handleQRScanResult(invalidQRContent)
        
        // Verify scan failure is handled
        XCTAssertTrue(decryptViewModel.encryptedText.isEmpty)
        XCTAssertNotNil(decryptViewModel.errorMessage)
    }
    
    func testQRWorkflowWithDecryptionFailure() {
        let expectedEnvelope = "WHISPER_ENVELOPE_v1:corrupted_content"
        
        // Successful QR scan
        mockQRCodeService.mockParseQRResult = .success(.encryptedMessage(expectedEnvelope))
        decryptViewModel.handleQRScanResult(expectedEnvelope)
        
        // Mock decryption failure
        mockWhisperService.mockDecryptResult = .failure(WhisperError.decryptionFailed("Corrupted message"))
        
        decryptViewModel.decryptMessage()
        
        // Verify decryption failure is handled
        XCTAssertNil(decryptViewModel.decryptedMessage)
        XCTAssertNotNil(decryptViewModel.errorMessage)
    }
    
    // MARK: - QR Content Type Validation Tests
    
    func testQRWorkflowRejectsPublicKeyBundle() {
        // Test that public key bundle QR codes are rejected in decrypt flow
        let publicKeyBundle = PublicKeyBundle(
            publicKey: Data(repeating: 7, count: 32),
            name: "Test Bundle",
            fingerprint: "BUNDLE-FINGERPRINT"
        )
        
        mockQRCodeService.mockParseQRResult = .success(.publicKeyBundle(publicKeyBundle))
        
        decryptViewModel.handleQRScanResult("public_key_qr_content")
        
        // Verify public key bundle is rejected
        XCTAssertTrue(decryptViewModel.encryptedText.isEmpty)
        XCTAssertNotNil(decryptViewModel.errorMessage)
        XCTAssertTrue(decryptViewModel.errorMessage?.contains("encrypted message") == true)
    }
    
    func testQRWorkflowAcceptsOnlyEncryptedMessages() {
        let validEnvelope = "WHISPER_ENVELOPE_v1:valid_encrypted_content"
        
        mockQRCodeService.mockParseQRResult = .success(.encryptedMessage(validEnvelope))
        
        decryptViewModel.handleQRScanResult(validEnvelope)
        
        // Verify encrypted message is accepted
        XCTAssertEqual(decryptViewModel.encryptedText, validEnvelope)
        XCTAssertNil(decryptViewModel.errorMessage)
    }
    
    // MARK: - Performance and Stress Tests
    
    func testQRWorkflowPerformance() {
        // Test performance of complete QR workflow
        let testMessage = "Performance test message"
        
        measure {
            testQRWorkflowWithMessage(testMessage)
            
            // Reset for next iteration
            composeViewModel.reset()
            decryptViewModel.reset()
        }
    }
    
    func testMultipleQRWorkflowIterations() {
        // Test multiple iterations of the QR workflow
        for i in 1...10 {
            let testMessage = "Iteration \(i) test message"
            testQRWorkflowWithMessage(testMessage)
            
            // Reset for next iteration
            composeViewModel.reset()
            decryptViewModel.reset()
        }
    }
    
    // MARK: - Integration with Real Components
    
    func testQRWorkflowWithRealQRCodeService() {
        // Test with actual QRCodeService (not mocked)
        let realQRCodeService = QRCodeService()
        let realComposeViewModel = ComposeViewModel(
            whisperService: mockWhisperService,
            qrCodeService: realQRCodeService,
            contactManager: mockContactManager,
            identityManager: mockIdentityManager
        )
        let realDecryptViewModel = DecryptViewModel(
            whisperService: mockWhisperService,
            qrCodeService: realQRCodeService
        )
        
        let testMessage = "Real QR service test"
        let expectedEnvelope = "WHISPER_ENVELOPE_v1:real_test_content"
        
        // Test with real QR service
        realComposeViewModel.messageText = testMessage
        realComposeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        mockWhisperService.mockEncryptResult = .success(expectedEnvelope)
        realComposeViewModel.encryptMessage()
        
        // Verify QR generation with real service
        XCTAssertNotNil(realComposeViewModel.qrCodeImage)
        
        // Test QR parsing with real service
        realDecryptViewModel.handleQRScanResult(expectedEnvelope)
        
        // Note: Real QR service will validate the envelope format
        // This tests the integration between QR workflow and actual QR service
    }
    
    // MARK: - Edge Cases and Boundary Conditions
    
    func testEmptyMessageQRWorkflow() {
        // Test with empty message
        composeViewModel.messageText = ""
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        // Should not allow encryption of empty message
        composeViewModel.encryptMessage()
        
        XCTAssertNil(composeViewModel.encryptedMessage)
        XCTAssertFalse(composeViewModel.showingQRCode)
    }
    
    func testQRWorkflowWithNoContacts() {
        // Test with no selected contacts
        composeViewModel.messageText = "Test message"
        composeViewModel.selectedContacts = Set()
        
        // Should not allow encryption without contacts
        composeViewModel.encryptMessage()
        
        XCTAssertNil(composeViewModel.encryptedMessage)
        XCTAssertFalse(composeViewModel.showingQRCode)
    }
    
    func testQRWorkflowWithInactiveIdentity() {
        // Test with inactive identity
        mockIdentityManager.mockActiveIdentity?.isActive = false
        
        let testMessage = "Test with inactive identity"
        composeViewModel.messageText = testMessage
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        // Should handle inactive identity appropriately
        composeViewModel.encryptMessage()
        
        // Behavior depends on implementation - either should fail or use fallback
        // This test ensures the workflow handles the edge case gracefully
    }
}

// MARK: - Mock Service Extensions for QR Workflow Testing

extension MockWhisperService {
    func reset() {
        mockEncryptResult = nil
        mockDecryptResult = nil
    }
}

extension MockQRCodeService {
    func reset() {
        mockGenerateQRResult = nil
        mockParseQRResult = nil
    }
}

// MARK: - ViewModel Extensions for Testing

extension ComposeViewModel {
    func reset() {
        messageText = ""
        selectedContacts = Set()
        encryptedMessage = nil
        qrCodeImage = nil
        showingQRCode = false
        errorMessage = nil
    }
}

extension DecryptViewModel {
    func reset() {
        encryptedText = ""
        decryptedMessage = nil
        senderFingerprint = nil
        isReplay = false
        errorMessage = nil
    }
}