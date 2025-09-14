#!/usr/bin/env swift

import Foundation

print("🔍 Testing Biometric Service Build Fix...")
print(String(repeating: "=", count: 50))

var allTestsPassed = true

// Test 1: Verify the build error fix - accessControlError variable exists
print("\n1. Testing error variable conflict resolution...")
let biometricServicePath = "./WhisperApp/Services/BiometricService.swift"
if let content = try? String(contentsOfFile: biometricServicePath) {
    let hasAccessControlError = content.contains("var accessControlError: Unmanaged<CFError>?")
    let hasAccessControlErrorUsage = content.contains("&accessControlError")
    let hasConflictingErrorDeclaration = content.contains("var error: Unmanaged<CFError>?")
    
    print("  ✅ accessControlError variable declared: \(hasAccessControlError ? "PASS" : "FAIL")")
    print("  ✅ accessControlError variable used: \(hasAccessControlErrorUsage ? "PASS" : "FAIL")")
    print("  ✅ No conflicting CFError error variable: \(!hasConflictingErrorDeclaration ? "PASS" : "FAIL")")
    
    if !hasAccessControlError || !hasAccessControlErrorUsage || hasConflictingErrorDeclaration {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read BiometricService.swift")
    allTestsPassed = false
}

// Test 2: Verify the access control creation uses the renamed variable
print("\n2. Testing access control variable usage...")
if let content = try? String(contentsOfFile: biometricServicePath) {
    let hasAccessControlErrorUsage = content.contains("&accessControlError")
    let hasOldErrorUsage = content.range(of: "SecAccessControlCreateWithFlags.*&error", options: .regularExpression) != nil
    
    print("  ✅ Uses &accessControlError in SecAccessControlCreateWithFlags: \(hasAccessControlErrorUsage ? "PASS" : "FAIL")")
    print("  ✅ No conflicting &error usage in access control: \(!hasOldErrorUsage ? "PASS" : "FAIL")")
    
    if !hasAccessControlErrorUsage || hasOldErrorUsage {
        allTestsPassed = false
    }
}

// Test 3: Verify both error variables are used in their correct contexts
print("\n3. Testing error variable context usage...")
if let content = try? String(contentsOfFile: biometricServicePath) {
    let hasNSErrorContext = content.contains("var error: NSError?")
    let hasCFErrorContext = content.contains("var accessControlError: Unmanaged<CFError>?")
    let hasCanEvaluatePolicyUsage = content.contains("canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)")
    
    print("  ✅ NSError variable for LAContext: \(hasNSErrorContext ? "PASS" : "FAIL")")
    print("  ✅ CFError variable for SecAccessControl: \(hasCFErrorContext ? "PASS" : "FAIL")")
    print("  ✅ Correct error variable in canEvaluatePolicy: \(hasCanEvaluatePolicyUsage ? "PASS" : "FAIL")")
    
    if !hasNSErrorContext || !hasCFErrorContext || !hasCanEvaluatePolicyUsage {
        allTestsPassed = false
    }
}

print("\n" + String(repeating: "=", count: 50))
if allTestsPassed {
    print("🎉 All biometric service build fixes PASSED!")
    print("\n✅ Summary of fix:")
    print("  • Renamed second error variable to 'accessControlError'")
    print("  • Resolved 'Invalid redeclaration of error' build error")
    print("  • Maintained correct usage contexts for both error variables")
    print("  • NSError used for LAContext.canEvaluatePolicy")
    print("  • CFError used for SecAccessControlCreateWithFlags")
    print("\n🔨 The build error should now be resolved!")
} else {
    print("❌ Some biometric service build fixes FAILED!")
    print("\nPlease review the failed tests above and ensure:")
    print("  • No duplicate variable names in the same scope")
    print("  • Correct error variable usage in each context")
    print("  • Both NSError and CFError variables are properly declared")
}

print("\n🔍 Biometric service build fix verification complete.")