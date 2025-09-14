import CoreData
import CryptoKit
import Foundation

// MARK: - Contact Manager Protocol

protocol ContactManager {
    func addContact(_ contact: Contact) throws
    func updateContact(_ contact: Contact) throws
    func deleteContact(id: UUID) throws
    func getContact(id: UUID) -> Contact?
    func getContact(byRkid rkid: Data) -> Contact?
    func listContacts() -> [Contact]
    func searchContacts(query: String) -> [Contact]
    func verifyContact(id: UUID, sasConfirmed: Bool) throws
    func blockContact(id: UUID) throws
    func unblockContact(id: UUID) throws
    func exportPublicKeybook() throws -> Data
    func handleKeyRotation(for contact: Contact, newX25519Key: Data, newEd25519Key: Data?) throws
    func checkForKeyRotation(contact: Contact, currentX25519Key: Data) -> Bool
}

// MARK: - Contact Manager Errors

enum ContactManagerError: Error, LocalizedError {
    case contactNotFound
    case contactAlreadyExists
    case invalidPublicKey
    case keyRotationDetected
    case exportFailed
    case persistenceError(Error)

    var errorDescription: String? {
        switch self {
        case .contactNotFound:
            return "Contact not found"
        case .contactAlreadyExists:
            return "Contact already exists"
        case .invalidPublicKey:
            return "Invalid public key"
        case .keyRotationDetected:
            return "Key changed — re-verify"
        case .exportFailed:
            return "Failed to export keybook"
        case .persistenceError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Core Data Contact Manager

class CoreDataContactManager: ContactManager {
    private let persistentContainer: NSPersistentContainer
    private let context: NSManagedObjectContext

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        self.context = persistentContainer.viewContext
    }

    // MARK: - Contact Management

    func addContact(_ contact: Contact) throws {
        // Check if contact already exists
        if getContact(id: contact.id) != nil {
            throw ContactManagerError.contactAlreadyExists
        }

        // Check if contact with same fingerprint exists
        let existingContacts = listContacts()
        if existingContacts.contains(where: { $0.fingerprint == contact.fingerprint }) {
            throw ContactManagerError.contactAlreadyExists
        }

        do {
            let entity = ContactEntity(context: context)
            try mapContactToEntity(contact, entity: entity)
            try context.save()
        } catch {
            throw ContactManagerError.persistenceError(error)
        }
    }

    func updateContact(_ contact: Contact) throws {
        guard let entity = fetchContactEntity(id: contact.id) else {
            throw ContactManagerError.contactNotFound
        }

        do {
            try mapContactToEntity(contact, entity: entity)
            try context.save()
        } catch {
            throw ContactManagerError.persistenceError(error)
        }
    }

    func deleteContact(id: UUID) throws {
        guard let entity = fetchContactEntity(id: id) else {
            throw ContactManagerError.contactNotFound
        }

        do {
            context.delete(entity)
            try context.save()
        } catch {
            throw ContactManagerError.persistenceError(error)
        }
    }

    func getContact(id: UUID) -> Contact? {
        guard let entity = fetchContactEntity(id: id) else {
            return nil
        }
        return mapEntityToContact(entity)
    }

    func getContact(byRkid rkid: Data) -> Contact? {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "rkid == %@", rkid as NSData)
        request.fetchLimit = 1

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            return mapEntityToContact(entity)
        } catch {
            return nil
        }
    }

    func listContacts() -> [Contact] {
        print("🔍 CONTACT_MANAGER: listContacts called")
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]

        do {
            let entities = try context.fetch(request)
            let contacts = entities.compactMap { mapEntityToContact($0) }
            print("🔍 CONTACT_MANAGER: Found \(contacts.count) contacts")
            for (index, contact) in contacts.enumerated() {
                print("🔍 CONTACT_MANAGER: Contact \(index): '\(contact.displayName)'")
                print(
                    "🔍 CONTACT_MANAGER:   - Fingerprint: \(contact.fingerprint.prefix(8).base64EncodedString())..."
                )
                print("🔍 CONTACT_MANAGER:   - Has signing key: \(contact.ed25519PublicKey != nil)")
                print("🔍 CONTACT_MANAGER:   - Trust level: \(contact.trustLevel)")
            }
            return contacts
        } catch {
            print("🔍 CONTACT_MANAGER: ❌ Error fetching contacts: \(error)")
            return []
        }
    }

    func searchContacts(query: String) -> [Contact] {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "displayName CONTAINS[cd] %@ OR note CONTAINS[cd] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]

        do {
            let entities = try context.fetch(request)
            return entities.compactMap { mapEntityToContact($0) }
        } catch {
            return []
        }
    }

    // MARK: - Trust Management

    func verifyContact(id: UUID, sasConfirmed: Bool) throws {
        guard var contact = getContact(id: id) else {
            throw ContactManagerError.contactNotFound
        }

        if sasConfirmed {
            contact = contact.withUpdatedTrustLevel(.verified)
        } else {
            contact = contact.withUpdatedTrustLevel(.unverified)
        }

        try updateContact(contact)
    }

    func blockContact(id: UUID) throws {
        guard var contact = getContact(id: id) else {
            throw ContactManagerError.contactNotFound
        }

        contact = contact.withUpdatedBlockStatus(true)
        try updateContact(contact)
    }

    func unblockContact(id: UUID) throws {
        guard var contact = getContact(id: id) else {
            throw ContactManagerError.contactNotFound
        }

        contact = contact.withUpdatedBlockStatus(false)
        try updateContact(contact)
    }

    // MARK: - Key Rotation

    func handleKeyRotation(for contact: Contact, newX25519Key: Data, newEd25519Key: Data? = nil)
        throws
    {
        // Create key history entry for the old key
        let oldKeyHistory = try KeyHistoryEntry(
            keyVersion: contact.keyVersion,
            x25519PublicKey: contact.x25519PublicKey,
            ed25519PublicKey: contact.ed25519PublicKey
        )

        // Create new contact with updated keys
        let updatedContact = try Contact(
            displayName: contact.displayName,
            x25519PublicKey: newX25519Key,
            ed25519PublicKey: newEd25519Key,
            note: contact.note
        )

        // Create updated key history with the old key entry
        let updatedKeyHistory = contact.keyHistory + [oldKeyHistory]

        // Create final contact with updated key history and reset trust level
        let finalContact = Contact(
            id: contact.id,
            displayName: updatedContact.displayName,
            x25519PublicKey: updatedContact.x25519PublicKey,
            ed25519PublicKey: updatedContact.ed25519PublicKey,
            fingerprint: updatedContact.fingerprint,
            shortFingerprint: updatedContact.shortFingerprint,
            sasWords: updatedContact.sasWords,
            rkid: updatedContact.rkid,
            trustLevel: .unverified,  // Reset trust level on key rotation
            isBlocked: contact.isBlocked,
            keyVersion: updatedContact.keyVersion,
            keyHistory: updatedKeyHistory,
            createdAt: contact.createdAt,
            lastSeenAt: contact.lastSeenAt,
            note: updatedContact.note
        )

        try updateContact(finalContact)
    }

    func checkForKeyRotation(contact: Contact, currentX25519Key: Data) -> Bool {
        return contact.x25519PublicKey != currentX25519Key
    }

    // MARK: - Export

    func exportPublicKeybook() throws -> Data {
        let contacts = listContacts()
        let publicBundles = contacts.map { PublicKeyBundle(from: $0) }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(publicBundles)
        } catch {
            throw ContactManagerError.exportFailed
        }
    }

    // MARK: - Private Helper Methods

    private func fetchContactEntity(id: UUID) -> ContactEntity? {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let entities = try context.fetch(request)
            return entities.first
        } catch {
            return nil
        }
    }

    private func mapContactToEntity(_ contact: Contact, entity: ContactEntity) throws {
        entity.id = contact.id
        entity.displayName = contact.displayName
        entity.x25519PublicKey = contact.x25519PublicKey
        entity.ed25519PublicKey = contact.ed25519PublicKey
        entity.fingerprint = contact.fingerprint
        entity.shortFingerprint = contact.shortFingerprint
        entity.rkid = contact.rkid
        entity.trustLevel = contact.trustLevel.rawValue
        entity.isBlocked = contact.isBlocked
        entity.keyVersion = Int32(contact.keyVersion)
        entity.createdAt = contact.createdAt
        entity.lastSeenAt = contact.lastSeenAt
        entity.note = contact.note

        // Handle key history
        // Clear existing key history
        if let existingHistory = entity.keyHistory {
            for historyEntity in existingHistory {
                context.delete(historyEntity as! NSManagedObject)
            }
        }

        // Add new key history entries
        for historyEntry in contact.keyHistory {
            let historyEntity = KeyHistoryEntity(context: context)
            historyEntity.id = historyEntry.id
            historyEntity.keyVersion = Int32(historyEntry.keyVersion)
            historyEntity.x25519PublicKey = historyEntry.x25519PublicKey
            historyEntity.ed25519PublicKey = historyEntry.ed25519PublicKey
            historyEntity.fingerprint = historyEntry.fingerprint
            historyEntity.createdAt = historyEntry.createdAt
            historyEntity.contact = entity
        }
    }

    private func mapEntityToContact(_ entity: ContactEntity) -> Contact? {
        guard let id = entity.id,
            let displayName = entity.displayName,
            let x25519PublicKey = entity.x25519PublicKey,
            let fingerprint = entity.fingerprint,
            let shortFingerprint = entity.shortFingerprint,
            let rkid = entity.rkid,
            let trustLevelString = entity.trustLevel,
            let trustLevel = TrustLevel(rawValue: trustLevelString),
            let createdAt = entity.createdAt
        else {
            return nil
        }

        // Map key history
        var keyHistory: [KeyHistoryEntry] = []
        if let historyEntities = entity.keyHistory {
            for historyEntity in historyEntities {
                if let historyEntity = historyEntity as? KeyHistoryEntity,
                    let historyId = historyEntity.id,
                    let historyX25519Key = historyEntity.x25519PublicKey,
                    let historyFingerprint = historyEntity.fingerprint,
                    let historyCreatedAt = historyEntity.createdAt
                {

                    let entry = KeyHistoryEntry(
                        id: historyId,
                        keyVersion: Int(historyEntity.keyVersion),
                        x25519PublicKey: historyX25519Key,
                        ed25519PublicKey: historyEntity.ed25519PublicKey,
                        fingerprint: historyFingerprint,
                        createdAt: historyCreatedAt
                    )
                    keyHistory.append(entry)
                }
            }
        }

        // Generate SAS words from fingerprint
        let sasWords = Contact.generateSASWords(from: fingerprint)

        // Create contact using internal initializer with all properties
        return Contact(
            id: id,
            displayName: displayName,
            x25519PublicKey: x25519PublicKey,
            ed25519PublicKey: entity.ed25519PublicKey,
            fingerprint: fingerprint,
            shortFingerprint: shortFingerprint,
            sasWords: sasWords,
            rkid: rkid,
            trustLevel: trustLevel,
            isBlocked: entity.isBlocked,
            keyVersion: Int(entity.keyVersion),
            keyHistory: keyHistory,
            createdAt: createdAt,
            lastSeenAt: entity.lastSeenAt,
            note: entity.note
        )
    }
}

// MARK: - KeyHistoryEntry Extension

extension KeyHistoryEntry {
    init(
        id: UUID, keyVersion: Int, x25519PublicKey: Data, ed25519PublicKey: Data?,
        fingerprint: Data, createdAt: Date
    ) {
        self.id = id
        self.keyVersion = keyVersion
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.fingerprint = fingerprint
        self.createdAt = createdAt
    }
}
