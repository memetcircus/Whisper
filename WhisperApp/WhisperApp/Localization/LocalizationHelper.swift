import Foundation

/// Helper for accessing localized strings with type safety and consistency
struct LocalizationHelper {
    
    // MARK: - General
    static let appName = NSLocalizedString("app.name", comment: "App name")
    static let cancel = NSLocalizedString("cancel", comment: "Cancel button")
    static let ok = NSLocalizedString("ok", comment: "OK button")
    static let done = NSLocalizedString("done", comment: "Done button")
    static let save = NSLocalizedString("save", comment: "Save button")
    static let delete = NSLocalizedString("delete", comment: "Delete button")
    static let edit = NSLocalizedString("edit", comment: "Edit button")
    static let add = NSLocalizedString("add", comment: "Add button")
    static let remove = NSLocalizedString("remove", comment: "Remove button")
    static let retry = NSLocalizedString("retry", comment: "Retry button")
    static let close = NSLocalizedString("close", comment: "Close button")
    
    // MARK: - Sign/Biometric
    struct Sign {
        static let bioPrepTitle = NSLocalizedString("sign.bio_prep.title", comment: "Biometric prep title")
        static let bioPrepBody = NSLocalizedString("sign.bio_prep.body", comment: "Biometric prep body")
        static let bioRequiredTitle = NSLocalizedString("sign.bio_required.title", comment: "Bio required title")
        static let bioRequiredMessage = NSLocalizedString("sign.bio_required.message", comment: "Bio required message")
        static let bioCancelledTitle = NSLocalizedString("sign.bio_cancelled.title", comment: "Bio cancelled title")
        static let bioCancelledMessage = NSLocalizedString("sign.bio_cancelled.message", comment: "Bio cancelled message")
        static let bioFailedTitle = NSLocalizedString("sign.bio_failed.title", comment: "Bio failed title")
        static let bioFailedMessage = NSLocalizedString("sign.bio_failed.message", comment: "Bio failed message")
        static let bioUnavailableTitle = NSLocalizedString("sign.bio_unavailable.title", comment: "Bio unavailable title")
        static let bioUnavailableMessage = NSLocalizedString("sign.bio_unavailable.message", comment: "Bio unavailable message")
    }
    
    // MARK: - Policy
    struct Policy {
        static let contactRequiredTitle = NSLocalizedString("policy.contact_required.title", comment: "Contact required title")
        static let contactRequiredMessage = NSLocalizedString("policy.contact_required.message", comment: "Contact required message")
        static let signatureRequiredTitle = NSLocalizedString("policy.signature_required.title", comment: "Signature required title")
        static let signatureRequiredMessage = NSLocalizedString("policy.signature_required.message", comment: "Signature required message")
        static let biometricRequiredTitle = NSLocalizedString("policy.biometric_required.title", comment: "Biometric required title")
        static let biometricRequiredMessage = NSLocalizedString("policy.biometric_required.message", comment: "Biometric required message")
        static let autoArchiveDescription = NSLocalizedString("policy.auto_archive.description", comment: "Auto archive description")
    }
    
    // MARK: - Contact
    struct Contact {
        static let title = NSLocalizedString("contact.title", comment: "Contacts title")
        static let verifiedBadge = NSLocalizedString("contact.verified.badge", comment: "Verified badge")
        static let unverifiedBadge = NSLocalizedString("contact.unverified.badge", comment: "Unverified badge")
        static let revokedBadge = NSLocalizedString("contact.revoked.badge", comment: "Revoked badge")
        static let blockedBadge = NSLocalizedString("contact.blocked.badge", comment: "Blocked badge")
        static let addTitle = NSLocalizedString("contact.add.title", comment: "Add contact title")
        static let editTitle = NSLocalizedString("contact.edit.title", comment: "Edit contact title")
        static let deleteTitle = NSLocalizedString("contact.delete.title", comment: "Delete contact title")
        static let deleteMessage = NSLocalizedString("contact.delete.message", comment: "Delete contact message")
        static let blockTitle = NSLocalizedString("contact.block.title", comment: "Block contact title")
        static let blockMessage = NSLocalizedString("contact.block.message", comment: "Block contact message")
        static let unblockTitle = NSLocalizedString("contact.unblock.title", comment: "Unblock contact title")
        static let verifyTitle = NSLocalizedString("contact.verify.title", comment: "Verify contact title")
        static let verifyMessage = NSLocalizedString("contact.verify.message", comment: "Verify contact message")
        static let keyRotationTitle = NSLocalizedString("contact.key_rotation.title", comment: "Key rotation title")
        static let keyRotationMessage = NSLocalizedString("contact.key_rotation.message", comment: "Key rotation message")
        static let searchPlaceholder = NSLocalizedString("contact.search.placeholder", comment: "Search placeholder")
        static let exportKeybook = NSLocalizedString("contact.export_keybook", comment: "Export keybook")
        static let importContacts = NSLocalizedString("contact.import", comment: "Import contacts")
        static let fingerprint = NSLocalizedString("contact.fingerprint", comment: "Fingerprint")
        static let shortId = NSLocalizedString("contact.short_id", comment: "Short ID")
        static let sasWords = NSLocalizedString("contact.sas_words", comment: "SAS words")
        static let trustLevel = NSLocalizedString("contact.trust_level", comment: "Trust level")
        static let lastSeen = NSLocalizedString("contact.last_seen", comment: "Last seen")
        static let neverSeen = NSLocalizedString("contact.never_seen", comment: "Never seen")
    }
    
    // MARK: - Identity
    struct Identity {
        static let active = NSLocalizedString("identity.active", comment: "Active identity")
        static let archived = NSLocalizedString("identity.archived", comment: "Archived identity")
        static let createTitle = NSLocalizedString("identity.create.title", comment: "Create identity title")
        static let createNamePlaceholder = NSLocalizedString("identity.create.name.placeholder", comment: "Identity name placeholder")
        static let switchTitle = NSLocalizedString("identity.switch.title", comment: "Switch identity title")
        static let archiveTitle = NSLocalizedString("identity.archive.title", comment: "Archive identity title")
        static let archiveMessage = NSLocalizedString("identity.archive.message", comment: "Archive identity message")
        static let rotateTitle = NSLocalizedString("identity.rotate.title", comment: "Rotate keys title")
        static let rotateMessage = NSLocalizedString("identity.rotate.message", comment: "Rotate keys message")
        static let exportTitle = NSLocalizedString("identity.export.title", comment: "Export identity title")
        static let importTitle = NSLocalizedString("identity.import.title", comment: "Import identity title")
        static let backupTitle = NSLocalizedString("identity.backup.title", comment: "Backup identity title")
        static let restoreTitle = NSLocalizedString("identity.restore.title", comment: "Restore identity title")
        static let expirationWarning = NSLocalizedString("identity.expiration.warning", comment: "Expiration warning")
    }
    
    // MARK: - Encrypt
    struct Encrypt {
        static let title = NSLocalizedString("encrypt.title", comment: "Encrypt title")
        static let fromIdentity = NSLocalizedString("encrypt.from_identity", comment: "From identity")
        static let to = NSLocalizedString("encrypt.to", comment: "To")
        static let message = NSLocalizedString("encrypt.message", comment: "Message")
        static let options = NSLocalizedString("encrypt.options", comment: "Options")
        static let includeSignature = NSLocalizedString("encrypt.include_signature", comment: "Include signature")
        static let signatureRequiredNote = NSLocalizedString("encrypt.signature_required_note", comment: "Signature required note")
        static let selectContact = NSLocalizedString("encrypt.select_contact", comment: "Select contact")
        static let useRawKey = NSLocalizedString("encrypt.use_raw_key", comment: "Use raw key")
        static let change = NSLocalizedString("encrypt.change", comment: "Change")
        static let encryptMessage = NSLocalizedString("encrypt.encrypt_message", comment: "Encrypt message")
        static let share = NSLocalizedString("encrypt.share", comment: "Share")
        static let qrCode = NSLocalizedString("encrypt.qr_code", comment: "QR code")
        static let copy = NSLocalizedString("encrypt.copy", comment: "Copy")
        static let successTitle = NSLocalizedString("encrypt.success.title", comment: "Encrypt success title")
        static let successMessage = NSLocalizedString("encrypt.success.message", comment: "Encrypt success message")
        
        struct Error {
            static let noIdentity = NSLocalizedString("encrypt.error.no_identity", comment: "No identity error")
            static let noRecipient = NSLocalizedString("encrypt.error.no_recipient", comment: "No recipient error")
            static let emptyMessage = NSLocalizedString("encrypt.error.empty_message", comment: "Empty message error")
        }
    }
    
    // MARK: - Decrypt
    struct Decrypt {
        static let title = NSLocalizedString("decrypt.title", comment: "Decrypt title")
        static let bannerTitle = NSLocalizedString("decrypt.banner.title", comment: "Banner title")
        static let bannerMessage = NSLocalizedString("decrypt.banner.message", comment: "Banner message")
        static let bannerDecrypt = NSLocalizedString("decrypt.banner.decrypt", comment: "Banner decrypt")
        static let inputTitle = NSLocalizedString("decrypt.input.title", comment: "Input title")
        static let inputPlaceholder = NSLocalizedString("decrypt.input.placeholder", comment: "Input placeholder")
        static let invalidFormat = NSLocalizedString("decrypt.invalid_format", comment: "Invalid format")
        static let decryptMessage = NSLocalizedString("decrypt.decrypt_message", comment: "Decrypt message")
        static let decryptedMessage = NSLocalizedString("decrypt.decrypted_message", comment: "Decrypted message")
        static let sender = NSLocalizedString("decrypt.sender", comment: "Sender")
        static let content = NSLocalizedString("decrypt.content", comment: "Content")
        static let messageDetails = NSLocalizedString("decrypt.message_details", comment: "Message details")
        static let received = NSLocalizedString("decrypt.received", comment: "Received")
        static let security = NSLocalizedString("decrypt.security", comment: "Security")
        static let endToEndEncrypted = NSLocalizedString("decrypt.end_to_end_encrypted", comment: "End to end encrypted")
        static let copyMessage = NSLocalizedString("decrypt.copy_message", comment: "Copy message")
        static let clear = NSLocalizedString("decrypt.clear", comment: "Clear")
        static let successTitle = NSLocalizedString("decrypt.success.title", comment: "Decrypt success title")
        static let successMessage = NSLocalizedString("decrypt.success.message", comment: "Decrypt success message")
        
        struct Error {
            static let invalidEnvelope = NSLocalizedString("decrypt.error.invalid_envelope", comment: "Invalid envelope error")
            static let replayDetected = NSLocalizedString("decrypt.error.replay_detected", comment: "Replay detected error")
            static let messageExpired = NSLocalizedString("decrypt.error.message_expired", comment: "Message expired error")
            static let notForMe = NSLocalizedString("decrypt.error.not_for_me", comment: "Not for me error")
        }
    }
    
    // MARK: - QR Code
    struct QR {
        static let title = NSLocalizedString("qr.title", comment: "QR title")
        static let scanTitle = NSLocalizedString("qr.scan.title", comment: "QR scan title")
        static let displayTitle = NSLocalizedString("qr.display.title", comment: "QR display title")
        static let contactTitle = NSLocalizedString("qr.contact.title", comment: "QR contact title")
        static let messageTitle = NSLocalizedString("qr.message.title", comment: "QR message title")
        static let sizeWarningTitle = NSLocalizedString("qr.size_warning.title", comment: "QR size warning title")
        static let sizeWarningMessage = NSLocalizedString("qr.size_warning.message", comment: "QR size warning message")
        static let scanInvalid = NSLocalizedString("qr.scan.invalid", comment: "QR scan invalid")
        static let scanSuccess = NSLocalizedString("qr.scan.success", comment: "QR scan success")
        static let generateError = NSLocalizedString("qr.generate.error", comment: "QR generate error")
    }
    
    // MARK: - Settings
    struct Settings {
        static let title = NSLocalizedString("settings.title", comment: "Settings title")
        static let securityPolicies = NSLocalizedString("settings.security_policies", comment: "Security policies")
        static let contactRequired = NSLocalizedString("settings.contact_required", comment: "Contact required")
        static let signatureRequired = NSLocalizedString("settings.signature_required", comment: "Signature required")
        static let autoArchive = NSLocalizedString("settings.auto_archive", comment: "Auto archive")
        static let biometricGated = NSLocalizedString("settings.biometric_gated", comment: "Biometric gated")
        static let identityManagement = NSLocalizedString("settings.identity_management", comment: "Identity management")
        static let biometricSettings = NSLocalizedString("settings.biometric_settings", comment: "Biometric settings")
        static let exportImport = NSLocalizedString("settings.export_import", comment: "Export import")
        static let backupRestore = NSLocalizedString("settings.backup_restore", comment: "Backup restore")
        static let legal = NSLocalizedString("settings.legal", comment: "Legal")
    }
    
    // MARK: - Legal
    struct Legal {
        static let title = NSLocalizedString("legal.title", comment: "Legal title")
        static let accept = NSLocalizedString("legal.accept", comment: "Legal accept")
        static let decline = NSLocalizedString("legal.decline", comment: "Legal decline")
        static let required = NSLocalizedString("legal.required", comment: "Legal required")
        static let content = NSLocalizedString("legal.content", comment: "Legal content")
    }
    
    // MARK: - Errors
    struct Error {
        static let generic = NSLocalizedString("error.generic", comment: "Generic error")
        static let cryptographicFailure = NSLocalizedString("error.cryptographic_failure", comment: "Cryptographic failure")
        static let keyNotFound = NSLocalizedString("error.key_not_found", comment: "Key not found")
        static let contactNotFound = NSLocalizedString("error.contact_not_found", comment: "Contact not found")
        static let invalidPadding = NSLocalizedString("error.invalid_padding", comment: "Invalid padding")
        static let networkingDetected = NSLocalizedString("error.networking_detected", comment: "Networking detected")
    }
    
    // MARK: - Accessibility
    struct Accessibility {
        static func trustBadgeVerified() -> String {
            return NSLocalizedString("accessibility.trust_badge.verified", comment: "Verified trust badge accessibility")
        }
        
        static func trustBadgeUnverified() -> String {
            return NSLocalizedString("accessibility.trust_badge.unverified", comment: "Unverified trust badge accessibility")
        }
        
        static func trustBadgeRevoked() -> String {
            return NSLocalizedString("accessibility.trust_badge.revoked", comment: "Revoked trust badge accessibility")
        }
        
        static func trustBadgeBlocked() -> String {
            return NSLocalizedString("accessibility.trust_badge.blocked", comment: "Blocked trust badge accessibility")
        }
        
        static func contactAvatar(_ name: String) -> String {
            return String(format: NSLocalizedString("accessibility.contact_avatar", comment: "Contact avatar accessibility"), name)
        }
        
        static let identitySelector = NSLocalizedString("accessibility.identity_selector", comment: "Identity selector accessibility")
        static let contactSelector = NSLocalizedString("accessibility.contact_selector", comment: "Contact selector accessibility")
        static let encryptButton = NSLocalizedString("accessibility.encrypt_button", comment: "Encrypt button accessibility")
        static let decryptButton = NSLocalizedString("accessibility.decrypt_button", comment: "Decrypt button accessibility")
        static let qrScanner = NSLocalizedString("accessibility.qr_scanner", comment: "QR scanner accessibility")
        static let qrDisplay = NSLocalizedString("accessibility.qr_display", comment: "QR display accessibility")
        static let biometricPrompt = NSLocalizedString("accessibility.biometric_prompt", comment: "Biometric prompt accessibility")
        
        static func policyToggle(_ policyName: String) -> String {
            return String(format: NSLocalizedString("accessibility.policy_toggle", comment: "Policy toggle accessibility"), policyName)
        }
        
        static let messageInput = NSLocalizedString("accessibility.message_input", comment: "Message input accessibility")
        static let encryptedInput = NSLocalizedString("accessibility.encrypted_input", comment: "Encrypted input accessibility")
        
        // Hints
        static let hintTrustBadge = NSLocalizedString("accessibility.hint.trust_badge", comment: "Trust badge hint")
        static let hintContactRow = NSLocalizedString("accessibility.hint.contact_row", comment: "Contact row hint")
        static let hintEncryptButton = NSLocalizedString("accessibility.hint.encrypt_button", comment: "Encrypt button hint")
        static let hintDecryptButton = NSLocalizedString("accessibility.hint.decrypt_button", comment: "Decrypt button hint")
        static let hintQrScan = NSLocalizedString("accessibility.hint.qr_scan", comment: "QR scan hint")
        static let hintPolicyToggle = NSLocalizedString("accessibility.hint.policy_toggle", comment: "Policy toggle hint")
    }
    
    // MARK: - Attribution
    struct Attribution {
        static func signedVerified(_ name: String) -> String {
            return String(format: NSLocalizedString("attribution.signed_verified", comment: "Signed verified attribution"), name)
        }
        
        static func signedUnverified(_ name: String) -> String {
            return String(format: NSLocalizedString("attribution.signed_unverified", comment: "Signed unverified attribution"), name)
        }
        
        static let signedUnknown = NSLocalizedString("attribution.signed_unknown", comment: "Signed unknown attribution")
        
        static func unsigned(_ name: String) -> String {
            return String(format: NSLocalizedString("attribution.unsigned", comment: "Unsigned attribution"), name)
        }
        
        static let invalidSignature = NSLocalizedString("attribution.invalid_signature", comment: "Invalid signature attribution")
        
        static let descriptionVerified = NSLocalizedString("attribution.description.verified", comment: "Verified description")
        static let descriptionUnverified = NSLocalizedString("attribution.description.unverified", comment: "Unverified description")
        static let descriptionUnknown = NSLocalizedString("attribution.description.unknown", comment: "Unknown description")
        static let descriptionUnsigned = NSLocalizedString("attribution.description.unsigned", comment: "Unsigned description")
        static let descriptionInvalid = NSLocalizedString("attribution.description.invalid", comment: "Invalid description")
    }
}