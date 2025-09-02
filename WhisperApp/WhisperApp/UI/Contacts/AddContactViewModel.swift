import Foundation
import CryptoKit

// MARK: - Add Contact View Model

@MainActor
class AddContactViewModel: ObservableObject {
    // Input fields
    @Published var displayName = ""
    @Published var x25519PublicKeyString = ""
    @Published var ed25519PublicKeyString = ""
    @Published var note = ""
    @Published var qrCodeData = ""
    
    // Computed properties
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var canAddContact: Bool {
        return !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               x25519PublicKey != nil
    }
    
    var canPreviewContact: Bool {
        return canAddContact
    }
    
    var x25519PublicKey: Data? {
        return parsePublicKey(x25519PublicKeyString)
    }
    
    var ed25519PublicKey: Data? {
        guard !ed25519PublicKeyString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return parsePublicKey(ed25519PublicKeyString)
    }
    
    var shortFingerprint: String {
        guard let publicKey = x25519PublicKey else { return "" }
        
        do {
            let fingerprint = try Contact.generateFingerprint(from: publicKey)
            return Contact.generateShortFingerprint(from: fingerprint)
        } catch {
            return ""
        }
    }
    
    var fingerprintDisplay: String {
        guard let publicKey = x25519PublicKey else { return "" }
        
        do {
            let fingerprint = try Contact.generateFingerprint(from: publicKey)
            return fingerprint.map { String(format: "%02x", $0) }.joined(separator: " ")
        } catch {
            return ""
        }
    }
    
    var sasWords: [String] {
        guard let publicKey = x25519PublicKey else { return [] }
        
        do {
            let fingerprint = try Contact.generateFingerprint(from: publicKey)
            return Contact.generateSASWords(from: fingerprint)
        } catch {
            return []
        }
    }
    
    // MARK: - Public Methods
    
    func createContact() throws -> Contact {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw AddContactError.invalidDisplayName
        }
        
        guard let x25519Key = x25519PublicKey else {
            throw AddContactError.invalidX25519Key
        }
        
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = trimmedNote.isEmpty ? nil : trimmedNote
        
        return try Contact(
            displayName: trimmedName,
            x25519PublicKey: x25519Key,
            ed25519PublicKey: ed25519PublicKey,
            note: finalNote
        )
    }
    
    func parseQRData() {
        do {
            let bundle = try parsePublicKeyBundle(qrCodeData)
            displayName = bundle.displayName
            x25519PublicKeyString = bundle.x25519PublicKey.base64EncodedString()
            if let ed25519Key = bundle.ed25519PublicKey {
                ed25519PublicKeyString = ed25519Key.base64EncodedString()
            }
            errorMessage = nil
        } catch {
            errorMessage = "Invalid QR code data: \(error.localizedDescription)"
        }
    }
    
    func clearForm() {
        displayName = ""
        x25519PublicKeyString = ""
        ed25519PublicKeyString = ""
        note = ""
        qrCodeData = ""
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func parsePublicKey(_ keyString: String) -> Data? {
        let trimmed = keyString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // Try Base64 first
        if let data = Data(base64Encoded: trimmed) {
            return data.count == 32 ? data : nil
        }
        
        // Try hex encoding
        let hexString = trimmed.replacingOccurrences(of: " ", with: "")
        if hexString.count == 64, let data = Data(hexString: hexString) {
            return data
        }
        
        return nil
    }
    
    private func parsePublicKeyBundle(_ qrData: String) throws -> PublicKeyBundle {
        // Try to parse as JSON first (public key bundle)
        if let jsonData = qrData.data(using: .utf8) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let bundle = try? decoder.decode(PublicKeyBundle.self, from: jsonData) {
                return bundle
            }
        }
        
        // Try to parse as simple key format
        if let publicKey = parsePublicKey(qrData) {
            return PublicKeyBundle(
                displayName: "Scanned Contact",
                x25519PublicKey: publicKey,
                ed25519PublicKey: nil,
                fingerprint: try Contact.generateFingerprint(from: publicKey),
                keyVersion: 1,
                createdAt: Date()
            )
        }
        
        throw AddContactError.invalidQRData
    }
}

// MARK: - Add Contact Errors

enum AddContactError: Error, LocalizedError {
    case invalidDisplayName
    case invalidX25519Key
    case invalidEd25519Key
    case invalidQRData
    case contactAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .invalidDisplayName:
            return "Please enter a valid display name"
        case .invalidX25519Key:
            return "Invalid X25519 public key. Please enter a valid Base64 or hex encoded key."
        case .invalidEd25519Key:
            return "Invalid Ed25519 public key. Please enter a valid Base64 or hex encoded key."
        case .invalidQRData:
            return "Invalid QR code data. Please scan a valid contact QR code."
        case .contactAlreadyExists:
            return "A contact with this key already exists"
        }
    }
}

// MARK: - Data Extensions

extension Data {
    init?(hexString: String) {
        let length = hexString.count
        guard length % 2 == 0 else { return nil }
        
        var data = Data()
        var index = hexString.startIndex
        
        for _ in 0..<(length / 2) {
            let nextIndex = hexString.index(index, offsetBy: 2)
            let byteString = String(hexString[index..<nextIndex])
            
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            
            index = nextIndex
        }
        
        self = data
    }
}