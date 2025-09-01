import Foundation

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
}

/// Basic implementation of PolicyManager using UserDefaults
/// This is a minimal implementation for the identity management system
class UserDefaultsPolicyManager: PolicyManager {
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let contactRequiredToSend = "whisper.policy.contactRequiredToSend"
        static let requireSignatureForVerified = "whisper.policy.requireSignatureForVerified"
        static let autoArchiveOnRotation = "whisper.policy.autoArchiveOnRotation"
        static let biometricGatedSigning = "whisper.policy.biometricGatedSigning"
    }
    
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
}