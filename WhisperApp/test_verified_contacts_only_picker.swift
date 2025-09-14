#!/usr/bin/env swift

import Foundation

print("🔍 Testing Verified Contacts Only Picker...")

// Read the ComposeView file
let composeViewPath = "WhisperApp/UI/Compose/ComposeView.swift"
guard let composeViewContent = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

var issues: [String] = []

// Check 1: Toggle for "Show only verified contacts" should be removed
if composeViewContent.contains("Toggle(\"Show only verified contacts\"") {
    issues.append("❌ 'Show only verified contacts' toggle still present (should be removed)")
} else {
    print("✅ 'Show only verified contacts' toggle removed")
}

// Check 2: Should use verifiedContacts computed property
if composeViewContent.contains("private var verifiedContacts: [Contact]") {
    print("✅ verifiedContacts computed property added")
} else {
    issues.append("❌ verifiedContacts computed property missing")
}

// Check 3: Should filter for verified contacts only
if composeViewContent.contains("contactManager.contacts.filter { $0.trustLevel == .verified }") {
    print("✅ Filtering for verified contacts only")
} else {
    issues.append("❌ Not filtering for verified contacts")
}

// Check 4: Should use verifiedContacts in ForEach
if composeViewContent.contains("ForEach(verifiedContacts, id: \\.id)") {
    print("✅ Using verifiedContacts in list")
} else if composeViewContent.contains("ForEach(contactManager.contacts, id: \\.id)") {
    issues.append("❌ Still using all contacts instead of verified contacts")
}

// Check 5: Empty state should be specific to verified contacts
if composeViewContent.contains("No Verified Contacts") && 
   composeViewContent.contains("You don't have any verified contacts yet") {
    print("✅ Appropriate empty state for verified contacts")
} else {
    issues.append("❌ Empty state not updated for verified contacts only")
}

// Check 6: Should call loadVerifiedContactsOnly instead of loadContacts
if composeViewContent.contains("contactManager.loadVerifiedContactsOnly()") {
    print("✅ Loading verified contacts only")
} else if composeViewContent.contains("contactManager.loadContacts()") {
    issues.append("❌ Still loading all contacts instead of verified only")
}

// Check 7: Unverified warning should be removed from ContactPickerRowView
if composeViewContent.contains("// Warning for unverified contacts") ||
   composeViewContent.contains("exclamationmark.triangle.fill") ||
   composeViewContent.contains("Unverified") {
    issues.append("❌ Unverified contact warning still present (not needed for verified-only list)")
} else {
    print("✅ Unverified contact warning removed")
}

// Check 8: Contact count indicator should be removed
if composeViewContent.contains("\\(contactManager.contacts.count) contacts") {
    issues.append("❌ Contact count indicator still present (should be removed)")
} else {
    print("✅ Contact count indicator removed")
}

// Check 9: "Show All Contacts" button should be removed
if composeViewContent.contains("Show All Contacts") {
    issues.append("❌ 'Show All Contacts' button still present (should be removed)")
} else {
    print("✅ 'Show All Contacts' button removed")
}

// Summary
if issues.isEmpty {
    print("\n🎉 Verified contacts only picker successfully implemented!")
    print("🔒 Only verified contacts are shown in the picker")
    print("🎯 Cleaner interface without unnecessary toggles")
    print("⚡ Simplified user experience for secure messaging")
} else {
    print("\n⚠️ Found \(issues.count) issues with verified contacts only implementation:")
    for issue in issues {
        print("   \(issue)")
    }
    exit(1)
}

print("\n📋 Changes Made:")
print("• Removed 'Show only verified contacts' toggle")
print("• Added verifiedContacts computed property")
print("• Filter contacts to show only verified ones")
print("• Updated empty state message for verified contacts")
print("• Removed unverified contact warnings")
print("• Removed contact count indicator")
print("• Removed 'Show All Contacts' button")
print("• Call loadVerifiedContactsOnly() method")