import Foundation

// MARK: - Error Types

/// Types of policy violations that can occur
public enum PolicyViolationType {
    case contactRequired
    case signatureRequired
    case rawKeyBlocked
    case biometricRequired
    
    /// User-facing error message for policy violations
    public var userFacingMessage: String {
        switch self {
        case .contactRequired:
            return "Contact required for sending"
        case .signatureRequired:
            return "Signature required for verified contacts"
        case .rawKeyBlocked:
            return "Raw key sending is blocked by policy"
        case .biometricRequired:
            return "Biometric authentication required"
        }
    }
}

/// Comprehensive error type for all Whisper operations
public enum WhisperError: Error, LocalizedError {
    case cryptographicFailure
    case invalidEnvelope
    case keyNotFound
    case policyViolation(PolicyViolationType)
    case biometricAuthenticationFailed
    case replayDetected
    case messageExpired
    case invalidPadding
    case contactNotFound
    case messageNotForMe
    case networkingDetected // Build-time error
    
    public var errorDescription: String? {
        switch self {
        case .cryptographicFailure:
            return "Cryptographic operation failed"
        case .invalidEnvelope:
            return "Invalid envelope"
        case .keyNotFound:
            return "Key not found"
        case .policyViolation(let type):
            return type.userFacingMessage
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed"
        case .replayDetected:
            return "Replay detected"
        case .messageExpired:
            return "Message expired"
        case .invalidPadding:
            return "Invalid padding"
        case .contactNotFound:
            return "Contact not found"
        case .messageNotForMe:
            return "This message is not addressed to you"
        case .networkingDetected:
            return "Networking code detected in build"
        }
    }
}