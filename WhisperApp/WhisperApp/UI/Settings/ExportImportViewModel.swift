import Foundation

@MainActor
class ExportImportViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var identities: [Identity] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var shareURL: URL?
    @Published var showingShareSheet = false

    private var successMessageTimer: Timer?

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
    }

    func loadDataAndClearMessages() {
        contacts = contactManager.listContacts()
        identities = identityManager.listIdentities()
        clearMessages()
    }

    func exportContacts() {
        do {
            // Convert contacts to export format
            let exportData = contacts.map { contact in
                ContactExportData(
                    id: contact.id.uuidString,
                    displayName: contact.displayName,
                    x25519PublicKey: contact.x25519PublicKey,
                    ed25519PublicKey: contact.ed25519PublicKey,
                    fingerprint: contact.fingerprint,
                    shortFingerprint: contact.shortFingerprint,
                    trustLevel: contact.trustLevel.rawValue,
                    keyVersion: contact.keyVersion,
                    createdAt: contact.createdAt,
                    note: contact.note
                )
            }

            // Encode to JSON with proper date strategy
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(exportData)

            // Save to temporary directory for sharing
            let tempDir = FileManager.default.temporaryDirectory
            let filename = "whisper-contacts-\(Int(Date().timeIntervalSince1970)).json"
            let fileURL = tempDir.appendingPathComponent(filename)

            try jsonData.write(to: fileURL)

            showTemporarySuccessMessage(
                "Contacts exported successfully. The share sheet will appear to save or send the file."
            )

            // Trigger share sheet
            shareFile(url: fileURL)

        } catch {
            errorMessage = "Failed to export contacts: \(error.localizedDescription)"
            successMessage = nil
        }
    }

    func importContacts(data: Data) {
        do {
            print("📁 Starting contact import, data size: \(data.count) bytes")

            // Parse the JSON data and import contacts
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let importedContacts = try decoder.decode([ContactExportData].self, from: data)
            print("📁 Successfully decoded \(importedContacts.count) contacts from JSON")

            var importedCount = 0
            var failedCount = 0

            for contactData in importedContacts {
                do {
                    let contact = try Contact.fromExportData(contactData)
                    try contactManager.addContact(contact)
                    importedCount += 1
                    print("📁 Successfully imported contact: \(contact.displayName)")
                } catch {
                    failedCount += 1
                    print("📁 Failed to import contact \(contactData.displayName): \(error)")
                }
            }

            if importedCount > 0 {
                var message = "Successfully imported \(importedCount) contacts"
                if failedCount > 0 {
                    message += " (\(failedCount) failed)"
                }
                showTemporarySuccessMessage(message)
            } else {
                errorMessage = "No contacts could be imported (\(failedCount) failed)"
            }

            // Reload data to show imported contacts
            loadData()

        } catch {
            print("📁 Import failed with error: \(error)")
            errorMessage = "Failed to import contacts: \(error.localizedDescription)"
            successMessage = nil
        }
    }

    func exportIdentityPublicBundle(identity: Identity) {
        do {
            let publicBundle = try identityManager.exportPublicBundle(identity)

            // Save to temporary directory for sharing
            let tempDir = FileManager.default.temporaryDirectory
            let filename =
                "whisper-identity-\(identity.name.replacingOccurrences(of: " ", with: "-"))-\(Int(Date().timeIntervalSince1970)).wpub"
            let fileURL = tempDir.appendingPathComponent(filename)

            try publicBundle.write(to: fileURL)

            showTemporarySuccessMessage(
                "Identity public keys exported successfully. The share sheet will appear to save or send the file."
            )

            // Trigger share sheet
            shareFile(url: fileURL)

        } catch {
            errorMessage = "Failed to export identity: \(error.localizedDescription)"
            successMessage = nil
        }
    }

    func handleContactImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "No file was selected"
                return
            }

            print("📁 Attempting to import from: \(url.path)")
            print("📁 File exists: \(FileManager.default.fileExists(atPath: url.path))")

            // Request access to the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Failed to access the selected file. Please check file permissions."
                print("📁 Failed to start accessing security-scoped resource")
                return
            }

            defer {
                // Always stop accessing the resource when done
                url.stopAccessingSecurityScopedResource()
                print("📁 Stopped accessing security-scoped resource")
            }

            do {
                let data = try Data(contentsOf: url)
                print("📁 Successfully read contact import file: \(url.lastPathComponent)")
                print("📁 File size: \(data.count) bytes")

                // Validate it's JSON by trying to parse it first
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📁 File content preview: \(String(jsonString.prefix(200)))...")
                } else {
                    print("📁 Warning: File doesn't appear to be valid UTF-8 text")
                }

                importContacts(data: data)
            } catch {
                print("📁 Failed to read file: \(error)")
                errorMessage = "Failed to read import file: \(error.localizedDescription)"
                successMessage = nil
            }

        case .failure(let error):
            print("📁 File picker failed: \(error)")
            errorMessage = "Failed to select file: \(error.localizedDescription)"
            successMessage = nil
        }
    }

    func handlePublicKeyBundleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "No file was selected"
                return
            }

            print("📁 Attempting to import public key bundle from: \(url.path)")
            print("📁 File exists: \(FileManager.default.fileExists(atPath: url.path))")

            // Request access to the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Failed to access the selected file. Please check file permissions."
                print("📁 Failed to start accessing security-scoped resource")
                return
            }

            defer {
                // Always stop accessing the resource when done
                url.stopAccessingSecurityScopedResource()
                print("📁 Stopped accessing security-scoped resource")
            }

            do {
                let data = try Data(contentsOf: url)
                print("📁 Successfully read public key bundle file: \(url.lastPathComponent)")
                print("📁 File size: \(data.count) bytes")

                importPublicKeyBundle(data: data)
            } catch {
                print("📁 Failed to read file: \(error)")
                errorMessage =
                    "Failed to read public key bundle file: \(error.localizedDescription)"
                successMessage = nil
            }

        case .failure(let error):
            print("📁 File picker failed: \(error)")
            errorMessage = "Failed to select file: \(error.localizedDescription)"
            successMessage = nil
        }
    }

    private func shareFile(url: URL) {
        shareURL = url
        showingShareSheet = true
        print("📁 Export file created: \(url.lastPathComponent)")
        print("📁 File location: \(url.path)")
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
        successMessageTimer?.invalidate()
        successMessageTimer = nil
    }

    private func showTemporarySuccessMessage(_ message: String) {
        // Clear any existing timer
        successMessageTimer?.invalidate()

        // Set the success message
        successMessage = message
        errorMessage = nil

        // Auto-clear after 4 seconds
        successMessageTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) {
            [weak self] _ in
            DispatchQueue.main.async {
                self?.successMessage = nil
                self?.successMessageTimer = nil
            }
        }
    }

    func importPublicKeyBundle(data: Data) {
        do {
            print("📁 Starting public key bundle import, data size: \(data.count) bytes")

            // Try to parse with different date strategies since export doesn't use ISO8601
            var publicKeyBundle: PublicKeyBundleData?

            // First try with default date decoding (what the export actually uses)
            do {
                let decoder = JSONDecoder()
                publicKeyBundle = try decoder.decode(PublicKeyBundleData.self, from: data)
                print("📁 Successfully decoded with default date strategy")
            } catch {
                print("📁 Default date strategy failed, trying ISO8601: \(error)")

                // Fallback to ISO8601 for compatibility
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                publicKeyBundle = try decoder.decode(PublicKeyBundleData.self, from: data)
                print("📁 Successfully decoded with ISO8601 date strategy")
            }

            guard let publicKeyBundle = publicKeyBundle else {
                throw NSError(
                    domain: "ImportError", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to decode public key bundle"])
            }
            print("📁 Successfully decoded public key bundle for: \(publicKeyBundle.name)")

            // Create a contact from the public key bundle
            let contact = Contact(
                id: publicKeyBundle.id,
                displayName: publicKeyBundle.name,
                x25519PublicKey: publicKeyBundle.x25519PublicKey,
                ed25519PublicKey: publicKeyBundle.ed25519PublicKey,
                fingerprint: publicKeyBundle.fingerprint,
                shortFingerprint: Contact.generateShortFingerprint(
                    from: publicKeyBundle.fingerprint),
                sasWords: Contact.generateSASWords(from: publicKeyBundle.fingerprint),
                rkid: Data(publicKeyBundle.fingerprint.suffix(8)),
                trustLevel: .unverified,  // Always start as unverified for security
                isBlocked: false,
                keyVersion: publicKeyBundle.keyVersion,
                keyHistory: [],
                createdAt: publicKeyBundle.createdAt,
                lastSeenAt: nil,
                note: nil
            )

            // Add the contact
            try contactManager.addContact(contact)

            showTemporarySuccessMessage(
                "Successfully added \(contact.displayName) as a contact. Please verify their identity before sending sensitive messages."
            )

            print("📁 Successfully imported public key bundle as contact: \(contact.displayName)")

            // Reload data to show the new contact
            loadData()

        } catch {
            print("📁 Public key bundle import failed with error: \(error)")

            // Provide more specific error messages
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    errorMessage = "Invalid file format: \(context.debugDescription)"
                case .keyNotFound(let key, _):
                    errorMessage = "Missing required field: \(key.stringValue)"
                case .typeMismatch(let type, let context):
                    errorMessage =
                        "Invalid data type for field: expected \(type) at \(context.debugDescription)"
                case .valueNotFound(let type, let context):
                    errorMessage =
                        "Missing value for required field: \(type) at \(context.debugDescription)"
                @unknown default:
                    errorMessage = "Failed to parse public key bundle file"
                }
            } else {
                errorMessage = "Failed to import public key bundle: \(error.localizedDescription)"
            }
            successMessage = nil
        }
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

struct PublicKeyBundleData: Codable {
    let id: UUID
    let name: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date
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
            sasWords: [],  // Would be regenerated
            rkid: Data(),  // Would be regenerated
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
