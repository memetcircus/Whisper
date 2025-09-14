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
                Button("OK") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
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
        case .qrUnsupportedFormat:
            return "qrcode.viewfinder"
        case .qrInvalidContent:
            return "qrcode"
        case .qrCameraPermissionDenied:
            return "camera.fill"
        case .qrScanningNotAvailable:
            return "qrcode.viewfinder"
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
        case .qrUnsupportedFormat, .qrInvalidContent:
            return .orange
        case .qrCameraPermissionDenied:
            return .red
        case .qrScanningNotAvailable:
            return .gray
        }
    }

    private var errorTitle: String {
        switch error {
        case .invalidEnvelope:
            return "Invalid Message Format"
        case .replayDetected:
            return "Security Protection Active"
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
        case .qrUnsupportedFormat:
            return "Unsupported QR Code"
        case .qrInvalidContent:
            return "Invalid QR Content"
        case .qrCameraPermissionDenied:
            return "Camera Access Required"
        case .qrScanningNotAvailable:
            return "QR Scanning Unavailable"
        }
    }

    private var errorDescription: String {
        switch error {
        case .invalidEnvelope:
            return
                "Unable to decrypt this message. This usually happens when the message was encrypted for a different identity. Make sure you're using the same identity on both devices."
        case .replayDetected:
            return
                "This message has already been opened once before. For your security, Whisper messages can only be decrypted one time to prevent attackers from reusing old messages against you."
        case .messageExpired:
            return
                "This message is too old to decrypt safely. Whisper messages expire after 48 hours to protect you from attackers who might try to use old intercepted messages."
        case .messageNotForMe:
            return
                "This message was encrypted for a different identity. Make sure both devices are using the same identity name and keys."
        case .policyViolation(let type):
            return getPolicyViolationDescription(type)
        case .biometricAuthenticationFailed:
            return "Biometric authentication was cancelled or unsuccessful. Your security settings require fingerprint or face verification to decrypt messages."
        case .keyNotFound:
            return "The encryption key needed to decrypt this message isn't available on this device. This might happen if the message is very old or was sent to a different identity."
        case .cryptographicFailure:
            return "Unable to decrypt this message. This usually means the message was encrypted for a different identity or the sender is not in your contacts."
        case .invalidPadding:
            return "This message appears to be corrupted or incomplete. Try copying the message again from the original source."
        case .contactNotFound:
            return "The person who sent this message isn't in your verified contacts list. Add them as a contact first to decrypt their messages."
        case .networkingDetected:
            return "A security violation was detected. Whisper is designed to work completely offline for your privacy and security."
        case .qrUnsupportedFormat:
            return "This QR code format is not supported by Whisper. Only QR codes containing encrypted messages or contact information can be scanned."
        case .qrInvalidContent:
            return "This QR code contains a contact bundle instead of an encrypted message. Use the Contacts tab to add new contacts from QR codes."
        case .qrCameraPermissionDenied:
            return "Camera access is required to scan QR codes. Please enable camera permissions for Whisper in your device Settings."
        case .qrScanningNotAvailable:
            return "QR code scanning is not available on this device. You can still decrypt messages by pasting them manually in the text field above."
        }
    }

    private var errorAdditionalInfo: String? {
        switch error {
        case .replayDetected:
            return
                "🔒 Security Explanation: Each message can only be decrypted once to prevent 'replay attacks' - a common hacking technique where attackers capture and reuse old encrypted messages. This protection ensures that even if someone intercepts your messages, they cannot be maliciously replayed later. To decrypt a message again, you'll need a fresh copy from the sender."
        case .messageExpired:
            return
                "The 48-hour freshness window helps prevent old messages from being replayed by attackers."
        case .messageNotForMe:
            return
                "Each message is encrypted for a specific recipient using their public key. Only the intended recipient can decrypt it."
        case .policyViolation:
            return
                "Your security policies prevent this operation. You can adjust these settings in the app preferences."
        case .cryptographicFailure, .invalidPadding:
            return
                "This could indicate the message was corrupted during transmission or potentially tampered with."
        case .qrCameraPermissionDenied:
            return
                "To enable camera access: Go to Settings > Privacy & Security > Camera > Whisper > Allow Camera Access."
        case .qrInvalidContent:
            return
                "QR codes for contacts should be scanned from the Contacts tab, not the Decrypt tab. Only encrypted message QR codes can be used here."
        default:
            return nil
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
            return
                "Your security policy requires all messages to be digitally signed by verified contacts."
        case .rawKeyBlocked:
            return "Your security policy prevents decryption of messages sent to raw public keys."
        case .biometricRequired:
            return
                "Your security policy requires biometric authentication for all cryptographic operations."
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
                // Show retry button for recoverable QR errors
                if let currentError = error, isRetryableError(currentError), let onRetry = onRetry {
                    Button("Retry") {
                        error = nil
                        onRetry()
                    }
                    Button("Cancel") {
                        error = nil
                    }
                } else {
                    Button("OK") {
                        error = nil
                    }
                }
            } message: {
                if let error = error {
                    Text(getErrorMessage(error))
                }
            }
    }
    
    /// Determines if an error is recoverable and should show a retry option
    private func isRetryableError(_ error: WhisperError) -> Bool {
        switch error {
        case .qrCameraPermissionDenied, .qrScanningNotAvailable:
            return true
        case .biometricAuthenticationFailed:
            return true
        default:
            // For decryption failures, don't show retry - they need to fix the underlying issue
            return false
        }
    }



    private func getErrorMessage(_ error: WhisperError) -> String {
        switch error {
        case .invalidEnvelope:
            return "Unable to decrypt this message. Please make sure you're using the same identity that the message was sent to."
        case .replayDetected:
            return
                "This message was already decrypted once. For security, each message can only be processed once to prevent replay attacks."
        case .messageExpired:
            return "This message has expired (older than 48 hours)."
        case .messageNotForMe:
            return "This message was encrypted for a different identity. Make sure you're using the same identity that the sender used."
        case .policyViolation(let type):
            return getPolicyViolationMessage(type)
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed or was cancelled."
        case .keyNotFound:
            return "Required decryption key not found."
        case .cryptographicFailure:
            return "Unable to decrypt this message. The message may be corrupted or you may not have the correct decryption key."
        case .invalidPadding:
            return "Message appears to be corrupted or incomplete."
        case .contactNotFound:
            return "Sender not found in contacts."
        case .networkingDetected:
            return "Network operation detected (security violation)."
        case .qrUnsupportedFormat:
            return "This QR code format is not supported. Only Whisper encrypted messages can be scanned here."
        case .qrInvalidContent:
            return "This QR code contains contact information, not an encrypted message. Use the Contacts tab to add contacts."
        case .qrCameraPermissionDenied:
            return "Camera access is required to scan QR codes. Please enable camera permissions in Settings."
        case .qrScanningNotAvailable:
            return "QR scanning is not available. You can paste the encrypted message manually instead."
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
    func decryptErrorAlert(error: Binding<WhisperError?>, onRetry: (() -> Void)? = nil) -> some View
    {
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
