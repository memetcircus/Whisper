#!/usr/bin/env swift

import Foundation

print("🔍 Testing Identity Tag Removal...")

// Read the ComposeView file
let composeViewPath = "WhisperApp/UI/Compose/ComposeView.swift"
guard let composeViewContent = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

var issues: [String] = []

// Check 1: Should not have LocalizationHelper.Identity.active
if composeViewContent.contains("LocalizationHelper.Identity.active") {
    issues.append("❌ Still shows LocalizationHelper.Identity.active (default identity tag)")
} else {
    print("✅ Removed LocalizationHelper.Identity.active tag")
}

// Check 2: Should not have "Default Identity" text
if composeViewContent.contains("Default Identity") {
    issues.append("❌ Still contains 'Default Identity' text")
} else {
    print("✅ No 'Default Identity' text found")
}

// Check 3: Identity section should have simplified layout
if composeViewContent.contains("Text(activeIdentity.name)") && 
   composeViewContent.contains("HStack(spacing: 12)") {
    print("✅ Simplified identity layout with direct HStack")
} else {
    issues.append("⚠️ Identity section layout may need verification")
}

// Check 4: Should still have the identity name
if composeViewContent.contains("Text(activeIdentity.name)") {
    print("✅ Identity name is still displayed")
} else {
    issues.append("❌ Identity name missing")
}

// Check 5: Should still have Change button
if composeViewContent.contains("Button(LocalizationHelper.Encrypt.change)") {
    print("✅ Change button is still present")
} else {
    issues.append("❌ Change button missing")
}

// Check 6: Should have proper HStack layout
if composeViewContent.contains("HStack(spacing: 12)") && 
   composeViewContent.contains("Text(activeIdentity.name)") &&
   composeViewContent.contains("Spacer()") {
    print("✅ Proper HStack layout with name, spacer, and button")
} else {
    issues.append("⚠️ HStack layout may need verification")
}

// Summary
if issues.isEmpty {
    print("\n🎉 Default identity tag successfully removed!")
    print("📱 Cleaner identity section without redundant tag")
    print("🎯 Simplified layout with just name and change button")
    print("✨ Better visual hierarchy and less clutter")
} else {
    print("\n⚠️ Found \(issues.count) remaining issues:")
    for issue in issues {
        print("   \(issue)")
    }
    exit(1)
}

print("\n📋 Changes Made:")
print("• Removed LocalizationHelper.Identity.active tag")
print("• Simplified identity section layout")
print("• Removed unnecessary VStack for name and tag")
print("• Maintained identity name and change button")
print("• Cleaner, less cluttered interface")