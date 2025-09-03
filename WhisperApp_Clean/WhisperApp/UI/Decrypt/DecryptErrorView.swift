import SwiftUI

/// Specialized view for displaying decryption errors with appropriate icons and messages
struct DecryptErrorView: View {
    let error: WhisperError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: errorIcon)
                .font(.system(size: 60))
                .foregroundColor(errorColor)
            
            // Error Title
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Error Description
            Text(errorDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Additional Information (if applicable)
            if let additionalInfo = errorAdditionalInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    Text(additionalInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if let onRetry = onRetry, canRetry {
                    Button("Try Again") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Error Properties
    
    private var errorIcon: String {
        switch error {
        case .invalidEnvelope:
            return "envelope.badge.fill"
        case .replayDetected:
            return "arrow.clockwise.circle.fill"
        case .messageExpired:
            return "clock.fill"
        case .messageNotForMe:
            return "person.crop.circle.badge.xmark"
        case .policyViolation:
            return "shield.fill"
        case .biometricAuthenticationFailed:
            return "faceid"
        case .keyNotFound:
            return "key.fill"
        case .cryptographicFailure:
            return "lock.trianglebadge.exclamationmark.fill"
        case .invalidPadding:
            return "exclamationmark.triangle.fill"
        case .contactNotFound:
            return "person.fill.questionmark"
        case .networkingDetected:
            return "wifi.exclamationmark"
        }
    }
    
    private var errorColor: Color {
        switch error {
        case .invalidEnvelope, .invalidPadding, .cryptographicFailure:
            return .red
        case .replayDetected:
            return .orange
        case .messageExpired:
            return .yellow
        case .messageNotForMe:
            return .blue
        case .policyViolation:
            return .purple
        case .biometricAuthenticationFailed:
            return .indigo
        case .keyNotFound, .contactNotFound:
            return .gray
        case .networkingDetected:
            return .red
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .invalidEnvelope:
            return "Invalid Message Format"
        case .replayDetected:
            return "Message Already Processed"
        case .messageExpired:
            return "Message Expired"
        case .messageNotForMe:
            return "Message Not For You"
        case .policyViolation(let type):
            return getPolicyViolationTitle(type)
        case .biometricAuthenticationFailed:
            return "Authentication Failed"
        case .keyNotFound:
            return "Decryption Key Not Found"
        case .cryptographicFailure:
            return "Decryption Failed"
        case .invalidPadding:
            return "Message Corrupted"
        case .contactNotFound:
            return "Unknown Sender"
        case .networkingDetected:
            return "Security Violation"
        }
    }
    
    private var errorDescription: String {
        switch error {
        case .invalidEnvelope:
            return "The message format is not recognized. Please check that you have the complete message."
        case .replayDetected:
            return "This message has already been processed. For security, messages can only be decrypted once."
        case .messageExpired:
            return "This message has expired. Messages must be decrypted within 48 hours of being sent."
        case .messageNotForMe:
            return "This message was not intended for you. It was encrypted for a different recipient."
        case .policyViolation(let type):
            return getPolicyViolationDescription(type)
        case .biometricAuthenticationFailed:
            return "Authentication was cancelled or failed. Please try again."
        case .keyNotFound:
            return "Unable to decrypt this message. The required key was not found."
        case .cryptographicFailure:
            return "Unable to decrypt this message. It may be corrupted or invalid."
        case .invalidPadding:
            return "This message appears to be corrupted and cannot be decrypted."
        case .contactNotFound:
            return "The message sender is not in your contacts."
        case .networkingDetected:
            return "A security violation was detected."
        }
    }
    
    private var errorAdditionalInfo: String? {
        switch error {
        case .replayDetected:
            return "Replay protection prevents the same message from being decrypted multiple times to protect against replay attacks."
        case .messageExpired:
            return "The 48-hour freshness window helps prevent old messages from being replayed by attackers."
        case .messageNotForMe:
            return "Each message is encrypted for a specific recipient using their public key. Only the intended recipient can decrypt it."
        case .policyViolation:
            return "Your security policies prevent this operation. You can adjust these settings in the app preferences."
        case .cryptographicFailure, .invalidPadding:
            return "This could indicate the message was corrupted during transmission or potentially tampered with."
        default:
            return nil
        }
    }
    
    private var canRetry: Bool {
        switch error {
        case .biometricAuthenticationFailed:
            return true
        case .invalidEnvelope, .cryptographicFailure, .invalidPadding:
            return true // User might want to try with corrected input
        default:
            return false
        }
    }
    
    // MARK: - Policy Violation Helpers
    
    private func getPolicyViolationTitle(_ type: PolicyViolationType) -> String {
        switch type {
        case .contactRequired:
            return "Contact Verification Required"
        case .signatureRequired:
            return "Message Signature Required"
        case .rawKeyBlocked:
            return "Raw Key Usage Blocked"
        case .biometricRequired:
            return "Biometric Authentication Required"
        }
    }
    
    private func getPolicyViolationDescription(_ type: PolicyViolationType) -> String {
        switch type {
        case .contactRequired:
            return "Your security policy requires the sender to be in your verified contacts list."
        case .signatureRequired:
            return "Your security policy requires all messages to be digitally signed by verified contacts."
        case .rawKeyBlocked:
            return "Your security policy prevents decryption of messages sent to raw public keys."
        case .biometricRequired:
            return "Your security policy requires biometric authentication for all cryptographic operations."
        }
    }
}

// MARK: - Error Alert Modifier

/// View modifier for showing decryption errors as alerts
struct DecryptErrorAlert: ViewModifier {
    @Binding var error: WhisperError?
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Decryption Error", isPresented: .constant(error != nil)) {
                if let onRetry = onRetry, canRetry(error) {
                    Button("Try Again") {
                        onRetry()
                    }
                }
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(getErrorMessage(error))
                }
            }
    }
    
    private func canRetry(_ error: WhisperError?) -> Bool {
        guard let error = error else { return false }
        
        switch error {
        case .biometricAuthenticationFailed, .invalidEnvelope, .cryptographicFailure, .invalidPadding:
            return true
        default:
            return false
        }
    }
    
    private func getErrorMessage(_ error: WhisperError) -> String {
        switch error {
        case .invalidEnvelope:
            return "The message format is invalid or corrupted."
        case .replayDetected:
            return "This message has already been processed."
        case .messageExpired:
            return "This message has expired (older than 48 hours)."
        case .messageNotForMe:
            return "This message is not addressed to you."
        case .policyViolation(let type):
            return getPolicyViolationMessage(type)
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed or was cancelled."
        case .keyNotFound:
            return "Required decryption key not found."
        case .cryptographicFailure:
            return "Cryptographic operation failed."
        case .invalidPadding:
            return "Message padding is invalid."
        case .contactNotFound:
            return "Sender not found in contacts."
        case .networkingDetected:
            return "Network operation detected (security violation)."
        }
    }
    
    private func getPolicyViolationMessage(_ type: PolicyViolationType) -> String {
        switch type {
        case .contactRequired:
            return "Contact verification required by security policy."
        case .signatureRequired:
            return "Message signature required by security policy."
        case .rawKeyBlocked:
            return "Raw key usage blocked by security policy."
        case .biometricRequired:
            return "Biometric authentication required by security policy."
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds decryption error alert to the view
    func decryptErrorAlert(error: Binding<WhisperError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(DecryptErrorAlert(error: error, onRetry: onRetry))
    }
}

// MARK: - Preview

struct DecryptErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DecryptErrorView(
                error: .replayDetected,
                onRetry: nil,
                onDismiss: {}
            )
            .previewDisplayName("Replay Detected")
            
            DecryptErrorView(
                error: .messageExpired,
                onRetry: nil,
                onDismiss: {}
            )
            .previewDisplayName("Message Expired")
            
            DecryptErrorView(
                error: .biometricAuthenticationFailed,
                onRetry: {},
                onDismiss: {}
            )
            .previewDisplayName("Biometric Failed")
        }
    }
}