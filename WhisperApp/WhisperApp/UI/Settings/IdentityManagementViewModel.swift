import CoreData
import Foundation

@MainActor
class IdentityManagementViewModel: ObservableObject {
    @Published var identities: [Identity] = []
    @Published var activeIdentity: Identity?
    @Published var errorMessage: String?
    @Published var qrCodeResult: QRCodeResult?
    @Published var showingQRCode = false

    private let identityManager: IdentityManager
    private let qrCodeService = QRCodeService()

    init(identityManager: IdentityManager? = nil) {
        // In a real app, this would be injected via dependency injection
        // For now, we'll create a default instance
        if let manager = identityManager {
            self.identityManager = manager
        } else {
            // This would normally be injected from the app's dependency container
            let context = PersistenceController.shared.container.viewContext
            let cryptoEngine = CryptoKitEngine()
            let policyManager = UserDefaultsPolicyManager()
            self.identityManager = CoreDataIdentityManager(
                context: context,
                cryptoEngine: cryptoEngine,
                policyManager: policyManager
            )
        }
    }

    func loadIdentities() {
        identities = identityManager.listIdentities()
        activeIdentity = identityManager.getActiveIdentity()
    }
    
    func clearError() {
        errorMessage = nil
    }

    func createIdentity(name: String) {
        // Ensure we have the latest identities loaded
        loadIdentities()
        
        // Check for duplicate names (case-insensitive)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            errorMessage = "Identity name cannot be empty."
            return
        }
        
        let existingNames = identities.map { $0.name.lowercased() }
        print("🔍 Checking for duplicates. Existing names: \(existingNames)")
        print("🔍 New name (lowercase): '\(trimmedName.lowercased())'")

        if existingNames.contains(trimmedName.lowercased()) {
            errorMessage = "An identity with the name '\(trimmedName)' already exists. Please choose a different name."
            print("❌ Duplicate name detected: '\(trimmedName)'")
            return
        }

        do {
            let newIdentity = try identityManager.createIdentity(name: trimmedName)
            loadIdentities()

            // If this is the first identity, make it active
            if activeIdentity == nil {
                try identityManager.setActiveIdentity(newIdentity)
                activeIdentity = newIdentity
            }

            print("✅ Created new identity: \(trimmedName)")
        } catch {
            errorMessage = "Failed to create identity: \(error.localizedDescription)"
            print("❌ Failed to create identity: \(error)")
        }
    }

    func setActiveIdentity(_ identity: Identity) {
        do {
            try identityManager.setActiveIdentity(identity)

            // Force refresh to get updated identity status
            loadIdentities()

            // Update the active identity reference
            activeIdentity = identityManager.getActiveIdentity()

            print("✅ Set \(identity.name) as default identity")

            // If the identity was archived, it should now be active
            if let updatedIdentity = identities.first(where: { $0.id == identity.id }) {
                if updatedIdentity.status == .active {
                    print("🔄 Successfully restored archived identity to active status")
                }
            }
        } catch {
            errorMessage = "Failed to activate identity: \(error.localizedDescription)"
            print("❌ Failed to set active identity: \(error)")
        }
    }

    func rotateActiveIdentity() {
        guard let currentActive = activeIdentity else {
            errorMessage = "No active identity to rotate"
            return
        }
        
        do {
            let newIdentity = try identityManager.rotateActiveIdentity()
            activeIdentity = newIdentity
            loadIdentities()
            
            // Provide success feedback
            print("✅ Successfully rotated identity '\(currentActive.name)' to '\(newIdentity.name)'")
            print("🔒 Old identity archived for decrypt-only access")
        } catch {
            errorMessage = "Failed to rotate identity: \(error.localizedDescription)"
            print("❌ Failed to rotate identity: \(error)")
        }
    }

    func generateQRCode(for identity: Identity) {
        do {
            // Extract public keys from the identity's key pairs
            let x25519PublicKey = identity.x25519KeyPair.publicKey
            let ed25519PublicKey = identity.ed25519KeyPair?.publicKey

            // Create a public key bundle from the identity
            let publicKeyBundle = PublicKeyBundle(
                id: identity.id,
                name: identity.name,
                x25519PublicKey: x25519PublicKey,
                ed25519PublicKey: ed25519PublicKey,
                fingerprint: identity.fingerprint,
                keyVersion: identity.keyVersion,
                createdAt: identity.createdAt
            )

            // Generate QR code for the public key bundle
            let qrResult = try qrCodeService.generateQRCode(for: publicKeyBundle)
            self.qrCodeResult = qrResult
            self.showingQRCode = true
        } catch {
            errorMessage = "Failed to generate QR code: \(error.localizedDescription)"
        }
    }

    func deleteIdentity(_ identity: Identity) {
        do {
            try identityManager.deleteIdentity(identity)
            loadIdentities()

            // If we deleted the active identity, clear it
            if activeIdentity?.id == identity.id {
                activeIdentity = nil
            }
        } catch {
            errorMessage = "Failed to delete identity: \(error.localizedDescription)"
        }
    }

    func archiveIdentity(_ identity: Identity) {
        do {
            let wasActiveIdentity = activeIdentity?.id == identity.id

            // Archive the identity
            try identityManager.archiveIdentity(identity)

            // If we archived the active identity, automatically set a new default
            if wasActiveIdentity {
                // Find the first active (non-archived) identity to set as new default
                let remainingActiveIdentities = identityManager.listIdentities().filter {
                    $0.status == .active && $0.id != identity.id
                }

                if let newDefaultIdentity = remainingActiveIdentities.first {
                    try identityManager.setActiveIdentity(newDefaultIdentity)
                    activeIdentity = newDefaultIdentity
                    print("🔄 Automatically set \(newDefaultIdentity.name) as new default identity")
                } else {
                    // No active identities left
                    activeIdentity = nil
                    print("⚠️ No active identities remaining after archiving")
                }
            }

            loadIdentities()
        } catch {
            errorMessage = "Failed to archive identity: \(error.localizedDescription)"
        }
    }
}
