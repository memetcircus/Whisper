# Whisper iOS Encryption App

## 🔐 Secure End-to-End Encryption for iOS

Whisper is a privacy-focused iOS app that provides secure end-to-end encryption with no network connectivity. All operations are performed locally on your device.

## ✅ Features Implemented

### Core Security
- **CryptoKit Integration**: X25519, Ed25519, ChaCha20-Poly1305, HKDF
- **Zero Network Policy**: No networking capabilities whatsoever
- **Local-Only Storage**: All data remains on your device
- **Keychain Security**: Private keys stored in iOS Keychain
- **Replay Protection**: Prevents message replay attacks
- **Message Padding**: Constant-time padding for traffic analysis resistance

### User Features
- **Multiple Identities**: Create and manage multiple cryptographic identities
- **Contact Management**: Local contact database with trust levels
- **Message Encryption/Decryption**: Secure message handling
- **QR Code Support**: Share keys and messages via QR codes
- **Biometric Authentication**: Face ID/Touch ID for sensitive operations
- **Backup/Restore**: Encrypted identity backups
- **Legal Compliance**: Mandatory legal disclaimer on first launch

### Security Policies
- **Contact-Required**: Optionally require contacts for sending
- **Signature-Required**: Require signatures for verified contacts
- **Auto-Archive**: Automatically archive old identities on rotation
- **Biometric-Gated**: Require biometrics for signing operations

## 🚀 Getting Started

### Requirements
- Xcode 15.0 or later
- iOS 15.0 or later
- Physical iOS device (for biometric testing)

### Installation
1. **Download the project**
2. **Open in Xcode**: Double-click `WhisperApp.xcodeproj`
3. **Set Development Team**: Select your Apple Developer account in project settings
4. **Build and Run**: Select your device and press Cmd+R

### First Launch
1. The app will show a legal disclaimer on first launch
2. Accept the disclaimer to proceed
3. Create your first identity
4. Start encrypting messages!

## 📱 Usage

### Creating an Identity
1. Tap "Settings" → "Identity Management"
2. Tap "Create New Identity"
3. Enter a name for your identity
4. Your cryptographic keys are generated automatically

### Adding Contacts
1. Tap "Manage Contacts"
2. Tap "Add Contact"
3. Scan QR code or enter public key manually
4. Verify the contact through secure channel

### Encrypting Messages
1. Tap "Compose Message"
2. Select recipient contact
3. Type your message
4. Tap "Encrypt"
5. Share the encrypted envelope

### Decrypting Messages
1. Tap "Decrypt Message"
2. Paste or scan encrypted envelope
3. Message is decrypted automatically
4. View sender attribution and verification status

## 🔒 Security Features

### Cryptographic Algorithms
- **Key Agreement**: X25519 (Curve25519)
- **Encryption**: ChaCha20-Poly1305 AEAD
- **Signatures**: Ed25519
- **Key Derivation**: HKDF-SHA256
- **Hashing**: SHA256, BLAKE2s

### Security Guarantees
- **Forward Secrecy**: Each message uses ephemeral keys
- **Authenticity**: Optional digital signatures
- **Integrity**: AEAD encryption prevents tampering
- **Freshness**: Timestamp validation prevents replay
- **Privacy**: No metadata collection or network communication

### Threat Model
- **Protects Against**: Network surveillance, message tampering, replay attacks, traffic analysis
- **Assumes**: Device security, secure key exchange, trusted contacts
- **Does Not Protect**: Against device compromise, malicious contacts, physical access

## 🧪 Testing

### Automated Tests
The project includes comprehensive test suites:
- Cryptographic validation tests
- Security policy tests
- Integration tests
- Performance tests
- Accessibility tests

### Manual Testing Checklist
- [ ] Legal disclaimer appears on first launch
- [ ] Identity creation and management
- [ ] Contact addition and verification
- [ ] Message encryption/decryption
- [ ] QR code generation/scanning
- [ ] Biometric authentication (on device)
- [ ] Backup/restore functionality
- [ ] All UI components accessible with VoiceOver

## 🔧 Development

### Project Structure
```
WhisperApp/
├── Core/
│   ├── Crypto/           # Cryptographic engines
│   ├── Identity/         # Identity management
│   ├── Contacts/         # Contact management
│   └── Policies/         # Security policies
├── Services/             # High-level services
├── UI/                   # SwiftUI views
└── Storage/              # Core Data models
```

### Key Components
- **CryptoEngine**: Core cryptographic operations
- **EnvelopeProcessor**: Message format handling
- **IdentityManager**: Identity lifecycle management
- **ContactManager**: Contact database operations
- **WhisperService**: High-level encryption API
- **PolicyManager**: Security policy enforcement

## 📋 Known Limitations

### Current Implementation
- Basic UI (functional but minimal styling)
- Limited error handling in UI layer
- No advanced contact verification features
- No message threading or conversation history

### Future Enhancements
- Enhanced UI/UX design
- Advanced contact verification (SAS, TOFU)
- Message threading and history
- Group messaging support
- Additional export formats

## 🔐 Security Considerations

### Before Production Use
1. **Security Audit**: Have the cryptographic implementation audited
2. **Penetration Testing**: Test against real-world attacks
3. **Code Review**: Review all code for security vulnerabilities
4. **Compliance**: Ensure compliance with local regulations

### Operational Security
- Keep your device updated and secure
- Use strong device passcodes/biometrics
- Verify contact identities through secure channels
- Regularly backup your identities securely
- Be aware of physical device security

## 📄 Legal

### Export Compliance
This software uses cryptographic algorithms and may be subject to export regulations. See `Documentation/AppStoreCompliance.md` for details.

### Privacy
Whisper collects no user data and operates entirely offline. All data remains on your device.

### License
This implementation is for educational and research purposes. Review all code before production use.

## 🆘 Troubleshooting

### Build Issues
- Ensure Xcode 15.0 or later
- Set valid development team
- Clean build folder (Cmd+Shift+K)

### Runtime Issues
- Check device iOS version (15.0+)
- Verify biometric setup on device
- Check camera permissions for QR scanning

### Crypto Issues
- All cryptographic operations use iOS CryptoKit
- Keys are stored in iOS Keychain with device-only access
- No custom cryptographic implementations

## 📞 Support

For issues or questions:
1. Check this README
2. Review the code documentation
3. Test on a clean device
4. Verify all requirements are met

---

**⚠️ Security Notice**: This is a reference implementation. Conduct thorough security review before production use.