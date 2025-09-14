import Foundation

// MARK: - Protocol Definition

/// Protocol defining security policy management operations
/// Handles configurable security policies that enforce user-defined constraints
protocol PolicyManager {
    /// Whether contact is required for sending messages (blocks raw key sending)
    var contactRequiredToSend: Bool { get set }
    

    
    /// Whether to auto-archive identities after key rotation
    var autoArchiveOnRotation: Bool { get set }
    
    /// Whether biometric authentication is required for signing operations
    var biometricGatedSigning: Bool { get set }
    
    /// Whether to show only verified contacts in compose message picker
    var showOnlyVerifiedContacts: Bool { get set }
    
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
        static let autoArchiveOnRotation = "whisper.policy.autoArchiveOnRotation"
        static let biometricGatedSigning = "whisper.policy.biometricGatedSigning"
        static let showOnlyVerifiedContacts = "whisper.policy.showOnlyVerifiedContacts"
        // Legacy key for cleanup
        static let requireSignatureForVerified = "whisper.policy.requireSignatureForVerified"
    }
    
    // MARK: - Policy Properties
    
    var contactRequiredToSend: Bool {
        get { userDefaults.bool(forKey: Keys.contactRequiredToSend) }
        set { userDefaults.set(newValue, forKey: Keys.contactRequiredToSend) }
    }
    

    
    var autoArchiveOnRotation: Bool {
        get { userDefaults.bool(forKey: Keys.autoArchiveOnRotation) }
        set { userDefaults.set(newValue, forKey: Keys.autoArchiveOnRotation) }
    }
    
    var biometricGatedSigning: Bool {
        get {
            // Default to true if not explicitly set, to enable biometric signing by default
            if userDefaults.object(forKey: Keys.biometricGatedSigning) == nil {
                return true
            }
            return userDefaults.bool(forKey: Keys.biometricGatedSigning)
        }
        set { userDefaults.set(newValue, forKey: Keys.biometricGatedSigning) }
    }
    
    var showOnlyVerifiedContacts: Bool {
        get { userDefaults.bool(forKey: Keys.showOnlyVerifiedContacts) }
        set { userDefaults.set(newValue, forKey: Keys.showOnlyVerifiedContacts) }
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
    /// Note: Signature requirements have been removed - this method is kept for compatibility
    /// - Parameters:
    ///   - recipient: Contact to send to
    ///   - hasSignature: Whether the message includes a signature
    /// - Throws: WhisperError.policyViolation if policy is violated
    func validateSignaturePolicy(recipient: Contact?, hasSignature: Bool) throws {
        // Signature requirements removed - no validation needed
        // Method kept for compatibility with existing code
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