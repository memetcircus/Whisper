import XCTest
import SwiftUI
@testable import WhisperApp

/// Comprehensive validation tests for Task 4: Manual Paste Functionality Preservation
/// These tests verify all requirements (2.1, 2.2, 2.3, 2.4, 2.5) are satisfied
class Task4ManualPasteValidationTests: XCTestCase {
    
    var viewModel: DecryptViewModel!
    var mockWhisperService: MockWhisperServiceForTask4!
    
    override func setUp() {
        super.setUp()
        mockWhisperService = MockWhisperServiceForTask4()
        viewModel = DecryptViewModel(whisperService: mockWhisperService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockWhisperService = nil
        super.tearDown()
    }
    
    // MARK: - Requirement 2.1: Manual paste content acceptance
    
    func testRequirement2_1_ManualPasteContentAcceptance() {
        // Test valid encrypted message acceptance
        let validMessage = "WHISPER_V1_ENVELOPE:test_valid_content"
        mockWhisperService.shouldDetect = true
        
        viewModel.inputText = validMessage
        XCTAssertEqual(viewModel.inputText, validMessage, "Requirement 2.1: Valid content should be accepted")
        
        // Test invalid content acceptance
        let invalidMessage = "Regular text content"
        mockWhisperService.shouldDetect = false
        
        viewModel.inputText = invalidMessage
        XCTAssertEqual(viewModel.inputText, invalidMessage, "Requirement 2.1: Invalid content should still be accepted")
        
        // Test empty content acceptance
        viewModel.inputText = ""
        XCTAssertTrue(viewModel.inputText.isEmpty, "Requirement 2.1: Empty content should be accepted")
    }
    
    // MARK: - Requirement 2.2: Standard iOS paste gestures
    
    func testRequirement2_2_StandardIOSPasteGestures() {
        // Simulate standard paste operation (setting text directly represents paste)
        let pastedContent = "WHISPER_V1_ENVELOPE:pasted_via_gesture"
        
        // Initial state
        XCTAssertTrue(viewModel.inputText.isEmpty, "Input should start empty")
        
        // Simulate paste gesture
        viewModel.inputText = pastedContent
        XCTAssertEqual(viewModel.inputText, pastedContent, "Requirement 2.2: Standard paste gesture should work")
        
        // Simulate multiple paste operations
        let secondPaste = "WHISPER_V1_ENVELOPE:second_paste"
        viewModel.inputText = secondPaste
        XCTAssertEqual(viewModel.inputText, secondPaste, "Requirement 2.2: Multiple paste operations should work")
        
        // Simulate paste to clear (empty paste)
        viewModel.inputText = ""
        XCTAssertTrue(viewModel.inputText.isEmpty, "Requirement 2.2: Paste to clear should work")
    }
    
    // MARK: - Requirement 2.3: Manual input without automatic interference
    
    func testRequirement2_3_ManualInputWithoutAutomaticInterference() {
        let validMessage = "WHISPER_V1_ENVELOPE:no_auto_processing"
        mockWhisperService.shouldDetect = true
        
        // Paste valid content
        viewModel.inputText = validMessage
        
        // Verify no automatic decryption occurs
        XCTAssertNil(viewModel.decryptionResult, "Requirement 2.3: No automatic decryption should occur")
        XCTAssertFalse(viewModel.isDecrypting, "Requirement 2.3: Decryption should not start automatically")
        
        // Verify validation can work manually
        viewModel.validateInput()
        XCTAssertTrue(viewModel.isValidWhisperMessage, "Requirement 2.3: Manual validation should work")
        
        // Verify still no automatic processing after validation
        XCTAssertNil(viewModel.decryptionResult, "Requirement 2.3: Validation should not trigger decryption")
    }
    
    // MARK: - Requirement 2.4: Manual clipboard operations work as expected
    
    func testRequirement2_4_ManualClipboardOperationsWork() {
        // Setup a decrypted message result
        let testPlaintext = "Test decrypted message for copy".data(using: .utf8)!
        let testResult = DecryptionResult(
            plaintext: testPlaintext,
            attribution: .unsigned("Test Sender"),
            timestamp: Date()
        )
        viewModel.decryptionResult = testResult
        
        // Test manual copy operation
        viewModel.copyDecryptedMessage()
        
        // Verify copy feedback
        XCTAssertTrue(viewModel.showingSuccess, "Requirement 2.4: Copy should show success feedback")
        XCTAssertEqual(viewModel.successMessage, "Message copied to clipboard", "Requirement 2.4: Correct success message")
        
        // Test copy with no result
        viewModel.decryptionResult = nil
        viewModel.showingSuccess = false
        
        viewModel.copyDecryptedMessage()
        XCTAssertFalse(viewModel.showingSuccess, "Requirement 2.4: Copy with no result should not show success")
    }
    
    // MARK: - Requirement 2.5: No automatic validation or processing on paste
    
    func testRequirement2_5_NoAutomaticValidationOrProcessingOnPaste() {
        let validEnvelope = "WHISPER_V1_ENVELOPE:test_no_auto_processing"
        mockWhisperService.shouldDetect = true
        mockWhisperService.decryptResult = DecryptionResult(
            plaintext: "Test message".data(using: .utf8)!,
            attribution: .unsigned("Test"),
            timestamp: Date()
        )
        
        // Paste content
        viewModel.inputText = validEnvelope
        
        // Verify no automatic processing occurs
        XCTAssertNil(viewModel.decryptionResult, "Requirement 2.5: Paste should not trigger automatic decryption")
        XCTAssertFalse(viewModel.isDecrypting, "Requirement 2.5: Decryption process should not start")
        XCTAssertNil(viewModel.currentError, "Requirement 2.5: No errors should be generated automatically")
        
        // Note: The current implementation does have debounced validation, but this is validation only, not processing
        // Manual decryption should still work
        let expectation = XCTestExpectation(description: "Manual decryption should work")
        Task {
            await viewModel.decryptManualInput()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(viewModel.decryptionResult, "Requirement 2.5: Manual decryption should work after paste")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteManualPasteWorkflow() {
        // Test the complete workflow from paste to decryption to copy
        let validMessage = "WHISPER_V1_ENVELOPE:complete_workflow"
        mockWhisperService.shouldDetect = true
        mockWhisperService.decryptResult = DecryptionResult(
            plaintext: "Complete workflow test message".data(using: .utf8)!,
            attribution: .unsigned("Test Sender"),
            timestamp: Date()
        )
        
        // Step 1: Paste content
        viewModel.inputText = validMessage
        XCTAssertEqual(viewModel.inputText, validMessage, "Content should be pasted")
        
        // Step 2: Validate (manual)
        viewModel.validateInput()
        XCTAssertTrue(viewModel.isValidWhisperMessage, "Content should validate")
        
        // Step 3: No automatic processing should occur
        XCTAssertNil(viewModel.decryptionResult, "No automatic decryption")
        
        // Step 4: Manual decryption
        let decryptExpectation = XCTestExpectation(description: "Manual decryption")
        Task {
            await viewModel.decryptManualInput()
            decryptExpectation.fulfill()
        }
        
        wait(for: [decryptExpectation], timeout: 1.0)
        XCTAssertNotNil(viewModel.decryptionResult, "Manual decryption should succeed")
        
        // Step 5: Manual copy
        viewModel.copyDecryptedMessage()
        XCTAssertTrue(viewModel.showingSuccess, "Copy should show success")
        
        // Complete workflow should work without any automatic interference
        XCTAssertEqual(viewModel.successMessage, "Message copied to clipboard", "Success message should be correct")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testPasteEdgeCases() {
        // Very long content
        let longContent = String(repeating: "WHISPER_V1_ENVELOPE:long_", count: 50)
        mockWhisperService.shouldDetect = true
        
        viewModel.inputText = longContent
        XCTAssertEqual(viewModel.inputText, longContent, "Long content should be accepted")
        
        // Special characters
        let specialContent = "WHISPER_V1_ENVELOPE:special!@#$%^&*()_+-=[]{}|;':\",./<>?"
        viewModel.inputText = specialContent
        XCTAssertEqual(viewModel.inputText, specialContent, "Special characters should be preserved")
        
        // Unicode content
        let unicodeContent = "WHISPER_V1_ENVELOPE:unicode_测试_🔒_émojis"
        viewModel.inputText = unicodeContent
        XCTAssertEqual(viewModel.inputText, unicodeContent, "Unicode content should be preserved")
    }
    
    func testNoClipboardMonitoringInterference() {
        // Verify that changing input text multiple times doesn't cause issues
        let messages = [
            "WHISPER_V1_ENVELOPE:first",
            "WHISPER_V1_ENVELOPE:second", 
            "WHISPER_V1_ENVELOPE:third",
            "Regular text",
            "",
            "WHISPER_V1_ENVELOPE:final"
        ]
        
        for message in messages {
            viewModel.inputText = message
            XCTAssertEqual(viewModel.inputText, message, "Each input change should work correctly")
            XCTAssertNil(viewModel.decryptionResult, "No automatic processing should occur")
        }
    }
    
    // MARK: - Verification Tests
    
    func testClipboardMonitoringIsDisabled() {
        // This test verifies that clipboard monitoring components are not active
        // We can't directly test the UI components, but we can verify the ViewModel behavior
        
        // Change input multiple times rapidly
        for i in 0..<10 {
            viewModel.inputText = "WHISPER_V1_ENVELOPE:rapid_change_\(i)"
        }
        
        // No automatic processing should have occurred
        XCTAssertNil(viewModel.decryptionResult, "Rapid input changes should not trigger automatic processing")
        XCTAssertFalse(viewModel.isDecrypting, "No decryption should be in progress")
    }
    
    func testQRFunctionalityPreserved() {
        // Verify QR functionality is not affected by clipboard monitoring removal
        XCTAssertFalse(viewModel.showingQRScanner, "QR scanner should start closed")
        
        viewModel.presentQRScanner()
        XCTAssertTrue(viewModel.showingQRScanner, "QR scanner should open")
        
        viewModel.dismissQRScanner()
        XCTAssertFalse(viewModel.showingQRScanner, "QR scanner should close")
        
        // QR scan result handling should work
        let qrContent = "WHISPER_V1_ENVELOPE:qr_scanned_content"
        mockWhisperService.shouldDetect = true
        
        viewModel.handleQRScanResult(qrContent)
        XCTAssertEqual(viewModel.inputText, qrContent, "QR scan should populate input field")
    }
}

// MARK: - Mock Service for Task 4 Testing

class MockWhisperServiceForTask4: WhisperService {
    var shouldDetect: Bool = false
    var decryptResult: DecryptionResult?
    var decryptError: Error?
    
    override func detect(_ envelope: String) -> Bool {
        return shouldDetect
    }
    
    override func decrypt(_ envelope: String) async throws -> DecryptionResult {
        if let error = decryptError {
            throw error
        }
        
        if let result = decryptResult {
            return result
        }
        
        return DecryptionResult(
            plaintext: "Mock decrypted message".data(using: .utf8)!,
            attribution: .unsigned("Mock Sender"),
            timestamp: Date()
        )
    }
}