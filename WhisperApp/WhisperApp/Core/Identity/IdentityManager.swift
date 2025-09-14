import CoreData
import CryptoKit
import Foundation

/// Protocol defining identity management operations
/// Handles creation, storage, rotation, and lifecycle of cryptographic identities
protocol IdentityManager {
    /// Creates a new identity with X25519/Ed25519 key pairs
    /// - Parameter name: Display name for the identity
    /// - Returns: Newly created identity
    /// - Throws: IdentityError if creation fails
    func createIdentity(name: String) throws -> Identity

    /// Lists all identities in the system
    /// - Returns: Array of all identities
    func listIdentities() -> [Identity]

    /// Gets the currently active identity
    /// - Returns: Active identity or nil if none set
    func getActiveIdentity() -> Identity?

    /// Sets the active identity for encryption operations
    /// - Parameter identity: Identity to activate
    /// - Throws: IdentityError if activation fails
    func setActiveIdentity(_ identity: Identity) throws

    /// Archives an identity (makes it decrypt-only)
    /// - Parameter identity: Identity to archive
    /// - Throws: IdentityError if archiving fails
    func archiveIdentity(_ identity: Identity) throws

    /// Permanently deletes an identity and its private keys
    /// - Parameter identity: Identity to delete
    /// - Throws: IdentityError if deletion fails or identity is active
    func deleteIdentity(_ identity: Identity) throws

    /// Rotates the active identity by creating a new one
    /// - Returns: New active identity
    /// - Throws: IdentityError if rotation fails
    func rotateActiveIdentity() throws -> Identity

    /// Exports public key bundle for sharing
    /// - Parameter identity: Identity to export
    /// - Returns: Serialized public key bundle
    /// - Throws: IdentityError if export fails
    func exportPublicBundle(_ identity: Identity) throws -> Data

    /// Imports a public key bundle
    /// - Parameter data: Serialized public key bundle
    /// - Returns: Public key bundle structure
    /// - Throws: IdentityError if import fails
    func importPublicBundle(_ data: Data) throws -> PublicKeyBundle

    /// Creates an encrypted backup of an identity
    /// - Parameters:
    ///   - identity: Identity to backup
    ///   - passphrase: Passphrase for encryption
    /// - Returns: Encrypted backup data
    /// - Throws: IdentityError if backup fails
    func backupIdentity(_ identity: Identity, passphrase: String) throws -> Data

    /// Restores an identity from encrypted backup
    /// - Parameters:
    ///   - backup: Encrypted backup data
    ///   - passphrase: Passphrase for decryption
    /// - Returns: Restored identity
    /// - Throws: IdentityError if restore fails
    func restoreIdentity(from backup: Data, passphrase: String) throws -> Identity

    /// Gets identity by recipient key ID (rkid)
    /// - Parameter rkid: 8-byte recipient key ID
    /// - Returns: Matching identity or nil
    func getIdentity(byRkid rkid: Data) -> Identity?

    /// Checks if any identity is approaching expiration
    /// - Returns: Array of identities needing rotation warning
    func getIdentitiesNeedingRotationWarning() -> [Identity]
}

/// Concrete implementation of IdentityManager
/// Manages identities using Core Data for persistence and Keychain for private keys
class CoreDataIdentityManager: IdentityManager {
    private let context: NSManagedObjectContext
    private let cryptoEngine: CryptoEngine
    private let policyManager: PolicyManager?

    /// Key rotation warning threshold (30 days before recommended rotation)
    private let rotationWarningThreshold: TimeInterval = 30 * 24 * 60 * 60  // 30 days

    /// Recommended key rotation interval (1 year)
    private let recommendedRotationInterval: TimeInterval = 365 * 24 * 60 * 60  // 1 year

    init(
        context: NSManagedObjectContext,
        cryptoEngine: CryptoEngine,
        policyManager: PolicyManager? = nil
    ) {
        self.context = context
        self.cryptoEngine = cryptoEngine
        self.policyManager = policyManager
    }

    // MARK: - Identity Creation and Management

    func createIdentity(name: String) throws -> Identity {
        // Generate new identity using crypto engine
        var newIdentity = try cryptoEngine.generateIdentity()
        newIdentity = Identity(
            id: newIdentity.id,
            name: name,
            x25519KeyPair: newIdentity.x25519KeyPair,
            ed25519KeyPair: newIdentity.ed25519KeyPair,
            fingerprint: newIdentity.fingerprint,
            createdAt: newIdentity.createdAt,
            status: .active,
            keyVersion: newIdentity.keyVersion
        )

        // Store private keys in Keychain
        try KeychainManager.storeX25519PrivateKey(
            newIdentity.x25519KeyPair.privateKey,
            identifier: newIdentity.id.uuidString)

        if let ed25519KeyPair = newIdentity.ed25519KeyPair {
            try KeychainManager.storeEd25519PrivateKey(
                ed25519KeyPair.privateKey,
                identifier: newIdentity.id.uuidString,
                requireBiometric: false)
        }

        // Store identity metadata in Core Data
        let entity = IdentityEntity(context: context)
        entity.id = newIdentity.id
        entity.name = newIdentity.name
        entity.x25519PublicKey = newIdentity.x25519KeyPair.publicKey
        entity.ed25519PublicKey = newIdentity.ed25519KeyPair?.publicKey
        entity.fingerprint = newIdentity.fingerprint
        entity.createdAt = newIdentity.createdAt
        entity.expiresAt = Calendar.current.date(
            byAdding: .year, value: 1, to: newIdentity.createdAt)
        entity.status = newIdentity.status.rawValue
        entity.keyVersion = Int32(newIdentity.keyVersion)
        entity.isActive = false  // Will be set when activated

        try context.save()

        return newIdentity
    }

    func listIdentities() -> [Identity] {
        let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \IdentityEntity.createdAt, ascending: false)
        ]

        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                return try? loadIdentity(from: entity)
            }
        } catch {
            print("Failed to fetch identities: \(error)")
            return []
        }
    }

    func getActiveIdentity() -> Identity? {
        let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            return try loadIdentity(from: entity)
        } catch {
            print("Failed to fetch active identity: \(error)")
            return nil
        }
    }

    func setActiveIdentity(_ identity: Identity) throws {
        // Deactivate all current active identities
        let deactivateRequest: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        deactivateRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeEntities = try context.fetch(deactivateRequest)
        for entity in activeEntities {
            entity.isActive = false
        }

        // Activate the specified identity
        let activateRequest: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        activateRequest.predicate = NSPredicate(format: "id == %@", identity.id as CVarArg)
        activateRequest.fetchLimit = 1
        let entities = try context.fetch(activateRequest)
        guard let entity = entities.first else {
            throw IdentityError.identityNotFound
        }

        entity.isActive = true

        // If the identity was archived, restore it to active status when setting as default
        if entity.status == IdentityStatus.archived.rawValue {
            entity.status = IdentityStatus.active.rawValue
            print("🔄 Restored archived identity '\(entity.name ?? "Unknown")' to active status")
        }

        try context.save()
    }

    func archiveIdentity(_ identity: Identity) throws {
        let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", identity.id as CVarArg)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        guard let entity = entities.first else {
            throw IdentityError.identityNotFound
        }

        entity.status = IdentityStatus.archived.rawValue
        entity.isActive = false

        try context.save()
    }

    func deleteIdentity(_ identity: Identity) throws {
        // Prevent deletion of active identity
        if let activeIdentity = getActiveIdentity(), activeIdentity.id == identity.id {
            throw IdentityError.cannotDeleteActiveIdentity
        }

        // Delete from Core Data
        let request: NSFetchRequest<IdentityEntity> = IdentityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", identity.id as CVarArg)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        guard let entity = entities.first else {
            throw IdentityError.identityNotFound
        }

        context.delete(entity)

        // Delete private keys from Keychain
        try KeychainManager.deleteKey(keyType: "x25519", identifier: identity.id.uuidString)
        if identity.ed25519KeyPair != nil {
            try KeychainManager.deleteKey(keyType: "ed25519", identifier: identity.id.uuidString)
        }

        try context.save()
    }

    func rotateActiveIdentity() throws -> Identity {
        guard let currentActive = getActiveIdentity() else {
            throw IdentityError.noActiveIdentity
        }

        // Extract the base name by removing any existing rotation suffix
        let baseName = extractBaseName(from: currentActive.name)

        // Create new identity with a clear name indicating it's rotated
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        let newName = "\(baseName) (Rotated \(dateString))"

        let newIdentity = try createIdentity(name: newName)

        // Set new identity as active
        try setActiveIdentity(newIdentity)

        // Auto-archive old identity if policy is enabled
        if policyManager?.autoArchiveOnRotation == true {
            print("🔄 Auto-archiving old identity: \(currentActive.name)")
            try archiveIdentity(currentActive)
        } else {
            print("🔄 Auto-archive disabled, keeping old identity active: \(currentActive.name)")
        }

        return newIdentity
    }

    /// Extracts the base name from an identity name by removing rotation suffixes
    /// Examples:
    /// - "Project A" -> "Project A"
    /// - "Project A (Rotated 2025-01-09 14:30:25)" -> "Project A"
    /// - "Project A (Rotated 2025-01-09)" -> "Project A" (backward compatibility)
    private func extractBaseName(from name: String) -> String {
        // Use regex to remove all rotation suffixes (with or without time)
        let pattern = #" \(Rotated \d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2})?\)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: name.utf16.count)
        let cleanName = regex.stringByReplacingMatches(
            in: name, options: [], range: range, withTemplate: "")

        // Return the cleaned name, or original if no matches found
        return cleanName.isEmpty ? name : cleanName
    }

    // MARK: - Import/Export Operations

    func exportPublicBundle(_ identity: Identity) throws -> Data {
        let bundle = PublicKeyBundle(
            id: identity.id,
            name: identity.name,
            x25519PublicKey: identity.x25519KeyPair.publicKey,
            ed25519PublicKey: identity.ed25519KeyPair?.publicKey,
            fingerprint: identity.fingerprint,
            keyVersion: identity.keyVersion,
            createdAt: identity.createdAt
        )

        return try JSONEncoder().encode(bundle)
    }

    func importPublicBundle(_ data: Data) throws -> PublicKeyBundle {
        do {
            return try JSONDecoder().decode(PublicKeyBundle.self, from: data)
        } catch {
            throw IdentityError.invalidBundleFormat(error)
        }
    }

    func backupIdentity(_ identity: Identity, passphrase: String) throws -> Data {
        // Retrieve private keys from Keychain
        let x25519PrivateKey = try KeychainManager.retrieveX25519PrivateKey(
            identifier: identity.id.uuidString)

        var ed25519PrivateKey: Curve25519.Signing.PrivateKey?
        if identity.ed25519KeyPair != nil {
            ed25519PrivateKey = try KeychainManager.retrieveEd25519PrivateKey(
                identifier: identity.id.uuidString)
        }

        // Create backup structure
        let backup = IdentityBackup(
            id: identity.id,
            name: identity.name,
            x25519PrivateKey: x25519PrivateKey.rawRepresentation,
            ed25519PrivateKey: ed25519PrivateKey?.rawRepresentation,
            fingerprint: identity.fingerprint,
            keyVersion: identity.keyVersion,
            createdAt: identity.createdAt
        )

        // Serialize backup
        let backupData = try JSONEncoder().encode(backup)

        // Encrypt with passphrase using AES-GCM
        return try encryptBackup(backupData, passphrase: passphrase)
    }

    func restoreIdentity(from backup: Data, passphrase: String) throws -> Identity {
        // Decrypt backup
        let backupData = try decryptBackup(backup, passphrase: passphrase)

        // Deserialize backup
        let identityBackup = try JSONDecoder().decode(IdentityBackup.self, from: backupData)

        // Recreate key pairs
        let x25519PrivateKey = try Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: identityBackup.x25519PrivateKey)
        let x25519PublicKey = x25519PrivateKey.publicKey.rawRepresentation

        var ed25519KeyPair: Ed25519KeyPair?
        if let ed25519PrivateData = identityBackup.ed25519PrivateKey {
            let ed25519PrivateKey = try Curve25519.Signing.PrivateKey(
                rawRepresentation: ed25519PrivateData)
            let ed25519PublicKey = ed25519PrivateKey.publicKey.rawRepresentation
            ed25519KeyPair = Ed25519KeyPair(
                privateKey: ed25519PrivateKey,
                publicKey: ed25519PublicKey)
        }

        // Create identity
        let identity = Identity(
            id: identityBackup.id,
            name: identityBackup.name,
            x25519KeyPair: X25519KeyPair(
                privateKey: x25519PrivateKey,
                publicKey: x25519PublicKey),
            ed25519KeyPair: ed25519KeyPair,
            fingerprint: identityBackup.fingerprint,
            createdAt: identityBackup.createdAt,
            status: .active,
            keyVersion: identityBackup.keyVersion
        )

        // Store in Keychain and Core Data
        try KeychainManager.storeX25519PrivateKey(
            x25519PrivateKey,
            identifier: identity.id.uuidString)

        if let ed25519KeyPair = ed25519KeyPair {
            try KeychainManager.storeEd25519PrivateKey(
                ed25519KeyPair.privateKey,
                identifier: identity.id.uuidString)
        }

        // Store metadata in Core Data
        let entity = IdentityEntity(context: context)
        entity.id = identity.id
        entity.name = identity.name
        entity.x25519PublicKey = identity.x25519KeyPair.publicKey
        entity.ed25519PublicKey = identity.ed25519KeyPair?.publicKey
        entity.fingerprint = identity.fingerprint
        entity.createdAt = identity.createdAt
        entity.expiresAt = Calendar.current.date(byAdding: .year, value: 1, to: identity.createdAt)
        entity.status = identity.status.rawValue
        entity.keyVersion = Int32(identity.keyVersion)
        entity.isActive = false

        try context.save()

        return identity
    }

    // MARK: - Query Operations

    func getIdentity(byRkid rkid: Data) -> Identity? {
        print("🔍 IDENTITY_MANAGER: getIdentity(byRkid:) called")
        print("🔍 IDENTITY_MANAGER: Looking for RKID: \(rkid.base64EncodedString())")

        let identities = listIdentities()
        print("🔍 IDENTITY_MANAGER: Available identities: \(identities.count)")

        for (index, identity) in identities.enumerated() {
            print("🔍 IDENTITY_MANAGER: Checking identity \(index): '\(identity.name)'")
            let identityRkid = cryptoEngine.generateRecipientKeyId(
                x25519PublicKey: identity.x25519KeyPair.publicKey)
            print("🔍 IDENTITY_MANAGER: Identity RKID: \(identityRkid.base64EncodedString())")
            print("🔍 IDENTITY_MANAGER: Match: \(identityRkid == rkid ? "✅ YES" : "❌ NO")")

            if identityRkid == rkid {
                print("🔍 IDENTITY_MANAGER: ✅ Found matching identity: '\(identity.name)'")
                return identity
            }
        }

        print("🔍 IDENTITY_MANAGER: ❌ No matching identity found for RKID")
        return nil
    }

    func getIdentitiesNeedingRotationWarning() -> [Identity] {
        let identities = listIdentities()
        let now = Date()

        return identities.filter { identity in
            let timeSinceCreation = now.timeIntervalSince(identity.createdAt)
            let timeUntilRecommendedRotation = recommendedRotationInterval - timeSinceCreation
            return timeUntilRecommendedRotation <= rotationWarningThreshold
                && timeUntilRecommendedRotation > 0
        }
    }

    // MARK: - Private Helper Methods

    private func loadIdentity(from entity: IdentityEntity) throws -> Identity {
        guard let id = entity.id,
            let name = entity.name,
            let x25519PublicKey = entity.x25519PublicKey,
            let fingerprint = entity.fingerprint,
            let createdAt = entity.createdAt,
            let statusString = entity.status
        else {
            throw IdentityError.corruptedIdentityData
        }

        guard let status = IdentityStatus(rawValue: statusString) else {
            throw IdentityError.invalidIdentityStatus
        }

        // Load private keys from Keychain
        let x25519PrivateKey = try KeychainManager.retrieveX25519PrivateKey(
            identifier: id.uuidString)

        var ed25519KeyPair: Ed25519KeyPair?
        if let ed25519PublicKey = entity.ed25519PublicKey {
            let ed25519PrivateKey = try KeychainManager.retrieveEd25519PrivateKey(
                identifier: id.uuidString)
            ed25519KeyPair = Ed25519KeyPair(
                privateKey: ed25519PrivateKey,
                publicKey: ed25519PublicKey)
        }

        return Identity(
            id: id,
            name: name,
            x25519KeyPair: X25519KeyPair(
                privateKey: x25519PrivateKey,
                publicKey: x25519PublicKey),
            ed25519KeyPair: ed25519KeyPair,
            fingerprint: fingerprint,
            createdAt: createdAt,
            status: status,
            keyVersion: Int(entity.keyVersion)
        )
    }

    private func encryptBackup(_ data: Data, passphrase: String) throws -> Data {
        // Derive key from passphrase using PBKDF2
        let salt = try cryptoEngine.generateSecureRandom(length: 16)
        let key = try deriveKeyFromPassphrase(passphrase, salt: salt)

        // Generate random nonce
        let nonce = try cryptoEngine.generateSecureRandom(length: 12)

        // Encrypt using AES-GCM
        let symmetricKey = SymmetricKey(data: key)
        let aesNonce = try AES.GCM.Nonce(data: nonce)
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: aesNonce)

        // Combine salt + nonce + ciphertext
        var result = Data()
        result.append(salt)
        result.append(nonce)
        guard let combinedData = sealedBox.combined else {
            throw IdentityError.invalidBackupFormat
        }
        result.append(combinedData)

        return result
    }

    private func decryptBackup(_ data: Data, passphrase: String) throws -> Data {
        guard data.count >= 28 else {  // 16 (salt) + 12 (nonce) minimum
            throw IdentityError.invalidBackupFormat
        }

        // Extract components
        let salt = data.prefix(16)
        let nonce = data.subdata(in: 16..<28)
        let ciphertext = data.suffix(from: 28)

        // Derive key from passphrase
        let key = try deriveKeyFromPassphrase(passphrase, salt: Data(salt))

        // Decrypt using AES-GCM
        let symmetricKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)

        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }

    private func deriveKeyFromPassphrase(_ passphrase: String, salt: Data) throws -> Data {
        guard let passphraseData = passphrase.data(using: .utf8) else {
            throw IdentityError.invalidPassphrase
        }

        // Use PBKDF2 with SHA-256, 100,000 iterations
        let derivedKey = try HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passphraseData),
            salt: salt,
            info: "whisper-backup-v1".data(using: .utf8)!,
            outputByteCount: 32
        )

        return derivedKey.withUnsafeBytes { Data($0) }
    }
}

// MARK: - Supporting Types

/// Public key bundle for sharing identities
struct PublicKeyBundle: Codable {
    let id: UUID
    let name: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date

    /// Default memberwise initializer for identity export
    init(
        id: UUID, name: String, x25519PublicKey: Data, ed25519PublicKey: Data?, fingerprint: Data,
        keyVersion: Int, createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.fingerprint = fingerprint
        self.keyVersion = keyVersion
        self.createdAt = createdAt
    }

    /// Creates a PublicKeyBundle from a Contact for QR code sharing
    init(from contact: Contact) {
        self.id = contact.id
        self.name = contact.displayName
        self.x25519PublicKey = contact.x25519PublicKey
        self.ed25519PublicKey = contact.ed25519PublicKey
        self.fingerprint = contact.fingerprint
        self.keyVersion = contact.keyVersion
        self.createdAt = contact.createdAt
    }
}

/// Encrypted backup structure for identity restoration
private struct IdentityBackup: Codable {
    let id: UUID
    let name: String
    let x25519PrivateKey: Data
    let ed25519PrivateKey: Data?
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date
}

// MARK: - Error Types

enum IdentityError: Error, LocalizedError {
    case identityNotFound
    case noActiveIdentity
    case cannotDeleteActiveIdentity
    case corruptedIdentityData
    case invalidIdentityStatus
    case invalidBundleFormat(Error)
    case invalidBackupFormat
    case invalidPassphrase
    case keychainError(KeychainError)
    case coreDataError(Error)

    var errorDescription: String? {
        switch self {
        case .identityNotFound:
            return "Identity not found"
        case .noActiveIdentity:
            return "No active identity available"
        case .cannotDeleteActiveIdentity:
            return "Cannot delete the active identity. Please activate another identity first."
        case .corruptedIdentityData:
            return "Identity data is corrupted"
        case .invalidIdentityStatus:
            return "Invalid identity status"
        case .invalidBundleFormat(let error):
            return "Invalid bundle format: \(error.localizedDescription)"
        case .invalidBackupFormat:
            return "Invalid backup format"
        case .invalidPassphrase:
            return "Invalid passphrase"
        case .keychainError(let error):
            return "Keychain error: \(error.localizedDescription)"
        case .coreDataError(let error):
            return "Core Data error: \(error.localizedDescription)"
        }
    }
}

// MARK: - IdentityStatus Extension

extension IdentityStatus {
    var rawValue: String {
        switch self {
        case .active:
            return "active"
        case .archived:
            return "archived"
        case .rotated:
            return "rotated"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "active":
            self = .active
        case "archived":
            self = .archived
        case "rotated":
            self = .rotated
        default:
            return nil
        }
    }
}
