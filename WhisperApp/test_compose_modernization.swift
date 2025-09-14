#!/usr/bin/env swift

import Foundation

print("🔍 Testing Compose View Modernization...")

// Read the ComposeView file
let composeViewPath = "WhisperApp/UI/Compose/ComposeView.swift"
guard let composeViewContent = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

var issues: [String] = []

// Check 1: Improved no identity message
if composeViewContent.contains("Create your identity in Settings first") {
    print("✅ Improved no identity message with proper grammar")
} else if composeViewContent.contains("No default identity selected") {
    issues.append("❌ Still using old 'No default identity selected' message")
} else {
    issues.append("⚠️ No identity message not found")
}

// Check 2: Modern message box styling
if composeViewContent.contains(".cornerRadius(16)") {
    print("✅ Modern corner radius (16pt) for message box")
} else if composeViewContent.contains(".cornerRadius(12)") {
    issues.append("⚠️ Message box still using 12pt corner radius")
}

// Check 3: Thinner border
if composeViewContent.contains("lineWidth: 0.5") {
    print("✅ Thin, modern border (0.5pt)")
} else if composeViewContent.contains("lineWidth: 1") {
    issues.append("❌ Message box still using thick 1pt border")
}

// Check 4: Better background color
if composeViewContent.contains("Color(.systemBackground)") {
    print("✅ Clean system background color")
} else {
    issues.append("⚠️ Message box background may need improvement")
}

// Check 5: Modern shadow
if composeViewContent.contains(".shadow(") {
    print("✅ Added subtle shadow for depth")
} else {
    issues.append("⚠️ No shadow added for modern look")
}

// Summary
if issues.isEmpty {
    print("\n🎉 Compose view successfully modernized!")
    print("📱 Better no identity message with proper grammar")
    print("💎 Modern message box with thin borders and subtle shadow")
    print("🎨 Professional, clean styling throughout")
} else {
    print("\n⚠️ Found \(issues.count) areas for improvement:")
    for issue in issues {
        print("   \(issue)")
    }
    exit(1)
}

print("\n📋 Modernization Changes:")
print("• Improved no identity message: 'Create your identity in Settings first'")
print("• Modern corner radius: 12pt → 16pt")
print("• Thinner border: 1pt → 0.5pt")
print("• Clean background: systemGray6 → systemBackground")
print("• Added subtle shadow for depth and professionalism")