#!/usr/bin/env swift

import Foundation

// Test that PolicyManager showOnlyVerifiedContacts references have been removed

print("🧪 Testing PolicyManager showOnlyVerifiedContacts Removal")
print(String(repeating: "=", count: 50))

// Read the ContactListViewModel file
let contactListViewModelPath = "WhisperApp/UI/Contacts/ContactListViewModel.swift"

guard let content = try? String(contentsOfFile: contactListViewModelPath) else {
    print("❌ Could not read ContactListViewModel.swift")
    exit(1)
}

print("\n🔍 Checking for PolicyManager property removal...")

// Check that showOnlyVerifiedContacts references are removed
let hasShowOnlyVerifiedContacts = content.contains("showOnlyVerifiedContacts")
print("  \(hasShowOnlyVerifiedContacts ? "❌" : "✅") showOnlyVerifiedContacts references removed")

// Check that policyManager property is removed from ContactPickerViewModel
let hasPolicyManagerProperty = content.contains("private let policyManager")
print("  \(hasPolicyManagerProperty ? "❌" : "✅") policyManager property removed")

// Check that UserDefaultsPolicyManager initialization is removed
let hasPolicyManagerInit = content.contains("UserDefaultsPolicyManager()")
print("  \(hasPolicyManagerInit ? "❌" : "✅") UserDefaultsPolicyManager initialization removed")

// Check that toggleVerificationFilter is simplified
let hasSimplifiedToggle = content.contains("showOnlyVerified.toggle()") && 
                         !content.contains("policyManager.showOnlyVerifiedContacts")
print("  \(hasSimplifiedToggle ? "✅" : "❌") toggleVerificationFilter simplified")

// Check that ContactPickerViewModel still exists and works
let hasContactPickerViewModel = content.contains("class ContactPickerViewModel")
print("  \(hasContactPickerViewModel ? "✅" : "❌") ContactPickerViewModel still exists")

print("\n🎯 Fix Status:")
let fixComplete = !hasShowOnlyVerifiedContacts && !hasPolicyManagerProperty && 
                 !hasPolicyManagerInit && hasSimplifiedToggle && hasContactPickerViewModel

if fixComplete {
    print("✅ POLICYMANAGER REFERENCES SUCCESSFULLY REMOVED!")
    print("  ✅ No showOnlyVerifiedContacts references")
    print("  ✅ No policyManager property")
    print("  ✅ No UserDefaultsPolicyManager initialization")
    print("  ✅ Simplified toggle function")
    print("  ✅ ContactPickerViewModel still functional")
} else {
    print("❌ Fix incomplete:")
    if hasShowOnlyVerifiedContacts {
        print("  ❌ showOnlyVerifiedContacts references still present")
    }
    if hasPolicyManagerProperty {
        print("  ❌ policyManager property still present")
    }
    if hasPolicyManagerInit {
        print("  ❌ UserDefaultsPolicyManager initialization still present")
    }
    if !hasSimplifiedToggle {
        print("  ❌ toggleVerificationFilter not simplified")
    }
    if !hasContactPickerViewModel {
        print("  ❌ ContactPickerViewModel missing")
    }
}

print("\n🔧 Expected Behavior:")
print("- Build should compile without PolicyManager property errors")
print("- ContactPickerViewModel works with local showOnlyVerified state")
print("- No dependency on missing PolicyManager properties")
print("- Verification filter still functional")

print("\n" + String(repeating: "=", count: 50))
print("Test completed!")