#!/usr/bin/env swift

import Foundation

print("🔍 Testing Contact Detail View Font Sizing Fixes...")

// Read the ContactDetailView file
let contactDetailPath = "WhisperApp/UI/Contacts/ContactDetailView.swift"
guard let contactDetailContent = try? String(contentsOfFile: contactDetailPath) else {
    print("❌ Could not read ContactDetailView.swift")
    exit(1)
}

var issues: [String] = []

// Check 1: Navigation title should use inline mode (not large)
if contactDetailContent.contains(".navigationBarTitleDisplayMode(.large)") {
    issues.append("❌ Navigation title still using .large mode")
} else if contactDetailContent.contains(".navigationBarTitleDisplayMode(.inline)") {
    print("✅ Navigation title correctly using .inline mode")
} else {
    issues.append("⚠️ Navigation title display mode not found")
}

// Check 2: Contact header should use reasonable font sizes
if contactDetailContent.contains(".font(.title2)") {
    issues.append("❌ Contact header still using .title2 font (too large)")
} else if contactDetailContent.contains(".font(.headline)") {
    print("✅ Contact header using appropriate .headline font")
}

// Check 3: Section headers should use subheadline instead of headline
let sectionHeaders = [
    "Trust Status",
    "Fingerprint", 
    "SAS Words",
    "Technical Information",
    "Key History"
]

for header in sectionHeaders {
    // Look for the pattern: Text("HeaderName").font(.headline)
    let headlinePattern = "Text(\"\(header)\")\\s*\\.font\\(\\.headline\\)"
    let subheadlinePattern = "Text(\"\(header)\")\\s*\\.font\\(\\.subheadline\\)"
    
    if contactDetailContent.range(of: headlinePattern, options: .regularExpression) != nil {
        issues.append("❌ \(header) section still using .headline font (too large)")
    } else if contactDetailContent.range(of: subheadlinePattern, options: .regularExpression) != nil {
        print("✅ \(header) section using appropriate .subheadline font")
    }
}

// Check 4: ID text should use smaller font
if contactDetailContent.contains("Text(\"ID: \\(contact.shortFingerprint)\")") {
    if contactDetailContent.contains(".font(.subheadline)") && 
       contactDetailContent.range(of: "ID.*subheadline", options: .regularExpression) != nil {
        issues.append("❌ Contact ID still using .subheadline font (too large)")
    } else if contactDetailContent.range(of: "ID.*caption", options: .regularExpression) != nil {
        print("✅ Contact ID using appropriate .caption font")
    }
}

// Summary
if issues.isEmpty {
    print("\n🎉 All font sizing issues have been fixed!")
    print("📱 The contact detail view should now have appropriately sized fonts")
    print("📏 Navigation title will be compact and section headers will be readable")
} else {
    print("\n⚠️ Found \(issues.count) remaining font sizing issues:")
    for issue in issues {
        print("   \(issue)")
    }
    exit(1)
}

print("\n📋 Font Sizing Changes Made:")
print("• Navigation title: .large → .inline (compact header)")
print("• Contact name: .title2 → .headline (smaller but readable)")
print("• Contact ID: .subheadline → .caption (more subtle)")
print("• Section headers: .headline → .subheadline (appropriately sized)")
print("• All sections maintain proper hierarchy and readability")