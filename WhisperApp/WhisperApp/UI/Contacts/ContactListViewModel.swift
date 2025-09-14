import Combine
import CoreData
import Foundation

// MARK: - Contact List View Model

@MainActor
class ContactListViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let contactManager: ContactManager
    private var cancellables = Set<AnyCancellable>()

    init(contactManager: ContactManager? = nil) {
        // Use dependency injection or create default instance
        if let manager = contactManager {
            self.contactManager = manager
        } else {
            // Use real CoreDataContactManager - will be initialized when needed
            self.contactManager = SharedContactManager.shared
        }
    }

    // MARK: - Public Methods

    func loadContacts() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedContacts = contactManager.listContacts()
                await MainActor.run {
                    self.contacts = loadedContacts.sorted { $0.displayName < $1.displayName }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func refreshContacts() async {
        await MainActor.run {
            loadContacts()
        }
    }

    func searchContacts(query: String) -> [Contact] {
        return contactManager.searchContacts(query: query)
    }

    func addContact(_ contact: Contact) {
        do {
            try contactManager.addContact(contact)
            loadContacts()  // Refresh the list
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateContact(_ contact: Contact) {
        do {
            try contactManager.updateContact(contact)
            loadContacts()  // Refresh the list
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteContact(_ contactId: UUID) throws {
        try contactManager.deleteContact(id: contactId)
        loadContacts()  // Refresh the list
    }

    func blockContact(_ contactId: UUID) throws {
        try contactManager.blockContact(id: contactId)
        loadContacts()  // Refresh the list
    }

    func unblockContact(_ contactId: UUID) throws {
        try contactManager.unblockContact(id: contactId)
        loadContacts()  // Refresh the list
    }

    func verifyContact(_ contactId: UUID, sasConfirmed: Bool) throws {
        try contactManager.verifyContact(id: contactId, sasConfirmed: sasConfirmed)
        loadContacts()  // Refresh the list
    }

    func exportKeybook() throws -> Data {
        return try contactManager.exportPublicKeybook()
    }

    func needsKeyRotationWarning(for contact: Contact) -> Bool {
        // Check if contact has had key rotation and needs re-verification
        return contact.keyHistory.count > 0 && contact.trustLevel == .unverified
    }

    func handleKeyRotation(for contact: Contact, newX25519Key: Data, newEd25519Key: Data? = nil)
        throws
    {
        try contactManager.handleKeyRotation(
            for: contact, newX25519Key: newX25519Key, newEd25519Key: newEd25519Key)
        loadContacts()  // Refresh the list
    }

}

// MARK: - Mock Contact Manager (for development/testing)

class MockContactManager: ContactManager {
    private var contacts: [Contact] = []

    init() {
        // Add some sample contacts for development
        addSampleContacts()
    }

    func addContact(_ contact: Contact) throws {
        if contacts.contains(where: { $0.id == contact.id }) {
            throw ContactManagerError.contactAlreadyExists
        }
        contacts.append(contact)
    }

    func updateContact(_ contact: Contact) throws {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else {
            throw ContactManagerError.contactNotFound
        }
        contacts[index] = contact
    }

    func deleteContact(id: UUID) throws {
        guard let index = contacts.firstIndex(where: { $0.id == id }) else {
            throw ContactManagerError.contactNotFound
        }
        contacts.remove(at: index)
    }

    func getContact(id: UUID) -> Contact? {
        return contacts.first { $0.id == id }
    }

    func getContact(byRkid rkid: Data) -> Contact? {
        return contacts.first { $0.rkid == rkid }
    }

    func listContacts() -> [Contact] {
        return contacts
    }

    func searchContacts(query: String) -> [Contact] {
        return contacts.filter { contact in
            contact.displayName.localizedCaseInsensitiveContains(query)
                || contact.note?.localizedCaseInsensitiveContains(query) == true
        }
    }

    func verifyContact(id: UUID, sasConfirmed: Bool) throws {
        guard let index = contacts.firstIndex(where: { $0.id == id }) else {
            throw ContactManagerError.contactNotFound
        }

        let trustLevel: TrustLevel = sasConfirmed ? .verified : .unverified
        contacts[index] = contacts[index].withUpdatedTrustLevel(trustLevel)
    }

    func blockContact(id: UUID) throws {
        guard let index = contacts.firstIndex(where: { $0.id == id }) else {
            throw ContactManagerError.contactNotFound
        }
        contacts[index] = contacts[index].withUpdatedBlockStatus(true)
    }

    func unblockContact(id: UUID) throws {
        guard let index = contacts.firstIndex(where: { $0.id == id }) else {
            throw ContactManagerError.contactNotFound
        }
        contacts[index] = contacts[index].withUpdatedBlockStatus(false)
    }

    func exportPublicKeybook() throws -> Data {
        let publicBundles = contacts.map { PublicKeyBundle(from: $0) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(publicBundles)
    }

    func handleKeyRotation(for contact: Contact, newX25519Key: Data, newEd25519Key: Data?) throws {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else {
            throw ContactManagerError.contactNotFound
        }

        // Create updated contact with new keys and reset trust level
        let updatedContact = try Contact(
            id: contact.id,
            displayName: contact.displayName,
            x25519PublicKey: newX25519Key,
            ed25519PublicKey: newEd25519Key,
            note: contact.note
        ).withUpdatedTrustLevel(.unverified)  // Reset trust on key rotation

        contacts[index] = updatedContact
    }

    func checkForKeyRotation(contact: Contact, currentX25519Key: Data) -> Bool {
        return contact.x25519PublicKey != currentX25519Key
    }

    private func addSampleContacts() {
        do {
            let alice = try Contact(
                displayName: "Alice Smith",
                x25519PublicKey: Data(repeating: 0x01, count: 32),
                ed25519PublicKey: Data(repeating: 0x02, count: 32),
                note: "Work colleague"
            ).withUpdatedTrustLevel(.verified)

            let bob = try Contact(
                displayName: "Bob Johnson",
                x25519PublicKey: Data(repeating: 0x03, count: 32),
                note: "Friend from college"
            )

            let charlie = try Contact(
                displayName: "Charlie Brown",
                x25519PublicKey: Data(repeating: 0x05, count: 32),
                ed25519PublicKey: Data(repeating: 0x06, count: 32)
            ).withUpdatedBlockStatus(true)

            contacts = [alice, bob, charlie]
        } catch {
            print("Error creating sample contacts: \(error)")
        }
    }
}

// MARK: - Contact Picker View Model (for Compose View)

@MainActor
class ContactPickerViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showOnlyVerified: Bool = true  // ✅ Default to verified only for security

    private let contactManager: ContactManager

    init() {
        // Always use real contact manager for contact picker
        self.contactManager = SharedContactManager.shared
    }

    func loadContacts() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedContacts = contactManager.listContacts()
                await MainActor.run {
                    // Filter out blocked contacts
                    var filteredContacts = loadedContacts.filter { !$0.isBlocked }

                    // SECURITY: Only show verified contacts by default for message composition
                    if showOnlyVerified {
                        filteredContacts = filteredContacts.filter { $0.trustLevel == .verified }
                    }

                    // Sort by trust level first (verified first), then by name
                    self.contacts = filteredContacts.sorted { contact1, contact2 in
                        if contact1.trustLevel != contact2.trustLevel {
                            return contact1.trustLevel == .verified
                                && contact2.trustLevel != .verified
                        }
                        return contact1.displayName < contact2.displayName
                    }

                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func toggleVerificationFilter() {
        showOnlyVerified.toggle()
        loadContacts()  // Reload with new filter
    }
}

// MARK: - Shared Contact Manager

class SharedContactManager {
    static let shared: ContactManager = {
        // Try to get the real CoreDataContactManager
        // If PersistenceController is available, use it
        // Otherwise fall back to mock for development
        #if DEBUG
            // In debug mode, you can switch between real and mock
            // Set this to true to use real data, false for mock data
            let useRealData = true  // ✅ Always use real data to avoid dummy contacts

            if useRealData {
                // This will be resolved at runtime when PersistenceController is available
                return RealContactManagerWrapper()
            } else {
                return MockContactManager()
            }
        #else
            // In release mode, always use real data
            return RealContactManagerWrapper()
        #endif
    }()
}

// MARK: - Real Contact Manager Wrapper

class RealContactManagerWrapper: ContactManager {
    private lazy var realManager: ContactManager = {
        // Get the shared persistence controller from the app
        let persistentContainer = PersistenceController.shared.container
        return CoreDataContactManager(persistentContainer: persistentContainer)
    }()

    func addContact(_ contact: Contact) throws {
        try realManager.addContact(contact)
    }

    func updateContact(_ contact: Contact) throws {
        try realManager.updateContact(contact)
    }

    func deleteContact(id: UUID) throws {
        try realManager.deleteContact(id: id)
    }

    func getContact(id: UUID) -> Contact? {
        return realManager.getContact(id: id)
    }

    func getContact(byRkid rkid: Data) -> Contact? {
        return realManager.getContact(byRkid: rkid)
    }

    func listContacts() -> [Contact] {
        return realManager.listContacts()
    }

    func searchContacts(query: String) -> [Contact] {
        return realManager.searchContacts(query: query)
    }

    func verifyContact(id: UUID, sasConfirmed: Bool) throws {
        try realManager.verifyContact(id: id, sasConfirmed: sasConfirmed)
    }

    func blockContact(id: UUID) throws {
        try realManager.blockContact(id: id)
    }

    func unblockContact(id: UUID) throws {
        try realManager.unblockContact(id: id)
    }

    func exportPublicKeybook() throws -> Data {
        return try realManager.exportPublicKeybook()
    }

    func handleKeyRotation(for contact: Contact, newX25519Key: Data, newEd25519Key: Data?) throws {
        try realManager.handleKeyRotation(
            for: contact, newX25519Key: newX25519Key, newEd25519Key: newEd25519Key)
    }

    func checkForKeyRotation(contact: Contact, currentX25519Key: Data) -> Bool {
        return realManager.checkForKeyRotation(contact: contact, currentX25519Key: currentX25519Key)
    }
}
