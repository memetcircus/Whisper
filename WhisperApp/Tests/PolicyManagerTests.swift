import XCTest
@testable import WhisperApp

class PolicyManagerTests: XCTestCase {
    
    var policyManager: UserDefaultsPolicyManager!
    
    override func setUp() {
        super.setUp()
        policyManager = UserDefaultsPolicyManager()
        
        // Reset all policies to default (false) state
        policyManager.contactRequiredToSend = false
        policyManager.requireSignatureForVerified = false
        policyManager.autoArchiveOnRotation = false
        policyManager.biometricGatedSigning = false
    }
    
    override func tearDown() {
        // Clean up UserDefaults after each test
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "whisper.policy.contactRequiredToSend")
        userDefaults.removeObject(forKey: "whisper.policy.requireSignatureForVerified")
        userDefaults.removeObject(forKey: "whisper.policy.autoArchiveOnRotation")
        userDefaults.removeObject(forKey: "whisper.policy.biometricGatedSigning")
        
        policyManager = nil
        super.tearDown()
    }
    
    // MARK: - Policy Property Tests
    
    func testContactRequiredToSendPolicy() {
        // Test default value
        XCTAssertFalse(policyManager.contactRequiredToSend)
        
        // Test setting to true
        policyManager.contactRequiredToSend = true
        XCTAssertTrue(policyManager.contactRequiredToSend)
        
        // Test persistence
        let newManager = UserDefaultsPolicyManager()
        XCTAssertTrue(newManager.contactRequiredToSend)
        
        // Test setting back to false
        policyManager.contactRequiredToSend = false
        XCTAssertFalse(policyManager.contactRequiredToSend)
    }
    
    func testRequireSignatureForVerifiedPolicy() {
        // Test default value
        XCTAssertFalse(policyManager.requireSignatureForVerified)
        
        // Test setting to true
        policyManager.requireSignatureForVerified = true
        XCTAssertTrue(policyManager.requireSignatureForVerified)
        
        // Test persistence
        let newManager = UserDefaultsPolicyManager()
        XCTAssertTrue(newManager.requireSignatureForVerified)
    }
    
    func testAutoArchiveOnRotationPolicy() {
        // Test default value
        XCTAssertFalse(policyManager.autoArchiveOnRotation)
        
        // Test setting to true
        policyManager.autoArchiveOnRotation = true
        XCTAssertTrue(policyManager.autoArchiveOnRotation)
        
        // Test shouldArchiveOnRotation method
        XCTAssertTrue(policyManager.shouldArchiveOnRotation())
        
        policyManager.autoArchiveOnRotation = false
        XCTAssertFalse(policyManager.shouldArchiveOnRotation())
    }
    
    func testBiometricGatedSigningPolicy() {
        // Test default value
        XCTAssertFalse(policyManager.biometricGatedSigning)
        
        // Test setting to true
        policyManager.biometricGatedSigning = true
        XCTAssertTrue(policyManager.biometricGatedSigning)
        
        // Test requiresBiometricForSigning method
        XCTAssertTrue(policyManager.requiresBiometricForSigning())
        
        policyManager.biometricGatedSigning = false
        XCTAssertFalse(policyManager.requiresBiometricForSigning())
    }
    
    // MARK: - Send Policy Validation Tests
    
    func testValidateSendPolicyWithContactRequiredDisabled() throws {
        // When contact-required policy is disabled, both contact and raw key sending should be allowed
        policyManager.contactRequiredToSend = false
        
        // Test with contact - should not throw
        let contact = createTestContact()
        XCTAssertNoThrow(try policyManager.validateSendPolicy(recipient: contact))
        
        // Test with nil (raw key) - should not throw
        XCTAssertNoThrow(try policyManager.validateSendPolicy(recipient: nil))
    }
    
    func testValidateSendPolicyWithContactRequiredEnabled() throws {
        // When contact-required policy is enabled, raw key sending should be blocked
        policyManager.contactRequiredToSend = true
        
        // Test with contact - should not throw
        let contact = createTestContact()
        XCTAssertNoThrow(try policyManager.validateSendPolicy(recipient: contact))
        
        // Test with nil (raw key) - should throw rawKeyBlocked error
        XCTAssertThrowsError(try policyManager.validateSendPolicy(recipient: nil)) { error in
            guard case WhisperError.policyViolation(.rawKeyBlocked) = error else {
                XCTFail("Expected policyViolation(.rawKeyBlocked), got \(error)")
                return
            }
        }
    }
    
    func testValidateSendPolicyWithBlockedContact() throws {
        // Blocked contacts should be rejected regardless of policy
        policyManager.contactRequiredToSend = false
        
        let blockedContact = createTestContact(isBlocked: true)
        
        XCTAssertThrowsError(try policyManager.validateSendPolicy(recipient: blockedContact)) { error in
            guard case WhisperError.policyViolation(.contactRequired) = error else {
                XCTFail("Expected policyViolation(.contactRequired), got \(error)")
                return
            }
        }
    }
    
    // MARK: - Signature Policy Validation Tests
    
    func testValidateSignaturePolicyWithRequireSignatureDisabled() throws {
        // When signature-required policy is disabled, signatures should be optional
        policyManager.requireSignatureForVerified = false
        
        let verifiedContact = createTestContact(trustLevel: .verified)
        let unverifiedContact = createTestContact(trustLevel: .unverified)
        
        // Test verified contact without signature - should not throw
        XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: verifiedContact, hasSignature: false))
        
        // Test verified contact with signature - should not throw
        XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: verifiedContact, hasSignature: true))
        
        // Test unverified contact without signature - should not throw
        XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: unverifiedContact, hasSignature: false))
    }
    
    func testValidateSignaturePolicyWithRequireSignatureEnabled() throws {
        // When signature-required policy is enabled, verified contacts must have signatures
        policyManager.requireSignatureForVerified = true
        
        let verifiedContact = createTestContact(trustLevel: .verified)
        let unverifiedContact = createTestContact(trustLevel: .unverified)
        
        // Test verified contact with signature - should not throw
        XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: verifiedContact, hasSignature: true))
        
        // Test verified contact without signature - should throw signatureRequired error
        XCTAssertThrowsError(try policyManager.validateSignaturePolicy(recipient: verifiedContact, hasSignature: false)) { error in
            guard case WhisperError.policyViolation(.signatureRequired) = error else {
                XCTFail("Expected policyViolation(.signatureRequired), got \(error)")
                return
            }
        }
        
        // Test unverified contact without signature - should not throw (policy only applies to verified)
        XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: unverifiedContact, hasSignature: false))
        
        // Test nil recipient - should not throw
        XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: nil, hasSignature: false))
    }
    
    func testValidateSignaturePolicyWithRevokedContact() throws {
        // Revoked contacts should not trigger signature requirements
        policyManager.requireSignatureForVerified = true
        
        let revokedContact = createTestContact(trustLevel: .revoked)
        
        // Test revoked contact without signature - should not throw
        XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: revokedContact, hasSignature: false))
    }
    
    // MARK: - Policy Combination Tests
    
    func testAllPoliciesEnabled() throws {
        // Test all four policies enabled together
        policyManager.contactRequiredToSend = true
        policyManager.requireSignatureForVerified = true
        policyManager.autoArchiveOnRotation = true
        policyManager.biometricGatedSigning = true
        
        // Verify all policies are enabled
        XCTAssertTrue(policyManager.contactRequiredToSend)
        XCTAssertTrue(policyManager.requireSignatureForVerified)
        XCTAssertTrue(policyManager.shouldArchiveOnRotation())
        XCTAssertTrue(policyManager.requiresBiometricForSigning())
        
        // Test send policy with verified contact and signature - should not throw
        let verifiedContact = createTestContact(trustLevel: .verified)
        XCTAssertNoThrow(try policyManager.validateSendPolicy(recipient: verifiedContact))
        XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: verifiedContact, hasSignature: true))
        
        // Test send policy with raw key - should throw
        XCTAssertThrowsError(try policyManager.validateSendPolicy(recipient: nil))
        
        // Test signature policy with verified contact but no signature - should throw
        XCTAssertThrowsError(try policyManager.validateSignaturePolicy(recipient: verifiedContact, hasSignature: false))
    }
    
    // MARK: - Error Message Tests
    
    func testPolicyViolationErrorMessages() {
        let rawKeyError = WhisperError.policyViolation(.rawKeyBlocked)
        let signatureError = WhisperError.policyViolation(.signatureRequired)
        let contactError = WhisperError.policyViolation(.contactRequired)
        let biometricError = WhisperError.policyViolation(.biometricRequired)
        
        XCTAssertEqual(rawKeyError.errorDescription, "Raw key sending is blocked by policy")
        XCTAssertEqual(signatureError.errorDescription, "Signature required for verified contacts")
        XCTAssertEqual(contactError.errorDescription, "Contact required for sending")
        XCTAssertEqual(biometricError.errorDescription, "Biometric authentication required")
    }
    
    // MARK: - Helper Methods
    
    private func createTestContact(trustLevel: TrustLevel = .unverified, isBlocked: Bool = false) -> Contact {
        // Create test X25519 public key (32 bytes)
        let x25519PublicKey = Data(repeating: 0x01, count: 32)
        
        do {
            var contact = try Contact(
                displayName: "Test Contact",
                x25519PublicKey: x25519PublicKey,
                ed25519PublicKey: Data(repeating: 0x02, count: 32)
            )
            contact.trustLevel = trustLevel
            contact.isBlocked = isBlocked
            return contact
        } catch {
            fatalError("Failed to create test contact: \(error)")
        }
    }
}

// MARK: - Policy Matrix Tests

extension PolicyManagerTests {
    
    /// Tests all 16 combinations of the 4 policies as required by the design document
    func testPolicyMatrix() {
        let policies = [true, false]
        
        for contactRequired in policies {
            for signatureRequired in policies {
                for autoArchive in policies {
                    for biometricGated in policies {
                        testPolicyCombination(
                            contactRequired: contactRequired,
                            signatureRequired: signatureRequired,
                            autoArchive: autoArchive,
                            biometricGated: biometricGated
                        )
                    }
                }
            }
        }
    }
    
    private func testPolicyCombination(contactRequired: Bool, signatureRequired: Bool, autoArchive: Bool, biometricGated: Bool) {
        // Set up policy combination
        policyManager.contactRequiredToSend = contactRequired
        policyManager.requireSignatureForVerified = signatureRequired
        policyManager.autoArchiveOnRotation = autoArchive
        policyManager.biometricGatedSigning = biometricGated
        
        // Verify policy states
        XCTAssertEqual(policyManager.contactRequiredToSend, contactRequired)
        XCTAssertEqual(policyManager.requireSignatureForVerified, signatureRequired)
        XCTAssertEqual(policyManager.shouldArchiveOnRotation(), autoArchive)
        XCTAssertEqual(policyManager.requiresBiometricForSigning(), biometricGated)
        
        // Test send policy validation
        let contact = createTestContact(trustLevel: .verified)
        
        if contactRequired {
            // Raw key sending should be blocked
            XCTAssertThrowsError(try policyManager.validateSendPolicy(recipient: nil))
            // Contact sending should be allowed
            XCTAssertNoThrow(try policyManager.validateSendPolicy(recipient: contact))
        } else {
            // Both should be allowed
            XCTAssertNoThrow(try policyManager.validateSendPolicy(recipient: nil))
            XCTAssertNoThrow(try policyManager.validateSendPolicy(recipient: contact))
        }
        
        // Test signature policy validation
        if signatureRequired {
            // Verified contact without signature should be blocked
            XCTAssertThrowsError(try policyManager.validateSignaturePolicy(recipient: contact, hasSignature: false))
            // Verified contact with signature should be allowed
            XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: contact, hasSignature: true))
        } else {
            // Both should be allowed
            XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: contact, hasSignature: false))
            XCTAssertNoThrow(try policyManager.validateSignaturePolicy(recipient: contact, hasSignature: true))
        }
    }
}