import Combine
import CoreData
import CryptoKit
import Foundation
import LocalAuthentication
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Type Definitions

// QRCodeService and QRCodeResult are defined in QRCodeService.swift

/// ViewModel for the compose view that handles encryption logic and policy enforcement
@MainActor
class ComposeViewModel: ObservableObject {
    // MARK: - Constants
    private let maxCharacterLimit = 40000

    // MARK: - Published Properties
    @Published var messageText: String = ""
    @Published var selectedContact: Contact?

    @Published var activeIdentity: Identity?
    @Published var encryptedMessage: String?

    // UI State
    @Published var showingContactPicker: Bool = false
    @Published var showingIdentityPicker: Bool = false
    @Published var showingError: Bool = false
    @Published var showingBiometricPrompt: Bool = false
    @Published var showingQRCode: Bool = false
    @Published var showingShareSheet: Bool = false
    @Published var errorMessage: String = ""
    @Published var qrCodeResult: QRCodeResult?
    @Published var availableIdentities: [Identity] = []

    // MARK: - Dependencies
    private let whisperService: WhisperService
    private let identityManager: IdentityManager
    private let contactManager: ContactManager
    private let policyManager: PolicyManager
    private let qrCodeService: QRCodeService

    // MARK: - Computed Properties
    var canEncrypt: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && activeIdentity != nil && selectedContact != nil
    }

    var showEncryptButton: Bool {
        encryptedMessage == nil
    }

    var showPostEncryptionButtons: Bool {
        encryptedMessage != nil
    }

    var characterCount: Int {
        messageText.count
    }

    var remainingCharacters: Int {
        maxCharacterLimit - messageText.count
    }

    var isContactRequired: Bool {
        policyManager.contactRequiredToSend
    }

    // MARK: - Methods
    func updateMessageText(_ newText: String) {
        let limitedText = String(newText.prefix(maxCharacterLimit))
        messageText = limitedText
    }

    // MARK: - Initialization
    init(
        whisperService: WhisperService? = nil,
        identityManager: IdentityManager? = nil,
        contactManager: ContactManager? = nil,
        policyManager: PolicyManager? = nil,
        qrCodeService: QRCodeService = QRCodeService()
    ) {

        // Use real services from ServiceContainer if not provided
        self.whisperService = whisperService ?? ServiceContainer.shared.whisperService
        self.identityManager = identityManager ?? ServiceContainer.shared.identityManager
        self.contactManager = contactManager ?? ServiceContainer.shared.contactManager
        self.policyManager = policyManager ?? ServiceContainer.shared.policyManager
        self.qrCodeService = qrCodeService

        loadActiveIdentity()

        // Clear encrypted message when message text or contact changes
        $messageText.dropFirst()  // Skip initial value
            .sink { [weak self] _ in
                self?.clearEncryptedMessage()
            }
            .store(in: &cancellables)

        $selectedContact.dropFirst()  // Skip initial value
            .sink { [weak self] _ in
                self?.clearEncryptedMessage()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func clearEncryptedMessage() {
        encryptedMessage = nil
        qrCodeResult = nil
        showingQRCode = false
        showingShareSheet = false
    }

    // MARK: - Public Methods
    
    /// Simple biometric authentication for user verification
    private func authenticateWithBiometrics() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let context = LAContext()
            let reason = "Authenticate to encrypt message"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    func encryptMessage() async {
        guard let identity = activeIdentity else {
            showError("No active identity selected")
            return
        }

        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Message cannot be empty")
            return
        }

        // Check if contact is required but not selected
        guard selectedContact != nil || !isContactRequired else {
            showError("Please select a contact to encrypt the message")
            return
        }

        // Check if biometric authentication is required
        let policyManager = ServiceContainer.shared.policyManager
        if policyManager.requiresBiometricForSigning() {
            do {
                let success = try await authenticateWithBiometrics()
                if !success {
                    showError("Biometric authentication failed")
                    return
                }
            } catch {
                showError("Biometric authentication failed: \(error.localizedDescription)")
                return
            }
        }

        let messageData = messageText.data(using: .utf8)!
        
        // Use normal signing behavior (not related to biometric authentication)
        let shouldSign = false  // Keep signatures disabled for now

        do {
            let envelope: String
            if let contact = selectedContact {
                // Encrypt to contact
                envelope = try await whisperService.encrypt(
                    messageData,
                    from: identity,
                    to: contact,
                    authenticity: shouldSign)
            } else {
                // This should not happen if policies are enforced correctly
                // But we'll handle raw key encryption for completeness
                guard !isContactRequired else {
                    showError("Contact selection is required by policy")
                    return
                }

                // For now, we don't support raw key input in this implementation
                showError("Please select a contact from your contact list to encrypt the message")
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

        // Copy to clipboard
        #if canImport(UIKit)
            UIPasteboard.general.string = message
        #endif

        // Show brief success feedback
        withAnimation {
            // Could add a success toast here in the future
            print("✅ Copied encrypted message to clipboard")
        }
    }

    func showIdentityPicker() {
        // Load all available identities
        availableIdentities = identityManager.listIdentities()
        print(
            "🔍 Loaded \(availableIdentities.count) identities: \(availableIdentities.map { $0.name })"
        )
        showingIdentityPicker = true
    }

    func selectIdentity(_ identity: Identity) {
        do {
            try identityManager.setActiveIdentity(identity)
            activeIdentity = identity
            showingIdentityPicker = false
            clearEncryptedMessage()  // Clear any existing encrypted message
            print("✅ Selected identity: \(identity.name)")
        } catch {
            print("❌ Failed to select identity: \(error)")
            showError("Failed to select identity: \(error.localizedDescription)")
        }
    }

    func showRawKeyInput() {
        // TODO: Implement raw key input dialog
        // This would show a text field for entering a raw X25519 public key
    }

    func showQRCode() {
        guard let envelope = encryptedMessage else { return }

        do {
            let result = try qrCodeService.generateQRCode(for: envelope)
            qrCodeResult = result
            showingQRCode = true
        } catch {
            showError("Failed to generate QR code: \(error.localizedDescription)")
        }
    }

    func cancelBiometricAuth() {
        showingBiometricPrompt = false
        // The encryption operation will fail with biometric cancellation
    }

    func handleSharingCompleted() {
        // Called when sharing is completed
        // This can be used for analytics, cleanup, or other post-sharing actions
        print("✅ Message sharing completed successfully")

        // Optional: Clear the encrypted message after sharing
        // clearEncryptedMessage()
    }

    // MARK: - Private Methods
    private func loadActiveIdentity() {
        // Load initial active identity - prefer active status over archived
        do {
            let allIdentities = identityManager.listIdentities()

            // First try to get the currently active identity
            if let currentActive = identityManager.getActiveIdentity(),
                currentActive.status == .active
            {
                activeIdentity = currentActive
            } else {
                // If no active identity or current active is archived,
                // select the first active (non-archived) identity
                activeIdentity = allIdentities.first { $0.status == .active }

                // If we found a better active identity, set it as the active one
                if let betterIdentity = activeIdentity {
                    try identityManager.setActiveIdentity(betterIdentity)
                }
            }

            print(
                "🔍 Selected identity: \(activeIdentity?.name ?? "none") (status: \(activeIdentity?.status.rawValue ?? "none"))"
            )
        } catch {
            print("❌ Failed to load active identity: \(error)")
            // Fallback to simple approach
            activeIdentity = identityManager.getActiveIdentity()
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
            case .biometricRequired:
                showingBiometricPrompt = true
            }
        case .biometricAuthenticationFailed:
            showError("Biometric authentication was cancelled or failed")
        case .keyNotFound:
            showError("Signing key not found. Please check your identity configuration.")
        default:
            showError(error.localizedDescription)
        }
    }

    private func requiresBiometricForSigning() -> Bool {
        return policyManager.requiresBiometricForSigning()
    }

    private func handleUserCancelled() {
        showError("Biometric authentication was cancelled")
    }
}

// MARK: - Service Container
// ServiceContainer is now defined in Services/ServiceContainer.swift

// MARK: - Mock Implementations
// MockWhisperService removed - now using real encryption/decryption services

/// Mock IdentityManager for UI development
class MockIdentityManager: IdentityManager {
    private var allIdentities: [Identity] = {
        // Create multiple mock identities to match what user has in settings
        var identities: [Identity] = []

        // Makif (Active)
        let makifPrivateKey = try! Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: Data(repeating: 1, count: 32))
        let makifEd25519Key = try! Curve25519.Signing.PrivateKey(
            rawRepresentation: Data(repeating: 2, count: 32))
        let makif = Identity(
            id: UUID(),
            name: "Makif",
            x25519KeyPair: X25519KeyPair(
                privateKey: makifPrivateKey, publicKey: Data(repeating: 1, count: 32)),
            ed25519KeyPair: Ed25519KeyPair(
                privateKey: makifEd25519Key, publicKey: Data(repeating: 2, count: 32)),
            fingerprint: Data(repeating: 3, count: 32),
            createdAt: Date(timeIntervalSinceNow: -86400 * 30),  // 30 days ago
            status: .active,
            keyVersion: 1
        )
        identities.append(makif)

        // Work
        let workPrivateKey = try! Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: Data(repeating: 4, count: 32))
        let workEd25519Key = try! Curve25519.Signing.PrivateKey(
            rawRepresentation: Data(repeating: 5, count: 32))
        let work = Identity(
            id: UUID(),
            name: "Work",
            x25519KeyPair: X25519KeyPair(
                privateKey: workPrivateKey, publicKey: Data(repeating: 4, count: 32)),
            ed25519KeyPair: Ed25519KeyPair(
                privateKey: workEd25519Key, publicKey: Data(repeating: 5, count: 32)),
            fingerprint: Data(repeating: 6, count: 32),
            createdAt: Date(timeIntervalSinceNow: -86400 * 20),  // 20 days ago
            status: .active,
            keyVersion: 1
        )
        identities.append(work)

        // Home
        let homePrivateKey = try! Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: Data(repeating: 7, count: 32))
        let homeEd25519Key = try! Curve25519.Signing.PrivateKey(
            rawRepresentation: Data(repeating: 8, count: 32))
        let home = Identity(
            id: UUID(),
            name: "Home",
            x25519KeyPair: X25519KeyPair(
                privateKey: homePrivateKey, publicKey: Data(repeating: 7, count: 32)),
            ed25519KeyPair: Ed25519KeyPair(
                privateKey: homeEd25519Key, publicKey: Data(repeating: 8, count: 32)),
            fingerprint: Data(repeating: 9, count: 32),
            createdAt: Date(timeIntervalSinceNow: -86400 * 10),  // 10 days ago
            status: .active,
            keyVersion: 1
        )
        identities.append(home)

        return identities
    }()

    private var activeIdentityId: UUID?

    init() {
        // Set the first identity (Makif) as active by default
        activeIdentityId = allIdentities.first?.id
    }

    func createIdentity(name: String) throws -> Identity {
        throw IdentityError.noActiveIdentity
    }

    func listIdentities() -> [Identity] {
        return allIdentities
    }

    func getActiveIdentity() -> Identity? {
        if let activeId = activeIdentityId {
            return allIdentities.first { $0.id == activeId }
        }
        // Default to first identity if none is set
        return allIdentities.first
    }

    func setActiveIdentity(_ identity: Identity) throws {
        guard allIdentities.contains(where: { $0.id == identity.id }) else {
            throw IdentityError.noActiveIdentity
        }
        activeIdentityId = identity.id
    }

    func archiveIdentity(_ identity: Identity) throws {}

    func rotateActiveIdentity() throws -> Identity { throw IdentityError.noActiveIdentity }

    func exportPublicBundle(_ identity: Identity) throws -> Data { return Data() }

    func importPublicBundle(_ data: Data) throws -> PublicKeyBundle {
        throw IdentityError.invalidBundleFormat(NSError())
    }

    func backupIdentity(_ identity: Identity, passphrase: String) throws -> Data { return Data() }

    func restoreIdentity(from backup: Data, passphrase: String) throws -> Identity {
        throw IdentityError.noActiveIdentity
    }

    func getIdentity(byRkid rkid: Data) -> Identity? { return nil }

    func getIdentitiesNeedingRotationWarning() -> [Identity] { return [] }

    func deleteIdentity(_ identity: Identity) throws {
        // Mock implementation - just remove from array
        allIdentities.removeAll { $0.id == identity.id }
        if activeIdentityId == identity.id {
            activeIdentityId = allIdentities.first?.id
        }
    }
}

// UserDefaultsPolicyManager is defined in PolicyManager.swift
// MockContactManager is defined in ContactListViewModel.swift

// MARK: - Extensions
// TrustLevel extension is defined in Contact.swift
// WhisperError extension is defined in WhisperService.swift
