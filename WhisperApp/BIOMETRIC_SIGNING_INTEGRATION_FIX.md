# Biometric Signing Integration Fix

## Problem
Face ID authentication was working in the Biometric Settings (test button), but **not prompting during message encryption** in the Compose Message screen when tapping "Share".

## Root Cause
The `biometricGatedSigning` policy in `PolicyManager` was defaulting to `false`, which meant:
- Even though Face ID was enrolled and available
- Even though `includeSignature` was `true` 
- The biometric authentication was never triggered during signing

## Solution

### 1. Policy Manager Fix
**File:** `WhisperApp/WhisperApp/Core/Policies/PolicyManager.swift`

Changed the `biometricGatedSigning` property to default to `true`:

```swift
var biometricGatedSigning: Bool {
    get { 
        // Default to true if not explicitly set, to enable biometric signing by default
        if userDefaults.object(forKey: Keys.biometricGatedSigning) == nil {
            return true
        }
        return userDefaults.bool(forKey: Keys.biometricGatedSigning) 
    }
    set { userDefaults.set(newValue, forKey: Keys.biometricGatedSigning) }
}
```

### 2. UI Enhancement
**Files:** 
- `WhisperApp/WhisperApp/UI/Settings/BiometricSettingsViewModel.swift`
- `WhisperApp/WhisperApp/UI/Settings/BiometricSettingsView.swift`

Added a "Require for Signing" toggle so users can control the biometric signing policy:

```swift
// In ViewModel
@Published var biometricSigningEnabled = false

func toggleBiometricSigning() {
    policyManager.biometricGatedSigning = !policyManager.biometricGatedSigning
    biometricSigningEnabled = policyManager.biometricGatedSigning
}

// In View
Toggle("", isOn: $viewModel.biometricSigningEnabled)
    .onChange(of: viewModel.biometricSigningEnabled) { _ in
        viewModel.toggleBiometricSigning()
    }
```

## How It Works

### Encryption Flow with Biometric Authentication

1. **User Action:** Taps "Share" in Compose Message
2. **ComposeViewModel:** Calls `encryptMessage()`
3. **WhisperService:** Calls `encrypt()` with `authenticity: true`
4. **Policy Check:** `policyManager.requiresBiometricForSigning()` returns `true`
5. **Biometric Trigger:** `createEnvelopeWithBiometric()` is called
6. **Face ID Prompt:** `BiometricService.sign()` prompts for authentication
7. **User Authentication:** User authenticates with Face ID
8. **Message Signing:** Message is cryptographically signed
9. **Share Sheet:** Encrypted message appears in share sheet

### Key Conditions for Biometric Prompt

For Face ID to prompt during message encryption, ALL must be true:
- ✅ Face ID is available and enrolled
- ✅ `biometricGatedSigning` policy is `true` (now defaults to true)
- ✅ `includeSignature` is `true` (signature toggle is ON)
- ✅ User taps "Share" button

## Testing

### On iPhone Device:
1. Build and install app on iPhone with Face ID
2. Go to **Settings > Biometric Settings**
3. Verify **"Require for Signing"** toggle is **ON**
4. Go to **Compose Message**
5. Write a message, select a contact
6. Ensure **"Include Signature"** toggle is **ON**
7. Tap **"Share"** button
8. **Face ID prompt should appear** 🎉
9. Authenticate with Face ID
10. Share sheet should appear with encrypted message

### Expected Results:
- ✅ Face ID prompts when encrypting signed messages
- ✅ Users can disable biometric signing via toggle
- ✅ Biometric authentication integrates seamlessly with encryption flow
- ✅ Error handling works for cancelled/failed authentication

## Files Modified

1. `WhisperApp/WhisperApp/Core/Policies/PolicyManager.swift`
   - Changed `biometricGatedSigning` to default to `true`

2. `WhisperApp/WhisperApp/UI/Settings/BiometricSettingsViewModel.swift`
   - Added `biometricSigningEnabled` property
   - Added `toggleBiometricSigning()` method
   - Added policy manager dependency

3. `WhisperApp/WhisperApp/UI/Settings/BiometricSettingsView.swift`
   - Added "Require for Signing" toggle section
   - Connected toggle to view model

## Impact

- **User Experience:** Face ID now prompts during message signing as expected
- **Security:** Biometric authentication is enabled by default for better security
- **Control:** Users can disable biometric signing if desired
- **Backward Compatibility:** Existing users will get biometric signing enabled automatically

The fix ensures that Face ID authentication works end-to-end in the message encryption workflow, not just in the settings test.