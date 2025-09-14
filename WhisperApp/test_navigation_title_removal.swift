#!/usr/bin/env swift

import Foundation

print("🔍 Testing Navigation Title Removal...")

// Read the ContactDetailView file
let contactDetailPath = "WhisperApp/UI/Contacts/ContactDetailView.swift"
guard let contactDetailContent = try? String(contentsOfFile: contactDetailPath) else {
    print("❌ Could not read ContactDetailView.swift")
    exit(1)
}

var issues: [String] = []

// Check 1: Navigation title should be empty string
if contactDetailContent.contains(".navigationTitle(\"\")") {
    print("✅ Navigation title set to empty string (removes redundant title)")
} else if contactDetailContent.contains(".navigationTitle(") {
    issues.append("❌ Navigation title still contains text (should be empty)")
} else {
    issues.append("⚠️ Navigation title configuration not found")
}

// Check 2: Should use inline display mode to minimize space
if contactDetailContent.contains(".navigationBarTitleDisplayMode(.inline)") {
    print("✅ Navigation title using .inline mode (minimal space)")
} else if contactDetailContent.contains(".navigationBarTitleDisplayMode(.large)") {
    issues.append("❌ Navigation title still using .large mode")
} else {
    issues.append("⚠️ Navigation title display mode not configured")
}

// Check 3: Verify toolbar is still present for Done button and menu
if contactDetailContent.contains(".toolbar {") {
    print("✅ Toolbar configuration present (maintains Done button and menu)")
} else {
    issues.append("❌ Toolbar configuration missing")
}

// Check 4: Verify Done button is still present
if contactDetailContent.contains("Button(\"Done\")") {
    print("✅ Done button present in toolbar")
} else {
    issues.append("❌ Done button missing from toolbar")
}

// Check 5: Verify contact name is still displayed in content
if contactDetailContent.contains("Text(contact.displayName)") {
    print("✅ Contact name displayed in content area (not redundant)")
} else {
    issues.append("❌ Contact name missing from content area")
}

// Summary
if issues.isEmpty {
    print("\n🎉 Navigation title successfully removed!")
    print("📱 The contact detail view no longer shows redundant title at top center")
    print("🎯 Clean navigation bar with only Done button and menu")
    print("📝 Contact name remains visible in the content area")
} else {
    print("\n⚠️ Found \(issues.count) issues with navigation title removal:")
    for issue in issues {
        print("   \(issue)")
    }
    exit(1)
}

print("\n📋 Changes Made:")
print("• Set navigation title to empty string (\"\") to remove redundant text")
print("• Used .inline display mode to minimize navigation bar space")
print("• Maintained toolbar with Done button and menu")
print("• Contact name remains in content area for clear identification")