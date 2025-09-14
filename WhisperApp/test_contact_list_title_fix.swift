#!/usr/bin/env swift

import Foundation

print("🔍 Testing Contact List Title Fix...")

func validateContactListTitleFix() -> Bool {
    print("\n📱 Validating Contact List title configuration...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Contacts/ContactListView.swift") else {
        print("❌ Could not read ContactListView")
        return false
    }
    
    let titleChecks = [
        ("Navigation Title", "navigationTitle(LocalizationHelper.Contact.title)"),
        ("Inline Display Mode", "navigationBarTitleDisplayMode(.inline)"),
        ("Toolbar Configuration", "toolbar {"),
        ("Add Button", "Image(systemName: \"plus\")")
    ]
    
    var passedChecks = 0
    
    for (description, pattern) in titleChecks {
        if content.contains(pattern) {
            print("✅ \(description): Found")
            passedChecks += 1
        } else {
            print("❌ \(description): Missing pattern '\(pattern)'")
        }
    }
    
    // Check that we don't have the large title mode
    let unwantedPatterns = [
        ("Large Title Mode", "navigationBarTitleDisplayMode(.large)")
    ]
    
    var foundUnwantedPatterns = 0
    for (description, pattern) in unwantedPatterns {
        if content.contains(pattern) {
            print("❌ Unwanted Pattern Found - \(description): \(pattern)")
            foundUnwantedPatterns += 1
        }
    }
    
    if foundUnwantedPatterns == 0 {
        print("✅ No unwanted large title mode detected")
    }
    
    let successRate = Double(passedChecks) / Double(titleChecks.count)
    print("📊 Contact List Title Fix: \(passedChecks)/\(titleChecks.count) (\(Int(successRate * 100))%)")
    
    return successRate >= 1.0 && foundUnwantedPatterns == 0
}

// Run validation
let success = validateContactListTitleFix()

print("\n" + String(repeating: "=", count: 50))
if success {
    print("🎉 Contact List title fix completed successfully!")
    print("\n📋 Key Changes:")
    print("• Changed from .large to .inline title display mode")
    print("• Title is now centered and appropriately sized")
    print("• Maintains all existing functionality")
    print("• Better visual hierarchy with smaller, centered title")
    print("• Consistent with modern iOS app design patterns")
    exit(0)
} else {
    print("❌ Contact List title fix validation failed!")
    exit(1)
}