import Foundation
import Security
import CryptoKit
import LocalAuthentication

// MARK: - BiometricService Protocol

/// Protocol defining biometric authentication operations for signing keys
/// Provides secure biometric-protected signing without exposing raw private keys
protocol BiometricService {
    /// Checks if biometric authentication is available on the device
    /// - Returns: True if Face ID or Touch ID is available and enrolled
    func isAvailable() -> Bool
    
    /// Enrolls a signing key with biometric protection in the Keychain
    /// - Parameters:
    ///   - key: The Ed25519 private key to enroll
    ///   - id: Unique identifier for the key
    /// - Throws: BiometricError if enrollment fails
    func enrollSigningKey(_ key: Curve25519.Signing.PrivateKey, id: String) throws
    
    /// Signs data using a biometric-protected key
    /// - Parameters:
    ///   - data: Data to sign
    ///   - keyId: Identifier of the key to use for signing
    /// - Returns: The signature data
    /// - Throws: BiometricError if signing fails or user cancels
    func sign(data: Data, keyId: String) async throws -> Data
    
    /// Removes a biometric-protected signing key
    /// - Parameter keyId: Identifier of the key to remove
    /// - Throws: BiometricError if removal fails
    func removeSigningKey(keyId: String) throws
    
    /// Gets the type of biometric authentication available
    /// - Returns: The biometry type (Face ID, Touch ID, or none)
    func biometryType() -> LABiometryType
}

// MARK: - BiometricError

/// Errors that can occur during biometric operations
enum BiometricError: Error, LocalizedError {
    case notAvailable
    case enrollmentFailed(OSStatus)
    case signingFailed(OSStatus)
    case userCancelled
    case keyNotFound
    case invalidKeyData
    case authenticationFailed
    case biometryNotEnrolled
    case biometryLockout
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available"
        case .enrollmentFailed(let status):
            return "Failed to enroll signing key: \(status)"
        case .signingFailed(let status):
            return "Failed to sign data: \(status)"
        case .userCancelled:
            return "Biometric authentication cancelled"
        case .keyNotFound:
            return "Signing key not found"
        case .invalidKeyData:
            return "Invalid key data"
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .biometryNotEnrolled:
            return "Biometric authentication is not enrolled"
        case .biometryLockout:
            return "Biometric authentication is locked out"
        }
    }
    
    /// Converts BiometricError to WhisperError for policy enforcement
    var asWhisperError: WhisperError {
        switch self {
        case .userCancelled:
            return .policyViolation(.biometricRequired)
        case .authenticationFailed, .biometryNotEnrolled, .biometryLockout:
            return .biometricAuthenticationFailed
        default:
            return .biometricAuthenticationFailed
        }
    }
}

// MARK: - Implementation

/// Implementation of BiometricService using iOS Keychain and LocalAuthentication
/// Provides secure biometric-protected signing operations without exposing private keys
class KeychainBiometricService: BiometricService {
    
    // MARK: - Constants
    
    private static let keyPrefix = "biometric-signing"
    private static let authenticationPrompt = "Authenticate to sign message"
    
    // MARK: - Biometric Availability
    
    func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.biometryCurrentSet, error: &error)
    }
    
    func biometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.biometryCurrentSet, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    // MARK: - Key Enrollment
    
    func enrollSigningKey(_ key: Curve25519.Signing.PrivateKey, id: String) throws {
        guard isAvailable() else {
            throw BiometricError.notAvailable
        }
        
        let keyData = key.rawRepresentation
        let keyTag = "\(Self.keyPrefix)-\(id)".data(using: .utf8)!
        
        // Create access control requiring biometric authentication
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.biometryCurrentSet, .privateKeyUsage],
            &error
        )
        
        guard let accessControl = accessControl else {
            throw BiometricError.enrollmentFailed(errSecParam)
        }
        
        // Remove existing key if present
        try? removeSigningKey(keyId: id)
        
        // Store the key with biometric protection
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrAccessControl as String: accessControl,
            kSecValueData as String: keyData,
            kSecAttrSynchronizable as String: false // Never sync to iCloud
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // Securely clear the key data from memory
        keyData.withUnsafeBytes { bytes in
            memset_s(UnsafeMutableRawPointer(mutating: bytes.baseAddress), bytes.count, 0, bytes.count)
        }
        
        guard status == errSecSuccess else {
            throw BiometricError.enrollmentFailed(status)
        }
    }
    
    // MARK: - Signing Operations
    
    func sign(data: Data, keyId: String) async throws -> Data {
        guard isAvailable() else {
            throw BiometricError.notAvailable
        }
        
        let keyTag = "\(Self.keyPrefix)-\(keyId)".data(using: .utf8)!
        
        // Query for the biometric-protected key
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: Self.authenticationPrompt
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &result)
                
                switch status {
                case errSecSuccess:
                    guard let keyData = result as? Data else {
                        continuation.resume(throwing: BiometricError.invalidKeyData)
                        return
                    }
                    
                    do {
                        // Create the private key from the retrieved data
                        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
                        
                        // Sign the data
                        let signature = try privateKey.signature(for: data)
                        
                        // Securely clear the key data from memory
                        keyData.withUnsafeBytes { bytes in
                            memset_s(UnsafeMutableRawPointer(mutating: bytes.baseAddress), bytes.count, 0, bytes.count)
                        }
                        
                        continuation.resume(returning: Data(signature))
                    } catch {
                        continuation.resume(throwing: BiometricError.signingFailed(errSecParam))
                    }
                    
                case errSecUserCancel:
                    continuation.resume(throwing: BiometricError.userCancelled)
                    
                case errSecAuthFailed:
                    continuation.resume(throwing: BiometricError.authenticationFailed)
                    
                case errSecBiometryNotAvailable:
                    continuation.resume(throwing: BiometricError.biometryNotEnrolled)
                    
                case errSecBiometryLockout:
                    continuation.resume(throwing: BiometricError.biometryLockout)
                    
                case errSecItemNotFound:
                    continuation.resume(throwing: BiometricError.keyNotFound)
                    
                default:
                    continuation.resume(throwing: BiometricError.signingFailed(status))
                }
            }
        }
    }
    
    // MARK: - Key Management
    
    func removeSigningKey(keyId: String) throws {
        let keyTag = "\(Self.keyPrefix)-\(keyId)".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BiometricError.enrollmentFailed(status)
        }
    }
}

// MARK: - Policy Integration

extension KeychainBiometricService {
    
    /// Signs data with policy enforcement
    /// Integrates with PolicyManager to enforce biometric gating policy
    /// - Parameters:
    ///   - data: Data to sign
    ///   - keyId: Identifier of the key to use for signing
    ///   - policyManager: Policy manager to check biometric requirements
    /// - Returns: The signature data
    /// - Throws: WhisperError.policyViolation(.biometricRequired) if policy requires biometric but user cancels
    func signWithPolicyEnforcement(data: Data, 
                                 keyId: String, 
                                 policyManager: PolicyManager) async throws -> Data {
        
        // Check if biometric gating is required by policy
        if policyManager.requiresBiometricForSigning() {
            guard isAvailable() else {
                throw WhisperError.policyViolation(.biometricRequired)
            }
            
            do {
                return try await sign(data: data, keyId: keyId)
            } catch let error as BiometricError {
                throw error.asWhisperError
            }
        } else {
            // If biometric gating is not required, we can still use biometric-protected keys
            // but fall back to regular keychain access if biometric fails
            do {
                return try await sign(data: data, keyId: keyId)
            } catch BiometricError.userCancelled {
                // If user cancels but policy doesn't require biometric, this is still an error
                // because the key is biometric-protected
                throw WhisperError.policyViolation(.biometricRequired)
            } catch let error as BiometricError {
                throw error.asWhisperError
            }
        }
    }
}