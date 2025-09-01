import Foundation
import CryptoKit

// MARK: - Contact Model

struct Contact {
    let id: UUID
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data // lower 32 bytes of BLAKE2s/SHA-256 hash
    let shortFingerprint: String // Base32 Crockford (12 chars)
    let sasWords: [String] // 6-word sequence for verification
    let rkid: Data
    var trustLevel: TrustLevel
    var isBlocked: Bool
    let keyVersion: Int
    let keyHistory: [KeyHistoryEntry]
    let createdAt: Date
    var lastSeenAt: Date?
    var note: String?
    
    init(id: UUID = UUID(),
         displayName: String,
         x25519PublicKey: Data,
         ed25519PublicKey: Data? = nil,
         note: String? = nil) throws {
        
        self.id = id
        self.displayName = displayName
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.note = note
        self.trustLevel = .unverified
        self.isBlocked = false
        self.keyVersion = 1
        self.keyHistory = []
        self.createdAt = Date()
        self.lastSeenAt = nil
        
        // Generate fingerprint using BLAKE2s or SHA-256 fallback
        self.fingerprint = try Contact.generateFingerprint(from: x25519PublicKey)
        
        // Generate short fingerprint (Base32 Crockford, 12 chars)
        self.shortFingerprint = Contact.generateShortFingerprint(from: fingerprint)
        
        // Generate SAS words (6-word sequence)
        self.sasWords = Contact.generateSASWords(from: fingerprint)
        
        // Generate recipient key ID (rkid) - lower 8 bytes of fingerprint
        self.rkid = Data(fingerprint.suffix(8))
    }
    
    // MARK: - Static Helper Methods
    
    static func generateFingerprint(from publicKey: Data) throws -> Data {
        // Try BLAKE2s first, fallback to SHA-256
        if #available(iOS 16.0, *) {
            // Use BLAKE2s if available (iOS 16+)
            let hash = try BLAKE2s.hash(data: publicKey, outputByteCount: 32)
            return Data(hash)
        } else {
            // Fallback to SHA-256
            let hash = SHA256.hash(data: publicKey)
            return Data(hash)
        }
    }
    
    static func generateShortFingerprint(from fingerprint: Data) -> String {
        // Take lower 32 bytes and encode as Base32 Crockford, then take first 12 chars
        let base32 = fingerprint.base32CrockfordEncoded()
        return String(base32.prefix(12))
    }
    
    static func generateSASWords(from fingerprint: Data) -> [String] {
        // Generate 6-word SAS sequence from fingerprint
        let sasWordList = SASWordList.words
        var words: [String] = []
        
        // Use first 6 bytes of fingerprint to select words
        let bytes = Array(fingerprint.prefix(6))
        for byte in bytes {
            let index = Int(byte) % sasWordList.count
            words.append(sasWordList[index])
        }
        
        return words
    }
}

// MARK: - Trust Level

enum TrustLevel: String, CaseIterable {
    case unverified = "unverified"
    case verified = "verified"
    case revoked = "revoked"
    
    var displayName: String {
        switch self {
        case .unverified:
            return "Unverified"
        case .verified:
            return "Verified"
        case .revoked:
            return "Revoked"
        }
    }
    
    var badgeColor: String {
        switch self {
        case .unverified:
            return "orange"
        case .verified:
            return "green"
        case .revoked:
            return "red"
        }
    }
}

// MARK: - Key History Entry

struct KeyHistoryEntry {
    let id: UUID
    let keyVersion: Int
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let createdAt: Date
    
    init(keyVersion: Int,
         x25519PublicKey: Data,
         ed25519PublicKey: Data? = nil) throws {
        
        self.id = UUID()
        self.keyVersion = keyVersion
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.createdAt = Date()
        
        // Generate fingerprint for this key version
        self.fingerprint = try Contact.generateFingerprint(from: x25519PublicKey)
    }
}

// MARK: - Public Key Bundle

struct PublicKeyBundle: Codable {
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date
    
    init(from contact: Contact) {
        self.displayName = contact.displayName
        self.x25519PublicKey = contact.x25519PublicKey
        self.ed25519PublicKey = contact.ed25519PublicKey
        self.fingerprint = contact.fingerprint
        self.keyVersion = contact.keyVersion
        self.createdAt = contact.createdAt
    }
}

// MARK: - Contact Extensions

extension Contact {
    func withUpdatedTrustLevel(_ newTrustLevel: TrustLevel) -> Contact {
        var updated = self
        updated.trustLevel = newTrustLevel
        return updated
    }
    
    func withUpdatedBlockStatus(_ isBlocked: Bool) -> Contact {
        var updated = self
        updated.isBlocked = isBlocked
        return updated
    }
    
    func withUpdatedLastSeen(_ date: Date) -> Contact {
        var updated = self
        updated.lastSeenAt = date
        return updated
    }
    
    func withUpdatedNote(_ note: String?) -> Contact {
        var updated = self
        updated.note = note
        return updated
    }
    
    func withKeyRotation(newX25519Key: Data, newEd25519Key: Data? = nil) throws -> Contact {
        let newKeyHistory = try KeyHistoryEntry(
            keyVersion: keyVersion + 1,
            x25519PublicKey: newX25519Key,
            ed25519PublicKey: newEd25519Key
        )
        
        var updated = self
        updated.keyHistory.append(newKeyHistory)
        // Note: In a real implementation, we'd need to update the primary keys and regenerate derived fields
        return updated
    }
}