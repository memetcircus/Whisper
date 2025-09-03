import Foundation
import Security
import CryptoKit
import LocalAuthentication

/// Default implementation of BiometricService
/// Provides secure biometric-protected signing operations
class DefaultBiometricService: BiometricService {
    
    // MARK: - Constants
    
    private static let keyPrefix = "biometric-signing"
    private static let authenticationPrompt = "Authenticate to sign message"
    
    // MARK: - Biometric Availability
    
    func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func biometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
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
            [.biometryAny, .privateKeyUsage],
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
        
        // Create authentication context
        let context = LAContext()
        context.localizedReason = Self.authenticationPrompt
        
        // Query for the biometric-protected key
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
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
                        
                        continuation.resume(returning: Data(signature))
                    } catch {
                        continuation.resume(throwing: BiometricError.signingFailed(errSecParam))
                    }
                    
                case errSecUserCancel:
                    continuation.resume(throwing: BiometricError.userCancelled)
                    
                case errSecAuthFailed:
                    continuation.resume(throwing: BiometricError.authenticationFailed)
                    
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