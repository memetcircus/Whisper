#!/usr/bin/env swift

import Foundation

// Test that key rotation detection logic has been removed

print("🧪 Testing Key Rotation Logic Removal")
print(String(repeating: "=", count: 50))

// Read the ContactListViewModel file
let contactListViewModelPath = "WhisperApp/UI/Contacts/ContactListViewModel.swift"

guard let content = try? String(contentsOfFile: contactListViewModelPath) else {
    print("❌ Could not read ContactListViewModel.swift")
    exit(1)
}

print("\n🔍 Checking for removal of key rotation detection logic...")

// Check that key rotation detection method is removed
let hasKeyRotationDetection = content.contains("findExistingContactForKeyRotation")
print("  \(hasKeyRotationDetection ? "❌" : "✅") Key rotation detection method removed")

// Check that withKeyRotation call is removed from addContact
let hasWithKeyRotationCall = content.contains("withKeyRotation(") && content.contains("newX25519Key:")
print("  \(hasWithKeyRotationCall ? "❌" : "✅") withKeyRotation call removed from addContact")

// Check that addContact is simplified
let hasSimpleAddContact = content.contains("try contactManager.addContact(contact)") && 
                         !content.contains("if let existingContact = findExistingContactForKeyRotation")
print("  \(hasSimpleAddContact ? "✅" : "❌") addContact method simplified")

// Check that updateContact call for key rotation is removed
let hasUpdateContactCall = content.contains("contactManager.updateContact(rotatedContact)")
print("  \(hasUpdateContactCall ? "❌" : "✅") updateContact call for key rotation removed")

// Check for any remaining key rotation logic
let hasKeyRotationLogic = content.contains("This is a key rotation") || 
                         content.contains("existingContact") ||
                         content.contains("rotatedContact")
print("  \(hasKeyRotationLogic ? "❌" : "✅") All key rotation logic removed")

print("\n🎯 Reversion Status:")
let reversionComplete = !hasKeyRotationDetection && !hasWithKeyRotationCall && 
                       hasSimpleAddContact && !hasUpdateContactCall && !hasKeyRotationLogic

if reversionComplete {
    print("✅ KEY ROTATION LOGIC SUCCESSFULLY REMOVED!")
    print("  ✅ Detection method removed")
    print("  ✅ addContact simplified to original behavior")
    print("  ✅ No key rotation logic remains")
    print("  ✅ Each QR scan will create new contact (correct behavior)")
} else {
    print("❌ Reversion incomplete:")
    if hasKeyRotationDetection {
        print("  ❌ Key rotation detection method still present")
    }
    if hasWithKeyRotationCall {
        print("  ❌ withKeyRotation call still in addContact")
    }
    if !hasSimpleAddContact {
        print("  ❌ addContact not simplified")
    }
    if hasUpdateContactCall {
        print("  ❌ updateContact call for key rotation still present")
    }
    if hasKeyRotationLogic {
        print("  ❌ Key rotation logic still present")
    }
}

print("\n🔧 Expected Behavior:")
print("- Each QR scan creates a new contact (no deduplication)")
print("- Multiple contacts with same name are allowed")
print("- Users manually manage duplicate contacts")
print("- Security prioritized over convenience")
print("- Honest serverless behavior")

print("\n" + String(repeating: "=", count: 50))
print("Test completed!")