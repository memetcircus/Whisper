import CryptoKit
import Foundation
import LocalAuthentication
import Security

@MainActor
class BiometricSettingsViewModel: ObservableObject {
    @Published var isBiometricAvailable = false
    @Published var isEnrolled = false
    @Published var biometryType: LABiometryType = .none
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var biometricSigningEnabled = false

    private let biometricService: BiometricService
    private var policyManager: PolicyManager
    private let testKeyId = "test-signing-key"

    init(
        biometricService: BiometricService = KeychainBiometricService(),
        policyManager: PolicyManager = ServiceContainer.shared.policyManager
    ) {
        self.biometricService = biometricService
        self.policyManager = policyManager
        self.biometricSigningEnabled = policyManager.biometricGatedSigning
    }

    func checkBiometricStatus() {
        isBiometricAvailable = biometricService.isAvailable()
        biometryType = biometricService.biometryType()
        biometricSigningEnabled = policyManager.biometricGatedSigning

        // Check if we have an enrolled key by trying to access it
        // In a real implementation, we'd have a better way to check enrollment status
        checkEnrollmentStatus()
    }

    func toggleBiometricSigning() {
        policyManager.biometricGatedSigning = !policyManager.biometricGatedSigning
        biometricSigningEnabled = policyManager.biometricGatedSigning
    }

    func enrollSigningKey() async {
        do {
            // Clear any previous messages
            errorMessage = nil
            successMessage = nil

            // Check biometric availability first
            guard biometricService.isAvailable() else {
                errorMessage = "Biometric authentication is not available on this device"
                return
            }

            // Generate a test signing key for enrollment
            // The biometric authentication will happen during the keychain storage
            let signingKey = Curve25519.Signing.PrivateKey()
            try biometricService.enrollSigningKey(signingKey, id: testKeyId)

            isEnrolled = true
            successMessage = "Encryption key enrolled successfully!"

            // Clear success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.successMessage == "Encryption key enrolled successfully!" {
                    self.successMessage = nil
                }
            }
        } catch BiometricError.notAvailable {
            errorMessage = "Biometric authentication is not available"
        } catch BiometricError.biometryNotEnrolled {
            errorMessage = "Please enroll Face ID or Touch ID in Settings first"
        } catch BiometricError.biometryLockout {
            errorMessage =
                "Biometric authentication is locked. Please unlock using passcode in Settings"
        } catch BiometricError.enrollmentFailed(let status) {
            switch status {
            case -25293:  // errSecBiometryLockout
                errorMessage =
                    "Biometric authentication is locked. Please unlock using passcode in Settings"
            case -25291:  // errSecBiometryNotAvailable
                errorMessage = "Please enroll Face ID or Touch ID in Settings first"
            case -25300:  // errSecMissingEntitlement
                errorMessage = "App configuration error. Please contact support"
            default:
                errorMessage = "Failed to enroll encryption key. Error code: \(status)"
            }
        } catch {
            errorMessage = "Failed to enroll encryption key: \(error.localizedDescription)"
        }
    }

    func removeEnrollment() {
        do {
            try biometricService.removeSigningKey(keyId: testKeyId)
            isEnrolled = false
            errorMessage = nil
            successMessage = nil
        } catch {
            errorMessage = "Failed to remove enrollment: \(error.localizedDescription)"
        }
    }

    func testAuthentication() async {
        do {
            let testData = "test authentication".data(using: .utf8)!
            _ = try await biometricService.sign(data: testData, keyId: testKeyId)
            errorMessage = nil

            // Show success message temporarily
            successMessage = "Authentication successful!"

            // Clear success message after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if self.successMessage == "Authentication successful!" {
                    self.successMessage = nil
                }
            }
        } catch BiometricError.userCancelled {
            errorMessage = "Authentication cancelled by user"
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
    }

    private func checkEnrollmentStatus() {
        // Check if key exists without triggering biometric authentication
        // We'll use a keychain query that doesn't require authentication
        let keyTag = "test-signing-key"
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "biometric-signing-\(keyTag)".data(using: .utf8)!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        isEnrolled = (status == errSecSuccess)
    }
}
