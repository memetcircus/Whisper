import Foundation
import UniformTypeIdentifiers

@MainActor
class BackupRestoreViewModel: ObservableObject {
    @Published var identities: [Identity] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let identityManager: IdentityManager
    
    init(identityManager: IdentityManager? = nil) {
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
        clearMessages()
    }
    
    func createBackup(identity: Identity, passphrase: String) {
        do {
            let backupData = try identityManager.backupIdentity(identity, passphrase: passphrase)
            
            // Save backup to Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let backupFileName = "whisper-backup-\(identity.name)-\(Date().timeIntervalSince1970).wbak"
            let backupURL = documentsPath.appendingPathComponent(backupFileName)
            
            try backupData.write(to: backupURL)
            
            successMessage = "Backup created successfully: \(backupFileName)"
            errorMessage = nil
            
            // Share the backup file
            shareBackupFile(url: backupURL)
            
        } catch {
            errorMessage = "Failed to create backup: \(error.localizedDescription)"
            successMessage = nil
        }
    }
    
    func restoreFromBackup(data: Data, passphrase: String) {
        do {
            let restoredIdentity = try identityManager.restoreIdentity(from: data, passphrase: passphrase)
            
            successMessage = "Identity '\(restoredIdentity.name)' restored successfully"
            errorMessage = nil
            
            // Reload identities to show the restored one
            loadIdentities()
            
        } catch {
            errorMessage = "Failed to restore backup: \(error.localizedDescription)"
            successMessage = nil
        }
    }
    
    func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let backupData = try Data(contentsOf: url)
                // For now, we'll just store the data and let the user enter the passphrase
                // In a real implementation, we'd show the restore sheet here
                
            } catch {
                errorMessage = "Failed to read backup file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "Failed to import file: \(error.localizedDescription)"
        }
    }
    
    private func shareBackupFile(url: URL) {
        // In a real implementation, we'd use UIActivityViewController
        // For now, we'll just note that the file is available in Documents
        print("Backup file available at: \(url.path)")
    }
    
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}