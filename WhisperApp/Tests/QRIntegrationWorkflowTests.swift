import XCTest
import SwiftUI
@testable import WhisperApp

/// Integration tests for QR code workflow between compose and decrypt views
/// Focuses on the actual QR code generation, encoding, and scanning integration
class QRIntegrationWorkflowTests: XCTestCase {
    
    var composeViewModel: ComposeViewModel!
    var decryptViewModel: DecryptViewModel!
    var qrCodeService: QRCodeService!
    var mockWhisperService: MockWhisperService!
    var mockContactManager: MockContactManager!
    var mockIdentityManager: MockIdentityManager!
    
    override func setUp() {
        super.setUp()
        
        // Use real QR code service for integration testing
        qrCodeService = QRCodeService()
        mockWhisperService = MockWhisperService()
        mockContactManager = MockContactManager()
        mockIdentityManager = MockIdentityManager()
        
        // Create view models with real QR service
        composeViewModel = ComposeViewModel(
            whisperService: mockWhisperService,
            qrCodeService: qrCodeService,
            contactManager: mockContactManager,
            identityManager: mockIdentityManager
        )
        
        decryptViewModel = DecryptViewModel(
            whisperService: mockWhisperService,
            qrCodeService: qrCodeService
        )
        
        setupTestData()
    }
    
    override func tearDown() {
        composeViewModel = nil
        decryptViewModel = nil
        qrCodeService = nil
        mockWhisperService = nil
        mockContactManager = nil
        mockIdentityManager = nil
        super.tearDown()
    }
    
    private func setupTestData() {
        // Create test identity
        let testIdentity = Identity(
            id: UUID(),
            name: "Integration Test Identity",
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
            name: "Integration Test Contact",
            publicKey: Data(repeating: 3, count: 32),
            fingerprint: "INTEGRATION-TEST-FINGERPRINT",
            isVerified: true,
            createdAt: Date()
        )
        mockContactManager.mockContacts = [testContact]
    }
    
    // MARK: - Real QR Code Generation and Parsing Tests
    
    func testRealQRCodeGenerationAndParsing() {
        // Test Requirements: 1.1, 1.3, 2.1, 2.2
        let testMessage = "Integration test message for real QR workflow"
        let testEnvelope = "WHISPER_ENVELOPE_v1:dGVzdCBlbmNyeXB0ZWQgY29udGVudA=="
        
        // Step 1: Generate encrypted message
        composeViewModel.messageText = testMessage
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        mockWhisperService.mockEncryptResult = .success(testEnvelope)
        composeViewModel.encryptMessage()
        
        // Verify encryption succeeded
        XCTAssertEqual(composeViewModel.encryptedMessage, testEnvelope)
        XCTAssertTrue(composeViewModel.showingQRCode)
        
        // Step 2: Generate actual QR code image
        let expectation = XCTestExpectation(description: "QR code generation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // QR code should be generated
            XCTAssertNotNil(self.composeViewModel.qrCodeImage)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Step 3: Simulate scanning the generated QR code
        // In a real scenario, this would involve camera scanning
        // Here we simulate the QR content being parsed
        decryptViewModel.handleQRScanResult(testEnvelope)
        
        // Verify the scanned content is properly handled
        XCTAssertEqual(decryptViewModel.encryptedText, testEnvelope)
        XCTAssertNil(decryptViewModel.errorMessage)
        
        // Step 4: Decrypt the scanned message
        mockWhisperService.mockDecryptResult = .success(
            DecryptionResult(
                message: testMessage,
                senderFingerprint: "INTEGRATION-TEST-FINGERPRINT",
                timestamp: Date(),
                isReplay: false
            )
        )
        
        decryptViewModel.decryptMessage()
        
        // Verify complete workflow
        XCTAssertEqual(decryptViewModel.decryptedMessage, testMessage)
        XCTAssertEqual(decryptViewModel.senderFingerprint, "INTEGRATION-TEST-FINGERPRINT")
    }
    
    func testQRCodeWithVariousEnvelopeFormats() {
        // Test different envelope formats that might be generated
        let testCases = [
            "WHISPER_ENVELOPE_v1:c2hvcnQ=", // "short" in base64
            "WHISPER_ENVELOPE_v1:bG9uZ2VyIG1lc3NhZ2Ugd2l0aCBtb3JlIGNvbnRlbnQ=", // longer message
            "WHISPER_ENVELOPE_v1:8J+YgCBVbmljb2RlIHRlc3Qg8J+MjfCfkY0=", // Unicode content
        ]
        
        for (index, envelope) in testCases.enumerated() {
            let testMessage = "Test message \(index + 1)"
            
            // Generate QR for envelope
            composeViewModel.messageText = testMessage
            composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
            
            mockWhisperService.mockEncryptResult = .success(envelope)
            composeViewModel.encryptMessage()
            
            // Verify QR generation
            XCTAssertNotNil(composeViewModel.qrCodeImage, "QR generation failed for envelope \(index + 1)")
            
            // Test scanning
            decryptViewModel.handleQRScanResult(envelope)
            XCTAssertEqual(decryptViewModel.encryptedText, envelope, "QR scan failed for envelope \(index + 1)")
            
            // Reset for next test
            composeViewModel.reset()
            decryptViewModel.reset()
        }
    }
    
    // MARK: - QR Code Size and Capacity Tests
    
    func testQRCodeWithMaximumCapacity() {
        // Test QR code generation with maximum data capacity
        let largeMessage = String(repeating: "Large message content for QR capacity testing. ", count: 100)
        let largeEnvelope = "WHISPER_ENVELOPE_v1:\(largeMessage.data(using: .utf8)?.base64EncodedString() ?? "")"
        
        composeViewModel.messageText = largeMessage
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        mockWhisperService.mockEncryptResult = .success(largeEnvelope)
        composeViewModel.encryptMessage()
        
        // Verify QR generation handles large content
        let expectation = XCTestExpectation(description: "Large QR code generation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Should either generate QR or fail gracefully
            if self.composeViewModel.qrCodeImage != nil {
                // QR generated successfully
                XCTAssertNotNil(self.composeViewModel.qrCodeImage)
            } else {
                // Should have appropriate error handling for oversized content
                XCTAssertNotNil(self.composeViewModel.errorMessage)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testQRCodeWithMinimalContent() {
        // Test QR code with minimal valid envelope
        let minimalEnvelope = "WHISPER_ENVELOPE_v1:dGVzdA==" // "test" in base64
        
        composeViewModel.messageText = "test"
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        mockWhisperService.mockEncryptResult = .success(minimalEnvelope)
        composeViewModel.encryptMessage()
        
        // Verify minimal QR generation
        XCTAssertNotNil(composeViewModel.qrCodeImage)
        
        // Test scanning minimal QR
        decryptViewModel.handleQRScanResult(minimalEnvelope)
        XCTAssertEqual(decryptViewModel.encryptedText, minimalEnvelope)
    }
    
    // MARK: - QR Code Error Correction and Robustness Tests
    
    func testQRCodeWithSpecialCharacters() {
        // Test QR codes containing special characters and encoding
        let specialMessage = "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        let specialEnvelope = "WHISPER_ENVELOPE_v1:\(specialMessage.data(using: .utf8)?.base64EncodedString() ?? "")"
        
        composeViewModel.messageText = specialMessage
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        mockWhisperService.mockEncryptResult = .success(specialEnvelope)
        composeViewModel.encryptMessage()
        
        // Verify QR handles special characters
        XCTAssertNotNil(composeViewModel.qrCodeImage)
        
        // Test scanning with special characters
        decryptViewModel.handleQRScanResult(specialEnvelope)
        XCTAssertEqual(decryptViewModel.encryptedText, specialEnvelope)
    }
    
    func testQRCodeWithUnicodeContent() {
        // Test QR codes with Unicode content
        let unicodeMessage = "Unicode: 🚀 中文 العربية русский 🌟"
        let unicodeEnvelope = "WHISPER_ENVELOPE_v1:\(unicodeMessage.data(using: .utf8)?.base64EncodedString() ?? "")"
        
        composeViewModel.messageText = unicodeMessage
        composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
        
        mockWhisperService.mockEncryptResult = .success(unicodeEnvelope)
        composeViewModel.encryptMessage()
        
        // Verify QR handles Unicode
        XCTAssertNotNil(composeViewModel.qrCodeImage)
        
        // Test scanning Unicode content
        decryptViewModel.handleQRScanResult(unicodeEnvelope)
        XCTAssertEqual(decryptViewModel.encryptedText, unicodeEnvelope)
    }
    
    // MARK: - QR Code Validation and Security Tests
    
    func testQRCodeValidationRejectsInvalidEnvelopes() {
        let invalidEnvelopes = [
            "INVALID_ENVELOPE:content",
            "WHISPER_ENVELOPE_v2:future_version",
            "NOT_AN_ENVELOPE_AT_ALL",
            "",
            "WHISPER_ENVELOPE_v1:", // Missing content
        ]
        
        for invalidEnvelope in invalidEnvelopes {
            decryptViewModel.handleQRScanResult(invalidEnvelope)
            
            // Should reject invalid envelopes
            XCTAssertTrue(decryptViewModel.encryptedText.isEmpty || decryptViewModel.errorMessage != nil,
                         "Should reject invalid envelope: \(invalidEnvelope)")
            
            // Reset for next test
            decryptViewModel.reset()
        }
    }
    
    func testQRCodeValidationAcceptsValidEnvelopes() {
        let validEnvelopes = [
            "WHISPER_ENVELOPE_v1:dGVzdA==",
            "WHISPER_ENVELOPE_v1:bG9uZ2VyIGNvbnRlbnQ=",
            "WHISPER_ENVELOPE_v1:VW5pY29kZSBjb250ZW50IPCfmIA=",
        ]
        
        for validEnvelope in validEnvelopes {
            decryptViewModel.handleQRScanResult(validEnvelope)
            
            // Should accept valid envelopes
            XCTAssertEqual(decryptViewModel.encryptedText, validEnvelope)
            XCTAssertNil(decryptViewModel.errorMessage)
            
            // Reset for next test
            decryptViewModel.reset()
        }
    }
    
    // MARK: - Performance and Stress Tests
    
    func testQRWorkflowPerformanceWithRealService() {
        let testMessage = "Performance test with real QR service"
        let testEnvelope = "WHISPER_ENVELOPE_v1:cGVyZm9ybWFuY2UgdGVzdA=="
        
        measure {
            // Measure complete QR workflow performance
            composeViewModel.messageText = testMessage
            composeViewModel.selectedContacts = Set([mockContactManager.mockContacts[0]])
            
            mockWhisperService.mockEncryptResult = .success(testEnvelope)
            composeViewModel.encryptMessage()
            
            // Wait for QR generation
            let expectation = XCTestExpectation(description: "QR generation performance")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
            
            // Test scanning performance
            decryptViewModel.handleQRScanResult(testEnvelope)
            
            // Reset for next iteration
            composeViewModel.reset()
            decryptViewModel.reset()
        }
    }
    
    func testConcurrentQROperations() {
        // Test multiple QR operations happening concurrently
        let concurrentExpectation = XCTestExpectation(description: "Concurrent QR operations")
        concurrentExpectation.expectedFulfillmentCount = 5
        
        for i in 1...5 {
            DispatchQueue.global(qos: .userInitiated).async {
                let message = "Concurrent test message \(i)"
                let envelope = "WHISPER_ENVELOPE_v1:Y29uY3VycmVudCB0ZXN0\(i)"
                
                DispatchQueue.main.async {
                    // Create separate view models for concurrent testing
                    let concurrentComposeVM = ComposeViewModel(
                        whisperService: self.mockWhisperService,
                        qrCodeService: self.qrCodeService,
                        contactManager: self.mockContactManager,
                        identityManager: self.mockIdentityManager
                    )
                    
                    concurrentComposeVM.messageText = message
                    concurrentComposeVM.selectedContacts = Set([self.mockContactManager.mockContacts[0]])
                    
                    self.mockWhisperService.mockEncryptResult = .success(envelope)
                    concurrentComposeVM.encryptMessage()
                    
                    // Verify concurrent operation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        XCTAssertNotNil(concurrentComposeVM.qrCodeImage)
                        concurrentExpectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [concurrentExpectation], timeout: 5.0)
    }
    
    // MARK: - Integration with Real Encryption Parameters
    
    func testQRWorkflowWithDifferentEncryptionMethods() {
        // Test QR workflow with different encryption scenarios
        let encryptionScenarios = [
            ("Single recipient", 1),
            ("Multiple recipients"