# Whisper iOS App

A fully client-side encryption/decryption iOS application that provides end-to-end encryption for messages shared over any messaging platform.

## Project Structure

```
WhisperApp/
├── WhisperApp.xcodeproj/          # Xcode project file
├── WhisperApp/                    # Main app target
│   ├── WhisperApp.entitlements    # App entitlements (Keychain access)
│   ├── Info.plist                 # App configuration
│   ├── WhisperApp.swift          # Main app entry point
│   ├── ContentView.swift         # Main UI view
│   ├── Core/                     # Core functionality
│   │   └── KeychainManager.swift # Secure key storage
│   ├── Services/                 # Application services
│   ├── UI/                       # User interface components
│   ├── Storage/                  # Data persistence
│   │   └── WhisperDataModel.xcdatamodeld # Core Data model
│   ├── Assets.xcassets/          # App assets
│   └── Preview Content/          # SwiftUI previews
└── Tests/                        # Test files
    └── NetworkDetectionTests.swift # Network isolation tests
```

## Security Features

### Network Isolation
- **Build-time detection**: Fails build if networking symbols are detected
- **Zero network policy**: No URLSession, Network framework, or socket APIs
- **Local-only operation**: All data stays on device

### Keychain Integration
- **Standard keys**: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- **Biometric keys**: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` + `biometryCurrentSet`
- **No iCloud sync**: `kSecAttrSynchronizable = false`

### Core Data Model
- **IdentityEntity**: User identities with X25519/Ed25519 keys
- **ContactEntity**: Trusted contacts with trust levels
- **ReplayProtectionEntity**: Message replay prevention
- **KeyHistoryEntity**: Contact key rotation history

## Build Configuration

### Requirements
- iOS 15.0+
- Xcode 15.0+
- Swift 5.0+

### Entitlements
- Keychain access groups
- Face ID usage description
- Camera usage (for QR scanning)

### Build Phases
1. **Sources**: Compile Swift files
2. **Frameworks**: Link system frameworks
3. **Resources**: Bundle assets
4. **Network Detection**: Fail if networking symbols found

## Development Notes

### Cryptographic Framework
- **CryptoKit only**: All crypto operations use Apple's CryptoKit
- **No custom crypto**: No third-party cryptographic libraries
- **Secure memory**: Automatic key zeroization

### Data Storage
- **Core Data**: Local database for entities
- **Keychain**: Secure storage for private keys
- **No cloud sync**: All data remains local

### Testing Strategy
- **Network detection**: Build-time symbol checking
- **Security validation**: Keychain access patterns
- **Unit tests**: Core functionality testing

## Next Steps

This foundation provides:
1. ✅ iOS project structure with proper entitlements
2. ✅ Build-time networking detection that fails build
3. ✅ Core Data model with required entities
4. ✅ Keychain access with proper security attributes

Ready for implementing the cryptographic engine and other components.