#!/usr/bin/env swift

import Foundation

// Test that ContactPickerViewModel defaults to verified contacts only for security

print("🔒 Testing Verified Contacts Only Security Fix")
print(String(repeating: "=", count: 50))

// Read the ContactListViewModel file
let contactListViewModelPath = "WhisperApp/UI/Contacts/ContactListViewModel.swift"

guard let content = try? String(contentsOfFile: contactListViewModelPath) else {
    print("❌ Could not read ContactListViewModel.swift")
    exit(1)
}

print("\n🔍 Checking for security improvements...")

// Check that showOnlyVerified defaults to true
let hasSecureDefault = content.contains("showOnlyVerified: Bool = true")
print("  \(hasSecureDefault ? "✅" : "❌") showOnlyVerified defaults to true (secure)")

// Check for security comment
let hasSecurityComment = content.contains("SECURITY: Only show verified contacts")
print("  \(hasSecurityComment ? "✅" : "❌") Security comment present")

// Check that verification filter is applied
let hasVerificationFilter = content.contains("filteredContacts.filter { $0.trustLevel == .verified }")
print("  \(hasVerificationFilter ? "✅" : "❌") Verification filter implemented")

// Check that blocked contacts are filtered out
let hasBlockedFilter = content.contains("filter { !$0.isBlocked }")
print("  \(hasBlockedFilter ? "✅" : "❌") Blocked contacts filtered out")

// Check for proper sorting (verified first)
let hasSecureSorting = content.contains("contact1.trustLevel == .verified")
print("  \(hasSecureSorting ? "✅" : "❌") Verified contacts sorted first")

// Check that toggle function still exists
let hasToggleFunction = content.contains("func toggleVerificationFilter()")
print("  \(hasToggleFunction ? "✅" : "❌") Toggle function available for advanced users")

print("\n🎯 Security Fix Status:")
let securityFixComplete = hasSecureDefault && hasSecurityComment && hasVerificationFilter && 
                         hasBlockedFilter && hasSecureSorting && hasToggleFunction

if securityFixComplete {
    print("✅ SECURITY FIX COMPLETE!")
    print("  ✅ Defaults to verified contacts only")
    print("  ✅ Security comment explains behavior")
    print("  ✅ Proper filtering implemented")
    print("  ✅ Blocked contacts excluded")
    print("  ✅ Verified contacts prioritized")
    print("  ✅ Advanced toggle still available")
} else {
    print("❌ Security fix incomplete:")
    if !hasSecureDefault {
        print("  ❌ showOnlyVerified doesn't default to true")
    }
    if !hasSecurityComment {
        print("  ❌ Security comment missing")
    }
    if !hasVerificationFilter {
        print("  ❌ Verification filter not implemented")
    }
    if !hasBlockedFilter {
        print("  ❌ Blocked contacts not filtered")
    }
    if !hasSecureSorting {
        print("  ❌ Secure sorting not implemented")
    }
    if !hasToggleFunction {
        print("  ❌ Toggle function missing")
    }
}

print("\n🔒 Security Benefits:")
print("- Users can only select verified contacts by default")
print("- Prevents accidental messages to unverified contacts")
print("- Reduces risk of man-in-the-middle attacks")
print("- Blocked contacts are never shown")
print("- Advanced users can still toggle to see all contacts if needed")

print("\n🎯 Expected Behavior:")
print("- Compose message only shows verified contacts")
print("- Unverified contacts (like rotated keys) not selectable")
print("- User must verify contacts before messaging")
print("- Clear security-first approach")

print("\n" + String(repeating: "=", count: 50))
print("Test completed!")