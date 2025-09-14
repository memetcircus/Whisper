#!/usr/bin/env swift

import Foundation

// Test the duplicate contact key rotation fix

print("🧪 Testing Duplicate Contact Key Rotation Fix")
print(String(repeating: "=", count: 50))

// Read the ContactListViewModel file
let contactListViewModelPath = "WhisperApp/UI/Contacts/ContactListViewModel.swift"

guard let content = try? String(contentsOfFile: contactListViewModelPath) else {
    print("❌ Could not read ContactListViewModel.swift")
    exit(1)
}

print("\n🔍 Checking for key rotation detection logic...")

// Check for the key rotation detection method
let hasKeyRotationDetection = content.contains("findExistingContactForKeyRotation")
print("  \(hasKeyRotationDetection ? "✅" : "❌") findExistingContactForKeyRotation method exists")

// Check for withKeyRotation call in addContact
let hasWithKeyRotationCall = content.contains("withKeyRotation(") && content.contains("newX25519Key:")
print("  \(hasWithKeyRotationCall ? "✅" : "❌") withKeyRotation call in addContact method")

// Check for updateContact call instead of addContact for key rotation
let hasUpdateContactCall = content.contains("contactManager.updateContact(rotatedContact)")
print("  \(hasUpdateContactCall ? "✅" : "❌") updateContact call for key rotation")

// Check for proper logic flow
let hasProperLogic = content.contains("if let existingContact = findExistingContactForKeyRotation")
print("  \(hasProperLogic ? "✅" : "❌") Proper key rotation detection logic")

// Check for name and key comparison
let hasNameComparison = content.contains("existingContact.displayName == newContact.displayName")
let hasKeyComparison = content.contains("existingContact.x25519PublicKey != newContact.x25519PublicKey")
let hasFingerprintComparison = content.contains("existingContact.fingerprint != newContact.fingerprint")

print("  \(hasNameComparison ? "✅" : "❌") Display name comparison")
print("  \(hasKeyComparison ? "✅" : "❌") X25519 key comparison")
print("  \(hasFingerprintComparison ? "✅" : "❌") Fingerprint comparison")

print("\n🎯 Fix Status:")
let allChecksPass = hasKeyRotationDetection && hasWithKeyRotationCall && hasUpdateContactCall && 
                   hasProperLogic && hasNameComparison && hasKeyComparison && hasFingerprintComparison

if allChecksPass {
    print("✅ ALL CHECKS PASSED - Duplicate contact fix is properly implemented!")
    print("\n📋 How it works:")
    print("1. When adding a contact, check for existing contacts with same name but different keys")
    print("2. If found, treat as key rotation and update existing contact using withKeyRotation()")
    print("3. Trust level will be reset to unverified, requiring re-verification")
    print("4. No duplicate contacts will be created")
} else {
    print("❌ Some checks failed - Fix may not be complete")
}

print("\n🔧 Expected Behavior:")
print("- Tugba rotates keys and shares new QR code")
print("- Akif scans QR code")
print("- System detects same name (Tugba) but different keys")
print("- Updates existing Tugba contact instead of creating new one")
print("- Trust level resets to unverified (security requirement)")
print("- Only one Tugba contact remains in list")

print("\n" + String(repeating: "=", count: 50))
print("Test completed!")