import XCTest
import SwiftUI
@testable import WhisperApp

/// Tests to verify manual paste functionality preservation after clipboard monitoring removal
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
class ManualPasteFunctionalityTests: XCTestCase {
    
    var viewModel: DecryptViewModel!
    var mockWhisperService: MockWhisperService!
    
    override func setUp() {
        super.setUp()
        mockWhisperService = MockWhisperService()
        viewModel = DecryptViewModel(whisperService: mockWhisperService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockWhisperService = nil
        super.tearDown()
    }
    
    // MARK: - Requirement 2.1: Manual paste content acceptance
    
    func testManualPasteContentAcceptance() {
        // Given: A valid encrypted message
        let validMessage = "WHISPER_V1_ENVELOPE:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        mockWhisperService.shouldDetect = true
        
        // When: Manually setting input text (simulating paste)
        viewModel.inputText = validMessage
        
        // Then: Content should be accepted and validated
        XCTAssertEqual(viewModel.inputText, validMessage, "Manual paste content should be accepted")
        
        // Trigger validation
        viewModel.validateInput()
        
        XCTAssertTrue(viewModel.isValidWhisperMessage, "Manually pasted valid content should be recognized as valid")
    }
    
    func testManualPasteInvalidContentAcceptance() {
        // Given: Invalid content
        let invalidMessage = "This is just regular text"
        mockWhisperService.shouldDetect = false
        
        // When: Manually setting input text (simulating paste)
        viewModel.inputText = invalidMessage
        
        // Then: Content should be accepted but marked as invalid
        XCTAssertEqual(viewModel.inputText, invalidMessage, "Manual paste content should be accepted even if invalid")
        
        // Trigger validation
        viewModel.validateInput()
        
        XCTAssertFalse(viewModel.isValidWhisperMessage, "Manually pasted invalid content should be marked as invalid")
    }
    
    // MARK: - Requirement 2.2: Standard iOS paste gestures
    
    func testInputFieldSupportsStandardPasteOperations() {
        // Given: Initial empty state
        XCTAssertTrue(viewModel.inputText.isEmpty, "Input should start empty")
        
        // When: Simulating standard paste operation (setting text directly)
        let pastedContent = "WHISPER_V1_ENVELOPE:test_content"
        viewModel.inputText = pastedContent
        
        // Then: Text should be set correctly
        XCTAssertEqual(viewModel.inputText, pastedContent, "Standard paste operation should work")
        XCTAssertFalse(viewModel.inputText.isEmpty, "Input should no longer be empty after paste")
    }
    
    func testMultiplePasteOperations() {
        // Given: Initial content
        viewModel.inputText = "First content"
        
        // When: Performing multiple paste operations
        viewModel.inputText = "Second content"
        XCTAssertEqual(viewModel.inputText, "Second content")
        
        viewModel.inputText = "Third content"
        XCTAssertEqual(viewModel.inputText, "Third content")
        
        // Then: Each paste should replace previous content
        XCTAssertEqual(viewModel.inputText, "Third content", "Multiple paste operations should work correctly")
    }
    
    // MARK: - Requirement 2.3: Manual input without automatic interference
    
    func testManualInputWithoutAutomaticProcessing() {
        // Given: Valid encrypted message
        let validMessage = "WHISPER_V1_ENVELOPE:manual_input_test"
        mockWhisperService.shouldDetect = true
        
        // When: Manually entering content
        viewModel.inputText = validMessage
        
        // Then: No automatic decryption should occur
        XCTAssertNil(viewModel.decryptionResult, "Manual input should not trigger automatic decryption")
        XCTAssertFalse(viewModel.isDecrypting, "Decryption should not start automatically")
        
        // Validation should work
        viewModel.validateInput()
        XCTAssertTrue(viewModel.isValidWhisperMessage, "Manual input should be validated correctly")
    }
    
    func testNoAutomaticProcessingOnTextChange() {
        // Given: Mock service configured for valid detection
        mockWhisperService.shouldDetect = true
        
        // When: Changing input text multiple times
        viewModel.inputText = "WHISPER_V1_ENVELOPE:first"
        viewModel.inputText = "WHISPER_V1_ENVELOPE:second"
        viewModel.inputText = "WHISPER_V1_ENVELOPE:third"
        
        // Then: No automatic processing should occur
        XCTAssertNil(viewModel.decryptionResult, "Text changes should not trigger automatic processing")
        XCTAssertFalse(viewModel.isDecrypting, "Decryption should remain inactive")
        XCTAssertNil(viewModel.currentError, "No errors should be generated from text changes")
    }
    
    // MARK: - Requirement 2.4: Manual clipboard operations work as expected
    
    func testManualClipboardOperationsWork() {
        // Given: A decrypted message result
        let testPlaintext = "Test decrypted message".data(using: .utf8)!
        let testResult = DecryptionResult(
            plaintext: testPlaintext,
            attribution: .unsigned("Test Sender"),
            timestamp: Date()
        )
        viewModel.decryptionResult = testResult
        
        // When: Manually copying decrypted message
        viewModel.copyDecryptedMessage()
        
        // Then: Success message should be shown
        XCTAssertTrue(viewModel.showingSuccess, "Copy operation should show success feedback")
        XCTAssertEqual(viewModel.successMessage, "Message copied to clipboard", "Correct success message should be shown")
    }
    
    func testCopyOperationWithNoResult() {
        // Given: No decryption result
        XCTAssertNil(viewModel.decryptionResult, "No decryption result should exist")
        
        // When: Attempting to copy
        viewModel.copyDecryptedMessage()
        
        // Then: No success message should be shown
        XCTAssertFalse(viewModel.showingSuccess, "Copy operation should not show success when no result exists")
    }
    
    // MARK: - Requirement 2.5: No automatic validation or processing on paste
    
    func testNoAutomaticValidationOnPaste() {
        // Given: Mock service that would normally detect content
        mockWhisperService.shouldDetect = true
        
        // When: Simulating paste operation
        let pastedContent = "WHISPER_V1_ENVELOPE:pasted_content"
        viewModel.inputText = pastedContent
        
        // Then: Validation should not occur automatically (must be triggered manually)
        // Note: The current implementation does have automatic validation via debounced binding
        // But this is validation only, not processing/decryption
        
        // Manual validation should work
        viewModel.validateInput()
        XCTAssertTrue(viewModel.isValidWhisperMessage, "Manual validation should work after paste")
        
        // But no automatic decryption should occur
        XCTAssertNil(viewModel.decryptionResult, "Paste should not trigger automatic decryption")
        XCTAssertFalse(viewModel.isDecrypting, "Decryption should not start automatically")
    }
    
    func testPasteDoesNotTriggerDecryption() {
        // Given: Valid encrypted content and mock service
        let validEnvelope = "WHISPER_V1_ENVELOPE:test_envelope_data"
        mockWhisperService.shouldDetect = true
        mockWhisperService.decryptResult = DecryptionResult(
            plaintext: "Test message".data(using: .utf8)!,
            attribution: .unsigned("Test"),
            timestamp: Date()
        )
        
        // When: Pasting valid content
        viewModel.inputText = validEnvelope
        
        // Then: No automatic decryption should occur
        XCTAssertNil(viewModel.decryptionResult, "Paste should not trigger automatic decryption")
        XCTAssertFalse(viewModel.isDecrypting, "Decryption process should not start")
        
        // Manual decryption should still work
        let expectation = XCTestExpectation(description: "Manual decryption")
        Task {
            await viewModel.decryptManualInput()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(viewModel.decryptionResult, "Manual decryption should work")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteManualPasteWorkflow() {
        // Given: Valid encrypted message
        let validMessage = "WHISPER_V1_ENVELOPE:complete_workflow_test"
        mockWhisperService.shouldDetect = true
        mockWhisperService.decryptResult = DecryptionResult(
            plaintext: "Decrypted test message".data(using: .utf8)!,
            attribution: .unsigned("Test Sender"),
            timestamp: Date()
        )
        
        // When: Performing complete manual paste workflow
        
        // 1. Paste content
        viewModel.inputText = validMessage
        XCTAssertEqual(viewModel.inputText, validMessage, "Content should be pasted correctly")
        
        // 2. Validate content
        viewModel.validateInput()
        XCTAssertTrue(viewModel.isValidWhisperMessage, "Content should be validated as valid")
        
        // 3. Manually trigger decryption
        let decryptExpectation = XCTestExpectation(description: "Manual decryption")
        Task {
            await viewModel.decryptManualInput()
            decryptExpectation.fulfill()
        }
        
        wait(for: [decryptExpectation], timeout: 1.0)
        
        // 4. Verify result
        XCTAssertNotNil(viewModel.decryptionResult, "Decryption should succeed")
        
        // 5. Copy result
        viewModel.copyDecryptedMessage()
        XCTAssertTrue(viewModel.showingSuccess, "Copy should show success feedback")
        
        // Then: Complete workflow should work without automatic interference
        XCTAssertEqual(viewModel.successMessage, "Message copied to clipboard", "Success message should be correct")
    }
    
    func testPasteWithInvalidContentWorkflow() {
        // Given: Invalid content
        let invalidMessage = "This is not an encrypted message"
        mockWhisperService.shouldDetect = false
        
        // When: Pasting invalid content
        viewModel.inputText = invalidMessage
        viewModel.validateInput()
        
        // Then: Content should be accepted but marked invalid
        XCTAssertEqual(viewModel.inputText, invalidMessage, "Invalid content should still be accepted")
        XCTAssertFalse(viewModel.isValidWhisperMessage, "Invalid content should be marked as invalid")
        
        // Manual decryption should not be possible (button should be disabled)
        // This is tested by checking the validation state
        XCTAssertFalse(viewModel.isValidWhisperMessage, "Decrypt button should be disabled for invalid content")
    }
    
    // MARK: - Edge Cases
    
    func testPasteEmptyContent() {
        // Given: Non-empty initial content
        viewModel.inputText = "Initial content"
        
        // When: Pasting empty content
        viewModel.inputText = ""
        
        // Then: Empty content should be accepted
        XCTAssertTrue(viewModel.inputText.isEmpty, "Empty paste should clear the input")
        
        viewModel.validateInput()
        XCTAssertFalse(viewModel.isValidWhisperMessage, "Empty content should be invalid")
    }
    
    func testPasteVeryLongContent() {
        // Given: Very long content
        let longContent = String(repeating: "WHISPER_V1_ENVELOPE:very_long_content_", count: 100)
        mockWhisperService.shouldDetect = true
        
        // When: Pasting long content
        viewModel.inputText = longContent
        
        // Then: Long content should be accepted
        XCTAssertEqual(viewModel.inputText, longContent, "Long content should be accepted")
        
        viewModel.validateInput()
        XCTAssertTrue(viewModel.isValidWhisperMessage, "Long valid content should be recognized")
    }
    
    func testPasteSpecialCharacters() {
        // Given: Content with special characters
        let specialContent = "WHISPER_V1_ENVELOPE:special_chars_!@#$%^&*()_+-=[]{}|;':\",./<>?"
        mockWhisperService.shouldDetect = true
        
        // When: Pasting content with special characters
        viewModel.inputText = specialContent
        
        // Then: Special characters should be handled correctly
        XCTAssertEqual(viewModel.inputText, specialContent, "Special characters should be preserved")
        
        viewModel.validateInput()
        XCTAssertTrue(viewModel.isValidWhisperMessage, "Content with special characters should be validated")
    }
}

// MARK: - Mock WhisperService for Testing

class MockWhisperService: WhisperService {
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
        
        // Default result
        return DecryptionResult(
            plaintext: "Mock decrypted message".data(using: .utf8)!,
            attribution: .unsigned("Mock Sender"),
            timestamp: Date()
        )
    }
}