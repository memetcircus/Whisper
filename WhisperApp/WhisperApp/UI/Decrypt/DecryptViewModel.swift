import Foundation
import SwiftUI
import Combine

/// ViewModel for decrypt view handling clipboard detection, decryption flow, and error handling
@MainActor
class DecryptViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var inputText: String = ""
    @Published var showDetectionBanner: Bool = false
    @Published var isValidWhisperMessage: Bool = false
    @Published var isDecrypting: Bool = false
    @Published var decryptionResult: DecryptionResult?
    @Published var currentError: WhisperError?
    @Published var showingSuccess: Bool = false
    @Published var successMessage: String = ""
    
    // MARK: - Private Properties
    
    private let whisperService: WhisperService
    private var clipboardContent: String = ""
    private var lastOperation: (() async -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(whisperService: WhisperService = ServiceContainer.shared.whisperService) {
        self.whisperService = whisperService
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Checks clipboard for whisper messages and shows detection banner if found
    func checkClipboard() {
        guard let clipboardString = UIPasteboard.general.string else {
            showDetectionBanner = false
            return
        }
        
        if whisperService.detect(clipboardString) {
            clipboardContent = clipboardString
            showDetectionBanner = true
        } else {
            showDetectionBanner = false
        }
    }
    
    /// Validates if the input text is a valid whisper message format
    func validateInput() {
        isValidWhisperMessage = whisperService.detect(inputText)
    }
    
    /// Decrypts message from clipboard
    func decryptFromClipboard() async {
        lastOperation = { await self.decryptMessage(self.clipboardContent) }
        await decryptMessage(clipboardContent)
    }
    
    /// Decrypts message from manual input
    func decryptManualInput() async {
        lastOperation = { await self.decryptMessage(self.inputText) }
        await decryptMessage(inputText)
    }
    
    /// Retries the last decryption operation
    func retryLastOperation() async {
        guard let operation = lastOperation else { return }
        await operation()
    }
    
    /// Copies the decrypted message to clipboard
    func copyDecryptedMessage() {
        guard let result = decryptionResult,
              let messageText = String(data: result.plaintext, encoding: .utf8) else {
            return
        }
        
        UIPasteboard.general.string = messageText
        
        // Show success feedback
        successMessage = "Message copied to clipboard"
        showingSuccess = true
        
        // Reset success message after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showingSuccess = false
        }
    }
    
    /// Clears the decryption result and resets the view
    func clearResult() {
        decryptionResult = nil
        inputText = ""
        showDetectionBanner = false
        clipboardContent = ""
        checkClipboard() // Re-check clipboard for new content
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
        guard !envelope.isEmpty else {
            currentError = .invalidEnvelope
            return
        }
        
        guard whisperService.detect(envelope) else {
            currentError = .invalidEnvelope
            return
        }
        
        isDecrypting = true
        currentError = nil // Clear any previous errors
        
        do {
            let result = try await whisperService.decrypt(envelope)
            
            // Success - update UI on main thread
            decryptionResult = result
            showDetectionBanner = false // Hide banner after successful decryption
            
        } catch let error as WhisperError {
            currentError = error
        } catch {
            currentError = .cryptographicFailure
        }
        
        isDecrypting = false
    }
    

}

// MARK: - Service Container

/// Simple service container for dependency injection
class ServiceContainer {
    static let shared = ServiceContainer()
    
    lazy var whisperService: WhisperService = {
        // In a real implementation, this would be properly initialized with all dependencies
        return DefaultWhisperService(
            cryptoEngine: DefaultCryptoEngine(),
            envelopeProcessor: DefaultEnvelopeProcessor(),
            identityManager: CoreDataIdentityManager(
                context: PersistenceController.shared.container.viewContext,
                cryptoEngine: DefaultCryptoEngine()
            ),
            contactManager: CoreDataContactManager(
                context: PersistenceController.shared.container.viewContext
            ),
            policyManager: DefaultPolicyManager(),
            biometricService: DefaultBiometricService(),
            replayProtector: CoreDataReplayProtector(
                context: PersistenceController.shared.container.viewContext
            ),
            messagePadding: DefaultMessagePadding()
        )
    }()
    
    private init() {}
}

