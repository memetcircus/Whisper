# Whisper - Secure End-to-End Encryption iOS App

![Whisper Logo](WhisperApp/Assets.xcassets/AppIcon.appiconset/icon.png)

**Whisper** is a privacy-focused iOS application that provides military-grade end-to-end encryption for secure communication. Built with SwiftUI and leveraging industry-standard cryptographic protocols, Whisper ensures your messages remain private and secure.

## 🔐 What is Whisper?

Whisper is a **serverless, peer-to-peer encryption app** that allows users to:
- Encrypt messages locally on their device
- Share encrypted content via QR codes
- Decrypt messages received from trusted contacts
- Manage cryptographic identities with biometric protection
- Verify contact authenticity through secure fingerprint verification

**Key Philosophy**: Your data never leaves your device unencrypted. No servers, no cloud storage, no third-party access.

## ✨ Core Features

### 🔒 **End-to-End Encryption**
- **Curve25519** elliptic curve cryptography for key exchange
- **ChaCha20-Poly1305** authenticated encryption
- **BLAKE2s** cryptographic hashing
- **Perfect Forward Secrecy** with automatic key rotation
- **Replay attack protection** with message freshness validation

### 📱 **Face ID Integration**
- Biometric authentication for encryption/decryption operations
- Secure key storage in iOS Keychain with biometric protection
- Optional Face ID requirement for enhanced security

### 🔄 **Identity Management**
- Multiple cryptographic identities per user
- Automatic key rotation with configurable intervals
- Identity backup and restore functionality
- Secure identity export/import via encrypted bundles

### 📲 **QR Code Workflow**
- Generate QR codes for encrypted messages
- Scan QR codes to decrypt received messages
- Share public keys via QR codes for contact establishment
- Photo library integration for QR code saving/loading

### 👥 **Contact Management**
- Add contacts via QR code scanning or manual key entry
- **SAS (Short Authentication String)** verification for contact authenticity
- Contact fingerprint verification to prevent man-in-the-middle attacks
- Secure contact key history tracking

### 🛡️ **Advanced Security Features**
- **Message padding** to prevent traffic analysis
- **Replay protection** with timestamp validation
- **Key verification** through cryptographic fingerprints
- **Secure deletion** of sensitive data
- **No network connectivity** - fully offline operation

## 🎯 Use Cases

### **Personal Privacy**
- Secure communication with family and friends
- Protecting sensitive personal information
- Private document sharing
- Confidential note-taking and storage

### **Business & Professional**
- Secure client communication for lawyers, doctors, consultants
- Confidential business document exchange
- Protecting intellectual property and trade secrets
- Secure internal team communication

### **Journalism & Activism**
- Source protection for journalists
- Secure communication in restrictive environments
- Whistleblower protection
- Activist coordination and planning

### **Healthcare & Legal**
- HIPAA-compliant patient communication
- Attorney-client privileged communications
- Medical record sharing
- Legal document exchange

### **Financial Services**
- Secure client communication for financial advisors
- Confidential transaction details
- Investment strategy discussions
- Regulatory compliance communication

### **Government & Military**
- Classified information sharing
- Secure inter-agency communication
- Field operation coordination
- Intelligence gathering and sharing

## 🛡️ Security Advantages

### **Cryptographic Strength**
- **Military-grade encryption**: Uses the same cryptographic primitives as Signal Protocol
- **Post-quantum resistant**: Curve25519 provides strong security against future quantum attacks
- **Authenticated encryption**: ChaCha20-Poly1305 prevents tampering and ensures message integrity
- **Perfect Forward Secrecy**: Compromised keys cannot decrypt past messages

### **Privacy Protection**
- **Zero-knowledge architecture**: No servers can access your data
- **Local-only processing**: All encryption/decryption happens on your device
- **No metadata collection**: No tracking, analytics, or user profiling
- **Offline operation**: Works completely without internet connectivity

### **Attack Resistance**
- **Man-in-the-middle protection**: SAS verification prevents impersonation
- **Replay attack prevention**: Timestamp validation ensures message freshness
- **Traffic analysis resistance**: Message padding obscures content patterns
- **Key compromise recovery**: Automatic key rotation limits damage from breaches

### **Device Security**
- **Biometric protection**: Face ID guards access to encryption keys
- **Secure Enclave integration**: Keys stored in iOS hardware security module
- **App sandboxing**: iOS security model isolates app data
- **Secure deletion**: Cryptographic erasure of sensitive data

### **Compliance & Standards**
- **FIPS-compliant algorithms**: Uses government-approved cryptographic standards
- **Open-source cryptography**: Based on well-audited, public algorithms
- **No proprietary crypto**: Avoids custom encryption schemes
- **Industry best practices**: Follows OWASP and NIST security guidelines

## 🏗️ Technical Architecture

### **Cryptographic Stack**
```
Application Layer (SwiftUI)
    ↓
Whisper Core (Encryption Engine)
    ↓
CryptoKit (Apple's Cryptography Framework)
    ↓
Secure Enclave (Hardware Security)
```

### **Key Components**
- **CryptoEngine**: Core encryption/decryption operations
- **IdentityManager**: Cryptographic identity lifecycle management
- **ContactManager**: Secure contact and key management
- **BiometricService**: Face ID integration and key protection
- **QRCodeService**: QR code generation and scanning
- **EnvelopeProcessor**: Message packaging and validation

### **Security Policies**
- **Verified contacts only**: Messages can only be sent to verified contacts
- **Automatic key rotation**: Keys rotate based on time or usage thresholds
- **Biometric gating**: Optional Face ID requirement for all operations
- **Secure storage**: All sensitive data encrypted at rest

## 🚀 Getting Started

### **Installation**
1. Clone the repository
2. Open `WhisperApp.xcodeproj` in Xcode
3. Build and run on iOS device (Face ID requires physical device)

### **First Use**
1. Accept the legal disclaimer
2. Create your first cryptographic identity
3. Set up Face ID protection (recommended)
4. Add contacts via QR code exchange
5. **Verify each contact using SAS words** (critical security step)
6. Start encrypting messages!

### **Basic Workflow**
1. **Add Contact**: Exchange public keys via QR codes
2. **Verify Contact**: Use SAS (Short Authentication String) words to confirm identity
3. **Compose**: Write your message and select verified recipient
4. **Encrypt**: App generates encrypted QR code
5. **Share**: Send QR code via any channel (email, messaging, etc.)
6. **Decrypt**: Recipient scans QR code to decrypt message

### **SAS Verification Process**
After adding a contact, both parties must verify each other using SAS words:
1. App generates 5 unique verification words for each contact
2. Compare these words with your contact through a secure channel (in person, phone call)
3. Both parties confirm the words match exactly
4. Only verified contacts can send/receive encrypted messages
5. This prevents man-in-the-middle attacks and ensures authentic communication

## ⚖️ Legal & Compliance

### **Export Compliance**
This software contains cryptographic functionality. Export and use may be restricted in some jurisdictions. Users are responsible for compliance with applicable laws and regulations.

### **No Warranty**
This software is provided "as is" without warranty of any kind. Users assume all risks associated with its use.

### **Privacy Policy**
Whisper collects no user data, has no servers, and performs no tracking. Your privacy is absolute.

## 🤝 Contributing

Whisper is built with security and privacy as core principles. Contributions should maintain these standards:

- All cryptographic changes must be reviewed by security experts
- No network connectivity features will be accepted
- User privacy must never be compromised
- Follow secure coding practices

## 📄 License

All rights reserved. M. Akif Acar, 2025.

---

**Whisper: Your messages, your keys, your privacy.** 🔐

*Built with ❤️ for privacy and security*