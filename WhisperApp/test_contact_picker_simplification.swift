#!/usr/bin/env swift

import Foundation

print("🔍 Testing Contact Picker Simplification...")

// Read the ComposeView file
let composeViewPath = "WhisperApp/UI/Compose/ComposeView.swift"
guard let composeViewContent = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

var issues: [String] = []

// Check 1: Should not have "Show only verified contacts" toggle
if composeViewContent.contains("Toggle(\"Show only verified contacts\"") {
    issues.append("❌ Still has 'Show only verified contacts' toggle (should be removed)")
} else {
    print("✅ Removed 'Show only verified contacts' toggle")
}

// Check 2: Should not have showOnlyVerified state
if composeViewContent.contains("@State private var showOnlyVerified") {
    issues.append("❌ Still has showOnlyVerified state variable (should be removed)")
} else {
    print("✅ Removed showOnlyVerified state variable")
}

// Check 3: Should use verifiedContacts instead of filteredContacts
if composeViewContent.contains("verifiedContacts") && !composeViewContent.contains("filteredContacts") {
    print("✅ Using verifiedContacts (always shows only verified)")
} else {
    issues.append("❌ Not using proper verifiedContacts filtering")
}

// Check 4: Should not have TrustBadgeView
if composeViewContent.contains("TrustBadgeView") {
    issues.append("❌ Still shows TrustBadgeView (verified tag should be removed)")
} else {
    print("✅ Removed TrustBadgeView (no more verified tags)")
}

// Check 5: Contact name should use .body font (not .headline)
if composeViewContent.contains("Text(contact.displayName)") && 
   composeViewContent.contains(".font(.body)") {
    print("✅ Contact name uses appropriate .body font size")
} else if composeViewContent.contains(".font(.headline)") {
    issues.append("❌ Contact name still using .headline font (too large)")
} else {
    issues.append("⚠️ Contact name font configuration not found")
}

// Check 6: Should not have complex HStack with trust badge
if composeViewContent.contains("HStack {") && 
   composeViewContent.contains("Text(contact.displayName)") &&
   !composeViewContent.contains("TrustBadgeView") {
    print("✅ Simplified contact row layout without trust badge")
} else {
    issues.append("⚠️ Contact row layout may still be complex")
}

// Check 7: Should have simpler empty state
if composeViewContent.contains("No Verified Contacts") && 
   !composeViewContent.contains("Show All Contacts") {
    print("✅ Simplified empty state without toggle options")
} else {
    issues.append("⚠️ Empty state may still have unnecessary options")
}

// Summary
if issues.isEmpty {
    print("\n🎉 Contact picker successfully simplified!")
    print("📱 Only shows verified contacts (no toggle needed)")
    print("🏷️ Removed verified tags (redundant since all are verified)")
    print("📝 Fixed contact name font size (.body instead of .headline)")
    print("🎯 Cleaner, simpler interface")
} else {
    print("\n⚠️ Found \(issues.count) remaining issues:")
    for issue in issues {
        print("   \(issue)")
    }
    exit(1)
}

print("\n📋 Simplifications Made:")
print("• Removed 'Show only verified contacts' toggle")
print("• Always filter to verified contacts only")
print("• Removed TrustBadgeView (verified tags)")
print("• Changed contact name font from .headline to .body")
print("• Simplified contact row layout")
print("• Cleaner empty state without unnecessary options")