import Foundation

@MainActor
class ExportImportViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var identities: [Identity] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let contactManager: ContactManager
    private let identityManager: IdentityManager
    
    init(contactManager: ContactManager? = nil, identityManager: IdentityManager? = nil) {
        // In a real app, these would be injected via dependency injection
        if let cManager = contactManager {
            self.contactManager = cManager
        } else {
            let context = PersistenceController.shared.container.viewContext
            self.contactManager = CoreDataContactManager(
                persistentContainer: PersistenceController.shared.container
            )
        }
        
        if let iManager = identityManager {
            self.identityManager = iManager
        } else {
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
    
    func loadData() {
        contacts = contactManager.listContacts()
        identities = identityManager.listIdentities()
        clearMessages()
    }
    
    func exportContacts() {
        do {
            let keybook = try contactManager.exportPublicKeybook()
            
            // Save to Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = "whisper-contacts-\(Date().timeIntervalSince1970).json"
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            try keybook.write(to: fileURL)
            
            successMessage = "Contacts exported successfully: \(filename)"
            errorMessage = nil
            
            // In a real implementation, we'd show a share sheet
            shareFile(url: fileURL)
            
        } catch {
            errorMessage = "Failed to export contacts: \(error.localizedDescription)"
            successMessage = nil
        }
    }
    
    func importContacts(data: Data) {
        do {
            // Parse the JSON data and import contacts
            let decoder = JSONDecoder()
            let importedContacts = try decoder.decode([ContactExportData].self, from: data)
            
            var importedCount = 0
            for contactData in importedContacts {
                do {
                    let contact = try Contact.fromExportData(contactData)
                    try contactManager.addContact(contact)
                    importedCount += 1
                } catch {
                    // Skip invalid contacts but continue importing others
                    print("Failed to import contact: \(error)")
                }
            }
            
            successMessage = "Successfully imported \(importedCount) contacts"
            errorMessage = nil
            
            // Reload data to show imported contacts
            loadData()
            
        } catch {
            errorMessage = "Failed to import contacts: \(error.localizedDescription)"
            successMessage = nil
        }
    }
    
    func exportIdentityPublicBundle(identity: Identity) {
        do {
            let publicBundle = try identityManager.exportPublicBundle(identity)
            
            // Save to Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = "whisper-identity-\(identity.name)-\(Date().timeIntervalSince1970).wpub"
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            try publicBundle.write(to: fileURL)
            
            successMessage = "Identity public keys exported: \(filename)"
            errorMessage = nil
            
            // In a real implementation, we'd show a share sheet
            shareFile(url: fileURL)
            
        } catch {
            errorMessage = "Failed to export identity: \(error.localizedDescription)"
            successMessage = nil
        }
    }
    
    func handleContactImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                importContacts(data: data)
            } catch {
                errorMessage = "Failed to read import file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "Failed to import file: \(error.localizedDescription)"
        }
    }
    
    private func shareFile(url: URL) {
        // In a real implementation, we'd use UIActivityViewController
        print("File available for sharing at: \(url.path)")
    }
    
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Export Data Structures

struct ContactExportData: Codable {
    let id: String
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let shortFingerprint: String
    let trustLevel: String
    let keyVersion: Int
    let createdAt: Date
    let note: String?
}

extension Contact {
    static func fromExportData(_ data: ContactExportData) throws -> Contact {
        guard let trustLevel = TrustLevel(rawValue: data.trustLevel) else {
            throw ContactError.invalidTrustLevel
        }
        
        return Contact(
            id: UUID(uuidString: data.id) ?? UUID(),
            displayName: data.displayName,
            x25519PublicKey: data.x25519PublicKey,
            ed25519PublicKey: data.ed25519PublicKey,
            fingerprint: data.fingerprint,
            shortFingerprint: data.shortFingerprint,
            sasWords: [], // Would be regenerated
            rkid: Data(), // Would be regenerated
            trustLevel: trustLevel,
            isBlocked: false,
            keyVersion: data.keyVersion,
            keyHistory: [],
            createdAt: data.createdAt,
            lastSeenAt: nil,
            note: data.note
        )
    }
}

enum ContactError: Error {
    case invalidTrustLevel
}