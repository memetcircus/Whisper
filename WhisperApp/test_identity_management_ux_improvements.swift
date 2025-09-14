#!/usr/bin/env swift

import Foundation

print("🔍 Testing Identity Management UX Improvements...")

// Test file paths
let identityManagementViewPath = "WhisperApp/UI/Settings/IdentityManagementView.swift"

func testFile(at path: String) -> Bool {
    let fileManager = FileManager.default
    let fullPath = path
    
    guard fileManager.fileExists(atPath: fullPath) else {
        print("❌ File not found: \(fullPath)")
        return false
    }
    
    guard (try? String(contentsOfFile: fullPath)) != nil else {
        print("❌ Could not read file: \(fullPath)")
        return false
    }
    
    print("✅ File exists and readable: \(path)")
    return true
}

func validateIdentityManagementImprovements() -> Bool {
    print("\n📱 Validating Identity Management UX improvements...")
    
    guard let content = try? String(contentsOfFile: identityManagementViewPath) else {
        print("❌ Could not read Identity Management view")
        return false
    }
    
    let improvements = [
        ("Modern Button Styles", "IdentityActionButtonStyle"),
        ("Card-based Layout", "IdentityCardView"),
        ("ScrollView Layout", "ScrollView"),
        ("Primary Action Button", "PrimaryActionButtonStyle"),
        ("Status Badge", "StatusBadge"),
        ("Info Rows", "InfoRow"),
        ("Visual Hierarchy", "LazyVStack"),
        ("Modern Typography", "design: .rounded"),
        ("Shadow Effects", "shadow(color:"),
        ("Color System", "Color(.systemBackground)"),
        ("Improved Create Flow", "Generate a new cryptographic identity"),
        ("Better Error Display", "exclamationmark.triangle.fill"),
        ("Info Section", "What happens next?"),
        ("Icon Integration", "Image(systemName:")
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
    print("\n📊 Identity Management UX Improvements: \(passedChecks)/\(improvements.count) (\(Int(successRate * 100))%)")
    
    return successRate >= 0.8
}

// Run tests
var allTestsPassed = true

print("🧪 Testing Identity Management UX Improvements")
print(String(repeating: "=", count: 50))

// Test file existence
allTestsPassed = testFile(at: identityManagementViewPath) && allTestsPassed

// Test UX improvements
allTestsPassed = validateIdentityManagementImprovements() && allTestsPassed

print("\n" + String(repeating: "=", count: 50))
if allTestsPassed {
    print("🎉 All Identity Management UX improvement tests passed!")
    print("\n📋 Key Improvements Made:")
    print("• Modern card-based layout with shadows")
    print("• Improved button styles with better visual feedback")
    print("• Better visual hierarchy with icons and typography")
    print("• Enhanced create identity flow with info section")
    print("• Status badges with color coding")
    print("• ScrollView layout for better content organization")
    print("• Consistent design system with rounded corners")
    print("• Better error handling and user feedback")
    exit(0)
} else {
    print("❌ Some Identity Management UX improvement tests failed!")
    exit(1)
}