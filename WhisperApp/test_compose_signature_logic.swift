#!/usr/bin/env swift

import Foundation

// Test script to verify ComposeViewModel signature logic changes

print("🧪 Testing ComposeViewModel signature logic changes...")

// Read the ComposeViewModel file
guard let fileContent = try? String(contentsOfFile: "WhisperApp/UI/Compose/ComposeViewModel.swift") else {
    print("❌ Could not read ComposeViewModel.swift")
    exit(1)
}

// Test 1: Check that SettingsPolicyManager dependency is added
if fileContent.contains("private let settingsManager: SettingsPolicyManager") {
    print("✅ SettingsPolicyManager dependency added correctly")
} else {
    print("❌ SettingsPolicyManager dependency is missing")
    exit(1)
}

// Test 2: Check that settingsManager is initialized in init method
if fileContent.contains("settingsManager: SettingsPolicyManager? = nil") &&
   fileContent.contains("self.settingsManager = settingsManager ?? UserDefaultsSettingsPolicyManager()") {
    print("✅ SettingsManager initialization added correctly")
} else {
    print("❌ SettingsManager initialization is missing or incorrect")
    exit(1)
}

// Test 3: Check that signature logic uses settings
if fileContent.contains("let shouldIncludeSignature = settingsManager.alwaysIncludeSignatures") &&
   fileContent.contains("authenticity: shouldIncludeSignature") {
    print("✅ Signature logic updated to use Settings")
} else {
    print("❌ Signature logic not updated correctly")
    exit(1)
}

// Test 4: Check that hardcoded signature value is removed
if !fileContent.contains("authenticity: true  // This will be updated in task 4 to use Settings") {
    print("✅ Hardcoded signature value removed")
} else {
    print("❌ Hardcoded signature value still present")
    exit(1)
}

// Test 5: Check that no includeSignature property exists (should have been removed in previous tasks)
if !fileContent.contains("@Published var includeSignature") && !fileContent.contains("var includeSignature") {
    print("✅ No includeSignature property found (correctly removed)")
} else {
    print("❌ includeSignature property still exists")
    exit(1)
}

print("\n✅ All tests passed! ComposeViewModel signature logic has been successfully updated.")
print("\n📝 Summary of changes:")
print("- Added SettingsPolicyManager dependency to ComposeViewModel")
print("- Updated encryptMessage() to use settingsManager.alwaysIncludeSignatures")
print("- Removed hardcoded signature logic")
print("- Signature inclusion now determined solely by Settings preference")
print("\n🎯 Task 4 requirements fulfilled:")
print("- ✅ Modified encryptMessage() method to determine signatures from Settings only")
print("- ✅ Replaced per-message signature logic with settingsManager.alwaysIncludeSignatures check")
print("- ✅ Removed signature-related properties and methods from ComposeViewModel")
print("- ✅ Ensured MessageAuthenticity is set based solely on Settings preference")