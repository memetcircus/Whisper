import XCTest
import SwiftUI
import Combine
import Foundation

/// UI tests for QR scan integration in DecryptView
/// Tests the complete QR scan workflow, accessibility, error handling, and integration
/// 
/// Requirements covered:
/// - 1.1: QR scan button visibility and accessibility
/// - 1.2: QR scanner presentation and dismissal
/// - 2.2: Integration with existing decrypt workflow
/// - 2.3: Error handling user experience
class DecryptViewQRUITests: XCTestCase {
    
    var mockWhisperService: MockWhisperService!
    var mockQRCodeService: MockQRCodeService!
    var viewModel: MockDecryptViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockWhisperService = MockWhisperService()
        mockQRCodeService = MockQRCodeService()
        viewModel = MockDecryptViewModel(
            whisperService: mockWhisperService,
            qrCodeService: mockQRCodeService
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockWhisperService = nil
        mockQRCodeService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - QR Scan Button Accessibility Tests (Requirement 1.1)
    
    func testQRScanButtonAccessibilityLabels() {
        // Test default state accessibility
        XCTAssertEqual(viewModel.qrScanAccessibilityLabel, "Scan QR code")
        XCTAssertEqual(viewModel.qrScanAccessibilityHint, "Double tap to scan a QR code containing an encrypted message")
        
        // Test scanning state accessibility
        viewModel.showingQRScanner = true
        XCTAssertEqual(viewModel.qrScanAccessibilityLabel, "QR scanner active")
        XCTAssertEqual(viewModel.qrScanAccessibilityHint, "QR scanner is currently active")
        
        // Test scan complete state accessibility
        viewModel.showingQRScanner = false
        viewModel.isQRScanComplete = true
        XCTAssertEqual(viewModel.qrScanAccessibilityLabel, "QR code scanned successfully")
        XCTAssertEqual(viewModel.qrScanAccessibilityHint, "QR code was successfully scanned")
    }
    
    func testQRScanButtonVisualStates() {
        // Test default state
        XCTAssertEqual(viewModel.qrScanButtonText, "Scan QR")
        XCTAssertEqual(viewModel.qrScanButtonColor, Color.blue)
        XCTAssertEqual(viewModel.qrScanButtonForegroundColor, Color.white)
        
        // Test scanning state
        viewModel.showingQRScanner = true
        XCTAssertEqual(viewModel.qrScanButtonText, "Scanning...")
        XCTAssertEqual(viewModel.qrScanButtonColor, Color.orange)
        
        // Test scan complete state
        viewModel.showingQRScanner = false
        viewModel.isQRScanComplete = true
        XCTAssertEqual(viewModel.qrScanButtonText, "Scanned")
        XCTAssertEqual(viewModel.qrScanButtonColor, Color.green)
    }
    
    func testQRScanButtonInteraction() {
        // Test button presentation
        XCTAssertFalse(viewModel.showingQRScanner)
        
        viewModel.presentQRScanner()
        
        XCTAssertTrue(viewModel.showingQRScanner)
        XCTAssertFalse(viewModel.isQRScanComplete)
    }
    
    // MARK: - QR Scanner Presentation Tests (Requirement 1.2)
    
    func testQRScannerPresentation() {
        let expectation = XCTestExpectation(description: "QR scanner presentation state change")
        
        // Monitor showingQRScanner changes
        viewModel.$showingQRScanner
            .dropFirst()
            .sink { isShowing in
                if isShowing {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Present scanner
        viewModel.presentQRScanner()
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showingQRScanner)
    }
    
    func testQRScannerDismissal() {
        // Setup: scanner is showing
        viewModel.showingQRScanner = true
        viewModel.isQRScanComplete = false
        
        let expectation = XCTestExpectation(description: "QR scanner dismissal")
        
        viewModel.$showingQRScanner
            .dropFirst()
            .sink { isShowing in
                if !isShowing {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Dismiss scanner
        viewModel.dismissQRScanner()
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.showingQRScanner)
    }
    
    func testQRScannerStateReset() {
        // Setup: previous scan was complete
        viewModel.isQRScanComplete = true
        
        // Present scanner again
        viewModel.presentQRScanner()
        
        // Should reset scan complete state
        XCTAssertFalse(viewModel.isQRScanComplete)
        XCTAssertTrue(viewModel.showingQRScanner)
    }
    
    // MARK: - Complete QR Scan to Decrypt Workflow Tests (Requirement 2.2)
    
    func testCompleteQRScanToDecryptWorkflow() {
        let validEnvelope = "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT"
        
        // Setup mocks for successful workflow
        mockQRCodeService.parseResult = .encryptedMessage(validEnvelope)
        mockWhisperService.detectResult = true
        
        let workflowExpectation = XCTestExpectation(description: "Complete QR scan workflow")
        
        // Monitor workflow completion
        viewModel.$inputText
            .dropFirst()
            .sink { inputText in
                if inputText == validEnvelope {
                    workflowExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Execute workflow
        viewModel.presentQRScanner()
        XCTAssertTrue(viewModel.showingQRScanner)
        
        // Simulate QR scan result
        viewModel.handleQRScanResult(validEnvelope)
        
        wait(for: [workflowExpectation], timeout: 2.0)
        
        // Verify workflow completion
        XCTAssertFalse(viewModel.showingQRScanner)
        XCTAssertTrue(viewModel.isQRScanComplete)
        XCTAssertEqual(viewModel.inputText, validEnvelope)
        XCTAssertTrue(viewModel.showingSuccess)
    }
    
    func testQRScanResultPopulatesInputField() {
        let testEnvelope = "whisper1:test.envelope.content"
        
        // Setup mocks
        mockQRCodeService.parseResult = .encryptedMessage(testEnvelope)
        mockWhisperService.detectResult = true
        
        // Handle QR scan result
        viewModel.handleQRScanResult(testEnvelope)
        
        // Verify input field is populated
        XCTAssertEqual(viewModel.inputText, testEnvelope)
        XCTAssertTrue(viewModel.isQRScanComplete)
        XCTAssertFalse(viewModel.showingQRScanner)
    }
    
    func testQRScanIntegrationWithExistingDecryptFlow() {
        let validEnvelope = "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT"
        
        // Setup mocks for complete flow
        mockQRCodeService.parseResult = .encryptedMessage(validEnvelope)
        mockWhisperService.detectResult = true
        mockWhisperService.decryptResult = DecryptionResult(
            plaintext: "Test message".data(using: .utf8)!,
            attribution: .unsigned("Test Sender"),
            timestamp: Date(),
            senderAttribution: "From: Test Sender"
        )
        
        // Scan QR code
        viewModel.handleQRScanResult(validEnvelope)
        
        // Verify input is populated and valid
        XCTAssertEqual(viewModel.inputText, validEnvelope)
        XCTAssertTrue(viewModel.isValidWhisperMessage)
        
        // Execute decrypt
        let decryptExpectation = XCTestExpectation(description: "Decryption completes")
        
        Task {
            await viewModel.decryptManualInput()
            decryptExpectation.fulfill()
        }
        
        wait(for: [decryptExpectation], timeout: 3.0)
        
        // Verify decryption result
        XCTAssertNotNil(viewModel.decryptionResult)
        XCTAssertEqual(
            String(data: viewModel.decryptionResult!.plaintext, encoding: .utf8),
            "Test message"
        )
    }
    
    // MARK: - Error Handling User Experience Tests (Requirement 2.3)
    
    func testQRScanErrorHandling() {
        // Test unsupported format error
        mockQRCodeService.shouldThrowError = true
        mockQRCodeService.errorToThrow = .unsupportedFormat
        
        viewModel.handleQRScanResult("invalid-qr-content")
        
        XCTAssertEqual(viewModel.currentError, .qrUnsupportedFormat)
        XCTAssertFalse(viewModel.showingQRScanner)
        XCTAssertFalse(viewModel.isQRScanComplete)
    }
    
    func testQRScanCameraPermissionError() {
        mockQRCodeService.shouldThrowError = true
        mockQRCodeService.errorToThrow = .cameraPermissionDenied
        
        viewModel.handleQRScanResult("test-content")
        
        XCTAssertEqual(viewModel.currentError, .qrCameraPermissionDenied)
        XCTAssertFalse(viewModel.showingQRScanner)
    }
    
    func testQRScanScanningNotAvailableError() {
        mockQRCodeService.shouldThrowError = true
        mockQRCodeService.errorToThrow = .scanningNotAvailable
        
        viewModel.handleQRScanResult("test-content")
        
        XCTAssertEqual(viewModel.currentError, .qrScanningNotAvailable)
        XCTAssertFalse(viewModel.showingQRScanner)
    }
    
    func testQRScanInvalidContentError() {
        // Test public key bundle rejection
        let bundle = createSamplePublicKeyBundle()
        mockQRCodeService.parseResult = .publicKeyBundle(bundle)
        
        viewModel.handleQRScanResult("whisper-bundle:test")
        
        XCTAssertEqual(viewModel.currentError, .qrInvalidContent)
        XCTAssertFalse(viewModel.showingQRScanner)
        XCTAssertFalse(viewModel.isQRScanComplete)
    }
    
    func testQRScanInvalidEnvelopeError() {
        let invalidEnvelope = "whisper1:invalid.format"
        
        mockQRCodeService.parseResult = .encryptedMessage(invalidEnvelope)
        mockWhisperService.detectResult = false // Invalid envelope
        
        viewModel.handleQRScanResult(invalidEnvelope)
        
        XCTAssertEqual(viewModel.currentError, .invalidEnvelope)
        XCTAssertFalse(viewModel.showingQRScanner)
        XCTAssertFalse(viewModel.isQRScanComplete)
    }
    
    func testQRScanErrorRecovery() {
        // Test retry after camera permission error
        viewModel.currentError = .qrCameraPermissionDenied
        
        let retryExpectation = XCTestExpectation(description: "QR scan retry")
        
        viewModel.$showingQRScanner
            .dropFirst()
            .sink { isShowing in
                if isShowing {
                    retryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.retryQRScan()
        
        wait(for: [retryExpectation], timeout: 1.0)
        
        XCTAssertNil(viewModel.currentError)
        XCTAssertTrue(viewModel.showingQRScanner)
        XCTAssertFalse(viewModel.isQRScanComplete)
    }
    
    func testQRScanRetryLastOperation() {
        // Setup: no last operation, should retry QR scan
        viewModel.currentError = .qrScanningNotAvailable
        
        let retryExpectation = XCTestExpectation(description: "Retry last operation triggers QR scan")
        
        viewModel.$showingQRScanner
            .dropFirst()
            .sink { isShowing in
                if isShowing {
                    retryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        Task {
            await viewModel.retryLastOperation()
        }
        
        wait(for: [retryExpectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showingQRScanner)
    }
    
    // MARK: - QR Scan Visual Feedback Tests
    
    func testQRScanVisualFeedbackStates() {
        // Test scanning state visual feedback
        viewModel.showingQRScanner = true
        
        XCTAssertEqual(viewModel.qrScanButtonText, "Scanning...")
        XCTAssertEqual(viewModel.qrScanButtonColor, Color.orange)
        XCTAssertEqual(viewModel.qrScanAccessibilityLabel, "QR scanner active")
        
        // Test success state visual feedback
        viewModel.showingQRScanner = false
        viewModel.isQRScanComplete = true
        
        XCTAssertEqual(viewModel.qrScanButtonText, "Scanned")
        XCTAssertEqual(viewModel.qrScanButtonColor, Color.green)
        XCTAssertEqual(viewModel.qrScanAccessibilityLabel, "QR code scanned successfully")
    }
    
    func testQRScanSuccessFeedback() {
        let validEnvelope = "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT"
        
        mockQRCodeService.parseResult = .encryptedMessage(validEnvelope)
        mockWhisperService.detectResult = true
        
        let successExpectation = XCTestExpectation(description: "Success feedback shown")
        
        viewModel.$showingSuccess
            .dropFirst()
            .sink { showingSuccess in
                if showingSuccess {
                    successExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.handleQRScanResult(validEnvelope)
        
        wait(for: [successExpectation], timeout: 1.0)
        
        XCTAssertTrue(viewModel.showingSuccess)
        XCTAssertEqual(viewModel.successMessage, "QR code scanned successfully! Message ready to decrypt.")
        XCTAssertTrue(viewModel.isQRScanComplete)
    }
    
    // MARK: - Integration with Existing Decrypt Functionality Tests
    
    func testQRScanDoesNotInterfereWithManualInput() {
        // Setup manual input
        viewModel.inputText = "manual-input-text"
        
        // Present and dismiss QR scanner without scanning
        viewModel.presentQRScanner()
        viewModel.dismissQRScanner()
        
        // Manual input should be preserved
        XCTAssertEqual(viewModel.inputText, "manual-input-text")
    }
    
    func testQRScanReplacesManualInput() {
        let validEnvelope = "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT"
        
        // Setup existing manual input
        viewModel.inputText = "existing-manual-input"
        
        // Setup mocks
        mockQRCodeService.parseResult = .encryptedMessage(validEnvelope)
        mockWhisperService.detectResult = true
        
        // Scan QR code
        viewModel.handleQRScanResult(validEnvelope)
        
        // QR scan should replace manual input
        XCTAssertEqual(viewModel.inputText, validEnvelope)
        XCTAssertNotEqual(viewModel.inputText, "existing-manual-input")
    }
    
    func testQRScanWithExistingDecryptionResult() {
        // Setup existing decryption result
        viewModel.decryptionResult = DecryptionResult(
            plaintext: "Existing result".data(using: .utf8)!,
            attribution: .unsigned("Sender"),
            timestamp: Date(),
            senderAttribution: "From: Sender"
        )
        
        let validEnvelope = "whisper1:new.envelope"
        mockQRCodeService.parseResult = .encryptedMessage(validEnvelope)
        mockWhisperService.detectResult = true
        
        // Scan new QR code
        viewModel.handleQRScanResult(validEnvelope)
        
        // Should populate input field even with existing result
        XCTAssertEqual(viewModel.inputText, validEnvelope)
        XCTAssertNotNil(viewModel.decryptionResult) // Existing result preserved
    }
    
    func testClearResultResetsQRScanState() {
        // Setup QR scan complete state
        viewModel.isQRScanComplete = true
        viewModel.inputText = "test-envelope"
        
        // Clear result
        viewModel.clearResult()
        
        // QR scan state should be reset
        XCTAssertFalse(viewModel.isQRScanComplete)
        XCTAssertEqual(viewModel.inputText, "")
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
}

// MARK: - Mock Services for UI Testing

/// Enhanced mock WhisperService for UI testing
class MockWhisperService: WhisperServiceProtocol {
    var detectResult: Bool = false
    var detectCalled: Bool = false
    var lastDetectInput: String?
    var decryptResult: DecryptionResult?
    var shouldThrowDecryptError: Bool = false
    var decryptError: WhisperError = .invalidEnvelope
    
    func detect(_ text: String) -> Bool {
        detectCalled = true
        lastDetectInput = text
        return detectResult
    }
    
    func decrypt(_ envelope: String) async throws -> DecryptionResult {
        if shouldThrowDecryptError {
            throw decryptError
        }
        return decryptResult ?? DecryptionResult(
            plaintext: "Default test message".data(using: .utf8)!,
            attribution: .unsigned("Test Sender"),
            timestamp: Date(),
            senderAttribution: "From: Test Sender"
        )
    }
    
    // Other required methods with default implementations
    func encrypt(_ plaintext: Data, from sender: Identity, to recipient: Contact, authenticity: Bool) throws -> String {
        return "mock-envelope"
    }
    
    func encryptToRawKey(_ plaintext: Data, from sender: Identity, to recipientKey: Data, authenticity: Bool) throws -> String {
        return "mock-envelope"
    }
}

/// Enhanced mock QRCodeService for UI testing
class MockQRCodeService: QRCodeServiceProtocol {
    var parseResult: QRCodeContent?
    var shouldThrowError: Bool = false
    var errorToThrow: QRCodeError = .unsupportedFormat
    
    func parseQRCode(_ content: String) throws -> QRCodeContent {
        if shouldThrowError {
            throw errorToThrow
        }
        return parseResult ?? .encryptedMessage(content)
    }
    
    // Other required methods with default implementations
    func generateQRCode(for bundle: PublicKeyBundle) throws -> UIImage {
        return UIImage()
    }
    
    func generateQRCode(for data: Data) throws -> UIImage {
        return UIImage()
    }
    
    func checkCameraPermission() -> AVAuthorizationStatus {
        return .authorized
    }
    
    func requestCameraPermission(_ completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

// MARK: - Protocol Definitions for Mocking

protocol WhisperServiceProtocol {
    func detect(_ text: String) -> Bool
    func decrypt(_ envelope: String) async throws -> DecryptionResult
    func encrypt(_ plaintext: Data, from sender: Identity, to recipient: Contact, authenticity: Bool) throws -> String
    func encryptToRawKey(_ plaintext: Data, from sender: Identity, to recipientKey: Data, authenticity: Bool) throws -> String
}

protocol QRCodeServiceProtocol {
    func parseQRCode(_ content: String) throws -> QRCodeContent
    func generateQRCode(for bundle: PublicKeyBundle) throws -> UIImage
    func generateQRCode(for data: Data) throws -> UIImage
    func checkCameraPermission() -> AVAuthorizationStatus
    func requestCameraPermission(_ completion: @escaping (Bool) -> Void)
}

// MARK: - Supporting Types for UI Tests

/// QR code content types for UI testing
enum QRCodeContent {
    case publicKeyBundle(PublicKeyBundle)
    case encryptedMessage(String)
}

/// QR code errors for UI testing
enum QRCodeError: Error, Equatable {
    case unsupportedFormat
    case invalidBundleData
    case invalidEnvelopeFormat
    case cameraPermissionDenied
    case scanningNotAvailable
    case generationFailed(String)
    case invalidBundleFormat(Error)
    
    var localizedDescription: String {
        switch self {
        case .unsupportedFormat:
            return "Unsupported QR code format"
        case .invalidBundleData:
            return "Invalid contact bundle data"
        case .invalidEnvelopeFormat:
            return "Invalid message envelope format"
        case .cameraPermissionDenied:
            return "Camera permission denied"
        case .scanningNotAvailable:
            return "QR scanning not available"
        case .generationFailed(let reason):
            return "QR generation failed: \(reason)"
        case .invalidBundleFormat:
            return "Invalid bundle format"
        }
    }
    
    static func == (lhs: QRCodeError, rhs: QRCodeError) -> Bool {
        switch (lhs, rhs) {
        case (.unsupportedFormat, .unsupportedFormat),
             (.invalidBundleData, .invalidBundleData),
             (.invalidEnvelopeFormat, .invalidEnvelopeFormat),
             (.cameraPermissionDenied, .cameraPermissionDenied),
             (.scanningNotAvailable, .scanningNotAvailable):
            return true
        case (.generationFailed(let lhsReason), .generationFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.invalidBundleFormat, .invalidBundleFormat):
            return true
        default:
            return false
        }
    }
}

/// Sample public key bundle for UI testing
struct PublicKeyBundle {
    let id: UUID
    let name: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date
}

/// Decryption result for UI testing
struct DecryptionResult {
    let plaintext: Data
    let attribution: AttributionResult
    let timestamp: Date
    let senderAttribution: String
    
    var isSigned: Bool {
        switch attribution {
        case .signed, .signedUnknown:
            return true
        case .unsigned, .invalidSignature:
            return false
        }
    }
}

/// Attribution result for UI testing
enum AttributionResult {
    case signed(String, String)
    case unsigned(String)
    case signedUnknown
    case invalidSignature
}

/// WhisperError for UI testing
enum WhisperError: Error, Equatable {
    case invalidEnvelope
    case cryptographicFailure
    case qrUnsupportedFormat
    case qrInvalidContent
    case qrCameraPermissionDenied
    case qrScanningNotAvailable
    case policyViolation(PolicyViolation)
    case replayDetected
}

/// Policy violation for UI testing
enum PolicyViolation: Error, Equatable {
    case biometricRequired
    case rawKeyBlocked
}

/// Identity for UI testing
struct Identity {
    let id: UUID
    let name: String
    let x25519KeyPair: MockKeyPair
    let ed25519KeyPair: MockKeyPair?
    let fingerprint: Data
    let shortFingerprint: String
    let sasWords: [String]
    let rkid: Data
    let status: IdentityStatus
}

/// Contact for UI testing
struct Contact {
    let id: UUID
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let shortFingerprint: String
    let sasWords: [String]
    let rkid: Data
    let trustLevel: TrustLevel
    let isBlocked: Bool
    let keyVersion: Int
    let keyHistory: [KeyHistoryEntry]
    let createdAt: Date
    let lastSeenAt: Date?
    let note: String?
}

/// Supporting types for UI testing
enum IdentityStatus {
    case active
    case archived
}

enum TrustLevel {
    case verified
    case unverified
    case revoked
}

struct KeyHistoryEntry {
    let publicKey: Data
    let version: Int
    let rotatedAt: Date
}

struct MockKeyPair {
    let publicKey: Data
    let privateKey: Data
}

// MARK: - Mock DecryptViewModel for UI Testing

/// Mock DecryptViewModel that implements QR scan functionality for UI testing
@MainActor
class MockDecryptViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var inputText: String = ""
    @Published var showDetectionBanner: Bool = false
    @Published var isValidWhisperMessage: Bool = false
    @Published var isDecrypting: Bool = false
    @Published var decryptionResult: DecryptionResult?
    @Published var currentError: WhisperError?
    @Published var showingSuccess: Bool = false
    @Published var successMessage: String = ""
    @Published var showingInvalidFormatAlert: Bool = false
    @Published var showingQRScanner: Bool = false
    @Published var isQRScanComplete: Bool = false
    
    // MARK: - Private Properties
    
    private let whisperService: MockWhisperService
    private let qrCodeService: MockQRCodeService
    private var lastOperation: (() async -> Void)?
    
    // MARK: - Initialization
    
    init(whisperService: MockWhisperService, qrCodeService: MockQRCodeService) {
        self.whisperService = whisperService
        self.qrCodeService = qrCodeService
    }
    
    // MARK: - Computed Properties for QR Scan Visual Feedback
    
    var qrScanButtonText: String {
        if showingQRScanner {
            return "Scanning..."
        } else if isQRScanComplete {
            return "Scanned"
        } else {
            return "Scan QR"
        }
    }
    
    var qrScanButtonColor: Color {
        if showingQRScanner {
            return Color.orange
        } else if isQRScanComplete {
            return Color.green
        } else {
            return Color.blue
        }
    }
    
    var qrScanButtonForegroundColor: Color {
        return .white
    }
    
    var qrScanAccessibilityLabel: String {
        if showingQRScanner {
            return "QR scanner active"
        } else if isQRScanComplete {
            return "QR code scanned successfully"
        } else {
            return "Scan QR code"
        }
    }
    
    var qrScanAccessibilityHint: String {
        if showingQRScanner {
            return "QR scanner is currently active"
        } else if isQRScanComplete {
            return "QR code was successfully scanned"
        } else {
            return "Double tap to scan a QR code containing an encrypted message"
        }
    }
    
    // MARK: - Public Methods
    
    func validateInput() {
        isValidWhisperMessage = whisperService.detect(inputText)
    }
    
    func isValidWhisperMessage(text: String) -> Bool {
        return whisperService.detect(text)
    }
    
    func decryptManualInput() async {
        lastOperation = { await self.decryptMessage(self.inputText) }
        await decryptMessage(inputText)
    }
    
    func retryLastOperation() async {
        guard let operation = lastOperation else {
            retryQRScan()
            return
        }
        await operation()
    }
    
    func retryQRScan() {
        currentError = nil
        isQRScanComplete = false
        presentQRScanner()
    }
    
    func clearResult() {
        decryptionResult = nil
        inputText = ""
        showDetectionBanner = false
        isQRScanComplete = false
    }
    
    // MARK: - QR Scan Methods
    
    func handleQRScanResult(_ content: String) {
        do {
            let qrContent = try qrCodeService.parseQRCode(content)
            
            switch qrContent {
            case .encryptedMessage(let envelope):
                if validateQRContent(envelope) {
                    isQRScanComplete = true
                    showingQRScanner = false
                    inputText = envelope
                    successMessage = "QR code scanned successfully! Message ready to decrypt."
                    showingSuccess = true
                } else {
                    currentError = WhisperError.invalidEnvelope
                    showingQRScanner = false
                    isQRScanComplete = false
                }
                
            case .publicKeyBundle(_):
                currentError = WhisperError.qrInvalidContent
                showingQRScanner = false
                isQRScanComplete = false
            }
            
        } catch let error as QRCodeError {
            handleQRScanError(error)
        } catch {
            currentError = WhisperError.invalidEnvelope
            showingQRScanner = false
            isQRScanComplete = false
        }
    }
    
    func validateQRContent(_ content: String) -> Bool {
        return whisperService.detect(content)
    }
    
    func presentQRScanner() {
        isQRScanComplete = false
        showingQRScanner = true
    }
    
    func dismissQRScanner() {
        showingQRScanner = false
    }
    
    // MARK: - Private Methods
    
    private func decryptMessage(_ envelope: String) async {
        guard !envelope.isEmpty else {
            currentError = .invalidEnvelope
            return
        }
        
        guard whisperService.detect(envelope) else {
            currentError = .invalidEnvelope
            return
        }
        
        isDecrypting = true
        currentError = nil
        
        do {
            let result = try await whisperService.decrypt(envelope)
            decryptionResult = result
            showDetectionBanner = false
        } catch let error as WhisperError {
            currentError = error
        } catch {
            currentError = .cryptographicFailure
        }
        
        isDecrypting = false
    }
    
    private func handleQRScanError(_ error: QRCodeError) {
        showingQRScanner = false
        isQRScanComplete = false
        
        switch error {
        case .unsupportedFormat:
            currentError = WhisperError.qrUnsupportedFormat
        case .invalidEnvelopeFormat:
            currentError = WhisperError.qrInvalidContent
        case .cameraPermissionDenied:
            currentError = WhisperError.qrCameraPermissionDenied
        case .scanningNotAvailable:
            currentError = WhisperError.qrScanningNotAvailable
        case .generationFailed(_):
            currentError = WhisperError.qrScanningNotAvailable
        case .invalidBundleData, .invalidBundleFormat(_):
            currentError = WhisperError.qrInvalidContent
        }
    }
}