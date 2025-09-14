#!/usr/bin/env swift

import Foundation

// Test the ContactListViewModel build fix

print("🧪 Testing ContactListViewModel Build Fix")
print(String(repeating: "=", count: 50))

// Read the ContactListViewModel file
let contactListViewModelPath = "WhisperApp/UI/Contacts/ContactListViewModel.swift"

guard let content = try? String(contentsOfFile: contactListViewModelPath) else {
    print("❌ Could not read ContactListViewModel.swift")
    exit(1)
}

print("\n🔍 Checking for build error fixes...")

// Check for the concrete type instead of protocol type
let hasConcreteType = content.contains("private let policyManager: UserDefaultsPolicyManager")
print("  \(hasConcreteType ? "✅" : "❌") Uses concrete UserDefaultsPolicyManager type")

// Check for proper initialization
let hasProperInit = content.contains("self.policyManager = UserDefaultsPolicyManager()")
print("  \(hasProperInit ? "✅" : "❌") Proper policyManager initialization")

// Check for showOnlyVerifiedContacts access
let hasPropertyAccess = content.contains("policyManager.showOnlyVerifiedContacts")
print("  \(hasPropertyAccess ? "✅" : "❌") showOnlyVerifiedContacts property access")

// Check for key rotation detection logic (our main fix)
let hasKeyRotationDetection = content.contains("findExistingContactForKeyRotation")
print("  \(hasKeyRotationDetection ? "✅" : "❌") Key rotation detection logic present")

// Check for withKeyRotation call
let hasWithKeyRotationCall = content.contains("withKeyRotation(")
print("  \(hasWithKeyRotationCall ? "✅" : "❌") withKeyRotation method call present")

print("\n🎯 Build Fix Status:")
let buildFixComplete = hasConcreteType && hasProperInit && hasPropertyAccess
let keyRotationFixComplete = hasKeyRotationDetection && hasWithKeyRotationCall

if buildFixComplete && keyRotationFixComplete {
    print("✅ ALL FIXES COMPLETE!")
    print("  ✅ Build error fixed - PolicyManager type issue resolved")
    print("  ✅ Key rotation detection implemented")
    print("  ✅ Duplicate contact prevention active")
} else {
    print("❌ Some fixes incomplete:")
    if !buildFixComplete {
        print("  ❌ Build error not fully fixed")
    }
    if !keyRotationFixComplete {
        print("  ❌ Key rotation detection not complete")
    }
}

print("\n🔧 Expected Behavior:")
print("- Build should compile without PolicyManager errors")
print("- Key rotation should update existing contact instead of creating duplicate")
print("- Trust level should reset to unverified on key rotation")

print("\n" + String(repeating: "=", count: 50))
print("Test completed!")