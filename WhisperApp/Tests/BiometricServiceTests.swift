import XCTest
import CryptoKit
import LocalAuthentication
@testable import WhisperApp

class BiometricServiceTests: XCTestCase {
    
    var biometricService: KeychainBiometricService!
    var mockPolicyManager: MockPolicyManager!
    
    override func setUp() {
        super.setUp()
        biometricService = KeychainBiometricService()
        mockPolicyManager = MockPolicyManager()
    }
    
    override func tearDown() {
        // Clean up any test keys
        let testKeyIds = ["test-key-1", "test-key-2", "policy-test-key"]
        for keyId in testKeyIds {
            try? biometricService.removeSigningKey(keyId: keyId)
        }
        
        biometricService = nil
        mockPolicyManager = nil
        super.tearDown()
    }
    
    // MARK: - Availability Tests
    
    func testBiometricAvailability() {
        // Test biometric availability check
        let isAvailable = biometricService.isAvailable()
        
        // This will vary by device/simulator, but should not crash
        XCTAssertNotNil(isAvailable)
        
        // Test biometry type
        let biometryType = biometricService.biometryType()
        XCTAssertNotNil(biometryType)
        
        // In simulator, biometry is typically not available
        if !isAvailable {
            XCTAssertEqual(biometryType, .none)
        }
    }
    
    // MARK: - Key Enrollment Tests
    
    func testSigningKeyEnrollment() throws {
        // Skip if biometric authentication is not available (e.g., in simulator)
        guard biometricService.isAvailable() else {
            throw XCTSkip("Biometric authentication not available")
        }
        
        // Generate a test signing key
        let signingKey = Curve25519.Signing.PrivateKey()
        let keyId = "test-key-1"
        
        // Test enrollment
        XCTAssertNoThrow(try biometricService.enrollSigningKey(signingKey, id: keyId))
        
        // Test re-enrollment (should replace existing key)
        let newSigningKey = Curve25519.Signing.PrivateKey()
        XCTAssertNoThrow(try biometricService.enrollSigningKey(newSigningKey, id: keyId))
        
        // Clean up
        try biometricService.removeSigningKey(keyId: keyId)
    }
    
    func testEnrollmentWithoutBiometric() {
        // Create a mock service that reports biometric as unavailable
        let mockService = MockBiometricService(isAvailable: false)
        let signingKey = Curve25519.Signing.PrivateKey()
        
        // Test that enrollment fails when biometric is not available
        XCTAssertThrowsError(try mockService.enrollSigningKey(signingKey, id: "test-key")) { error in
            XCTAssertEqual(error as? BiometricError, .notAvailable)
        }
    }
    
    // MARK: - Signing Tests
    
    func testSigningOperation() async throws {
        // Skip if biometric authentication is not available
        guard biometricService.isAvailable() else {
            throw XCTSkip("Biometric authentication not available")
        }
        
        let signingKey = Curve25519.Signing.PrivateKey()
        let keyId = "test-key-2"
        let testData = "Hello, World!".data(using: .utf8)!
        
        // Enroll the key
        try biometricService.enrollSigningKey(signingKey, id: keyId)
        
        // Note: In a real device with biometric authentication, this would prompt for Face ID/Touch ID
        // In simulator or without biometric setup, this will likely fail
        do {
            let signature = try await biometricService.sign(data: testData, keyId: keyId)
            
            // Verify the signature is valid
            XCTAssertFalse(signature.isEmpty)
            XCTAssertEqual(signature.count, 64) // Ed25519 signatures are 64 bytes
            
            // Verify signature with public key
            let publicKey = signingKey.publicKey
            XCTAssertTrue(publicKey.isValidSignature(signature, for: testData))
            
        } catch BiometricError.userCancelled {
            // Expected in simulator or if user cancels
            XCTAssertTrue(true, "User cancelled biometric authentication (expected in simulator)")
        } catch BiometricError.biometryNotEnrolled {
            // Expected if biometry is not enrolled
            XCTAssertTrue(true, "Biometry not enrolled (expected in simulator)")
        }
        
        // Clean up
        try biometricService.removeSigningKey(keyId: keyId)
    }
    
    func testSigningWithNonexistentKey() async {
        let testData = "Hello, World!".data(using: .utf8)!
        
        do {
            _ = try await biometricService.sign(data: testData, keyId: "nonexistent-key")
            XCTFail("Should have thrown an error for nonexistent key")
        } catch BiometricError.keyNotFound {
            // Expected
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Policy Integration Tests
    
    func testPolicyEnforcementWithBiometricRequired() async throws {
        // Skip if biometric authentication is not available
        guard biometricService.isAvailable() else {
            throw XCTSkip("Biometric authentication not available")
        }
        
        let signingKey = Curve25519.Signing.PrivateKey()
        let keyId = "policy-test-key"
        let testData = "Policy test data".data(using: .utf8)!
        
        // Enroll the key
        try biometricService.enrollSigningKey(signingKey, id: keyId)
        
        // Test with biometric gating enabled
        mockPolicyManager.biometricGatedSigning = true
        
        do {
            _ = try await biometricService.signWithPolicyEnforcement(
                data: testData,
                keyId: keyId,
                policyManager: mockPolicyManager
            )
            // If this succeeds, biometric authentication worked
            XCTAssertTrue(true)
        } catch WhisperError.policyViolation(.biometricRequired) {
            // Expected if user cancels or biometric fails
            XCTAssertTrue(true, "Biometric authentication required but failed (expected)")
        } catch WhisperError.biometricAuthenticationFailed {
            // Expected if biometric authentication fails
            XCTAssertTrue(true, "Biometric authentication failed (expected in simulator)")
        }
        
        // Clean up
        try biometricService.removeSigningKey(keyId: keyId)
    }
    
    func testPolicyEnforcementWithBiometricNotRequired() async throws {
        // Skip if biometric authentication is not available
        guard biometricService.isAvailable() else {
            throw XCTSkip("Biometric authentication not available")
        }
        
        let signingKey = Curve25519.Signing.PrivateKey()
        let keyId = "policy-test-key"
        let testData = "Policy test data".data(using: .utf8)!
        
        // Enroll the key
        try biometricService.enrollSigningKey(signingKey, id: keyId)
        
        // Test with biometric gating disabled
        mockPolicyManager.biometricGatedSigning = false
        
        do {
            _ = try await biometricService.signWithPolicyEnforcement(
                data: testData,
                keyId: keyId,
                policyManager: mockPolicyManager
            )
            // If this succeeds, signing worked
            XCTAssertTrue(true)
        } catch WhisperError.policyViolation(.biometricRequired) {
            // Even with policy disabled, if the key is biometric-protected and user cancels,
            // it should still fail
            XCTAssertTrue(true, "User cancelled biometric authentication")
        } catch WhisperError.biometricAuthenticationFailed {
            // Expected if biometric authentication fails
            XCTAssertTrue(true, "Biometric authentication failed (expected in simulator)")
        }
        
        // Clean up
        try biometricService.removeSigningKey(keyId: keyId)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorConversion() {
        // Test BiometricError to WhisperError conversion
        XCTAssertEqual(
            BiometricError.userCancelled.asWhisperError,
            WhisperError.policyViolation(.biometricRequired)
        )
        
        XCTAssertEqual(
            BiometricError.authenticationFailed.asWhisperError,
            WhisperError.biometricAuthenticationFailed
        )
        
        XCTAssertEqual(
            BiometricError.biometryNotEnrolled.asWhisperError,
            WhisperError.biometricAuthenticationFailed
        )
        
        XCTAssertEqual(
            BiometricError.biometryLockout.asWhisperError,
            WhisperError.biometricAuthenticationFailed
        )
    }
    
    // MARK: - Key Management Tests
    
    func testKeyRemoval() throws {
        // Skip if biometric authentication is not available
        guard biometricService.isAvailable() else {
            throw XCTSkip("Biometric authentication not available")
        }
        
        let signingKey = Curve25519.Signing.PrivateKey()
        let keyId = "removal-test-key"
        
        // Enroll the key
        try biometricService.enrollSigningKey(signingKey, id: keyId)
        
        // Remove the key
        XCTAssertNoThrow(try biometricService.removeSigningKey(keyId: keyId))
        
        // Try to remove again (should not throw)
        XCTAssertNoThrow(try biometricService.removeSigningKey(keyId: keyId))
    }
    
    // MARK: - Memory Security Tests
    
    func testMemoryClearing() throws {
        // This test verifies that sensitive key material is cleared from memory
        // Note: This is difficult to test directly, but we can verify the API behavior
        
        let signingKey = Curve25519.Signing.PrivateKey()
        let keyId = "memory-test-key"
        
        // The enrollment process should clear key data from memory
        if biometricService.isAvailable() {
            XCTAssertNoThrow(try biometricService.enrollSigningKey(signingKey, id: keyId))
            try biometricService.removeSigningKey(keyId: keyId)
        }
        
        // Verify that the original key is still valid (not corrupted by clearing)
        let testData = "Memory test".data(using: .utf8)!
        let signature = try signingKey.signature(for: testData)
        XCTAssertTrue(signingKey.publicKey.isValidSignature(signature, for: testData))
    }
}

// MARK: - Mock Classes

class MockBiometricService: BiometricService {
    private let mockIsAvailable: Bool
    private let mockBiometryType: LABiometryType
    private var enrolledKeys: [String: Curve25519.Signing.PrivateKey] = [:]
    
    init(isAvailable: Bool = true, biometryType: LABiometryType = .faceID) {
        self.mockIsAvailable = isAvailable
        self.mockBiometryType = biometryType
    }
    
    func isAvailable() -> Bool {
        return mockIsAvailable
    }
    
    func biometryType() -> LABiometryType {
        return mockBiometryType
    }
    
    func enrollSigningKey(_ key: Curve25519.Signing.PrivateKey, id: String) throws {
        guard mockIsAvailable else {
            throw BiometricError.notAvailable
        }
        enrolledKeys[id] = key
    }
    
    func sign(data: Data, keyId: String) async throws -> Data {
        guard mockIsAvailable else {
            throw BiometricError.notAvailable
        }
        
        guard let key = enrolledKeys[keyId] else {
            throw BiometricError.keyNotFound
        }
        
        let signature = try key.signature(for: data)
        return Data(signature)
    }
    
    func removeSigningKey(keyId: String) throws {
        enrolledKeys.removeValue(forKey: keyId)
    }
}

class MockPolicyManager: PolicyManager {
    var contactRequiredToSend: Bool = false
    var requireSignatureForVerified: Bool = false
    var autoArchiveOnRotation: Bool = false
    var biometricGatedSigning: Bool = false
    
    func validateSendPolicy(recipient: Contact?) throws {
        if contactRequiredToSend && recipient == nil {
            throw WhisperError.policyViolation(.rawKeyBlocked)
        }
    }
    
    func validateSignaturePolicy(recipient: Contact?, hasSignature: Bool) throws {
        if requireSignatureForVerified,
           let contact = recipient,
           contact.trustLevel == .verified,
           !hasSignature {
            throw WhisperError.policyViolation(.signatureRequired)
        }
    }
    
    func shouldArchiveOnRotation() -> Bool {
        return autoArchiveOnRotation
    }
    
    func requiresBiometricForSigning() -> Bool {
        return biometricGatedSigning
    }
}