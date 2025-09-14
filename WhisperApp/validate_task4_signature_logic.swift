#!/usr/bin/env swift

import Foundation

// Validation script for Task 4: Update ComposeViewModel to Use Settings-Based Signature Logic

print("🔍 Validating Task 4 Implementation...")
print("Task: Update ComposeViewModel to Use Settings-Based Signature Logic")
print("Requirements: 1.3, 2.5, 3.4")

// Read the ComposeViewModel file
guard let fileContent = try? String(contentsOfFile: "WhisperApp/UI/Compose/ComposeViewModel.swift") else {
    print("❌ Could not read ComposeViewModel.swift")
    exit(1)
}

var allTestsPassed = true

// Task Requirement 1: Modify encryptMessage() method to determine signatures from Settings only
print("\n📋 Validating: Modify encryptMessage() method to determine signatures from Settings only")
if fileContent.contains("let shouldIncludeSignature = settingsManager.alwaysIncludeSignatures") &&
   fileContent.contains("authenticity: shouldIncludeSignature") {
    print("✅ encryptMessage() now determines signatures from Settings only")
} else {
    print("❌ encryptMessage() does not use Settings for signature determination")
    allTestsPassed = false
}

// Task Requirement 2: Replace per-message signature logic with settingsManager.alwaysIncludeSignatures check
print("\n📋 Validating: Replace per-message signature logic with settingsManager.alwaysIncludeSignatures check")
if fileContent.contains("settingsManager.alwaysIncludeSignatures") &&
   !fileContent.contains("authenticity: true  // This will be updated in task 4 to use Settings") {
    print("✅ Per-message signature logic replaced with Settings check")
} else {
    print("❌ Per-message signature logic not properly replaced")
    allTestsPassed = false
}

// Task Requirement 3: Remove signature-related properties and methods from ComposeViewModel
print("\n📋 Validating: Remove signature-related properties and methods from ComposeViewModel")
let hasIncludeSignatureProperty = fileContent.contains("@Published var includeSignature") || 
                                  fileContent.contains("var includeSignature:")
let hasSignatureToggleMethods = fileContent.contains("func toggleSignature") ||
                               fileContent.contains("func setSignature")

if !hasIncludeSignatureProperty && !hasSignatureToggleMethods {
    print("✅ No signature-related properties or methods found")
} else {
    print("❌ Signature-related properties or methods still exist")
    allTestsPassed = false
}

// Task Requirement 4: Ensure MessageAuthenticity is set based solely on Settings preference
print("\n📋 Validating: Ensure MessageAuthenticity is set based solely on Settings preference")
if fileContent.contains("let shouldIncludeSignature = settingsManager.alwaysIncludeSignatures") &&
   fileContent.contains("authenticity: shouldIncludeSignature") &&
   !fileContent.contains("authenticity: true") &&
   !fileContent.contains("authenticity: false") {
    print("✅ MessageAuthenticity is set based solely on Settings preference")
} else {
    print("❌ MessageAuthenticity is not properly based on Settings preference")
    allTestsPassed = false
}

// Spec Requirements Validation
print("\n📋 Validating Spec Requirements:")

// Requirement 1.3: Signature inclusion determined by Settings policies without per-message input
print("\n🎯 Requirement 1.3: Signature inclusion determined by Settings policies without per-message input")
if fileContent.contains("settingsManager.alwaysIncludeSignatures") &&
   !fileContent.contains("includeSignature") {
    print("✅ Signature inclusion determined by Settings without per-message input")
} else {
    print("❌ Signature inclusion still requires per-message input")
    allTestsPassed = false
}

// Requirement 2.5: Setting applies to all future messages regardless of recipient type
print("\n🎯 Requirement 2.5: Setting applies to all future messages regardless of recipient type")
if fileContent.contains("let shouldIncludeSignature = settingsManager.alwaysIncludeSignatures") &&
   fileContent.contains("authenticity: shouldIncludeSignature") {
    print("✅ Setting applies to all messages through consistent Settings check")
} else {
    print("❌ Setting does not consistently apply to all messages")
    allTestsPassed = false
}

// Requirement 3.4: Signature inclusion determined solely by Settings preference
print("\n🎯 Requirement 3.4: Signature inclusion determined solely by Settings preference")
let hasOnlySettingsLogic = fileContent.contains("settingsManager.alwaysIncludeSignatures") &&
                          !fileContent.contains("includeSignature") &&
                          !fileContent.contains("authenticity: true") &&
                          !fileContent.contains("authenticity: false")

if hasOnlySettingsLogic {
    print("✅ Signature inclusion determined solely by Settings preference")
} else {
    print("❌ Signature inclusion not solely determined by Settings")
    allTestsPassed = false
}

// Dependencies Check
print("\n📋 Validating Dependencies:")
if fileContent.contains("private let settingsManager: SettingsPolicyManager") {
    print("✅ SettingsPolicyManager dependency added")
} else {
    print("❌ SettingsPolicyManager dependency missing")
    allTestsPassed = false
}

if fileContent.contains("self.settingsManager = settingsManager ?? UserDefaultsSettingsPolicyManager()") {
    print("✅ SettingsManager properly initialized")
} else {
    print("❌ SettingsManager not properly initialized")
    allTestsPassed = false
}

// Final Result
print("\n" + String(repeating: "=", count: 60))
if allTestsPassed {
    print("✅ TASK 4 VALIDATION SUCCESSFUL")
    print("\n🎉 All requirements have been successfully implemented:")
    print("- ✅ encryptMessage() modified to determine signatures from Settings only")
    print("- ✅ Per-message signature logic replaced with settingsManager.alwaysIncludeSignatures")
    print("- ✅ Signature-related properties and methods removed from ComposeViewModel")
    print("- ✅ MessageAuthenticity set based solely on Settings preference")
    print("\n🎯 Spec Requirements Fulfilled:")
    print("- ✅ Requirement 1.3: Signature inclusion by Settings without per-message input")
    print("- ✅ Requirement 2.5: Setting applies to all future messages")
    print("- ✅ Requirement 3.4: Signature inclusion solely by Settings preference")
    print("\n🔧 Implementation Details:")
    print("- Added SettingsPolicyManager dependency to ComposeViewModel")
    print("- Updated encryptMessage() to read alwaysIncludeSignatures from Settings")
    print("- Removed hardcoded signature values")
    print("- Ensured consistent Settings-based behavior for all messages")
} else {
    print("❌ TASK 4 VALIDATION FAILED")
    print("Some requirements are not properly implemented. Please review the issues above.")
    exit(1)
}
print(String(repeating: "=", count: 60))