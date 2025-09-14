import Foundation
import UniformTypeIdentifiers

@MainActor
class BackupRestoreViewModel: ObservableObject {
    @Published var identities: [Identity] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var shareURL: URL?
    @Published var showingShareSheet = false
    @Published var backupData: Data?
    @Published var showingRestoreSheet = false
    
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
            
            // Create backup file in temporary directory for sharing
            let tempDir = FileManager.default.temporaryDirectory
            let backupFileName = "whisper-backup-\(identity.name.replacingOccurrences(of: " ", with: "-"))-\(Int(Date().timeIntervalSince1970)).wbak"
            let backupURL = tempDir.appendingPathComponent(backupFileName)
            
            try backupData.write(to: backupURL)
            
            successMessage = "Backup created successfully. Use the share button to save it."
            errorMessage = nil
            
            // Trigger share sheet
            shareBackupFile(url: backupURL, fileName: backupFileName)
            
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
            
            // Request access to the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Failed to access the selected file. Please try again."
                return
            }
            
            defer {
                // Always stop accessing the resource when done
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let fileData = try Data(contentsOf: url)
                print("📁 Successfully read backup file: \(url.lastPathComponent)")
                print("📁 File size: \(fileData.count) bytes")
                
                // Store the backup data and show the restore sheet
                self.backupData = fileData
                showingRestoreSheet = true
                
                // Clear any previous messages
                successMessage = nil
                errorMessage = nil
                
            } catch {
                errorMessage = "Failed to read backup file: \(error.localizedDescription)"
                successMessage = nil
            }
            
        case .failure(let error):
            errorMessage = "Failed to import file: \(error.localizedDescription)"
            successMessage = nil
        }
    }
    
    private func shareBackupFile(url: URL, fileName: String) {
        shareURL = url
        showingShareSheet = true
        print("📁 Backup file created: \(fileName)")
        print("📁 File location: \(url.path)")
    }
    
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}