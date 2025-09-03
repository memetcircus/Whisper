# App Store Compliance Documentation

## Privacy Nutrition Labels

### Data Collection Summary
**Whisper collects NO data from users.**

### Privacy Label Configuration

#### Data Used to Track You
- **None** - Whisper does not track users across apps or websites.

#### Data Linked to You
- **None** - Whisper does not collect any data that is linked to user identity.

#### Data Not Linked to You
- **None** - Whisper does not collect any data whatsoever.

### Detailed Privacy Practices

#### No Data Collection
Whisper is designed with privacy-by-design principles:
- **No user accounts** - No registration or sign-in required
- **No analytics** - No usage tracking or analytics collection
- **No crash reporting** - No automatic crash or error reporting
- **No advertising** - No ads or advertising identifiers
- **No third-party services** - No external services or APIs

#### Local-Only Operation
- All data remains on the user's device
- No network communication whatsoever
- No cloud storage or synchronization
- No remote configuration or updates

#### Data Storage
- **Identity keys**: Stored in iOS Keychain with device-only access
- **Contacts**: Stored in local Core Data database
- **Messages**: Not stored - only encrypted/decrypted in memory
- **Settings**: Stored in UserDefaults locally

## Export Compliance

### Encryption Declaration

#### Product Information
- **Product Name**: Whisper
- **Bundle ID**: com.whisper.app
- **Version**: 1.0
- **Platform**: iOS 15.0+

#### Encryption Usage
Whisper uses encryption for the following purposes:
- End-to-end message encryption using industry-standard algorithms
- Local key storage protection using iOS Keychain
- No proprietary or custom cryptographic implementations

#### Cryptographic Algorithms Used

##### Symmetric Encryption
- **ChaCha20-Poly1305**: AEAD encryption for message content
- **HKDF-SHA256**: Key derivation function
- **BLAKE2s/SHA-256**: Hash functions for key identification

##### Asymmetric Cryptography
- **X25519**: Elliptic curve key agreement (RFC 7748)
- **Ed25519**: Digital signatures (RFC 8032)

##### Random Number Generation
- **CryptoKit SecureRNG**: iOS system secure random number generator
- **SecRandomCopyBytes**: iOS Security framework RNG

#### Export Administration Regulations (EAR) Classification

##### ECCN Classification
- **Proposed ECCN**: 5D002.c.1
- **Reason**: Mass market software with symmetric key length > 64 bits

##### Justification for Mass Market Classification
1. **Publicly Available**: Uses only publicly available cryptographic algorithms
2. **Standard Algorithms**: Implements only standard, published algorithms
3. **No Proprietary Crypto**: No custom or proprietary cryptographic implementations
4. **Consumer Software**: Designed for general consumer use

##### Algorithm Details
- **ChaCha20**: 256-bit key, publicly documented (RFC 8439)
- **Poly1305**: 256-bit key, publicly documented (RFC 8439)
- **X25519**: 255-bit key, publicly documented (RFC 7748)
- **Ed25519**: 256-bit key, publicly documented (RFC 8032)
- **HKDF-SHA256**: Variable key length, publicly documented (RFC 5869)

#### Self-Classification Statement
Based on the use of standard, publicly available cryptographic algorithms and the mass market nature of the software, Whisper qualifies for the mass market exemption under EAR 740.17(b)(1).

#### Required Notifications
- **BIS Notification**: Required within 30 days of first commercial shipment
- **NSA Notification**: Required for products using encryption

### Compliance Checklist

#### Pre-Submission Requirements
- [ ] Complete App Store Connect encryption questionnaire
- [ ] Prepare BIS notification (if required)
- [ ] Prepare NSA notification (if required)
- [ ] Document all cryptographic implementations
- [ ] Verify no proprietary algorithms used

#### App Store Connect Encryption Questions

1. **Does your app use encryption?**
   - Answer: **Yes**

2. **Does your app qualify for any of the exemptions provided in Category 5, Part 2?**
   - Answer: **Yes** - Mass market exemption

3. **Does your app implement any encryption algorithms that are proprietary or not accepted as standard by international bodies?**
   - Answer: **No**

4. **Does your app use encryption that's exempt under Category 5, Part 2 of the U.S. Export Administration Regulations?**
   - Answer: **Yes** - Standard cryptographic algorithms for consumer use

5. **What type of encryption algorithms does your app implement?**
   - Answer: **Symmetric and/or asymmetric algorithms**

## Accessibility Compliance

### WCAG 2.1 AA Compliance

#### Perceivable
- **Color Contrast**: All text meets 4.5:1 contrast ratio minimum
- **Text Scaling**: Full Dynamic Type support for all text elements
- **Alternative Text**: All images and icons have descriptive labels
- **Audio Content**: No audio content in current version

#### Operable
- **Keyboard Navigation**: Full VoiceOver support for all interactive elements
- **Touch Targets**: All buttons meet 44pt minimum touch target size
- **Timing**: No time-based interactions that cannot be extended
- **Seizures**: No flashing content or animations

#### Understandable
- **Language**: Content language properly declared
- **Navigation**: Consistent navigation patterns throughout app
- **Input Assistance**: Clear error messages and input validation
- **Instructions**: Clear instructions for all user actions

#### Robust
- **Compatibility**: Full compatibility with iOS assistive technologies
- **Valid Code**: SwiftUI code follows accessibility best practices
- **Future-Proof**: Uses semantic UI elements for maximum compatibility

### VoiceOver Support

#### Screen Reader Labels
All UI elements include appropriate accessibility labels:
- **Buttons**: Action-oriented labels ("Encrypt Message", "Add Contact")
- **Status Indicators**: Clear status descriptions ("Verified Contact", "Unverified Contact")
- **Navigation**: Clear navigation context and hierarchy
- **Forms**: Proper field labels and validation feedback

#### Accessibility Traits
- **Buttons**: Marked with button trait
- **Headers**: Proper heading hierarchy
- **Status**: Important status information marked appropriately
- **Groups**: Related elements properly grouped

### Testing Compliance

#### Automated Testing
- Accessibility tests included in test suite
- Color contrast validation
- Touch target size validation
- VoiceOver label completeness

#### Manual Testing
- Full VoiceOver navigation testing
- Dynamic Type scaling testing
- High contrast mode testing
- Reduced motion preference testing

## Content Rating

### Age Rating: 4+
Whisper is suitable for all ages as it:
- Contains no objectionable content
- Provides utility functionality only
- Has no social features or user-generated content
- Contains no advertising or in-app purchases

### Content Descriptors
- **None** - No content requiring age restrictions

## Localization

### Supported Languages
- **Primary**: English (US)
- **Future**: Planned support for additional languages

### Localization Requirements
- All user-facing strings externalized
- Proper string key organization
- RTL language support prepared
- Cultural considerations for cryptographic terminology

## Security and Privacy Features

### iOS Security Integration
- **Keychain Services**: Secure key storage with device-only access
- **Biometric Authentication**: Face ID/Touch ID integration for signing
- **App Sandbox**: Full compliance with iOS app sandboxing
- **Code Signing**: Proper app signing and entitlements

### Privacy by Design
- **Data Minimization**: Collects no unnecessary data
- **Purpose Limitation**: All data used only for stated purposes
- **Storage Limitation**: No persistent message storage
- **Transparency**: Open about all data practices

## Legal Compliance

### Terms of Service
- Clear disclaimer of warranties
- Limitation of liability
- User responsibilities
- Export compliance requirements

### Privacy Policy
- No data collection statement
- Local storage explanation
- User control over data
- Contact information for questions

### Open Source Considerations
- Uses only permissively licensed dependencies
- No GPL or copyleft dependencies
- Clear attribution for third-party code
- Compliance with all license requirements

## Submission Checklist

### Technical Requirements
- [ ] iOS 15.0+ deployment target
- [ ] Universal app (iPhone/iPad)
- [ ] All required app icons included
- [ ] Launch screen configured
- [ ] Proper bundle identifier set

### Content Requirements
- [ ] App description written
- [ ] Screenshots prepared for all device sizes
- [ ] App preview video (optional)
- [ ] Keywords selected
- [ ] Category selected (Utilities)

### Legal Requirements
- [ ] Privacy policy URL provided
- [ ] Export compliance documentation complete
- [ ] Age rating questionnaire complete
- [ ] Terms of service available

### Testing Requirements
- [ ] Full functionality testing complete
- [ ] Accessibility testing complete
- [ ] Performance testing complete
- [ ] Security validation complete

## Post-Launch Considerations

### Updates and Maintenance
- Security updates as needed
- iOS compatibility updates
- Bug fixes and improvements
- No feature updates that change privacy practices

### Monitoring
- No analytics or crash reporting
- User feedback through App Store reviews only
- Manual testing for each iOS update
- Security research monitoring

### Compliance Maintenance
- Annual export compliance review
- Privacy practice verification
- Accessibility compliance updates
- Legal requirement changes monitoring