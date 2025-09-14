import Foundation

// MARK: - Protocol Definition

/// Protocol defining security policy management operations
/// Handles configurable security policies that enforce user-defined constraints
protocol PolicyManager {
    /// Whether contact is required for sending messages (blocks raw key sending)
    var contactRequiredToSend: Bool { get set }
    
    /// Whether signatures are required for verified contacts
    var requireSignatureForVerified: Bool { get set }
    
    /// Whether to auto-archive identities after key rotation
    var autoArchiveOnRotation: Bool { get set }
    
    /// Whether biometric authentication is required for signing operations
    var biometricGatedSigning: Bool { get set }
    
    // MARK: - Policy Validation Methods
    
    /// Validates send policy for a given recipient
    /// - Parameter recipient: Contact to send to, or nil for raw key sending
    /// - Throws: WhisperError.policyViolation if policy is violated
    func validateSendPolicy(recipient: Contact?) throws
    
    /// Validates signature policy for a given recipient and signature presence
    /// - Parameters:
    ///   - recipient: Contact to send to
    ///   - hasSignature: Whether the message includes a signature
    /// - Throws: WhisperError.policyViolation if policy is violated
    func validateSignaturePolicy(recipient: Contact?, hasSignature: Bool) throws
    
    /// Determines if identity should be auto-archived after rotation
    /// - Returns: True if auto-archive policy is enabled
    func shouldArchiveOnRotation() -> Bool
    
    /// Determines if biometric authentication is required for signing
    /// - Returns: True if biometric gating policy is enabled
    func requiresBiometricForSigning() -> Bool
}

// MARK: - Implementation

/// Implementation of PolicyManager using UserDefaults for policy persistence
/// Provides configurable security policies with validation enforcement
class UserDefaultsPolicyManager: PolicyManager {
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let contactRequiredToSend = "whisper.policy.contactRequiredToSend"
        static let requireSignatureForVerified = "whisper.policy.requireSignatureForVerified"
        static let autoArchiveOnRotation = "whisper.policy.autoArchiveOnRotation"
        static let biometricGatedSigning = "whisper.policy.biometricGatedSigning"
    }
    
    // MARK: - Policy Properties
    
    var contactRequiredToSend: Bool {
        get { userDefaults.bool(forKey: Keys.contactRequiredToSend) }
        set { userDefaults.set(newValue, forKey: Keys.contactRequiredToSend) }
    }
    
    var requireSignatureForVerified: Bool {
        get { userDefaults.bool(forKey: Keys.requireSignatureForVerified) }
        set { userDefaults.set(newValue, forKey: Keys.requireSignatureForVerified) }
    }
    
    var autoArchiveOnRotation: Bool {
        get { userDefaults.bool(forKey: Keys.autoArchiveOnRotation) }
        set { userDefaults.set(newValue, forKey: Keys.autoArchiveOnRotation) }
    }
    
    var biometricGatedSigning: Bool {
        get { userDefaults.bool(forKey: Keys.biometricGatedSigning) }
        set { userDefaults.set(newValue, forKey: Keys.biometricGatedSigning) }
    }
    
    // MARK: - Policy Validation Methods
    
    /// Validates send policy for a given recipient
    /// Enforces Contact-Required-to-Send policy by blocking raw key sending when enabled
    /// - Parameter recipient: Contact to send to, or nil for raw key sending
    /// - Throws: WhisperError.policyViolation(.rawKeyBlocked) if contact required but recipient is nil
    func validateSendPolicy(recipient: Contact?) throws {
        // Check Contact-Required-to-Send policy
        if contactRequiredToSend && recipient == nil {
            throw WhisperError.policyViolation(.rawKeyBlocked)
        }
        
        // Additional validation: check if contact is blocked
        if let contact = recipient, contact.isBlocked {
            throw WhisperError.policyViolation(.contactRequired)
        }
    }
    
    /// Validates signature policy for a given recipient and signature presence
    /// Enforces Require-Signature-for-Verified policy for verified contacts
    /// - Parameters:
    ///   - recipient: Contact to send to
    ///   - hasSignature: Whether the message includes a signature
    /// - Throws: WhisperError.policyViolation(.signatureRequired) if signature required but not present
    func validateSignaturePolicy(recipient: Contact?, hasSignature: Bool) throws {
        // Check Require-Signature-for-Verified policy
        if requireSignatureForVerified,
           let contact = recipient,
           contact.trustLevel == .verified,
           !hasSignature {
            throw WhisperError.policyViolation(.signatureRequired)
        }
    }
    
    /// Determines if identity should be auto-archived after rotation
    /// - Returns: True if auto-archive policy is enabled
    func shouldArchiveOnRotation() -> Bool {
        return autoArchiveOnRotation
    }
    
    /// Determines if biometric authentication is required for signing
    /// - Returns: True if biometric gating policy is enabled
    func requiresBiometricForSigning() -> Bool {
        return biometricGatedSigning
    }
}