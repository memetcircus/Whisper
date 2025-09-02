import XCTest
import Foundation
@testable import WhisperApp

/// Tests for localization completeness and correctness
class LocalizationTests: XCTestCase {
    
    // MARK: - Required String Keys Tests
    
    func testSignStringKeys() {
        // Test all sign.* keys are present and resolve
        let requiredSignKeys = [
            "sign.bio_prep.title",
            "sign.bio_prep.body", 
            "sign.bio_required.title",
            "sign.bio_required.message",
            "sign.bio_cancelled.title",
            "sign.bio_cancelled.message",
            "sign.bio_failed.title",
            "sign.bio_failed.message",
            "sign.bio_unavailable.title",
            "sign.bio_unavailable.message"
        ]
        
        for key in requiredSignKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    func testPolicyStringKeys() {
        // Test all policy.* keys are present and resolve
        let requiredPolicyKeys = [
            "policy.contact_required.title",
            "policy.contact_required.message",
            "policy.signature_required.title", 
            "policy.signature_required.message",
            "policy.biometric_required.title",
            "policy.biometric_required.message",
            "policy.auto_archive.description"
        ]
        
        for key in requiredPolicyKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    func testContactStringKeys() {
        // Test all contact.* keys are present and resolve
        let requiredContactKeys = [
            "contact.title",
            "contact.verified.badge",
            "contact.unverified.badge",
            "contact.revoked.badge",
            "contact.blocked.badge",
            "contact.add.title",
            "contact.edit.title",
            "contact.delete.title",
            "contact.delete.message",
            "contact.block.title",
            "contact.block.message",
            "contact.unblock.title",
            "contact.verify.title",
            "contact.verify.message",
            "contact.key_rotation.title",
            "contact.key_rotation.message",
            "contact.search.placeholder",
            "contact.export_keybook",
            "contact.import",
            "contact.fingerprint",
            "contact.short_id",
            "contact.sas_words",
            "contact.trust_level",
            "contact.last_seen",
            "contact.never_seen"
        ]
        
        for key in requiredContactKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    func testIdentityStringKeys() {
        // Test all identity.* keys are present and resolve
        let requiredIdentityKeys = [
            "identity.active",
            "identity.archived",
            "identity.create.title",
            "identity.create.name.placeholder",
            "identity.switch.title",
            "identity.archive.title",
            "identity.archive.message",
            "identity.rotate.title",
            "identity.rotate.message",
            "identity.export.title",
            "identity.import.title",
            "identity.backup.title",
            "identity.restore.title",
            "identity.expiration.warning"
        ]
        
        for key in requiredIdentityKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    func testEncryptStringKeys() {
        // Test all encrypt.* keys are present and resolve
        let requiredEncryptKeys = [
            "encrypt.title",
            "encrypt.from_identity",
            "encrypt.to",
            "encrypt.message",
            "encrypt.options",
            "encrypt.include_signature",
            "encrypt.signature_required_note",
            "encrypt.select_contact",
            "encrypt.use_raw_key",
            "encrypt.change",
            "encrypt.encrypt_message",
            "encrypt.share",
            "encrypt.qr_code",
            "encrypt.copy",
            "encrypt.success.title",
            "encrypt.success.message",
            "encrypt.error.no_identity",
            "encrypt.error.no_recipient",
            "encrypt.error.empty_message"
        ]
        
        for key in requiredEncryptKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    func testDecryptStringKeys() {
        // Test all decrypt.* keys are present and resolve
        let requiredDecryptKeys = [
            "decrypt.title",
            "decrypt.banner.title",
            "decrypt.banner.message",
            "decrypt.banner.decrypt",
            "decrypt.input.title",
            "decrypt.input.placeholder",
            "decrypt.invalid_format",
            "decrypt.decrypt_message",
            "decrypt.decrypted_message",
            "decrypt.sender",
            "decrypt.content",
            "decrypt.message_details",
            "decrypt.received",
            "decrypt.security",
            "decrypt.end_to_end_encrypted",
            "decrypt.copy_message",
            "decrypt.clear",
            "decrypt.success.title",
            "decrypt.success.message",
            "decrypt.error.invalid_envelope",
            "decrypt.error.replay_detected",
            "decrypt.error.message_expired",
            "decrypt.error.not_for_me"
        ]
        
        for key in requiredDecryptKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    func testQRStringKeys() {
        // Test all qr.* keys are present and resolve
        let requiredQRKeys = [
            "qr.title",
            "qr.scan.title",
            "qr.display.title",
            "qr.contact.title",
            "qr.message.title",
            "qr.size_warning.title",
            "qr.size_warning.message",
            "qr.scan.invalid",
            "qr.scan.success",
            "qr.generate.error"
        ]
        
        for key in requiredQRKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    func testLegalStringKeys() {
        // Test all legal.* keys are present and resolve
        let requiredLegalKeys = [
            "legal.title",
            "legal.accept",
            "legal.decline",
            "legal.required",
            "legal.content"
        ]
        
        for key in requiredLegalKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    // MARK: - Accessibility String Keys Tests
    
    func testAccessibilityStringKeys() {
        // Test accessibility-specific string keys
        let requiredAccessibilityKeys = [
            "accessibility.trust_badge.verified",
            "accessibility.trust_badge.unverified", 
            "accessibility.trust_badge.revoked",
            "accessibility.trust_badge.blocked",
            "accessibility.contact_avatar",
            "accessibility.identity_selector",
            "accessibility.contact_selector",
            "accessibility.encrypt_button",
            "accessibility.decrypt_button",
            "accessibility.qr_scanner",
            "accessibility.qr_display",
            "accessibility.biometric_prompt",
            "accessibility.policy_toggle",
            "accessibility.message_input",
            "accessibility.encrypted_input",
            "accessibility.hint.trust_badge",
            "accessibility.hint.contact_row",
            "accessibility.hint.encrypt_button",
            "accessibility.hint.decrypt_button",
            "accessibility.hint.qr_scan",
            "accessibility.hint.policy_toggle"
        ]
        
        for key in requiredAccessibilityKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    // MARK: - Attribution String Keys Tests
    
    func testAttributionStringKeys() {
        // Test attribution message keys
        let requiredAttributionKeys = [
            "attribution.signed_verified",
            "attribution.signed_unverified",
            "attribution.signed_unknown",
            "attribution.unsigned",
            "attribution.invalid_signature",
            "attribution.description.verified",
            "attribution.description.unverified",
            "attribution.description.unknown",
            "attribution.description.unsigned",
            "attribution.description.invalid"
        ]
        
        for key in requiredAttributionKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    // MARK: - General String Keys Tests
    
    func testGeneralStringKeys() {
        // Test general UI string keys
        let requiredGeneralKeys = [
            "app.name",
            "cancel",
            "ok", 
            "done",
            "save",
            "delete",
            "edit",
            "add",
            "remove",
            "retry",
            "close",
            "continue",
            "back",
            "next",
            "yes",
            "no"
        ]
        
        for key in requiredGeneralKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    // MARK: - Error String Keys Tests
    
    func testErrorStringKeys() {
        // Test error message keys
        let requiredErrorKeys = [
            "error.generic",
            "error.cryptographic_failure",
            "error.key_not_found",
            "error.contact_not_found",
            "error.invalid_padding",
            "error.networking_detected"
        ]
        
        for key in requiredErrorKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
            XCTAssertFalse(localizedString.isEmpty, "Empty localization for key: \(key)")
        }
    }
    
    // MARK: - LocalizationHelper Tests
    
    func testLocalizationHelperConsistency() {
        // Test that LocalizationHelper returns the same values as direct NSLocalizedString calls
        XCTAssertEqual(LocalizationHelper.appName, NSLocalizedString("app.name", comment: ""))
        XCTAssertEqual(LocalizationHelper.cancel, NSLocalizedString("cancel", comment: ""))
        XCTAssertEqual(LocalizationHelper.ok, NSLocalizedString("ok", comment: ""))
        
        // Test nested structures
        XCTAssertEqual(LocalizationHelper.Contact.verifiedBadge, NSLocalizedString("contact.verified.badge", comment: ""))
        XCTAssertEqual(LocalizationHelper.Encrypt.title, NSLocalizedString("encrypt.title", comment: ""))
        XCTAssertEqual(LocalizationHelper.Decrypt.title, NSLocalizedString("decrypt.title", comment: ""))
    }
    
    func testParameterizedStrings() {
        // Test strings that take parameters
        let contactName = "Test User"
        let contactAvatarString = LocalizationHelper.Accessibility.contactAvatar(contactName)
        XCTAssertTrue(contactAvatarString.contains(contactName), "Parameterized string should contain the parameter")
        
        let policyName = "Test Policy"
        let policyToggleString = LocalizationHelper.Accessibility.policyToggle(policyName)
        XCTAssertTrue(policyToggleString.contains(policyName), "Parameterized string should contain the parameter")
    }
    
    // MARK: - Branding Tests
    
    func testWhisperBranding() {
        // Test that app uses "Whisper" branding (not "Kiro Whisper")
        let appName = LocalizationHelper.appName
        XCTAssertEqual(appName, "Whisper", "App name should be 'Whisper'")
        XCTAssertFalse(appName.contains("Kiro"), "App name should not contain 'Kiro'")
    }
    
    // MARK: - Performance Tests
    
    func testLocalizationPerformance() {
        // Test that localization lookups are performant
        measure {
            for _ in 0..<1000 {
                let _ = LocalizationHelper.Contact.verifiedBadge
                let _ = LocalizationHelper.Encrypt.title
                let _ = LocalizationHelper.Decrypt.title
                let _ = LocalizationHelper.Sign.bioPrepTitle
                let _ = LocalizationHelper.Policy.contactRequiredTitle
            }
        }
    }
    
    // MARK: - String Quality Tests
    
    func testStringQuality() {
        // Test that strings are of reasonable quality (not too short/long, proper capitalization, etc.)
        let appName = LocalizationHelper.appName
        XCTAssertGreaterThan(appName.count, 0, "App name should not be empty")
        XCTAssertLessThan(appName.count, 50, "App name should not be excessively long")
        
        let encryptTitle = LocalizationHelper.Encrypt.title
        XCTAssertGreaterThan(encryptTitle.count, 2, "Encrypt title should be meaningful")
        XCTAssertLessThan(encryptTitle.count, 100, "Encrypt title should not be excessively long")
        
        // Test that titles are properly capitalized
        XCTAssertTrue(encryptTitle.first?.isUppercase ?? false, "Titles should start with uppercase")
    }
}