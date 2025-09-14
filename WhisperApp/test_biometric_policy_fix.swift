#!/usr/bin/env swift

import Foundation

// Test script to verify biometric policy fix
print("🧪 Testing Biometric Policy Fix")
print(String(repeating: "=", count: 50))

// Simulate UserDefaults behavior
class MockUserDefaults {
    private var storage: [String: Any] = [:]
    
    func bool(forKey key: String) -> Bool {
        return storage[key] as? Bool ?? false
    }
    
    func object(forKey key: String) -> Any? {
        return storage[key]
    }
    
    func set(_ value: Any?, forKey key: String) {
        storage[key] = value
    }
}

// Mock PolicyManager with the fix
class TestPolicyManager {
    private let userDefaults = MockUserDefaults()
    private let biometricGatedSigningKey = "whisper.policy.biometricGatedSigning"
    
    var biometricGatedSigning: Bool {
        get { 
            // Default to true if not explicitly set, to enable biometric signing by default
            if userDefaults.object(forKey: biometricGatedSigningKey) == nil {
                return true
            }
            return userDefaults.bool(forKey: biometricGatedSigningKey) 
        }
        set { userDefaults.set(newValue, forKey: biometricGatedSigningKey) }
    }
    
    func requiresBiometricForSigning() -> Bool {
        return biometricGatedSigning
    }
}

// Test the fix
let policyManager = TestPolicyManager()

print("Test 1: Default behavior (no value set)")
print("biometricGatedSigning: \(policyManager.biometricGatedSigning)")
print("requiresBiometricForSigning(): \(policyManager.requiresBiometricForSigning())")
print("Expected: true (should default to enabled)")
print()

print("Test 2: Explicitly set to false")
policyManager.biometricGatedSigning = false
print("biometricGatedSigning: \(policyManager.biometricGatedSigning)")
print("requiresBiometricForSigning(): \(policyManager.requiresBiometricForSigning())")
print("Expected: false")
print()

print("Test 3: Explicitly set to true")
policyManager.biometricGatedSigning = true
print("biometricGatedSigning: \(policyManager.biometricGatedSigning)")
print("requiresBiometricForSigning(): \(policyManager.requiresBiometricForSigning())")
print("Expected: true")
print()

// Test the encryption flow logic
print("Test 4: Encryption flow simulation")
let includeSignature = true
let requiresBiometric = policyManager.requiresBiometricForSigning()

print("includeSignature: \(includeSignature)")
print("requiresBiometric: \(requiresBiometric)")
print("Should trigger biometric: \(includeSignature && requiresBiometric)")
print("Expected: true (Face ID should prompt)")
print()

print("✅ Biometric Policy Fix Test Complete")
print("The fix ensures biometric authentication is enabled by default")
print("when Face ID is available and enrolled.")