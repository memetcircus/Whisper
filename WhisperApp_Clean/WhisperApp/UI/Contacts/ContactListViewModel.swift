import Foundation
import Combine
import CoreData

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
            // TODO: Get from app's dependency container
            // For now, create a mock instance
            self.contactManager = MockContactManager()
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
            loadContacts() // Refresh the list
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateContact(_ contact: Contact) {
        do {
            try contactManager.updateContact(contact)
            loadContacts() // Refresh the list
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteContact(_ contactId: UUID) throws {
        try contactManager.deleteContact(id: contactId)
        loadContacts() // Refresh the list
    }
    
    func blockContact(_ contactId: UUID) throws {
        try contactManager.blockContact(id: contactId)
        loadContacts() // Refresh the list
    }
    
    func unblockContact(_ contactId: UUID) throws {
        try contactManager.unblockContact(id: contactId)
        loadContacts() // Refresh the list
    }
    
    func verifyContact(_ contactId: UUID, sasConfirmed: Bool) throws {
        try contactManager.verifyContact(id: contactId, sasConfirmed: sasConfirmed)
        loadContacts() // Refresh the list
    }
    
    func exportKeybook() throws -> Data {
        return try contactManager.exportPublicKeybook()
    }
    
    func needsKeyRotationWarning(for contact: Contact) -> Bool {
        // Check if contact has had key rotation and needs re-verification
        return contact.keyHistory.count > 0 && contact.trustLevel == .unverified
    }
    
    func handleKeyRotation(for contact: Contact, newX25519Key: Data, newEd25519Key: Data? = nil) throws {
        try contactManager.handleKeyRotation(for: contact, newX25519Key: newX25519Key, newEd25519Key: newEd25519Key)
        loadContacts() // Refresh the list
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
            contact.displayName.localizedCaseInsensitiveContains(query) ||
            contact.note?.localizedCaseInsensitiveContains(query) == true
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
        ).withUpdatedTrustLevel(.unverified) // Reset trust on key rotation
        
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