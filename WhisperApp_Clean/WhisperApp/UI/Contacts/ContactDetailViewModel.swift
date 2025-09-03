import Foundation

// MARK: - Contact Detail View Model

@MainActor
class ContactDetailViewModel: ObservableObject {
    @Published var contact: Contact
    @Published var showingQRCode = false
    @Published var qrCodeResult: QRCodeResult?
    
    private let qrCodeService = QRCodeService()
    
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
    
    func showQRCode() {
        do {
            let result = try qrCodeService.generateQRCode(for: contact)
            qrCodeResult = result
            showingQRCode = true
        } catch {
            // Handle error - in a real app you'd show an error alert
            print("Failed to generate QR code: \(error)")
        }
    }
}