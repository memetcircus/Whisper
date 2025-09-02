import Foundation
import CoreData

@MainActor
class IdentityManagementViewModel: ObservableObject {
    @Published var identities: [Identity] = []
    @Published var activeIdentity: Identity?
    @Published var errorMessage: String?
    
    private let identityManager: IdentityManager
    
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
    
    func createIdentity(name: String) {
        do {
            let newIdentity = try identityManager.createIdentity(name: name)
            loadIdentities()
            
            // If this is the first identity, make it active
            if activeIdentity == nil {
                try identityManager.setActiveIdentity(newIdentity)
                activeIdentity = newIdentity
            }
        } catch {
            errorMessage = "Failed to create identity: \(error.localizedDescription)"
        }
    }
    
    func setActiveIdentity(_ identity: Identity) {
        do {
            try identityManager.setActiveIdentity(identity)
            activeIdentity = identity
            loadIdentities()
        } catch {
            errorMessage = "Failed to activate identity: \(error.localizedDescription)"
        }
    }
    
    func archiveIdentity(_ identity: Identity) {
        do {
            try identityManager.archiveIdentity(identity)
            loadIdentities()
            
            // If we archived the active identity, clear it
            if activeIdentity?.id == identity.id {
                activeIdentity = nil
            }
        } catch {
            errorMessage = "Failed to archive identity: \(error.localizedDescription)"
        }
    }
    
    func rotateActiveIdentity() {
        do {
            let newIdentity = try identityManager.rotateActiveIdentity()
            activeIdentity = newIdentity
            loadIdentities()
        } catch {
            errorMessage = "Failed to rotate identity: \(error.localizedDescription)"
        }
    }
}

// Placeholder for PersistenceController - this would normally be defined elsewhere
class PersistenceController {
    static let shared = PersistenceController()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WhisperDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
}