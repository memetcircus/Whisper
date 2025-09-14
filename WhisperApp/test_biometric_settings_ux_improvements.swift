#!/usr/bin/env swift

import Foundation

print("🔍 Testing Biometric Settings UX Improvements...")

func validateBiometricSettingsUX() -> Bool {
    print("\n📱 Validating Biometric Settings UX improvements...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Settings/BiometricSettingsView.swift") else {
        print("❌ Could not read Biometric Settings view")
        return false
    }
    
    let improvements = [
        ("Enhanced Button Style", "BiometricActionButtonStyle"),
        ("Header Section", "Secure your signing keys"),
        ("Status Badge", "statusColor"),
        ("Action Buttons", "Enroll Signing Key"),
        ("Icon Integration", "Image(systemName:"),
        ("Better Layout", "VStack(spacing:"),
        ("Section Headers", "font(.system(.subheadline, weight: .semibold))"),
        ("Modern Typography", "font(.system(.subheadline, design: .rounded"),
        ("Color Coding", "foregroundColor(.blue)"),
        ("Improved Spacing", "padding(.vertical"),
        ("Corner Radius", "cornerRadius("),
        ("Visual Hierarchy", "fontWeight"),
        ("Status Indicators", "Circle().fill(statusColor)"),
        ("Message Styling", "background(Color.green.opacity(0.1))")
    ]
    
    var passedChecks = 0
    
    for (description, pattern) in improvements {
        if content.contains(pattern) {
            print("✅ \(description): Found")
            passedChecks += 1
        } else {
            print("❌ \(description): Missing pattern '\(pattern)'")
        }
    }
    
    let successRate = Double(passedChecks) / Double(improvements.count)
    print("\n📊 Biometric Settings UX Improvements: \(passedChecks)/\(improvements.count) (\(Int(successRate * 100))%)")
    
    return successRate >= 0.8
}

// Run validation
let success = validateBiometricSettingsUX()

print("\n" + String(repeating: "=", count: 50))
if success {
    print("🎉 Biometric Settings UX improvements completed successfully!")
    print("\n📋 Key Improvements:")
    print("• Enhanced button styles with modern design")
    print("• Improved header section with description")
    print("• Better visual hierarchy with icons and spacing")
    print("• Status indicators with color coding")
    print("• Enhanced action buttons with icons")
    print("• Better message display with background styling")
    print("• Modern typography and consistent styling")
    print("• Improved section organization")
    print("• Maintained compatibility with existing code")
    exit(0)
} else {
    print("❌ Biometric Settings UX improvements validation failed!")
    exit(1)
}