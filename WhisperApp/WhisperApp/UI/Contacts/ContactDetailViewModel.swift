import Foundation

// MARK: - Contact Detail View Model

@MainActor
class ContactDetailViewModel: ObservableObject {
    @Published var contact: Contact
    
    init(contact: Contact) {
        self.contact = contact
    }
    
    // MARK: - Public Methods
    
    func updateContact(_ updatedContact: Contact) {
        contact = updatedContact
    }
    
    func updateTrustLevel(_ trustLevel: TrustLevel) {
        contact = contact.withUpdatedTrustLevel(trustLevel)
    }
    
    func toggleBlockStatus() {
        contact = contact.withUpdatedBlockStatus(!contact.isBlocked)
    }
    
    func updateNote(_ note: String?) {
        contact = contact.withUpdatedNote(note)
    }
    
    func updateLastSeen() {
        contact = contact.withUpdatedLastSeen(Date())
    }
}