import Foundation
import LocalAuthentication
import CryptoKit

@MainActor
class BiometricSettingsViewModel: ObservableObject {
    @Published var isBiometricAvailable = false
    @Published var isEnrolled = false
    @Published var biometryType: LABiometryType = .none
    @Published var errorMessage: String?
    
    private let biometricService: BiometricService
    private let testKeyId = "test-signing-key"
    
    init(biometricService: BiometricService = DefaultBiometricService()) {
        self.biometricService = biometricService
    }
    
    func checkBiometricStatus() {
        isBiometricAvailable = biometricService.isAvailable()
        biometryType = biometricService.biometryType()
        
        // Check if we have an enrolled key by trying to access it
        // In a real implementation, we'd have a better way to check enrollment status
        checkEnrollmentStatus()
    }
    
    func enrollSigningKey() async {
        do {
            // Generate a test signing key for enrollment
            let signingKey = Curve25519.Signing.PrivateKey()
            try biometricService.enrollSigningKey(signingKey, id: testKeyId)
            
            isEnrolled = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to enroll signing key: \(error.localizedDescription)"
        }
    }
    
    func removeEnrollment() {
        do {
            try biometricService.removeSigningKey(keyId: testKeyId)
            isEnrolled = false
            errorMessage = nil
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
            errorMessage = "Authentication successful!"
            
            // Clear success message after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if self.errorMessage == "Authentication successful!" {
                    self.errorMessage = nil
                }
            }
        } catch BiometricError.userCancelled {
            errorMessage = "Authentication cancelled by user"
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
    }
    
    private func checkEnrollmentStatus() {
        // Try to access the test key to see if it exists
        // This is a simplified check - in a real app we'd have a proper enrollment registry
        Task {
            do {
                let testData = "enrollment check".data(using: .utf8)!
                _ = try await biometricService.sign(data: testData, keyId: testKeyId)
                await MainActor.run {
                    isEnrolled = true
                }
            } catch BiometricError.keyNotFound {
                await MainActor.run {
                    isEnrolled = false
                }
            } catch BiometricError.userCancelled {
                // User cancelled the check, assume enrolled
                await MainActor.run {
                    isEnrolled = true
                }
            } catch {
                await MainActor.run {
                    isEnrolled = false
                }
            }
        }
    }
}