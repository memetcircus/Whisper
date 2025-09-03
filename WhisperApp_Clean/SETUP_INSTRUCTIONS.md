# 🚀 Whisper App Setup Instructions

## Quick Setup (Recommended)

Since Xcode project files can be complex, here's the fastest way to get the app running:

### Option 1: Create New Xcode Project (5 minutes)

1. **Open Xcode**
2. **Create New Project**:
   - iOS App
   - Product Name: `WhisperApp`
   - Bundle Identifier: `com.whisper.app`
   - Language: Swift
   - Interface: SwiftUI
   - Use Core Data: ✅ YES
   - Include Tests: ✅ YES

3. **Add Source Files**:
   - Drag the entire `WhisperApp/Core/` folder into your Xcode project
   - Drag the entire `WhisperApp/Services/` folder into your Xcode project
   - Drag the entire `WhisperApp/UI/` folder into your Xcode project
   - Add `WhisperApp/BuildConfiguration.swift` to the project root

4. **Replace Default Files**:
   - Replace the default `ContentView.swift` with our version
   - Replace the default `WhisperApp.swift` with our version
   - Replace the Core Data model with our `WhisperDataModel.xcdatamodeld`

5. **Configure Entitlements**:
   - Add `WhisperApp.entitlements` to your project
   - Enable Keychain Sharing capability
   - Copy the contents from our `Info.plist`

6. **Build and Run**!

### Option 2: Manual File Addition

If you prefer to use the existing project:

1. **Open `WhisperApp.xcodeproj` in Xcode**
2. **Add Missing Files**: Right-click project → Add Files
3. **Check Target Membership**: Ensure all Swift files are added to the app target
4. **Fix Build Settings**: Set iOS deployment target to 15.0+
5. **Set Development Team**: Add your Apple Developer account

## 📁 Files to Include

### Essential Core Files
```
Core/Crypto/
├── CryptoEngine.swift          ✅ Core cryptographic operations
├── EnvelopeProcessor.swift     ✅ Message format handling  
└── MessagePadding.swift        ✅ Traffic analysis protection

Core/Identity/
└── IdentityManager.swift       ✅ Identity lifecycle management

Core/Contacts/
├── ContactManager.swift        ✅ Contact database operations
├── Contact.swift              ✅ Contact data model
└── SASWordList.swift          ✅ Verification word lists

Core/Policies/
└── PolicyManager.swift         ✅ Security policy enforcement

Core/
├── KeychainManager.swift       ✅ Secure key storage
└── ReplayProtectionService.swift ✅ Replay attack prevention
```

### Essential Service Files
```
Services/
├── WhisperService.swift        ✅ High-level encryption API
├── QRCodeService.swift         ✅ QR code generation/scanning
├── BiometricService.swift      ✅ Biometric authentication interface
└── DefaultBiometricService.swift ✅ Biometric implementation
```

### Essential UI Files
```
UI/Compose/
├── ComposeView.swift           ✅ Message composition interface
└── ComposeViewModel.swift      ✅ Composition logic

UI/Decrypt/
├── DecryptView.swift           ✅ Message decryption interface
└── DecryptViewModel.swift      ✅ Decryption logic

UI/Contacts/
├── ContactListView.swift       ✅ Contact management interface
└── ContactListViewModel.swift  ✅ Contact management logic

UI/Settings/
└── LegalDisclaimerView.swift   ✅ Legal compliance interface
```

### Configuration Files
```
WhisperApp.swift               ✅ App entry point with Core Data
ContentView.swift              ✅ Main app interface
BuildConfiguration.swift       ✅ Build utilities
Info.plist                    ✅ App configuration
WhisperApp.entitlements       ✅ Security capabilities
Storage/WhisperDataModel.xcdatamodeld ✅ Core Data model
```

## 🔧 Build Configuration

### Required Capabilities
- **Keychain Sharing**: For secure key storage
- **Camera**: For QR code scanning (optional)
- **Face ID**: For biometric authentication (optional)

### Build Settings
- **iOS Deployment Target**: 15.0 or later
- **Swift Language Version**: 5.0
- **Bundle Identifier**: `com.whisper.app`
- **Development Team**: Your Apple Developer account

### Frameworks
All required frameworks are part of iOS SDK:
- **CryptoKit**: Cryptographic operations
- **SwiftUI**: User interface
- **CoreData**: Local database
- **LocalAuthentication**: Biometric authentication
- **AVFoundation**: Camera access for QR codes

## ✅ Verification Checklist

After setup, verify these work:

### Build Verification
- [ ] Project builds without errors
- [ ] No missing file references
- [ ] All Swift files compile successfully
- [ ] Core Data model loads correctly

### Runtime Verification  
- [ ] App launches successfully
- [ ] Legal disclaimer appears on first launch
- [ ] Can navigate between main screens
- [ ] No immediate crashes or errors

### Feature Verification (on device)
- [ ] Can create new identity
- [ ] Can add contacts
- [ ] Can encrypt messages
- [ ] Can decrypt messages
- [ ] QR code generation works
- [ ] Biometric authentication works (if available)

## 🐛 Common Issues & Solutions

### Build Errors
**"Cannot find 'X' in scope"**
- Solution: Ensure all Swift files are added to the target

**"Missing required module"**
- Solution: Check that all imports are correct (CryptoKit, SwiftUI, etc.)

**"Entitlements error"**
- Solution: Add WhisperApp.entitlements and enable Keychain Sharing

### Runtime Errors
**"Core Data model not found"**
- Solution: Ensure WhisperDataModel.xcdatamodeld is added to target

**"Keychain access denied"**
- Solution: Check entitlements and run on physical device

**"Camera permission denied"**
- Solution: Add camera usage description to Info.plist

## 🎯 Success Criteria

You'll know it's working when:
1. ✅ App builds and runs without errors
2. ✅ Legal disclaimer appears on first launch
3. ✅ Can create identity and see main interface
4. ✅ All navigation works smoothly
5. ✅ No console errors during normal operation

## 📞 Need Help?

If you encounter issues:
1. **Check Xcode Console**: Look for specific error messages
2. **Verify File Inclusion**: Ensure all files are added to target
3. **Clean Build**: Product → Clean Build Folder
4. **Restart Xcode**: Sometimes helps with project issues
5. **Check iOS Version**: Ensure device runs iOS 15.0+

---

**🎉 Once setup is complete, you'll have a fully functional Whisper encryption app ready for testing!**