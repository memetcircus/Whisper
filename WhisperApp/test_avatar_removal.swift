#!/usr/bin/env swift

import Foundation

print("🔍 Testing Contact Avatar Removal...")

// Read the ContactDetailView file
let contactDetailPath = "WhisperApp/UI/Contacts/ContactDetailView.swift"
guard let contactDetailContent = try? String(contentsOfFile: contactDetailPath) else {
    print("❌ Could not read ContactDetailView.swift")
    exit(1)
}

var issues: [String] = []

// Check 1: ContactAvatarView should not be present in ContactHeaderView
if contactDetailContent.contains("ContactAvatarView(contact: contact)") {
    // Check if it's in the ContactHeaderView context
    let headerViewRange = contactDetailContent.range(of: "struct ContactHeaderView: View")
    let nextStructRange = contactDetailContent.range(of: "struct TrustStatusSection: View")
    
    if let headerStart = headerViewRange?.upperBound,
       let headerEnd = nextStructRange?.lowerBound {
        let headerContent = String(contactDetailContent[headerStart..<headerEnd])
        
        if headerContent.contains("ContactAvatarView") {
            issues.append("❌ ContactAvatarView still present in ContactHeaderView")
        } else {
            print("✅ ContactAvatarView successfully removed from ContactHeaderView")
        }
    }
} else {
    print("✅ No ContactAvatarView found in ContactDetailView")
}

// Check 2: Verify the header structure is clean
if contactDetailContent.contains("VStack(spacing: 16) {\n            VStack(spacing: 4) {") {
    print("✅ Header structure cleaned up - no avatar, direct to contact info")
} else if contactDetailContent.contains("VStack(spacing: 4) {") {
    print("✅ Contact info VStack present")
} else {
    issues.append("⚠️ Header structure may need verification")
}

// Check 3: Make sure scaleEffect is also removed
if contactDetailContent.contains(".scaleEffect(1.5)") {
    issues.append("❌ scaleEffect still present (should be removed with avatar)")
} else {
    print("✅ scaleEffect removed along with avatar")
}

// Summary
if issues.isEmpty {
    print("\n🎉 Contact avatar successfully removed!")
    print("📱 The contact detail view no longer shows the circular avatar with initials")
    print("🎯 Clean, minimal header with just the contact name and ID")
} else {
    print("\n⚠️ Found \(issues.count) issues with avatar removal:")
    for issue in issues {
        print("   \(issue)")
    }
    exit(1)
}

print("\n📋 Changes Made:")
print("• Removed ContactAvatarView from ContactHeaderView")
print("• Removed .scaleEffect(1.5) modifier")
print("• Simplified header to show only text information")
print("• Maintains clean, minimal design without circular avatar")