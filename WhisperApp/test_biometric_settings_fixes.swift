#!/usr/bin/env swift

import Foundation

print("🔍 Testing Biometric Settings Fixes...")
print(String(repeating: "=", count: 50))

var allTestsPassed = true

// Test 1: Verify title display mode is inline (not large)
print("\n1. Testing navigation title size fix...")
let biometricViewPath = "./WhisperApp/UI/Settings/BiometricSettingsView.swift"
if let content = try? String(contentsOfFile: biometricViewPath) {
    let hasInlineTitle = content.contains(".navigationBarTitleDisplayMode(.inline)")
    let hasLargeTitle = content.contains(".navigationBarTitleDisplayMode(.large)")
    
    print("  ✅ Navigation title set to inline: \(hasInlineTitle ? "PASS" : "FAIL")")
    print("  ✅ No large title display mode: \(!hasLargeTitle ? "PASS" : "FAIL")")
    
    if !hasInlineTitle || hasLargeTitle {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read BiometricSettingsView.swift")
    allTestsPassed = false
}

// Test 2: Verify error message font size is improved
print("\n2. Testing error message font size fix...")
if let content = try? String(contentsOfFile: biometricViewPath) {
    let hasBodyFont = content.contains(".font(.body)")
    let hasFixedSize = content.contains(".fixedSize(horizontal: false, vertical: true)")
    let hasCaptionFont = content.range(of: "\\.font\\(\\.caption\\).*\\.foregroundColor\\(\\.red\\)", options: .regularExpression) != nil
    
    print("  ✅ Error message uses body font: \(hasBodyFont ? "PASS" : "FAIL")")
    print("  ✅ Error message has fixed size: \(hasFixedSize ? "PASS" : "FAIL")")
    print("  ✅ No caption font for error messages: \(!hasCaptionFont ? "PASS" : "FAIL")")
    
    if !hasBodyFont || !hasFixedSize || hasCaptionFont {
        allTestsPassed = false
    }
}

// Test 3: Verify improved error handling in ViewModel
print("\n3. Testing enrollment error handling improvements...")
let biometricViewModelPath = "./WhisperApp/UI/Settings/BiometricSettingsViewModel.swift"
if let content = try? String(contentsOfFile: biometricViewModelPath) {
    let hasAvailabilityCheck = content.contains("guard biometricService.isAvailable()")
    let hasBiometryNotEnrolledHandling = content.contains("BiometricError.biometryNotEnrolled")
    let hasBiometryLockoutHandling = content.contains("BiometricError.biometryLockout")
    let hasSpecificErrorMessages = content.contains("Please enroll Face ID or Touch ID in Settings first")
    let hasStatusCodeHandling = content.contains("case -25293:")
    
    print("  ✅ Availability check before enrollment: \(hasAvailabilityCheck ? "PASS" : "FAIL")")
    print("  ✅ Biometry not enrolled error handling: \(hasBiometryNotEnrolledHandling ? "PASS" : "FAIL")")
    print("  ✅ Biometry lockout error handling: \(hasBiometryLockoutHandling ? "PASS" : "FAIL")")
    print("  ✅ Specific user-friendly error messages: \(hasSpecificErrorMessages ? "PASS" : "FAIL")")
    print("  ✅ Status code specific handling: \(hasStatusCodeHandling ? "PASS" : "FAIL")")
    
    if !hasAvailabilityCheck || !hasBiometryNotEnrolledHandling || !hasBiometryLockoutHandling || !hasSpecificErrorMessages || !hasStatusCodeHandling {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read BiometricSettingsViewModel.swift")
    allTestsPassed = false
}

// Test 4: Verify enrollment status check doesn't trigger biometric prompt
print("\n4. Testing enrollment status check improvement...")
if let content = try? String(contentsOfFile: biometricViewModelPath) {
    let hasKeychainQuery = content.contains("SecItemCopyMatching")
    // Check that checkEnrollmentStatus method doesn't contain biometric authentication
    let checkEnrollmentRange = content.range(of: "private func checkEnrollmentStatus\\(\\)[\\s\\S]*?^\\s*}", options: .regularExpression)
    let hasNoAuthenticationInCheck = checkEnrollmentRange == nil || !content[checkEnrollmentRange!].contains("biometricService.sign")
    let hasStatusCheck = content.contains("status == errSecSuccess")
    
    print("  ✅ Uses keychain query for status check: \(hasKeychainQuery ? "PASS" : "FAIL")")
    print("  ✅ No biometric authentication in status check: \(hasNoAuthenticationInCheck ? "PASS" : "FAIL")")
    print("  ✅ Checks keychain status properly: \(hasStatusCheck ? "PASS" : "FAIL")")
    
    if !hasKeychainQuery || !hasNoAuthenticationInCheck || !hasStatusCheck {
        allTestsPassed = false
    }
}

print("\n" + String(repeating: "=", count: 50))
if allTestsPassed {
    print("🎉 All biometric settings fixes PASSED!")
    print("\n✅ Summary of fixes:")
    print("  • Navigation title changed from large to inline")
    print("  • Error message font size increased from caption to body")
    print("  • Added proper error handling for biometric enrollment")
    print("  • Improved user-friendly error messages")
    print("  • Fixed enrollment status check to avoid biometric prompts")
    print("  • Added specific handling for common error codes")
} else {
    print("❌ Some biometric settings fixes FAILED!")
    print("\nPlease review the failed tests above and ensure:")
    print("  • Navigation title uses inline display mode")
    print("  • Error messages use body font with fixed size")
    print("  • Proper error handling for all biometric scenarios")
    print("  • User-friendly error messages for common issues")
    print("  • Enrollment status check doesn't trigger authentication")
}

print("\n🔍 Biometric settings fixes verification complete.")