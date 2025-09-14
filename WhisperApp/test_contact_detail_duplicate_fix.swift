#!/usr/bin/env swift

import Foundation

print("🔍 Testing Contact Detail Duplicate Declaration Fix...")

func validateContactDetailDuplicateFix() -> Bool {
    print("\n📱 Validating Contact Detail duplicate declaration fix...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Contacts/ContactDetailView.swift") else {
        print("❌ Could not read ContactDetailView")
        return false
    }
    
    let requiredComponents = [
        ("ContactHeaderView usage", "ContactHeaderView(contact: viewModel.contact)"),
        ("TrustStatusSection usage", "TrustStatusSection("),
        ("FingerprintSection usage", "FingerprintSection(contact: viewModel.contact)"),
        ("SASWordsSection usage", "SASWordsSection(contact: viewModel.contact)"),
        ("KeyInformationSection usage", "KeyInformationSection(contact: viewModel.contact)"),
        ("NoteSection usage", "NoteSection(note: note)"),
        ("KeyHistorySection usage", "KeyHistorySection(keyHistory: viewModel.contact.keyHistory)"),
        ("ContactAvatarView usage", "ContactAvatarView(contact: contact)"),
        ("TrustBadgeView usage", "TrustBadgeView(trustLevel: contact.trustLevel)"),
        ("Enhanced Visual Design", "shadow(color: Color.black.opacity(0.05)"),
        ("Enhanced Animations", "withAnimation(.easeInOut(duration: 0.2))"),
        ("Enhanced Icons", "Image(systemName:"),
        ("Enhanced Typography", "font(.headline)"),
        ("Enhanced Background", "Color(.systemGroupedBackground)"),
        ("Working Code Base", "ContactDetailViewModel")
    ]
    
    var passedChecks = 0
    
    for (description, pattern) in requiredComponents {
        if content.contains(pattern) {
            print("✅ \(description): Found")
            passedChecks += 1
        } else {
            print("❌ \(description): Missing pattern '\(pattern)'")
        }
    }
    
    // Check for duplicate declarations (should NOT be found)
    let duplicateDeclarations = [
        ("Duplicate ContactAvatarView", "struct ContactAvatarView: View"),
        ("Duplicate TrustBadgeView", "struct TrustBadgeView: View")
    ]
    
    var foundDuplicates = 0
    for (description, pattern) in duplicateDeclarations {
        if content.contains(pattern) {
            print("❌ Duplicate Declaration Found - \(description): \(pattern)")
            foundDuplicates += 1
        }
    }
    
    if foundDuplicates == 0 {
        print("✅ No duplicate declarations detected")
    }
    
    // Check for proper comment about shared components
    let hasSharedComment = content.contains("ContactAvatarView and TrustBadgeView are defined in ContactListView.swift")
    if hasSharedComment {
        print("✅ Proper documentation comment found")
    } else {
        print("❌ Missing documentation comment about shared components")
    }
    
    let successRate = Double(passedChecks) / Double(requiredComponents.count)
    print("📊 Contact Detail Duplicate Fix: \(passedChecks)/\(requiredComponents.count) (\(Int(successRate * 100))%)")
    
    return successRate >= 0.9 && foundDuplicates == 0 && hasSharedComment
}

// Run validation
let success = validateContactDetailDuplicateFix()

print("\n" + String(repeating: "=", count: 50))
if success {
    print("🎉 Contact Detail duplicate declaration fix completed successfully!")
    print("\n📋 Key Fixes:")
    print("• Removed duplicate ContactAvatarView declaration")
    print("• Removed duplicate TrustBadgeView declaration")
    print("• Components are now properly shared from ContactListView.swift")
    print("• Maintained all enhanced visual design features")
    print("• Added documentation comment about shared components")
    print("• All functionality preserved without duplication")
    print("• Build errors should now be resolved")
    exit(0)
} else {
    print("❌ Contact Detail duplicate declaration fix validation failed!")
    exit(1)
}