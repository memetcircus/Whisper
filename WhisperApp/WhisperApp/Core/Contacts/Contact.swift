import CryptoKit
import Foundation

// MARK: - Contact Model

struct Contact: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data  // lower 32 bytes of BLAKE2s/SHA-256 hash
    let shortFingerprint: String  // Base32 Crockford (12 chars)
    let sasWords: [String]  // 6-word sequence for verification
    let rkid: Data
    var trustLevel: TrustLevel
    var isBlocked: Bool
    let keyVersion: Int
    let keyHistory: [KeyHistoryEntry]
    let createdAt: Date
    var lastSeenAt: Date?
    var note: String?

    init(
        id: UUID = UUID(),
        displayName: String,
        x25519PublicKey: Data,
        ed25519PublicKey: Data? = nil,
        note: String? = nil
    ) throws {

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
    
    /// Initializer for creating Contact from PublicKeyBundle (preserves original fingerprint and SAS words)
    init(from bundle: PublicKeyBundle) {
        self.id = bundle.id
        self.displayName = bundle.name
        self.x25519PublicKey = bundle.x25519PublicKey
        self.ed25519PublicKey = bundle.ed25519PublicKey
        self.fingerprint = bundle.fingerprint
        self.shortFingerprint = Contact.generateShortFingerprint(from: bundle.fingerprint)
        self.sasWords = Contact.generateSASWords(from: bundle.fingerprint)
        self.rkid = Data(bundle.fingerprint.suffix(8))
        self.trustLevel = .unverified
        self.isBlocked = false
        self.keyVersion = bundle.keyVersion
        self.keyHistory = []
        self.createdAt = bundle.createdAt
        self.lastSeenAt = nil
        self.note = nil
    }
    
    // Private initializer for ContactManager to create Contact from database
    internal init(
        id: UUID,
        displayName: String,
        x25519PublicKey: Data,
        ed25519PublicKey: Data?,
        fingerprint: Data,
        shortFingerprint: String,
        sasWords: [String],
        rkid: Data,
        trustLevel: TrustLevel,
        isBlocked: Bool,
        keyVersion: Int,
        keyHistory: [KeyHistoryEntry],
        createdAt: Date,
        lastSeenAt: Date?,
        note: String?
    ) {
        self.id = id
        self.displayName = displayName
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.fingerprint = fingerprint
        self.shortFingerprint = shortFingerprint
        self.sasWords = sasWords
        self.rkid = rkid
        self.trustLevel = trustLevel
        self.isBlocked = isBlocked
        self.keyVersion = keyVersion
        self.keyHistory = keyHistory
        self.createdAt = createdAt
        self.lastSeenAt = lastSeenAt
        self.note = note
    }

    // MARK: - Static Helper Methods

    static func generateFingerprint(from publicKey: Data) throws -> Data {
        // Use SHA-256 for fingerprint generation (BLAKE2s not available in iOS CryptoKit)
        let hash = SHA256.hash(data: publicKey)
        return Data(hash)
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
            return LocalizationHelper.Contact.unverifiedBadge
        case .verified:
            return LocalizationHelper.Contact.verifiedBadge
        case .revoked:
            return LocalizationHelper.Contact.revokedBadge
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

    var accessibilityLabel: String {
        switch self {
        case .unverified:
            return LocalizationHelper.Accessibility.trustBadgeUnverified()
        case .verified:
            return LocalizationHelper.Accessibility.trustBadgeVerified()
        case .revoked:
            return LocalizationHelper.Accessibility.trustBadgeRevoked()
        }
    }
}

// MARK: - Key History Entry

struct KeyHistoryEntry: Equatable {
    let id: UUID
    let keyVersion: Int
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let createdAt: Date

    init(
        keyVersion: Int,
        x25519PublicKey: Data,
        ed25519PublicKey: Data? = nil
    ) throws {

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

struct ContactBundle: Codable {
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
    
    init(displayName: String, x25519PublicKey: Data, ed25519PublicKey: Data?, fingerprint: Data, keyVersion: Int, createdAt: Date) {
        self.displayName = displayName
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.fingerprint = fingerprint
        self.keyVersion = keyVersion
        self.createdAt = createdAt
    }
    
    init(publicKeyBundle: PublicKeyBundle) {
        self.displayName = publicKeyBundle.name
        self.x25519PublicKey = publicKeyBundle.x25519PublicKey
        self.ed25519PublicKey = publicKeyBundle.ed25519PublicKey
        self.fingerprint = publicKeyBundle.fingerprint
        self.keyVersion = publicKeyBundle.keyVersion
        self.createdAt = publicKeyBundle.createdAt
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
    
    /// Checks if this contact needs re-verification due to key rotation
    var needsReVerification: Bool {
        return keyHistory.count > 0 && trustLevel == .unverified
    }
    
    /// Returns a warning message if the contact has rotated keys and needs re-verification
    var keyRotationWarning: String? {
        if needsReVerification {
            return LocalizationHelper.Contact.keyRotationWarning
        }
        return nil
    }

    func withKeyRotation(newX25519Key: Data, newEd25519Key: Data? = nil) throws -> Contact {
        // Store the old keys in key history
        let oldKeyHistory = try KeyHistoryEntry(
            keyVersion: keyVersion,
            x25519PublicKey: x25519PublicKey,
            ed25519PublicKey: ed25519PublicKey
        )

        // Create new keyHistory array with the old keys
        let updatedKeyHistory = keyHistory + [oldKeyHistory]
        
        // Generate new fingerprint and identifiers for the new keys
        let newFingerprint = try Contact.generateFingerprint(from: newX25519Key)
        let newShortFingerprint = Contact.generateShortFingerprint(from: newFingerprint)
        let newSASWords = Contact.generateSASWords(from: newFingerprint)
        let newRkid = Data(newFingerprint.suffix(8))
        
        // Create new Contact with rotated keys and RESET TRUST LEVEL
        return Contact(
            id: id,
            displayName: displayName,
            x25519PublicKey: newX25519Key,        // ← New X25519 key
            ed25519PublicKey: newEd25519Key,      // ← New Ed25519 key
            fingerprint: newFingerprint,          // ← New fingerprint
            shortFingerprint: newShortFingerprint, // ← New short fingerprint
            sasWords: newSASWords,                // ← New SAS words
            rkid: newRkid,                        // ← New recipient key ID
            trustLevel: .unverified,              // ← SECURITY: Reset to unverified
            isBlocked: isBlocked,                 // ← Preserve block status
            keyVersion: keyVersion + 1,           // ← Increment version
            keyHistory: updatedKeyHistory,        // ← Store old keys in history
            createdAt: createdAt,                 // ← Preserve creation date
            lastSeenAt: lastSeenAt,               // ← Preserve last seen
            note: note                            // ← Preserve note
        )
    }
}
