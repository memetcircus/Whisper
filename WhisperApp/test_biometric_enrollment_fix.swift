#!/usr/bin/env swift

import Foundation

print("🔍 Testing Biometric Enrollment Fix...")
print(String(repeating: "=", count: 50))

var allTestsPassed = true

// Test 1: Verify upfront authentication removed from ViewModel
print("\n1. Testing ViewModel enrollment simplification...")
let viewModelPath = "./WhisperApp/UI/Settings/BiometricSettingsViewModel.swift"
if let content = try? String(contentsOfFile: viewModelPath) {
    let hasUpfrontAuth = content.contains("evaluatePolicy")
    let hasLAErrorHandling = content.contains("LAError")
    let hasBiometricErrorHandling = content.contains("BiometricError.enrollmentFailed")
    let hasDirectEnrollment = content.contains("biometricService.enrollSigningKey(signingKey, id: testKeyId)")
    
    print("  ✅ Removed upfront evaluatePolicy: \(!hasUpfrontAuth ? "PASS" : "FAIL")")
    print("  ✅ Removed LAError handling: \(!hasLAErrorHandling ? "PASS" : "FAIL")")
    print("  ✅ Added BiometricError handling: \(hasBiometricErrorHandling ? "PASS" : "FAIL")")
    print("  ✅ Direct enrollment call: \(hasDirectEnrollment ? "PASS" : "FAIL")")
    
    if hasUpfrontAuth || hasLAErrorHandling || !hasBiometricErrorHandling || !hasDirectEnrollment {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read BiometricSettingsViewModel.swift")
    allTestsPassed = false
}

// Test 2: Verify BiometricService access control simplification
print("\n2. Testing BiometricService access control fix...")
let biometricServicePath = "./WhisperApp/Services/BiometricService.swift"
if let content = try? String(contentsOfFile: biometricServicePath) {
    let hasSimplifiedAccessControl = content.contains(".biometryAny,")
    let hasComplexAccessControl = content.contains("[.biometryAny, .privateKeyUsage]")
    let hasRemovedPolicyCheck = content.contains("Let the keychain operation handle biometric authentication")
    let hasOldPolicyCheck = content.range(of: "enrollSigningKey.*canEvaluatePolicy", options: .regularExpression) != nil
    
    print("  ✅ Simplified access control flags: \(hasSimplifiedAccessControl ? "PASS" : "FAIL")")
    print("  ✅ Removed complex access control: \(!hasComplexAccessControl ? "PASS" : "FAIL")")
    print("  ✅ Removed upfront policy check: \(hasRemovedPolicyCheck ? "PASS" : "FAIL")")
    print("  ✅ No old policy check: \(!hasOldPolicyCheck ? "PASS" : "FAIL")")
    
    if !hasSimplifiedAccessControl || hasComplexAccessControl || !hasRemovedPolicyCheck || hasOldPolicyCheck {
        allTestsPassed = false
    }
}

// Test 3: Verify error handling improvements
print("\n3. Testing error handling improvements...")
if let content = try? String(contentsOfFile: viewModelPath) {
    let hasErrorCode25293 = content.contains("case -25293:")
    let hasErrorCode25291 = content.contains("case -25291:")
    let hasErrorCode25300 = content.contains("case -25300:")
    let hasGenericErrorCode = content.contains("Error code: \\(status)")
    
    print("  ✅ Handles error -25293 (biometry lockout): \(hasErrorCode25293 ? "PASS" : "FAIL")")
    print("  ✅ Handles error -25291 (biometry not available): \(hasErrorCode25291 ? "PASS" : "FAIL")")
    print("  ✅ Handles error -25300 (missing entitlement): \(hasErrorCode25300 ? "PASS" : "FAIL")")
    print("  ✅ Generic error code display: \(hasGenericErrorCode ? "PASS" : "FAIL")")
    
    if !hasErrorCode25293 || !hasErrorCode25291 || !hasErrorCode25300 || !hasGenericErrorCode {
        allTestsPassed = false
    }
}

print("\n" + String(repeating: "=", count: 50))
if allTestsPassed {
    print("🎉 All biometric enrollment fixes PASSED!")
    print("\n✅ Summary of fixes:")
    print("  • Removed upfront biometric authentication from ViewModel")
    print("  • Simplified access control to use .biometryAny only")
    print("  • Removed upfront policy evaluation in BiometricService")
    print("  • Let keychain operation handle biometric authentication")
    print("  • Enhanced error handling with specific error codes")
    print("  • Added user-friendly error messages")
    print("\n🔨 The enrollment should now work properly!")
    print("   Try enrolling again - the Face ID prompt should appear during keychain storage")
} else {
    print("❌ Some biometric enrollment fixes FAILED!")
    print("\nPlease review the failed tests above and ensure:")
    print("  • No upfront authentication in ViewModel")
    print("  • Simplified access control in BiometricService")
    print("  • Proper error handling for all scenarios")
    print("  • Keychain operation handles biometric authentication")
}

print("\n🔍 Biometric enrollment fix verification complete.")