import Combine
import Foundation
import LocalAuthentication
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

/// ViewModel for decrypt view handling decryption flow, and error handling
@MainActor
class DecryptViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var inputText: String = ""
    
    // @Published var clipboardContent: String = "" // Removed clipboard monitoring for better testing experience

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

    private let whisperService: WhisperService
    private let qrCodeService: QRCodeService

    private var lastOperation: (() async -> Void)?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        whisperService: WhisperService = ServiceContainer.shared.whisperService,
        qrCodeService: QRCodeService = QRCodeService()
    ) {
        self.whisperService = whisperService
        self.qrCodeService = qrCodeService
        setupBindings()
    }

    // MARK: - Computed Properties for QR Scan Visual Feedback

    /// Text displayed on the QR scan button based on current state
    var qrScanButtonText: String {
        if showingQRScanner {
            return "Scanning..."
        } else if isQRScanComplete {
            return "Scanned"
        } else {
            return "Scan QR"
        }
    }

    /// Background color for the QR scan button based on current state
    var qrScanButtonColor: Color {
        if showingQRScanner {
            return Color.orange  // Active scanning state
        } else if isQRScanComplete {
            return Color.green  // Success state
        } else {
            return Color.blue  // Default state
        }
    }

    /// Foreground color for the QR scan button based on current state
    var qrScanButtonForegroundColor: Color {
        return .white  // Always white for good contrast
    }

    /// Accessibility label for the QR scan button based on current state
    var qrScanAccessibilityLabel: String {
        if showingQRScanner {
            return "QR scanner active"
        } else if isQRScanComplete {
            return "QR code scanned successfully"
        } else {
            return "Scan QR code"
        }
    }

    /// Accessibility hint for the QR scan button based on current state
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
    
    /// Simple biometric authentication for user verification
    private func authenticateWithBiometrics() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let context = LAContext()
            let reason = "Authenticate to decrypt message"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }



    /// Validates if the input text is a valid whisper message format
    func validateInput() {
        isValidWhisperMessage = whisperService.detect(inputText)
    }

    /// Checks if the given text is a valid whisper message
    func isValidWhisperMessage(text: String) -> Bool {
        return whisperService.detect(text)
    }



    /// Decrypts message from manual input
    func decryptManualInput() async {
        lastOperation = { await self.decryptMessage(self.inputText) }
        await decryptMessage(inputText)
    }

    /// Retries the last decryption operation
    func retryLastOperation() async {
        guard let operation = lastOperation else {
            // If no last operation, try to retry QR scanning if that was the last action
            retryQRScan()
            return
        }
        await operation()
    }

    /// Retries QR scanning after permission or availability errors
    func retryQRScan() {
        // Clear any existing error and reset visual states
        currentError = nil
        isQRScanComplete = false
        // Present QR scanner again
        presentQRScanner()
    }

    /// Copies the decrypted message to clipboard
    func copyDecryptedMessage() {
        guard let result = decryptionResult,
            let messageText = String(data: result.plaintext, encoding: .utf8)
        else {
            return
        }

        // Handle clipboard access gracefully
        do {
            UIPasteboard.general.string = messageText

            // Show success feedback
            successMessage = "Message copied to clipboard"
            showingSuccess = true

            // Reset success message after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showingSuccess = false
            }
        } catch {
            // Clipboard access denied - show alternative feedback
            successMessage = "Clipboard access denied"
            showingSuccess = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showingSuccess = false
            }
        }
    }

    /// Clears the decryption result and resets the view
    func clearResult() {
        decryptionResult = nil
        inputText = ""
        isQRScanComplete = false  // Reset QR scan visual state
    }

    // MARK: - QR Scan Methods

    /// Handles QR scan result and validates content
    func handleQRScanResult(_ content: String) {
        print("🔍 QR SCAN: Received QR content: \(content.prefix(100))...")
        print("🔍 QR SCAN: Full content length: \(content.count)")

        do {
            // Parse the QR code content using QRCodeService
            let qrContent = try qrCodeService.parseQRCode(content)
            print("🔍 QR SCAN: Successfully parsed QR content")

            // Only accept encrypted messages, reject other types
            switch qrContent {
            case .encryptedMessage(let envelope):
                print("🔍 QR SCAN: Found encrypted message envelope")
                print("🔍 QR SCAN: Envelope: \(envelope.prefix(100))...")

                // Validate the envelope format using WhisperService
                if validateQRContent(envelope) {
                    print("🔍 QR SCAN: ✅ Envelope validation passed")

                    // Show scan completion visual feedback
                    isQRScanComplete = true
                    
                    // Populate input field with valid encrypted message
                    inputText = envelope
                    
                    // Dismiss scanner immediately - no need for delay
                    showingQRScanner = false
                    print("🔍 QR SCAN: QR scanner dismissed, message populated in input field")

                    // Provide haptic feedback for successful scan
                    #if canImport(UIKit)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    #endif

                    // Reset scan complete state after a delay to show success feedback
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        print("🔍 QR SCAN: Resetting QR scan complete state")
                        self.isQRScanComplete = false
                    }
                } else {
                    print("🔍 QR SCAN: ❌ Envelope validation failed")
                    // Invalid envelope format
                    currentError = WhisperError.invalidEnvelope
                    showingQRScanner = false
                    isQRScanComplete = false
                }

            case .publicKeyBundle(_):
                print("🔍 QR SCAN: ❌ Found public key bundle instead of encrypted message")
                // Reject public key bundle QR codes with appropriate error
                currentError = WhisperError.qrInvalidContent
                showingQRScanner = false
                isQRScanComplete = false
            }

        } catch let error as QRCodeError {
            print("🔍 QR SCAN: ❌ QR parsing error: \(error)")
            // Handle QR-specific errors
            handleQRScanError(error)
        } catch {
            print("🔍 QR SCAN: ❌ Unexpected error: \(error)")
            // Handle unexpected errors
            currentError = WhisperError.invalidEnvelope
            showingQRScanner = false
            isQRScanComplete = false
        }
    }

    /// Validates QR content using existing WhisperService.detect() method
    func validateQRContent(_ content: String) -> Bool {
        print("🔍 QR VALIDATION: Checking content: \(content.prefix(100))...")
        let isValid = whisperService.detect(content)
        print("🔍 QR VALIDATION: Content is valid: \(isValid)")
        return isValid
    }

    /// Presents the QR scanner
    func presentQRScanner() {
        // Reset previous scan completion state
        isQRScanComplete = false
        showingQRScanner = true

        // Provide haptic feedback when starting scan
        #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        #endif
    }

    /// Dismisses the QR scanner
    func dismissQRScanner() {
        print("🔍 DECRYPT_VM: dismissQRScanner called")
        showingQRScanner = false
        print("🔍 DECRYPT_VM: Set showingQRScanner = false")
        // Don't reset isQRScanComplete here - let it show success state if scan was successful
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Auto-validate input text changes
        $inputText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.validateInput()
            }
            .store(in: &cancellables)
    }

    /// Core decryption method with comprehensive error handling
    private func decryptMessage(_ envelope: String) async {
        print("🔍 DECRYPT_VM: decryptMessage called")
        print("🔍 DECRYPT_VM: Envelope length: \(envelope.count)")
        print("🔍 DECRYPT_VM: Envelope: \(envelope)")

        guard !envelope.isEmpty else {
            print("🔍 DECRYPT_VM: ❌ Empty envelope")
            currentError = .invalidEnvelope
            return
        }

        print("🔍 DECRYPT_VM: Checking envelope detection...")
        let isDetected = whisperService.detect(envelope)
        print("🔍 DECRYPT_VM: Envelope detected: \(isDetected)")

        guard isDetected else {
            print("🔍 DECRYPT_VM: ❌ Envelope not detected by WhisperService")
            currentError = .invalidEnvelope
            return
        }

        // Check if biometric authentication is required for decryption
        let policyManager = ServiceContainer.shared.policyManager
        if policyManager.requiresBiometricForSigning() {
            print("🔍 DECRYPT_VM: Biometric authentication required for decryption")
            
            // Simple biometric authentication using LocalAuthentication
            do {
                let success = try await authenticateWithBiometrics()
                if !success {
                    print("🔍 DECRYPT_VM: ❌ Biometric authentication failed")
                    currentError = .biometricAuthenticationFailed
                    return
                }
                print("🔍 DECRYPT_VM: ✅ Biometric authentication successful")
            } catch {
                print("🔍 DECRYPT_VM: ❌ Biometric authentication error: \(error)")
                currentError = .biometricAuthenticationFailed
                return
            }
        }

        print("🔍 DECRYPT_VM: Starting decryption process...")
        isDecrypting = true
        currentError = nil  // Clear any previous errors

        do {
            print("🔍 DECRYPT_VM: Calling whisperService.decrypt...")
            let result = try await whisperService.decrypt(envelope)
            print("🔍 DECRYPT_VM: ✅ Decryption successful!")
            print("🔍 DECRYPT_VM: Result plaintext length: \(result.plaintext.count)")
            if let messageText = String(data: result.plaintext, encoding: .utf8) {
                print("🔍 DECRYPT_VM: Decrypted message: '\(messageText)'")
            }

            // Success - update UI on main thread
            decryptionResult = result

        } catch let error as WhisperError {
            print("🔍 DECRYPT_VM: ❌ WhisperError: \(error)")
            print("🔍 DECRYPT_VM: Error description: \(error.errorDescription ?? "Unknown")")
            currentError = error
        } catch {
            print("🔍 DECRYPT_VM: ❌ Unknown error: \(error)")
            print("🔍 DECRYPT_VM: Error type: \(type(of: error))")
            currentError = .cryptographicFailure
        }

        print("🔍 DECRYPT_VM: Decryption process completed")
        isDecrypting = false
    }

    /// Handles QR scan specific errors
    private func handleQRScanError(_ error: QRCodeError) {
        showingQRScanner = false
        isQRScanComplete = false

        // Provide haptic feedback for error
        #if canImport(UIKit)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        #endif

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

// MARK: - Service Container
// ServiceContainer is now defined in Services/ServiceContainer.swift
