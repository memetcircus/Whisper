#!/usr/bin/env swift

import Foundation

print("🔍 DEBUGGING BIOMETRIC FLOW")
print(String(repeating: "=", count: 50))

print("Expected Flow when tapping 'Encrypt Message':")
print("1. ComposeView button calls viewModel.encryptMessage()")
print("2. ComposeViewModel.encryptMessage() calls whisperService.encrypt()")
print("3. WhisperService.encrypt() checks policyManager.requiresBiometricForSigning()")
print("4. If true AND includeSignature=true, calls createEnvelopeWithBiometric()")
print("5. createEnvelopeWithBiometric() calls BiometricService.sign()")
print("6. BiometricService.sign() prompts Face ID")
print("7. After Face ID success, encryption completes")
print("8. UI shows Share and QR Code buttons")
print()

print("🐛 POTENTIAL ISSUES:")
print()

print("Issue 1: Policy not enabled")
print("- Check: Settings > Biometric Settings > 'Require for Signing' toggle")
print("- Should be: ON (enabled)")
print()

print("Issue 2: Signature not included")
print("- Check: Compose Message > 'Include Signature' toggle")
print("- Should be: ON (green)")
print()

print("Issue 3: Contact not verified")
print("- Check: Selected contact shows 'Verified' badge")
print("- Some policies might require verified contacts for biometric signing")
print()

print("Issue 4: Biometric key not enrolled")
print("- Check: Settings > Biometric Settings > shows 'Enrolled' status")
print("- Should be: Green 'Enrolled' badge")
print()

print("Issue 5: Face ID permission denied")
print("- Check: iPhone Settings > Face ID & Passcode > Other Apps")
print("- WhisperApp should be listed and enabled")
print()

print("🧪 DEBUGGING STEPS:")
print("1. Go to Settings > Biometric Settings")
print("2. Verify 'Require for Signing' toggle is ON")
print("3. Tap 'Test Authentication' - Face ID should work")
print("4. Go to Compose Message")
print("5. Verify 'Include Signature' toggle is ON")
print("6. Tap 'Encrypt Message' - Face ID should prompt HERE")
print()

print("If Face ID works in step 3 but not step 6, the issue is in the encryption flow logic.")
print("If Face ID doesn't work in step 3, the issue is with biometric enrollment/permissions.")