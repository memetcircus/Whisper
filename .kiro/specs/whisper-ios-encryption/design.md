# Design Document

## Overview

Whisper is a client-side encryption iOS application that provides end-to-end encryption for messages shared through any platform. The app uses a layered architecture with strict separation between cryptographic operations, data persistence, and user interface components. All operations are performed locally with no network connectivity.

### Key Design Principles

- **Zero Network Policy**: No networking code whatsoever, enforced by build-time tests
- **Cryptographic Isolation**: All crypto operations isolated in dedicated modules using only CryptoKit
- **Identity Separation**: Multiple identities with clear lifecycle management
- **Policy-Driven Security**: Configurable security policies that enforce user-defined constraints
- **Defensive Programming**: Comprehensive input validation, error handling, and secure memory management

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                     │
├─────────────────────────────────────────────────────────────┤
│                   Application Services                      │
├─────────────────────────────────────────────────────────────┤
│                  Security & Policy Layer                   │
├─────────────────────────────────────────────────────────────┤
│                 Cryptographic Core Layer                   │
├─────────────────────────────────────────────────────────────┤
│                   Data Persistence Layer                   │
└─────────────────────────────────────────────────────────────┘
```

### Module Structure

```
WhisperApp/
├── Core/
│   ├── Crypto/           # Cryptographic operations
│   ├── Identity/         # Identity management
│   ├── Contacts/         # Contact management
│   ├── Policies/         # Security policy enforcement
│   └── Storage/          # Data persistence
├── Services/
│   ├── EncryptionService/    # High-level encryption API
│   ├── DecryptionService/    # High-level decryption API
│   └── BiometricService/     # Biometric authentication
├── UI/
│   ├── Compose/         # Message composition
│   ├── Decrypt/         # Message decryption
│   ├── Contacts/        # Contact management UI
│   ├── Settings/        # Policy and identity settings
│   └── Shared/          # Shared UI components
└── Tests/
    ├── Unit/            # Unit tests
    ├── Integration/     # Integration tests
    └── Security/        # Security-specific tests
```

## Components and Interfaces

### 1. Cryptographic Core Layer

#### CryptoEngine
```swift
protocol CryptoEngine {
    func generateIdentity() throws -> Identity
    func generateEphemeralKeyPair() throws -> (privateKey: Curve25519.KeyAgreement.PrivateKey, publicKey: Data)
    func performKeyAgreement(ephemeralPrivate: Curve25519.KeyAgreement.PrivateKey, 
                           recipientPublic: Data) throws -> SharedSecret
    func deriveKeys(sharedSecret: SharedSecret, salt: Data, info: Data) throws -> (encKey: Data, nonce: Data)
    func encrypt(plaintext: Data, key: Data, nonce: Data, aad: Data) throws -> Data
    func decrypt(ciphertext: Data, key: Data, nonce: Data, aad: Data) throws -> Data
    func sign(data: Data, privateKey: Curve25519.Signing.PrivateKey) throws -> Data
    func verify(signature: Data, data: Data, publicKey: Data) throws -> Bool
}
```

#### EnvelopeProcessor
```swift
protocol EnvelopeProcessor {
    func createEnvelope(plaintext: Data, 
                       senderIdentity: Identity, 
                       recipientPublic: Data, 
                       requireSignature: Bool) throws -> String
    func parseEnvelope(_ envelope: String) throws -> EnvelopeComponents
    func validateEnvelope(_ components: EnvelopeComponents) throws -> Bool
    func buildCanonicalContext(appId: String, version: String, 
                              senderFingerprint: Data, recipientFingerprint: Data,
                              policyFlags: UInt32, rkid: Data, epk: Data, 
                              salt: Data, msgid: Data, ts: Int64) -> Data
}
```

### 2. Identity Management Layer

#### IdentityManager
```swift
protocol IdentityManager {
    func createIdentity(name: String) throws -> Identity
    func listIdentities() -> [Identity]
    func getActiveIdentity() -> Identity?
    func setActiveIdentity(_ identity: Identity) throws
    func archiveIdentity(_ identity: Identity) throws
    func rotateActiveIdentity() throws -> Identity
    func exportPublicBundle(_ identity: Identity) throws -> Data
    func importPublicBundle(_ data: Data) throws -> PublicKeyBundle
    func backupIdentity(_ identity: Identity, passphrase: String) throws -> Data
    func restoreIdentity(from backup: Data, passphrase: String) throws -> Identity
}
```

#### Identity Model
```swift
struct Identity {
    let id: UUID
    let name: String
    let x25519KeyPair: X25519KeyPair
    let ed25519KeyPair: Ed25519KeyPair?
    let fingerprint: Data
    let createdAt: Date
    let status: IdentityStatus
    let keyVersion: Int
}

enum IdentityStatus {
    case active
    case archived
    case rotated
}
```

### 3. Contact Management Layer

#### ContactManager
```swift
protocol ContactManager {
    func addContact(_ contact: Contact) throws
    func updateContact(_ contact: Contact) throws
    func deleteContact(id: UUID) throws
    func getContact(id: UUID) -> Contact?
    func getContact(byRkid rkid: Data) -> Contact?
    func listContacts() -> [Contact]
    func verifyContact(id: UUID, sasConfirmed: Bool) throws
    func blockContact(id: UUID) throws
    func unblockContact(id: UUID) throws
    func exportPublicKeybook() throws -> Data
    func handleKeyRotation(for contact: Contact, newPublicKey: Data) throws
}
```

#### Contact Model
```swift
struct Contact {
    let id: UUID
    let displayName: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data // lower 32 bytes of BLAKE2s/SHA-256 hash
    let shortFingerprint: String // Base32 Crockford (12 chars)
    let sasWords: [String] // 6-word sequence for verification
    let rkid: Data
    var trustLevel: TrustLevel
    var isBlocked: Bool
    let keyVersion: Int
    let keyHistory: [KeyHistoryEntry]
    let createdAt: Date
    var lastSeenAt: Date?
    var note: String?
}

enum TrustLevel {
    case unverified
    case verified
    case revoked
}
```

### 4. Security Policy Layer

#### PolicyManager
```swift
protocol PolicyManager {
    var contactRequiredToSend: Bool { get set }
    var requireSignatureForVerified: Bool { get set }
    var autoArchiveOnRotation: Bool { get set }
    var biometricGatedSigning: Bool { get set }
    
    func validateSendPolicy(recipient: Contact?) throws
    func validateSignaturePolicy(recipient: Contact?, hasSignature: Bool) throws
    func shouldArchiveOnRotation() -> Bool
    func requiresBiometricForSigning() -> Bool
}
```

### 5. Biometric Authentication Layer

#### BiometricService
```swift
protocol BiometricService {
    func isAvailable() -> Bool
    func enrollSigningKey(_ key: Curve25519.Signing.PrivateKey, id: String) throws
    func sign(data: Data, keyId: String) async throws -> Data
}
```

### 6. High-Level Service Layer

#### WhisperService
```swift
protocol WhisperService {
    func encrypt(_ data: Data, 
                from identity: Identity, 
                to peer: Contact, 
                authenticity: Bool) async throws -> String
    func encryptToRawKey(_ data: Data, 
                        from identity: Identity, 
                        to publicKey: Data, 
                        authenticity: Bool) async throws -> String
    func decrypt(_ envelope: String) async throws -> DecryptionResult
    func detect(_ text: String) -> Bool
}
```

## Data Models

### Core Data Schema

#### Identity Entity
```swift
@objc(IdentityEntity)
class IdentityEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var x25519PublicKey: Data
    @NSManaged var ed25519PublicKey: Data?
    @NSManaged var fingerprint: Data
    @NSManaged var createdAt: Date
    @NSManaged var status: String
    @NSManaged var keyVersion: Int32
    @NSManaged var isActive: Bool
}
```

#### Contact Entity
```swift
@objc(ContactEntity)
class ContactEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var displayName: String
    @NSManaged var x25519PublicKey: Data
    @NSManaged var ed25519PublicKey: Data?
    @NSManaged var fingerprint: Data
    @NSManaged var shortFingerprint: String
    @NSManaged var rkid: Data
    @NSManaged var trustLevel: String
    @NSManaged var isBlocked: Bool
    @NSManaged var keyVersion: Int32
    @NSManaged var createdAt: Date
    @NSManaged var lastSeenAt: Date?
    @NSManaged var note: String?
    @NSManaged var keyHistory: Set<KeyHistoryEntity>
}
```

#### Replay Protection Entity
```swift
@objc(ReplayProtectionEntity)
class ReplayProtectionEntity: NSManagedObject {
    @NSManaged var messageId: Data
    @NSManaged var timestamp: Int64
    @NSManaged var receivedAt: Date
}
```

### Keychain Storage

#### Private Key Storage
- **Identity Keys**: Stored with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- **Biometric-Protected Keys**: Stored with `kSecAttrAccessControl` requiring `biometryCurrentSet` or `userPresence`
- **Key Identifiers**: Use UUID-based identifiers for key lookup
- **Hash Function**: Prefer BLAKE2s if available, fallback to SHA-256 for rkid generation

## Error Handling

### Error Types
```swift
enum WhisperError: Error {
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
}

enum PolicyViolationType {
    case contactRequired
    case signatureRequired
    case rawKeyBlocked
    case biometricRequired
}

protocol ReplayProtector {
    func checkAndCommit(msgId: Data, timestamp: Int64) -> Bool
    func isWithinFreshnessWindow(_ timestamp: Int64) -> Bool
    func cleanup() // Remove expired entries
}
```

### Error Presentation Strategy
- **User-Facing**: Only generic messages ("Invalid envelope", "Replay detected", "Message expired", "Signature cancelled", "This message is not addressed to you")
- **Development**: Detailed error information in debug builds only
- **Logging**: Local-only logs disabled in Release builds

## Testing Strategy

### Unit Testing
- **Cryptographic Functions**: Test vectors for all crypto operations
- **Envelope Processing**: Valid/invalid envelope parsing
- **Policy Enforcement**: All policy combinations and edge cases
- **Identity Management**: Create, rotate, archive operations
- **Contact Management**: Trust level transitions and key rotation

### Integration Testing
- **End-to-End Encryption**: Full encrypt/decrypt cycles
- **Multi-Identity Scenarios**: Cross-identity communication
- **Policy Integration**: Policy enforcement across components
- **Biometric Integration**: Mock biometric authentication flows

### Security Testing
- **Network Detection**: Build fails if networking symbols present
- **Memory Safety**: Ephemeral key zeroization verification
- **Replay Protection**: Duplicate message detection with atomic checkAndCommit
- **Timing Attacks**: Constant-time operations verification with timing leakage tests
- **Padding Validation**: Invalid padding rejection with constant-time checks
- **Determinism**: Same plaintext must yield different envelopes (random epk/salt/msgid)
- **Nonce Uniqueness**: Soak test with 1M iterations
- **Policy Matrix**: Test all 16 combinations of 4 policies
- **Algorithm Lock**: Strict v1.c20p enforcement, reject all other versions

### Performance Testing
- **Encryption Speed**: Benchmark encryption/decryption operations
- **Key Generation**: Identity creation performance
- **Database Operations**: Contact and identity queries
- **Memory Usage**: Memory footprint during operations

### Accessibility Testing
- **VoiceOver**: All UI elements properly labeled
- **Dynamic Type**: Text scaling support
- **Color Contrast**: Accessibility color requirements
- **Motor Accessibility**: Touch target sizes and gestures

## Security Considerations

### Cryptographic Security
- **Algorithm Selection**: Only approved algorithms (X25519, Ed25519, ChaCha20-Poly1305)
- **Key Management**: Proper key lifecycle and secure storage
- **Randomness**: CryptoKit secure random number generation
- **Forward Secrecy**: Ephemeral keys for each message

### Implementation Security
- **Memory Management**: Secure memory clearing for sensitive data
- **Side-Channel Resistance**: Constant-time operations where applicable
- **Input Validation**: Comprehensive validation of all inputs
- **Error Information**: Minimal error information disclosure

### Platform Security
- **Keychain Integration**: Proper use of iOS Keychain services
- **Biometric Integration**: Secure biometric authentication
- **App Sandbox**: Leverage iOS app sandboxing
- **Code Signing**: Proper app signing and entitlements

## Performance Considerations

### Optimization Strategies
- **Lazy Loading**: Load identities and contacts on demand
- **Caching**: Cache frequently accessed cryptographic materials
- **Background Processing**: Perform crypto operations off main thread
- **Memory Efficiency**: Minimize memory allocations during crypto operations

### Scalability Limits
- **Contact Limit**: Reasonable limits on contact storage (e.g., 10,000 contacts)
- **Identity Limit**: Practical limits on identity count (e.g., 100 identities)
- **Replay Cache**: 30-day retention with 10,000 entry limit
- **QR Code Size**: Warn users if envelope exceeds 400-900 bytes (QR version 11-15 with M error correction)
- **Message Size**: Practical limits based on QR code capacity and platform sharing limits

## Deployment Considerations

### Build Configuration
- **Debug Builds**: Enhanced logging and debugging features
- **Release Builds**: Optimized performance and minimal logging
- **Test Builds**: Additional test hooks and validation
- **Security Validation**: Build-time security checks

### App Store Compliance
- **Privacy Labels**: Accurate privacy nutrition labels
- **Export Compliance**: Cryptography export compliance documentation
- **Accessibility**: Full accessibility compliance
- **Localization**: Support for multiple languages and regions
#
# Context Binding Implementation

### Canonical Context Structure

The system uses a deterministic canonical byte structure for both AAD and HKDF info:

```swift
struct CanonicalContext {
    let appId: String = "whisper"
    let version: String = "v1"
    let senderFingerprint: Data // 32 bytes
    let recipientFingerprint: Data // 32 bytes
    let policyFlags: UInt32
    let rkid: Data // 8 bytes
    let epk: Data // 32 bytes
    let salt: Data // 16 bytes
    let msgid: Data // 16 bytes
    let timestamp: Int64
    
    func encode() -> Data {
        // Use CBOR or length-prefixed encoding for deterministic serialization
        // Must be identical for AAD and HKDF info construction
    }
}
```

### Padding Implementation

```swift
enum PaddingBucket: Int {
    case small = 256
    case medium = 512
    case large = 1024
    
    static func selectBucket(for messageLength: Int) -> PaddingBucket {
        if messageLength <= 256 { return .small }
        if messageLength <= 512 { return .medium }
        return .large
    }
}

struct MessagePadding {
    static func pad(_ message: Data, to bucket: PaddingBucket) -> Data {
        let length = UInt16(message.count).bigEndian
        var padded = Data()
        padded.append(Data(bytes: &length, count: 2))
        padded.append(message)
        
        let targetSize = bucket.rawValue
        let paddingNeeded = targetSize - padded.count
        padded.append(Data(repeating: 0x00, count: paddingNeeded))
        
        return padded
    }
    
    static func unpad(_ paddedData: Data) throws -> Data {
        guard paddedData.count >= 2 else { throw WhisperError.invalidPadding }
        
        let lengthBytes = paddedData.prefix(2)
        let messageLength = Int(UInt16(bigEndian: lengthBytes.withUnsafeBytes { $0.load(as: UInt16.self) }))
        
        guard messageLength + 2 <= paddedData.count else { throw WhisperError.invalidPadding }
        
        let message = paddedData.subdata(in: 2..<(2 + messageLength))
        let padding = paddedData.suffix(from: 2 + messageLength)
        
        // Constant-time padding validation
        var paddingValid = true
        for byte in padding {
            paddingValid = paddingValid && (byte == 0x00)
        }
        
        guard paddingValid else { throw WhisperError.invalidPadding }
        return message
    }
}
```

## Signature Attribution Logic

### Attribution Rules Implementation

```swift
struct SignatureAttributor {
    func attributeMessage(signature: Data?, 
                         senderPublicKey: Data?, 
                         contact: Contact?) -> AttributionResult {
        
        guard let signature = signature else {
            return .unsigned(contact?.displayName ?? "Unknown")
        }
        
        // Verify signature validity first
        guard let senderKey = senderPublicKey,
              verifySignature(signature, publicKey: senderKey) else {
            return .invalidSignature
        }
        
        // Check if signature matches known contact
        if let contact = contact,
           let contactSigningKey = contact.ed25519PublicKey,
           contactSigningKey == senderKey {
            
            let trustStatus = contact.trustLevel == .verified ? "Verified" : "Unverified"
            return .signed(contact.displayName, trustStatus)
        }
        
        // Valid signature but unknown sender
        return .signedUnknown
    }
}

enum AttributionResult {
    case signed(String, String) // name, trust status
    case signedUnknown
    case unsigned(String) // name or "Unknown"
    case invalidSignature
    
    var displayString: String {
        switch self {
        case .signed(let name, let trust):
            return "From: \(name) (\(trust), Signed)"
        case .signedUnknown:
            return "From: Unknown (Signed)"
        case .unsigned(let name):
            return "From: \(name)"
        case .invalidSignature:
            return "From: Unknown (Invalid Signature)"
        }
    }
}
```

## Replay Protection Implementation

### Atomic Replay Checking

```swift
class ReplayProtectionService: ReplayProtector {
    private let queue = DispatchQueue(label: "replay-protection", qos: .userInitiated)
    private var seenMessages: Set<Data> = []
    private let maxEntries = 10_000
    private let retentionDays = 30
    
    func checkAndCommit(msgId: Data, timestamp: Int64) -> Bool {
        return queue.sync {
            // Check freshness first (±48 hours)
            guard isWithinFreshnessWindow(timestamp) else {
                return false // Don't commit expired messages
            }
            
            // Check for replay
            guard !seenMessages.contains(msgId) else {
                return false // Replay detected
            }
            
            // Commit to cache
            seenMessages.insert(msgId)
            
            // Cleanup if needed
            if seenMessages.count > maxEntries {
                cleanup()
            }
            
            return true
        }
    }
    
    func isWithinFreshnessWindow(_ timestamp: Int64) -> Bool {
        let now = Int64(Date().timeIntervalSince1970)
        let windowSeconds: Int64 = 48 * 60 * 60 // 48 hours
        return abs(now - timestamp) <= windowSeconds
    }
    
    func cleanup() {
        // Remove oldest entries to maintain size limit
        // In production, this would use Core Data with timestamp-based cleanup
    }
}
```

## Enhanced Testing Requirements

### Comprehensive Test Matrix

```swift
class WhisperSecurityTests: XCTestCase {
    
    func testNetworkingSymbolsAbsent() {
        // Build-time test that fails if networking symbols are present
        let forbiddenSymbols = ["URLSession", "Network", "CFSocket", "NSURLConnection"]
        // Implementation would scan binary for these symbols
    }
    
    func testDeterministicEncryption() {
        let plaintext = "test message".data(using: .utf8)!
        let envelope1 = whisperService.encrypt(plaintext, from: identity, to: contact)
        let envelope2 = whisperService.encrypt(plaintext, from: identity, to: contact)
        
        XCTAssertNotEqual(envelope1, envelope2, "Same plaintext must yield different envelopes")
    }
    
    func testNonceUniqueness() {
        var nonces: Set<Data> = []
        
        for _ in 0..<1_000_000 {
            let (_, nonce) = try! cryptoEngine.deriveKeys(sharedSecret, salt: randomSalt, info: info)
            XCTAssertFalse(nonces.contains(nonce), "Nonce collision detected")
            nonces.insert(nonce)
        }
    }
    
    func testConstantTimePadding() {
        // Timing attack test for padding validation
        let validPadding = createValidPadding()
        let invalidPadding = createInvalidPadding()
        
        let validTime = measureTime { _ = try? MessagePadding.unpad(validPadding) }
        let invalidTime = measureTime { _ = try? MessagePadding.unpad(invalidPadding) }
        
        let timeDifference = abs(validTime - invalidTime)
        XCTAssertLessThan(timeDifference, 0.001, "Timing difference suggests side-channel leak")
    }
    
    func testPolicyMatrix() {
        let policies = [true, false]
        
        for contactRequired in policies {
            for signatureRequired in policies {
                for autoArchive in policies {
                    for biometricGated in policies {
                        // Test all 16 combinations
                        testPolicyCombination(contactRequired, signatureRequired, autoArchive, biometricGated)
                    }
                }
            }
        }
    }
    
    func testAlgorithmLock() {
        let invalidEnvelopes = [
            "whisper1:v2.c20p.rkid.flags.epk.salt.msgid.ts.ct",
            "whisper1:v1.aes.rkid.flags.epk.salt.msgid.ts.ct",
            "kiro1:v1.c20p.rkid.flags.epk.salt.msgid.ts.ct"
        ]
        
        for envelope in invalidEnvelopes {
            XCTAssertThrowsError(try whisperService.decrypt(envelope)) {
                XCTAssertEqual($0 as? WhisperError, .invalidEnvelope)
            }
        }
    }
    
    func testLocalizationKeys() {
        let requiredKeys = [
            "sign.bio_prep.title", "sign.bio_prep.body", "sign.bio_required.title",
            "policy.contact_required.title", "contact.verified.badge",
            "decrypt.banner.title", "legal.title"
        ]
        
        for key in requiredKeys {
            let localizedString = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localizedString, key, "Missing localization for key: \(key)")
        }
    }
}
```