import SwiftUI
import Foundation
import CryptoKit

// MARK: - Type Definitions

/// Represents a cryptographic identity with key pairs and metadata
struct Identity {
    let id: UUID
    let name: String
    let x25519KeyPair: X25519KeyPair
    let ed25519KeyPair: Ed25519KeyPair?
    let fingerprint: Data
    let createdAt: Date
    let status: IdentityStatus
    let keyVersion: Int
}

/// Status of a cryptographic identity
enum IdentityStatus {
    case active
    case archived
    case rotated
}

/// X25519 key pair for key agreement
struct X25519KeyPair {
    let privateKey: Curve25519.KeyAgreement.PrivateKey
    let publicKey: Data
}

/// Ed25519 key pair for signing
struct Ed25519KeyPair {
    let privateKey: Curve25519.Signing.PrivateKey
    let publicKey: Data
}

/// Public key bundle for sharing identities
struct PublicKeyBundle: Codable {
    let id: UUID
    let name: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date
}

/// Identity management errors
enum IdentityError: Error {
    case noActiveIdentity
    case invalidBundleFormat(Error)
}

/// ViewModel for the compose view that handles encryption logic and policy enforcement
@MainActor
class ComposeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messageText: String = ""
    @Published var selectedContact: Contact?
    @Published var includeSignature: Bool = false
    @Published var activeIdentity: Identity?
    @Published var encryptedMessage: String?
    
    // UI State
    @Published var showingContactPicker: Bool = false
    @Published var showingError: Bool = false
    @Published var showingBiometricPrompt: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Dependencies
    
    private let whisperService: WhisperService
    private let identityManager: IdentityManager
    private let contactManager: ContactManager
    private let policyManager: PolicyManager
    
    // MARK: - Computed Properties
    
    var canEncrypt: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        activeIdentity != nil &&
        (selectedContact != nil || !isContactRequired)
    }
    
    var isContactRequired: Bool {
        policyManager.contactRequiredToSend
    }
    
    var isSignatureRequired: Bool {
        guard let contact = selectedContact else { return false }
        return policyManager.requireSignatureForVerified && contact.trustLevel == .verified
    }
    
    // MARK: - Initialization
    
    init(whisperService: WhisperService = ServiceContainer.shared.whisperService,
         identityManager: IdentityManager = ServiceContainer.shared.identityManager,
         contactManager: ContactManager = ServiceContainer.shared.contactManager,
         policyManager: PolicyManager = ServiceContainer.shared.policyManager) {
        
        self.whisperService = whisperService
        self.identityManager = identityManager
        self.contactManager = contactManager
        self.policyManager = policyManager
        
        loadActiveIdentity()
        updateSignatureRequirement()
    }
    
    // MARK: - Public Methods
    
    func encryptMessage() async {
        guard let identity = activeIdentity else {
            showError("No active identity selected")
            return
        }
        
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Message cannot be empty")
            return
        }
        
        let messageData = messageText.data(using: .utf8)!
        let shouldSign = includeSignature || isSignatureRequired
        
        do {
            let envelope: String
            
            if let contact = selectedContact {
                // Encrypt to contact
                envelope = try await whisperService.encrypt(
                    messageData,
                    from: identity,
                    to: contact,
                    authenticity: shouldSign
                )
            } else {
                // This should not happen if policies are enforced correctly
                // But we'll handle raw key encryption for completeness
                guard !isContactRequired else {
                    showError("Contact selection is required by policy")
                    return
                }
                
                // For now, we don't support raw key input in this implementation
                showError("Raw key encryption not implemented in this view")
                return
            }
            
            encryptedMessage = envelope
            
        } catch let error as WhisperError {
            handleWhisperError(error)
        } catch {
            showError("Encryption failed: \(error.localizedDescription)")
        }
    }
    
    func copyToClipboard() {
        guard let message = encryptedMessage else { return }
        
        UIPasteboard.general.string = message
        
        // Show brief success feedback
        withAnimation {
            // You could add a success state here
        }
    }
    
    func showIdentityPicker() {
        // TODO: Implement identity picker
        // For now, just reload the active identity
        loadActiveIdentity()
    }
    
    func showRawKeyInput() {
        // TODO: Implement raw key input dialog
        // This would show a text field for entering a raw X25519 public key
    }
    
    func cancelBiometricAuth() {
        showingBiometricPrompt = false
        // The encryption operation will fail with biometric cancellation
    }
    
    // MARK: - Private Methods
    
    private func loadActiveIdentity() {
        activeIdentity = identityManager.getActiveIdentity()
    }
    
    private func updateSignatureRequirement() {
        // Update signature toggle based on policy and selected contact
        if isSignatureRequired {
            includeSignature = true
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func handleWhisperError(_ error: WhisperError) {
        switch error {
        case .policyViolation(let type):
            switch type {
            case .contactRequired, .rawKeyBlocked:
                showError("Contact selection is required by your security policy")
            case .signatureRequired:
                showError("Signature is required for verified contacts")
                includeSignature = true
            case .biometricRequired:
                showingBiometricPrompt = true
            }
        case .biometricAuthenticationFailed:
            showError("Biometric authentication was cancelled or failed")
        case .keyNotFound:
            showError("Signing key not found. Please check your identity configuration.")
        default:
            showError(error.userFacingMessage)
        }
    }
    
    private func requiresBiometricForSigning() -> Bool {
        return policyManager.requiresBiometricForSigning()
    }
    
    private func handleUserCancelled() {
        showError("Biometric authentication was cancelled")
    }
}

// MARK: - Contact Picker ViewModel

@MainActor
class ContactPickerViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    
    private let contactManager: ContactManager
    
    init(contactManager: ContactManager = ServiceContainer.shared.contactManager) {
        self.contactManager = contactManager
    }
    
    func loadContacts() {
        // Load all non-blocked contacts
        contacts = contactManager.listContacts().filter { !$0.isBlocked }
    }
}

// MARK: - Service Container

/// Simple service container for dependency injection
/// In a real app, this would be more sophisticated
class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {}
    
    // MARK: - Service Properties
    
    lazy var whisperService: WhisperService = {
        // For now, return a mock implementation
        return MockWhisperService()
    }()
    
    lazy var identityManager: IdentityManager = {
        // For now, return a mock implementation
        return MockIdentityManager()
    }()
    
    lazy var contactManager: ContactManager = {
        // For now, return a mock implementation
        return MockContactManager()
    }()
    
    lazy var policyManager: PolicyManager = {
        return UserDefaultsPolicyManager()
    }()
}

// MARK: - Mock Implementations

/// Mock WhisperService for UI development
class MockWhisperService: WhisperService {
    func encrypt(_ data: Data, from identity: Identity, to peer: Contact, authenticity: Bool) async throws -> String {
        // Simulate encryption delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return a mock envelope
        return "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT.SIGNATURE"
    }
    
    func encryptToRawKey(_ data: Data, from identity: Identity, to publicKey: Data, authenticity: Bool) async throws -> String {
        // Simulate encryption delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return a mock envelope
        return "whisper1:v1.c20p.ABC123DEF456.01.EPHEMERAL_KEY.SALT.MSGID.TIMESTAMP.CIPHERTEXT.SIGNATURE"
    }
    
    func decrypt(_ envelope: String) async throws -> DecryptionResult {
        throw WhisperError.invalidEnvelope
    }
    
    func detect(_ text: String) -> Bool {
        return text.contains("whisper1:")
    }
}

/// Mock IdentityManager for UI development
class MockIdentityManager: IdentityManager {
    private var activeIdentity: Identity? = Identity(
        id: UUID(),
        name: "My Identity",
        x25519KeyPair: X25519KeyPair(
            privateKey: try! Curve25519.KeyAgreement.PrivateKey(rawRepresentation: Data(repeating: 1, count: 32)),
            publicKey: Data(repeating: 1, count: 32)
        ),
        ed25519KeyPair: Ed25519KeyPair(
            privateKey: try! Curve25519.Signing.PrivateKey(rawRepresentation: Data(repeating: 2, count: 32)),
            publicKey: Data(repeating: 2, count: 32)
        ),
        fingerprint: Data(repeating: 3, count: 32),
        createdAt: Date(),
        status: .active,
        keyVersion: 1
    )
    
    func createIdentity(name: String) throws -> Identity {
        throw IdentityError.noActiveIdentity
    }
    
    func listIdentities() -> [Identity] {
        return activeIdentity.map { [$0] } ?? []
    }
    
    func getActiveIdentity() -> Identity? {
        return activeIdentity
    }
    
    func setActiveIdentity(_ identity: Identity) throws {}
    func archiveIdentity(_ identity: Identity) throws {}
    func rotateActiveIdentity() throws -> Identity { throw IdentityError.noActiveIdentity }
    func exportPublicBundle(_ identity: Identity) throws -> Data { return Data() }
    func importPublicBundle(_ data: Data) throws -> PublicKeyBundle { throw IdentityError.invalidBundleFormat(NSError()) }
    func backupIdentity(_ identity: Identity, passphrase: String) throws -> Data { return Data() }
    func restoreIdentity(from backup: Data, passphrase: String) throws -> Identity { throw IdentityError.noActiveIdentity }
    func getIdentity(byRkid rkid: Data) -> Identity? { return nil }
    func getIdentitiesNeedingRotationWarning() -> [Identity] { return [] }
}

/// Mock ContactManager for UI development
class MockContactManager: ContactManager {
    private var contacts: [Contact] = [
        try! Contact(id: UUID(), displayName: "Alice", x25519PublicKey: Data(repeating: 4, count: 32)),
        try! Contact(id: UUID(), displayName: "Bob", x25519PublicKey: Data(repeating: 5, count: 32)),
        try! Contact(id: UUID(), displayName: "Charlie", x25519PublicKey: Data(repeating: 6, count: 32))
    ]
    
    func addContact(_ contact: Contact) throws {}
    func updateContact(_ contact: Contact) throws {}
    func deleteContact(id: UUID) throws {}
    func getContact(id: UUID) -> Contact? { return nil }
    func getContact(byRkid rkid: Data) -> Contact? { return nil }
    func listContacts() -> [Contact] { return contacts }
    func searchContacts(query: String) -> [Contact] { return contacts }
    func verifyContact(id: UUID, sasConfirmed: Bool) throws {}
    func blockContact(id: UUID) throws {}
    func unblockContact(id: UUID) throws {}
    func exportPublicKeybook() throws -> Data { return Data() }
    func handleKeyRotation(for contact: Contact, newX25519Key: Data, newEd25519Key: Data?) throws {}
    func checkForKeyRotation(contact: Contact, currentX25519Key: Data) -> Bool { return false }
}

// MARK: - Extensions

extension TrustLevel {
    var badgeColor: String {
        switch self {
        case .unverified:
            return "orange"
        case .verified:
            return "green"
        case .revoked:
            return "red"
        }
    }
}

extension WhisperError {
    var userFacingMessage: String {
        switch self {
        case .invalidEnvelope:
            return "Invalid envelope"
        case .replayDetected:
            return "Replay detected"
        case .messageExpired:
            return "Message expired"
        case .messageNotForMe:
            return "This message is not addressed to you"
        case .policyViolation(let type):
            return type.userFacingMessage
        case .biometricAuthenticationFailed:
            return "Signature cancelled"
        default:
            return "Invalid envelope"
        }
    }
}