#!/usr/bin/env swift

import Foundation

print("🔍 Testing Biometric Authentication Fix...")
print(String(repeating: "=", count: 50))

var allTestsPassed = true

// Test 1: Verify access control flags are updated
print("\n1. Testing access control configuration...")
let biometricServicePath = "./WhisperApp/Services/BiometricService.swift"
if let content = try? String(contentsOfFile: biometricServicePath) {
    let hasBiometryAny = content.contains(".biometryAny")
    let hasOldBiometryCurrentSet = content.contains(".biometryCurrentSet")
    let hasPrivateKeyUsage = content.contains(".privateKeyUsage")
    
    print("  ✅ Uses .biometryAny flag: \(hasBiometryAny ? "PASS" : "FAIL")")
    print("  ✅ Removed .biometryCurrentSet: \(!hasOldBiometryCurrentSet ? "PASS" : "FAIL")")
    print("  ✅ Keeps .privateKeyUsage: \(hasPrivateKeyUsage ? "PASS" : "FAIL")")
    
    if !hasBiometryAny || hasOldBiometryCurrentSet || !hasPrivateKeyUsage {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read BiometricService.swift")
    allTestsPassed = false
}

// Test 2: Verify enhanced enrollment process
print("\n2. Testing enrollment process improvements...")
let biometricViewModelPath = "./WhisperApp/UI/Settings/BiometricSettingsViewModel.swift"
if let content = try? String(contentsOfFile: biometricViewModelPath) {
    let hasUpfrontAuth = content.contains("evaluatePolicy")
    let hasLAErrorHandling = content.contains("LAError")
    let hasSuccessMessage = content.contains("enrolled successfully")
    let hasProperImports = content.contains("import Security")
    
    print("  ✅ Upfront biometric authentication: \(hasUpfrontAuth ? "PASS" : "FAIL")")
    print("  ✅ LAError handling: \(hasLAErrorHandling ? "PASS" : "FAIL")")
    print("  ✅ Success feedback message: \(hasSuccessMessage ? "PASS" : "FAIL")")
    print("  ✅ Proper Security framework import: \(hasProperImports ? "PASS" : "FAIL")")
    
    if !hasUpfrontAuth || !hasLAErrorHandling || !hasSuccessMessage || !hasProperImports {
        allTestsPassed = false
    }
}

// Test 3: Verify biometric availability check in BiometricService
print("\n3. Testing biometric availability check...")
if let content = try? String(contentsOfFile: biometricServicePath) {
    let hasCanEvaluatePolicy = content.contains("canEvaluatePolicy")
    let hasErrorHandling = content.contains("biometryNotEnrolled")
    let hasLockoutHandling = content.contains("biometryLockout")
    
    print("  ✅ Policy evaluation check: \(hasCanEvaluatePolicy ? "PASS" : "FAIL")")
    print("  ✅ Not enrolled error handling: \(hasErrorHandling ? "PASS" : "FAIL")")
    print("  ✅ Lockout error handling: \(hasLockoutHandling ? "PASS" : "FAIL")")
    
    if !hasCanEvaluatePolicy || !hasErrorHandling || !hasLockoutHandling {
        allTestsPassed = false
    }
}

// Test 4: Verify Info.plist has Face ID usage description
print("\n4. Testing Face ID usage description...")
let infoPlistPath = "./WhisperApp/Info.plist"
if let content = try? String(contentsOfFile: infoPlistPath) {
    let hasFaceIDUsage = content.contains("NSFaceIDUsageDescription")
    let hasUsageText = content.contains("signing keys")
    
    print("  ✅ NSFaceIDUsageDescription present: \(hasFaceIDUsage ? "PASS" : "FAIL")")
    print("  ✅ Descriptive usage text: \(hasUsageText ? "PASS" : "FAIL")")
    
    if !hasFaceIDUsage || !hasUsageText {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read Info.plist")
    allTestsPassed = false
}

// Test 5: Verify entitlements configuration
print("\n5. Testing keychain entitlements...")
let entitlementsPath = "./WhisperApp/WhisperApp.entitlements"
if let content = try? String(contentsOfFile: entitlementsPath) {
    let hasKeychainAccess = content.contains("keychain-access-groups")
    let hasBundleId = content.contains("com.mehmetakifacar.Whisper")
    
    print("  ✅ Keychain access groups configured: \(hasKeychainAccess ? "PASS" : "FAIL")")
    print("  ✅ Bundle identifier in keychain group: \(hasBundleId ? "PASS" : "FAIL")")
    
    if !hasKeychainAccess || !hasBundleId {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read entitlements file")
    allTestsPassed = false
}

print("\n" + String(repeating: "=", count: 50))
if allTestsPassed {
    print("🎉 All biometric authentication fixes PASSED!")
    print("\n✅ Summary of fixes:")
    print("  • Changed access control from .biometryCurrentSet to .biometryAny")
    print("  • Added upfront biometric authentication during enrollment")
    print("  • Enhanced error handling for LAError cases")
    print("  • Added success feedback for enrollment")
    print("  • Proper biometric availability checks")
    print("  • Face ID usage description configured")
    print("  • Keychain entitlements properly set")
    print("\n📱 Next steps:")
    print("  1. Clean build and reinstall the app")
    print("  2. Try enrolling biometric authentication again")
    print("  3. Check Settings > Face ID & Passcode > Other Apps")
    print("  4. WhisperApp should now appear in the list")
} else {
    print("❌ Some biometric authentication fixes FAILED!")
    print("\nPlease review the failed tests above and ensure:")
    print("  • Access control uses .biometryAny instead of .biometryCurrentSet")
    print("  • Enrollment includes upfront authentication")
    print("  • Proper LAError handling is implemented")
    print("  • Info.plist has NSFaceIDUsageDescription")
    print("  • Entitlements are properly configured")
}

print("\n🔍 Biometric authentication fix verification complete.")