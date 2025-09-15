import Foundation
import Security
import CryptoKit
import LocalAuthentication

// MARK: - Security Constants

/// Security error constants
private let errSecUserCancel: OSStatus = -128

/// Manages secure storage of cryptographic keys in the iOS Keychain
/// Implements proper security attributes as required by the security model
class KeychainManager {
    
    // MARK: - Security Attributes
    
    /// Standard keychain access for identity keys
    /// Uses kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly for security
    private static let standardAccessControl: SecAccessControl = {
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            [],
            &error
        )
        
        guard let accessControl = accessControl else {
            fatalError("Failed to create standard access control: \(error?.takeRetainedValue() as Any)")
        }
        
        return accessControl
    }()
    
    /// Biometric-protected access control for signing keys
    /// Requires Face ID/Touch ID for access
    private static let biometricAccessControl: SecAccessControl = {
        var error: Unmanaged<CFError>?
        let flags: SecAccessControlCreateFlags
        if #available(iOS 11.3, *) {
            flags = [.biometryAny, .privateKeyUsage]
        } else {
            flags = [.touchIDAny, .privateKeyUsage]
        }
        
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            flags,
            &error
        )
        
        guard let accessControl = accessControl else {
            fatalError("Failed to create biometric access control: \(error?.takeRetainedValue() as Any)")
        }
        
        return accessControl
    }()
    
    // MARK: - Key Storage
    
    /// Stores an identity's X25519 private key in the Keychain
    /// - Parameters:
    ///   - privateKey: The X25519 private key to store
    ///   - identifier: Unique identifier for the key
    /// - Throws: KeychainError if storage fails
    static func storeX25519PrivateKey(_ privateKey: Curve25519.KeyAgreement.PrivateKey, 
                                     identifier: String) throws {
        let keyData = privateKey.rawRepresentation
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "x25519-\(identifier)".data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrAccessControl as String: standardAccessControl,
            kSecValueData as String: keyData,
            kSecAttrSynchronizable as String: false // Never sync to iCloud
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storageFailure(status)
        }
        
        // Securely clear the key data from memory
        keyData.withUnsafeBytes { bytes in
            memset_s(UnsafeMutableRawPointer(mutating: bytes.baseAddress), bytes.count, 0, bytes.count)
        }
    }
    
    /// Stores an Ed25519 signing key with biometric protection
    /// - Parameters:
    ///   - privateKey: The Ed25519 private key to store
    ///   - identifier: Unique identifier for the key
    ///   - requireBiometric: Whether to require biometric authentication
    /// - Throws: KeychainError if storage fails
    static func storeEd25519PrivateKey(_ privateKey: Curve25519.Signing.PrivateKey,
                                      identifier: String,
                                      requireBiometric: Bool = false) throws {
        let keyData = privateKey.rawRepresentation
        let accessControl = requireBiometric ? biometricAccessControl : standardAccessControl
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "ed25519-\(identifier)".data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrAccessControl as String: accessControl,
            kSecValueData as String: keyData,
            kSecAttrSynchronizable as String: false // Never sync to iCloud
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storageFailure(status)
        }
        
        // Securely clear the key data from memory
        keyData.withUnsafeBytes { bytes in
            memset_s(UnsafeMutableRawPointer(mutating: bytes.baseAddress), bytes.count, 0, bytes.count)
        }
    }
    
    // MARK: - Key Retrieval
    
    /// Retrieves an X25519 private key from the Keychain
    /// - Parameter identifier: Unique identifier for the key
    /// - Returns: The X25519 private key
    /// - Throws: KeychainError if retrieval fails
    static func retrieveX25519PrivateKey(identifier: String) throws -> Curve25519.KeyAgreement.PrivateKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "x25519-\(identifier)".data(using: .utf8)!,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.retrievalFailure(status)
        }
        
        guard let keyData = result as? Data else {
            throw KeychainError.invalidKeyData
        }
        
        do {
            let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: keyData)
            
            // Securely clear the key data from memory
            keyData.withUnsafeBytes { bytes in
                memset_s(UnsafeMutableRawPointer(mutating: bytes.baseAddress), bytes.count, 0, bytes.count)
            }
            
            return privateKey
        } catch {
            throw KeychainError.keyCreationFailure(error)
        }
    }
    
    /// Retrieves an Ed25519 private key from the Keychain
    /// - Parameter identifier: Unique identifier for the key
    /// - Returns: The Ed25519 private key
    /// - Throws: KeychainError if retrieval fails
  static func retrieveEd25519PrivateKey(identifier: String) throws -> Curve25519.Signing.PrivateKey {
       
        let context = LAContext()
        context.localizedReason = "Authenticate to access signing key"

        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "ed25519-\(identifier)".data(using: .utf8)!,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
     
        query[kSecUseAuthenticationContext as String] = context

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecUserCancel {
                throw KeychainError.userCancelled
            }
            throw KeychainError.retrievalFailure(status)
        }

        guard let keyData = result as? Data else {
            throw KeychainError.invalidKeyData
        }

        do {
            let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
            keyData.withUnsafeBytes { bytes in
                memset_s(UnsafeMutableRawPointer(mutating: bytes.baseAddress), bytes.count, 0, bytes.count)
            }
            return privateKey
        } catch {
            throw KeychainError.keyCreationFailure(error)
        }
    }
    
    // MARK: - Key Deletion
    
    /// Deletes a key from the Keychain
    /// - Parameters:
    ///   - keyType: Type of key (x25519 or ed25519)
    ///   - identifier: Unique identifier for the key
    /// - Throws: KeychainError if deletion fails
    static func deleteKey(keyType: String, identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "\(keyType)-\(identifier)".data(using: .utf8)!
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailure(status)
        }
    }
    
    // MARK: - Biometric Availability
    
    /// Checks if biometric authentication is available
    /// - Returns: True if Face ID or Touch ID is available and enrolled
    static func isBiometricAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Use .deviceOwnerAuthenticationWithBiometrics which is available on all iOS versions
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Gets the type of biometric authentication available
    /// - Returns: The biometry type (Face ID, Touch ID, or none)
    static func biometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
}

// MARK: - Keychain Errors

enum KeychainError: Error, LocalizedError {
    case storageFailure(OSStatus)
    case retrievalFailure(OSStatus)
    case deletionFailure(OSStatus)
    case invalidKeyData
    case keyCreationFailure(Error)
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .storageFailure(let status):
            return "Failed to store key in Keychain: \(status)"
        case .retrievalFailure(let status):
            return "Failed to retrieve key from Keychain: \(status)"
        case .deletionFailure(let status):
            return "Failed to delete key from Keychain: \(status)"
        case .invalidKeyData:
            return "Invalid key data retrieved from Keychain"
        case .keyCreationFailure(let error):
            return "Failed to create key from Keychain data: \(error.localizedDescription)"
        case .userCancelled:
            return "User cancelled biometric authentication"
        }
    }
}