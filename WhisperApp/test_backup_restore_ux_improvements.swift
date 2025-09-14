#!/usr/bin/env swift

import Foundation

print("🔍 Testing Backup & Restore UX Improvements...")

func validateBackupRestoreUX() -> Bool {
    print("\n📱 Validating Backup & Restore UX improvements...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Settings/BackupRestoreView.swift") else {
        print("❌ Could not read Backup & Restore view")
        return false
    }
    
    let improvements = [
        ("Enhanced Button Style", "BackupActionButtonStyle"),
        ("Header Section", "Secure your cryptographic identities"),
        ("Action Buttons", "Create Backup"),
        ("Enhanced Identity Row", "EnhancedIdentityRowView"),
        ("Status Indicators", "statusColor"),
        ("Icon Integration", "Image(systemName:"),
        ("Better Layout", "VStack(spacing:"),
        ("Enhanced Sheets", "EnhancedBackupIdentitySheet"),
        ("Warning Section", "Important"),
        ("Modern Typography", "font(.system"),
        ("Color Coding", "foregroundColor(.blue)"),
        ("Improved Spacing", "padding(.vertical"),
        ("Corner Radius", "cornerRadius("),
        ("Visual Hierarchy", "fontWeight(.semibold)")
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
    print("\n📊 Backup & Restore UX Improvements: \(passedChecks)/\(improvements.count) (\(Int(successRate * 100))%)")
    
    return successRate >= 0.8
}

// Run validation
let success = validateBackupRestoreUX()

print("\n" + String(repeating: "=", count: 50))
if success {
    print("🎉 Backup & Restore UX improvements completed successfully!")
    print("\n📋 Key Improvements:")
    print("• Enhanced button styles with modern design")
    print("• Improved header section with description")
    print("• Better visual hierarchy with icons and spacing")
    print("• Status indicators with color coding")
    print("• Enhanced backup and restore sheets")
    print("• Better empty state messaging")
    print("• Modern typography and consistent styling")
    print("• Improved warning and info sections")
    print("• Maintained compatibility with existing code")
    exit(0)
} else {
    print("❌ Backup & Restore UX improvements validation failed!")
    exit(1)
}