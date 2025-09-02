import XCTest
import CryptoKit
@testable import WhisperApp

class PolicyMatrixTests: XCTestCase {
    
    var identityManager: IdentityManager!
    var contactManager: ContactManager!
    var policyManager: PolicyManager!
    var biometricService: MockBiometricService!
    var replayProtector: ReplayProtectionService!
    var whisperService: WhisperService!
    var cryptoEngine: CryptoEngine!
    
    var alice: Identity!
    var bob: Identity!
    var bobContact: Contact!
    var testMessage: Data!
    
    override func setUp() {
        super.setUp()
        
        // Initialize all components
        identityManager = IdentityManager()
        contactManager = ContactManager()
        policyManager = PolicyManager()
        biometricService = MockBiometricService()
        replayProtector = ReplayProtectionService()
        cryptoEngine = CryptoEngine()
        
        whisperService = WhisperService(
            identityManager: identityManager,
            contactManager: contactManager,
            policyManager: policyManager,
            biometricService: biometricService,
            replayProtector: replayProtector,
            cryptoEngine: cryptoEngine
        )
        
        // Create test identities and contacts
        alice = try! identityManager.createIdentity(name: "Alice")
        bob = try! identityManager.createIdentity(name: "Bob")
        
        try! identityManager.setActiveIdentity(alice)
        
        bobContact = Contact(
            id: UUID(),
            displayName: "Bob",
            x25519PublicKey: bob.x25519KeyPair.publicKey,
            ed25519PublicKey: bob.ed25519KeyPair?.publicKey,
            fingerprint: bob.fingerprint,
            shortFingerprint: bob.shortFingerprint,
            sasWords: bob.sasWords,
            rkid: bob.rkid,
            trustLevel: .verified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try! contactManager.addContact(bobContact)
        
        testMessage = "Policy matrix test message".data(using: .utf8)!
        
        // Set up biometric service
        biometricService.isAvailable = true
        biometricService.shouldSucceed = true
        try! biometricService.enrollSigningKey(alice.ed25519KeyPair!.privateKey, id: alice.id.uuidString)
    }
    
    override func tearDown() {
        // Clean up test data
        try? identityManager.deleteAllIdentities()
        try? contactManager.deleteAllContacts()
        replayProtector.clearCache()
        biometricService.reset()
        
        super.tearDown()
    }
    
    // MARK: - Comprehensive Policy Matrix Tests
    
    func testAllPolicyCombinations() throws {
        let policies = [false, true]
        var testResults: [(String, Bool, String?)] = []
        
        for contactRequired in policies {
            for signatureRequired in policies {
                for autoArchive in policies {
                    for biometricGated in policies {
                        
                        let policyDescription = "CR:\(contactRequired ? "T" : "F") SR:\(signatureRequired ? "T" : "F") AA:\(autoArchive ? "T" : "F") BG:\(biometricGated ? "T" : "F")"
                        
                        // Reset policies
                        policyManager.contactRequiredToSend = contactRequired
                        policyManager.requireSignatureForVerified = signatureRequired
                        policyManager.autoArchiveOnRotation = autoArchive
                        policyManager.biometricGatedSigning = biometricGated
                        
                        // Configure biometric service
                        biometricService.shouldSucceed = true
                        
                        do {
                            // Test 1: Encrypt to verified contact with signature
                            let envelope1 = try whisperService.encrypt(
                                testMessage,
                                from: alice,
                                to: bobContact,
                                authenticity: true
                            )
                            
                            XCTAssertTrue(envelope1.hasPrefix("whisper1:"), "Failed envelope creation for policy: \(policyDescription)")
                            testResults.append((policyDescription + " (contact+sig)", true, nil))
                            
                            // Test 2: Encrypt to verified contact without signature
                            if signatureRequired {
                                // Should fail for verified contact without signature
                                XCTAssertThrowsError(
                                    try whisperService.encrypt(
                                        testMessage,
                                        from: alice,
                                        to: bobContact,
                                        authenticity: false
                                    )
                                ) { error in
                                    XCTAssertEqual(error as? WhisperError, .policyViolation(.signatureRequired))
                                }
                                testResults.append((policyDescription + " (contact-sig)", false, "signatureRequired"))
                            } else {
                                let envelope2 = try whisperService.encrypt(
                                    testMessage,
                                    from: alice,
                                    to: bobContact,
                                    authenticity: false
                                )
                                XCTAssertTrue(envelope2.hasPrefix("whisper1:"))
                                testResults.append((policyDescription + " (contact-sig)", true, nil))
                            }
                            
                            // Test 3: Encrypt to raw key
                            if contactRequired {
                                // Should fail when contact required
                                XCTAssertThrowsError(
                                    try whisperService.encryptToRawKey(
                                        testMessage,
                                        from: alice,
                                        to: bob.x25519KeyPair.publicKey,
                                        authenticity: false
                                    )
                                ) { error in
                                    XCTAssertEqual(error as? WhisperError, .policyViolation(.rawKeyBlocked))
                                }
                                testResults.append((policyDescription + " (rawkey)", false, "rawKeyBlocked"))
                            } else {
                                let envelope3 = try whisperService.encryptToRawKey(
                                    testMessage,
                                    from: alice,
                                    to: bob.x25519KeyPair.publicKey,
                                    authenticity: false
                                )
                                XCTAssertTrue(envelope3.hasPrefix("whisper1:"))
                                testResults.append((policyDescription + " (rawkey)", true, nil))
                            }
                            
                            // Test 4: Biometric failure scenario
                            if biometricGated {
                                biometricService.shouldSucceed = false
                                
                                XCTAssertThrowsError(
                                    try whisperService.encrypt(
                                        testMessage,
                                        from: alice,
                                        to: bobContact,
                                        authenticity: true
                                    )
                                ) { error in
                                    XCTAssertEqual(error as? WhisperError, .policyViolation(.biometricRequired))
                                }
                                testResults.append((policyDescription + " (bio-fail)", false, "biometricRequired"))
                                
                                // Reset biometric for next tests
                                biometricService.shouldSucceed = true
                            }
                            
                        } catch {
                            testResults.append((policyDescription, false, "\(error)"))
                            XCTFail("Unexpected error for policy \(policyDescription): \(error)")
                        }
                    }
                }
            }
        }
        
        // Print test results summary
        print("\n=== Policy Matrix Test Results ===")
        for (policy, success, error) in testResults {
            let status = success ? "✅" : "❌"
            let errorInfo = error != nil ? " (\(error!))" : ""
            print("\(status) \(policy)\(errorInfo)")
        }
        print("===================================\n")
    }
    
    func testSpecificPolicyScenarios() throws {
        // Scenario 1: Maximum security (all policies enabled)
        policyManager.contactRequiredToSend = true
        policyManager.requireSignatureForVerified = true
        policyManager.autoArchiveOnRotation = true
        policyManager.biometricGatedSigning = true
        
        // Should succeed with proper setup
        let envelope1 = try whisperService.encrypt(
            testMessage,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        XCTAssertTrue(envelope1.hasPrefix("whisper1:"))
        
        // Should fail for raw key
        XCTAssertThrowsError(
            try whisperService.encryptToRawKey(
                testMessage,
                from: alice,
                to: bob.x25519KeyPair.publicKey,
                authenticity: false
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.rawKeyBlocked))
        }
        
        // Should fail without signature for verified contact
        XCTAssertThrowsError(
            try whisperService.encrypt(
                testMessage,
                from: alice,
                to: bobContact,
                authenticity: false
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.signatureRequired))
        }
        
        // Test key rotation with auto-archive
        let oldAliceId = alice.id
        let newAlice = try identityManager.rotateActiveIdentity()
        
        let identities = identityManager.listIdentities()
        let oldAlice = identities.first { $0.id == oldAliceId }
        XCTAssertEqual(oldAlice?.status, .archived)
        XCTAssertEqual(newAlice.status, .active)
        
        // Scenario 2: Minimum security (all policies disabled)
        policyManager.contactRequiredToSend = false
        policyManager.requireSignatureForVerified = false
        policyManager.autoArchiveOnRotation = false
        policyManager.biometricGatedSigning = false
        
        // Should succeed for all operations
        let envelope2 = try whisperService.encrypt(
            testMessage,
            from: newAlice,
            to: bobContact,
            authenticity: false
        )
        XCTAssertTrue(envelope2.hasPrefix("whisper1:"))
        
        let envelope3 = try whisperService.encryptToRawKey(
            testMessage,
            from: newAlice,
            to: bob.x25519KeyPair.publicKey,
            authenticity: false
        )
        XCTAssertTrue(envelope3.hasPrefix("whisper1:"))
        
        // Key rotation should not auto-archive
        let newerAlice = try identityManager.rotateActiveIdentity()
        let allIdentities = identityManager.listIdentities()
        let previousAlice = allIdentities.first { $0.id == newAlice.id }
        XCTAssertEqual(previousAlice?.status, .active) // Should remain active
    }
    
    func testPolicyInteractions() throws {
        // Test interaction between signature required and biometric gated
        policyManager.requireSignatureForVerified = true
        policyManager.biometricGatedSigning = true
        
        // Should succeed when biometric succeeds
        biometricService.shouldSucceed = true
        let envelope1 = try whisperService.encrypt(
            testMessage,
            from: alice,
            to: bobContact,
            authenticity: true
        )
        XCTAssertTrue(envelope1.hasPrefix("whisper1:"))
        
        // Should fail when biometric fails
        biometricService.shouldSucceed = false
        XCTAssertThrowsError(
            try whisperService.encrypt(
                testMessage,
                from: alice,
                to: bobContact,
                authenticity: true
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.biometricRequired))
        }
        
        // Test interaction between contact required and signature required
        policyManager.contactRequiredToSend = true
        policyManager.requireSignatureForVerified = true
        policyManager.biometricGatedSigning = false
        biometricService.shouldSucceed = true
        
        // Create unverified contact
        let charlieIdentity = try identityManager.createIdentity(name: "Charlie")
        let charlieContact = Contact(
            id: UUID(),
            displayName: "Charlie",
            x25519PublicKey: charlieIdentity.x25519KeyPair.publicKey,
            ed25519PublicKey: charlieIdentity.ed25519KeyPair?.publicKey,
            fingerprint: charlieIdentity.fingerprint,
            shortFingerprint: charlieIdentity.shortFingerprint,
            sasWords: charlieIdentity.sasWords,
            rkid: charlieIdentity.rkid,
            trustLevel: .unverified,
            isBlocked: false,
            keyVersion: 1,
            keyHistory: [],
            createdAt: Date()
        )
        try contactManager.addContact(charlieContact)
        
        // Should succeed for unverified contact without signature (signature not required for unverified)
        let envelope2 = try whisperService.encrypt(
            testMessage,
            from: alice,
            to: charlieContact,
            authenticity: false
        )
        XCTAssertTrue(envelope2.hasPrefix("whisper1:"))
        
        // Should fail for verified contact without signature
        XCTAssertThrowsError(
            try whisperService.encrypt(
                testMessage,
                from: alice,
                to: bobContact,
                authenticity: false
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.signatureRequired))
        }
        
        // Should fail for raw key (contact required)
        XCTAssertThrowsError(
            try whisperService.encryptToRawKey(
                testMessage,
                from: alice,
                to: charlieIdentity.x25519KeyPair.publicKey,
                authenticity: false
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.rawKeyBlocked))
        }
    }
    
    func testPolicyValidationTiming() throws {
        // Test that policy validation happens before expensive crypto operations
        policyManager.contactRequiredToSend = true
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        XCTAssertThrowsError(
            try whisperService.encryptToRawKey(
                testMessage,
                from: alice,
                to: bob.x25519KeyPair.publicKey,
                authenticity: false
            )
        ) { error in
            XCTAssertEqual(error as? WhisperError, .policyViolation(.rawKeyBlocked))
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Policy validation should be very fast (< 1ms)
        XCTAssertLessThan(duration, 0.001, "Policy validation took too long: \(duration)s")
    }
    
    func testPolicyPersistence() throws {
        // Set specific policy configuration
        policyManager.contactRequiredToSend = true
        policyManager.requireSignatureForVerified = false
        policyManager.autoArchiveOnRotation = true
        policyManager.biometricGatedSigning = false
        
        // Simulate app restart by creating new policy manager
        let newPolicyManager = PolicyManager()
        
        // Policies should persist (assuming PolicyManager uses UserDefaults or similar)
        XCTAssertEqual(newPolicyManager.contactRequiredToSend, true)
        XCTAssertEqual(newPolicyManager.requireSignatureForVerified, false)
        XCTAssertEqual(newPolicyManager.autoArchiveOnRotation, true)
        XCTAssertEqual(newPolicyManager.biometricGatedSigning, false)
    }
    
    func testPolicyErrorMessages() throws {
        // Test that appropriate error messages are generated for each policy violation
        
        // Contact required error
        policyManager.contactRequiredToSend = true
        XCTAssertThrowsError(
            try whisperService.encryptToRawKey(
                testMessage,
                from: alice,
                to: bob.x25519KeyPair.publicKey,
                authenticity: false
            )
        ) { error in
            if case WhisperError.policyViolation(let type) = error {
                XCTAssertEqual(type, .rawKeyBlocked)
            } else {
                XCTFail("Expected policyViolation(.rawKeyBlocked), got \(error)")
            }
        }
        
        // Signature required error
        policyManager.contactRequiredToSend = false
        policyManager.requireSignatureForVerified = true
        XCTAssertThrowsError(
            try whisperService.encrypt(
                testMessage,
                from: alice,
                to: bobContact,
                authenticity: false
            )
        ) { error in
            if case WhisperError.policyViolation(let type) = error {
                XCTAssertEqual(type, .signatureRequired)
            } else {
                XCTFail("Expected policyViolation(.signatureRequired), got \(error)")
            }
        }
        
        // Biometric required error
        policyManager.requireSignatureForVerified = false
        policyManager.biometricGatedSigning = true
        biometricService.shouldSucceed = false
        
        XCTAssertThrowsError(
            try whisperService.encrypt(
                testMessage,
                from: alice,
                to: bobContact,
                authenticity: true
            )
        ) { error in
            if case WhisperError.policyViolation(let type) = error {
                XCTAssertEqual(type, .biometricRequired)
            } else {
                XCTFail("Expected policyViolation(.biometricRequired), got \(error)")
            }
        }
    }
}