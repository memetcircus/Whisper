# Xcode Build Fixes Guide 🔧

This guide shows you exactly which files to change in Xcode to fix the compilation errors.

## Summary of Changes Needed

You need to make changes to **3 files** in your Xcode project:

1. **IdentityManager.swift** - Add missing initializer
2. **QRCodeService.swift** - Remove duplicate ContactBundle references  
3. **MemoryOptimizedCrypto.swift** - Remove duplicate PaddingBucket definition

---

## 🔧 Fix 1: IdentityManager.swift

**File Location:** `WhisperApp/Core/Identity/IdentityManager.swift`

**Problem:** Missing `init(from contact: Contact)` initializer for PublicKeyBundle

**What to Change:**
Find the `PublicKeyBundle` struct (around line 500) and replace it with this:

```swift
/// Public key bundle for sharing identities
struct PublicKeyBundle: Codable {
    let id: UUID
    let name: String
    let x25519PublicKey: Data
    let ed25519PublicKey: Data?
    let fingerprint: Data
    let keyVersion: Int
    let createdAt: Date
    
    /// Default memberwise initializer for identity export
    init(id: UUID, name: String, x25519PublicKey: Data, ed25519PublicKey: Data?, fingerprint: Data, keyVersion: Int, createdAt: Date) {
        self.id = id
        self.name = name
        self.x25519PublicKey = x25519PublicKey
        self.ed25519PublicKey = ed25519PublicKey
        self.fingerprint = fingerprint
        self.keyVersion = keyVersion
        self.createdAt = createdAt
    }
    
    /// Creates a PublicKeyBundle from a Contact for QR code sharing
    init(from contact: Contact) {
        self.id = contact.id
        self.name = contact.displayName
        self.x25519PublicKey = contact.x25519PublicKey
        self.ed25519PublicKey = contact.ed25519PublicKey
        self.fingerprint = contact.fingerprint
        self.keyVersion = contact.keyVersion
        self.createdAt = contact.createdAt
    }
}
```

**Also in the same file:**
Find the `encryptBackup` method (around line 450) and change this line:
```swift
// OLD:
result.append(sealedBox.combined)

// NEW:
guard let combinedData = sealedBox.combined else {
    throw IdentityError.invalidBackupFormat
}
result.append(combinedData)
```

---

## 🔧 Fix 2: QRCodeService.swift

**File Location:** `WhisperApp/Services/QRCodeService.swift`

**Problem:** References to non-existent ContactBundle type

**What to Change:**

1. **Remove the ContactBundle method** (around line 60):
```swift
// DELETE THIS ENTIRE METHOD:
func generateQRCode(for bundle: ContactBundle) throws -> QRCodeResult {
    // ... delete everything in this method
}
```

2. **Update the parseQRCode method** (around line 75):
```swift
// OLD:
func parseQRCode(_ content: String) throws -> QRCodeContent {
    if content.hasPrefix("whisper-bundle:") {
        return try parsePublicKeyBundle(content)
    } else if content.hasPrefix("whisper-contact:") {
        return try parseContactBundle(content)
    } else if content.hasPrefix("whisper1:") {
        return try parseEncryptedMessage(content)
    } else {
        throw QRCodeError.unsupportedFormat
    }
}

// NEW:
func parseQRCode(_ content: String) throws -> QRCodeContent {
    if content.hasPrefix("whisper-bundle:") {
        return try parsePublicKeyBundle(content)
    } else if content.hasPrefix("whisper1:") {
        return try parseEncryptedMessage(content)
    } else {
        throw QRCodeError.unsupportedFormat
    }
}
```

3. **Remove the parseContactBundle method** (around line 150):
```swift
// DELETE THIS ENTIRE METHOD:
private func parseContactBundle(_ content: String) throws -> QRCodeContent {
    // ... delete everything in this method
}
```

4. **Update the QRCodeType enum** (around line 190):
```swift
// OLD:
enum QRCodeType {
    case publicKeyBundle
    case contactBundle
    case encryptedMessage
    
    var displayName: String {
        switch self {
        case .publicKeyBundle:
            return "Public Key Bundle"
        case .contactBundle:
            return "Contact Bundle"
        case .encryptedMessage:
            return "Encrypted Message"
        }
    }
}

// NEW:
enum QRCodeType {
    case publicKeyBundle
    case encryptedMessage
    
    var displayName: String {
        switch self {
        case .publicKeyBundle:
            return "Public Key Bundle"
        case .encryptedMessage:
            return "Encrypted Message"
        }
    }
}
```

5. **Update the QRCodeContent enum** (around line 210):
```swift
// OLD:
enum QRCodeContent {
    case publicKeyBundle(PublicKeyBundle)
    case contactBundle(ContactBundle)
    case encryptedMessage(String)
    
    var type: QRCodeType {
        switch self {
        case .publicKeyBundle:
            return .publicKeyBundle
        case .contactBundle:
            return .contactBundle
        case .encryptedMessage:
            return .encryptedMessage
        }
    }
}

// NEW:
enum QRCodeContent {
    case publicKeyBundle(PublicKeyBundle)
    case encryptedMessage(String)
    
    var type: QRCodeType {
        switch self {
        case .publicKeyBundle:
            return .publicKeyBundle
        case .encryptedMessage:
            return .encryptedMessage
        }
    }
}
```

---

## 🔧 Fix 3: MemoryOptimizedCrypto.swift

**File Location:** `WhisperApp/Core/Performance/MemoryOptimizedCrypto.swift`

**Problem:** Multiple interface mismatches and duplicate definitions

**What to Change:**

1. **Remove the duplicate PaddingBucket extension** (around line 350):
```swift
// DELETE THIS ENTIRE SECTION:
// MARK: - MessagePadding Extension for Bucket Selection

extension MessagePadding {
    enum PaddingBucket: Int {
        case small = 256
        case medium = 512
        case large = 1024
    }
    
    static func selectBucket(for messageLength: Int) -> PaddingBucket {
        if messageLength <= 254 { // Account for 2-byte length prefix
            return .small
        } else if messageLength <= 510 {
            return .medium
        } else {
            return .large
        }
    }
}

// REPLACE WITH JUST THIS COMMENT:
// MARK: - MessagePadding Extension for Bucket Selection
// Note: PaddingBucket enum and selectBucket method are already defined in MessagePadding.swift
```

2. **Fix EnvelopeComponents property names** (around line 240):
```swift
// OLD:
recipientPublic: components.ephemeralPublic

// NEW:
recipientPublic: components.epk
```

```swift
// OLD:
let info = components.ephemeralPublic + components.msgId

// NEW:
let info = components.epk + components.msgid
```

```swift
// OLD:
ephemeralPublic: components.ephemeralPublic,
msgId: components.msgId,

// NEW:
ephemeralPublic: components.epk,
msgId: components.msgid,
```

3. **Fix createEnvelope method call** (around line 195):
```swift
// OLD:
let envelope = try self.envelopeProcessor.createEnvelope(
    rkid: rkid,
    flags: flags,
    ephemeralPublic: ephemeralPublic,
    salt: salt,
    msgId: msgId,
    timestamp: timestamp,
    ciphertext: ciphertext,
    signature: signature
)

// NEW:
let envelope = try self.buildEnvelopeString(
    rkid: rkid,
    flags: flags,
    ephemeralPublic: ephemeralPublic,
    salt: salt,
    msgId: msgId,
    timestamp: timestamp,
    ciphertext: ciphertext,
    signature: signature
)
```

4. **Add buildEnvelopeString method** (add this method before the last closing brace):
```swift
private func buildEnvelopeString(
    rkid: Data,
    flags: UInt8,
    ephemeralPublic: Data,
    salt: Data,
    msgId: Data,
    timestamp: Int64,
    ciphertext: Data,
    signature: Data?
) throws -> String {
    // Build envelope in whisper1: format
    // whisper1:v1.c20p.<rkid>.<flags>.<epk>.<salt>.<msgid>.<ts>.<ct>[.sig]
    
    var envelope = "whisper1:v1.c20p"
    envelope += "." + rkid.base64URLEncodedString()
    envelope += "." + String(format: "%02x", flags)
    envelope += "." + ephemeralPublic.base64URLEncodedString()
    envelope += "." + salt.base64URLEncodedString()
    envelope += "." + msgId.base64URLEncodedString()
    envelope += "." + String(timestamp)
    envelope += "." + ciphertext.base64URLEncodedString()
    
    if let signature = signature {
        envelope += "." + signature.base64URLEncodedString()
    }
    
    return envelope
}
```

5. **Add base64URLEncodedString extension** (add to the Data extension):
```swift
extension Data {
    /// Securely overwrites data with zeros
    mutating func secureZero() {
        // ... existing code ...
    }
    
    /// Creates a copy with secure cleanup of original
    func secureClone() -> Data {
        // ... existing code ...
    }
    
    /// Base64URL encoding without padding
    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
```

6. **Update the method calls** in the same file:
```swift
// OLD (around line 90):
let paddingSize = MessagePadding.selectBucket(for: plaintext.count).rawValue

// NEW:
let paddingSize = MessagePadding.PaddingBucket.selectBucket(for: plaintext.count).rawValue
```

```swift
// OLD (around line 280):
let bucket = MessagePadding.selectBucket(for: plaintext.count)

// NEW:
let bucket = MessagePadding.PaddingBucket.selectBucket(for: plaintext.count)
```

---

## ✅ How to Apply These Changes

1. **Open your Xcode project**
2. **Navigate to each file** using the file navigator on the left
3. **Find the sections mentioned** using Cmd+F to search for the code snippets
4. **Make the changes** as shown above
5. **Build the project** (Cmd+B) to verify the fixes work

## 🎯 Expected Result

After making these changes, your project should compile without the following errors:
- ✅ "Argument type 'Contact' does not conform to expected type 'Decoder'"
- ✅ "No exact matches in call to initializer"
- ✅ "Value of optional type 'Data?' must be unwrapped"
- ✅ "Invalid redeclaration of 'PaddingBucket'"
- ✅ "'PaddingBucket' is ambiguous for type lookup"

## 🆘 If You Need Help

If you get stuck on any of these changes:
1. **Take a screenshot** of the error in Xcode
2. **Show me the specific line** that's causing trouble
3. **Copy the exact error message** from Xcode

The key is to make these changes **exactly as shown** - don't modify anything else in these files.