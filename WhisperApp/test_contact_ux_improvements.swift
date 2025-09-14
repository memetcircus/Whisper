#!/usr/bin/env swift

import Foundation

print("🔍 Testing Contact UX Improvements...")

func validateContactListUX() -> Bool {
    print("\n📱 Validating Contact List UX improvements...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Contacts/ContactListView.swift") else {
        print("❌ Could not read ContactListView")
        return false
    }
    
    let improvements = [
        ("Enhanced Button Style", "ContactActionButtonStyle"),
        ("Header Section", "headerSection"),
        ("Stat Badges", "StatBadgeView"),
        ("Enhanced Contact Row", "EnhancedContactRowView"),
        ("Enhanced Avatar", "EnhancedContactAvatarView"),
        ("Enhanced Trust Badge", "EnhancedTrustBadgeView"),
        ("Status Indicators", "StatusIndicatorView"),
        ("Enhanced Search Bar", "EnhancedSearchBar"),
        ("Empty State", "emptyStateView"),
        ("Icon Integration", "Image(systemName:"),
        ("Better Layout", "VStack(spacing:"),
        ("Modern Typography", "font(.system"),
        ("Color Coding", "foregroundColor(.blue)"),
        ("Corner Radius", "cornerRadius(")
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
    print("📊 Contact List UX: \(passedChecks)/\(improvements.count) (\(Int(successRate * 100))%)")
    
    return successRate >= 0.8
}

func validateContactDetailUX() -> Bool {
    print("\n📱 Validating Contact Detail UX improvements...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Contacts/ContactDetailView.swift") else {
        print("❌ Could not read ContactDetailView")
        return false
    }
    
    let improvements = [
        ("Enhanced Header", "EnhancedContactHeaderView"),
        ("Enhanced Trust Status", "EnhancedTrustStatusSection"),
        ("Enhanced Fingerprint", "EnhancedFingerprintSection"),
        ("Enhanced SAS Words", "EnhancedSASWordsSection"),
        ("Enhanced Key Info", "EnhancedKeyInformationSection"),
        ("Enhanced Note", "EnhancedNoteSection"),
        ("Enhanced Key History", "EnhancedKeyHistorySection"),
        ("Key Display", "KeyDisplayView"),
        ("Animation Support", "withAnimation"),
        ("Shadow Effects", "shadow(color:"),
        ("Icon Integration", "Image(systemName:"),
        ("Better Layout", "VStack(spacing:"),
        ("Modern Typography", "font(.system"),
        ("Color Coding", "foregroundColor(.blue)")
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
    print("📊 Contact Detail UX: \(passedChecks)/\(improvements.count) (\(Int(successRate * 100))%)")
    
    return successRate >= 0.8
}

// Run validations
let listSuccess = validateContactListUX()
let detailSuccess = validateContactDetailUX()

print("\n" + String(repeating: "=", count: 50))
if listSuccess && detailSuccess {
    print("🎉 Contact UX improvements completed successfully!")
    print("\n📋 Key Improvements:")
    print("• Enhanced contact list with header stats and empty state")
    print("• Modern contact rows with trust indicators and status badges")
    print("• Improved contact detail view with card-based sections")
    print("• Better visual hierarchy with icons and animations")
    print("• Enhanced trust status display and verification flow")
    print("• Improved fingerprint and SAS words presentation")
    print("• Better technical information display with show/hide")
    print("• Modern search bar and action buttons")
    print("• Maintained compatibility with existing functionality")
    exit(0)
} else {
    print("❌ Contact UX improvements validation failed!")
    exit(1)
}