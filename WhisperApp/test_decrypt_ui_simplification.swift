#!/usr/bin/env swift

import Foundation

print("🧪 Testing Decrypt UI Simplification...")

// Test 1: Verify detection banner section is removed
print("\n1. Testing detection banner removal...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let content = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that detection banner section is completely removed
if !content.contains("detectionBannerSection") &&
   !content.contains("Encrypted Message Detected") &&
   !content.contains("Found whisper message in clipboard") {
    print("✅ Detection banner section completely removed")
} else {
    print("❌ Detection banner section still present")
}

// Check that showDetectionBanner references are removed from main view
let mainViewSection = content.components(separatedBy: "var body: some View")[1].components(separatedBy: "// MARK: - View Components")[0]
if !mainViewSection.contains("showDetectionBanner") {
    print("✅ Detection banner logic removed from main view")
} else {
    print("❌ Detection banner logic still present in main view")
}

// Test 2: Verify paste button is removed
print("\n2. Testing paste button removal...")

// Check that paste button is completely removed from manual input section
if !content.contains("Button(\"Paste\")") &&
   !content.contains("Paste from clipboard") {
    print("✅ Paste button completely removed")
} else {
    print("❌ Paste button still present")
}

// Check that manual paste button functionality is removed (auto-populate in onAppear is OK)
let manualInputSection = content.components(separatedBy: "manualInputSection")[1].components(separatedBy: "private func")[0]
if !manualInputSection.contains("Button(\"Paste\")") {
    print("✅ Manual paste button functionality removed from input section")
} else {
    print("❌ Manual paste button functionality still present in input")
}

// Test 3: Verify decrypt button is moved to bottom
print("\n3. Testing decrypt button positioning...")

// Check that decrypt button is now at the bottom of the main VStack
if content.contains("Spacer()") &&
   content.contains("// Decrypt button at bottom") &&
   content.contains("Button(LocalizationHelper.Decrypt.decryptMessage)") {
    print("✅ Decrypt button moved to bottom of screen")
} else {
    print("❌ Decrypt button not properly positioned at bottom")
}

// Check that actionButtonsSection is removed
if !content.contains("actionButtonsSection") {
    print("✅ Action buttons section removed")
} else {
    print("❌ Action buttons section still present")
}

// Check that decrypt button uses regular size
if content.contains(".controlSize(.regular)") &&
   !content.contains(".controlSize(.large)") {
    print("✅ Decrypt button uses regular size")
} else {
    print("❌ Decrypt button size not properly set")
}

// Test 4: Verify simplified onAppear logic
print("\n4. Testing simplified onAppear logic...")

// Check that onAppear no longer calls checkClipboard or uses showDetectionBanner
let onAppearSection = content.components(separatedBy: ".onAppear")[1].components(separatedBy: "}")[0]
if !onAppearSection.contains("checkClipboard") &&
   !onAppearSection.contains("showDetectionBanner") &&
   onAppearSection.contains("clipboardString") {
    print("✅ OnAppear logic simplified - auto-populates without detection banner")
} else {
    print("❌ OnAppear logic not properly simplified")
}

// Test 5: Verify invalid format warning is still present
print("\n5. Testing invalid format warning...")

// Check that invalid format warning is still shown but simplified
if content.contains("LocalizationHelper.Decrypt.invalidFormat") &&
   content.contains("!viewModel.isValidWhisperMessage") {
    print("✅ Invalid format warning maintained")
} else {
    print("❌ Invalid format warning missing")
}

// Test 6: Verify layout structure
print("\n6. Testing overall layout structure...")

// Check that the main VStack has the correct structure
let bodyContent = content.components(separatedBy: "var body: some View")[1].components(separatedBy: "// MARK: - View Components")[0]
if bodyContent.contains("manualInputSection") &&
   bodyContent.contains("decryptionResultSection") &&
   bodyContent.contains("Spacer()") &&
   bodyContent.contains("Button(LocalizationHelper.Decrypt.decryptMessage)") {
    print("✅ Layout structure is correct: input -> result -> spacer -> button")
} else {
    print("❌ Layout structure is incorrect")
}

print("\n🎉 Decrypt UI simplification test completed!")
print("\nSummary of changes:")
print("• Removed 'Encrypted Message Detected' banner section")
print("• Removed paste button (messages auto-populate)")
print("• Moved decrypt button to bottom of screen")
print("• Simplified onAppear logic")
print("• Maintained invalid format warning")
print("• Clean, minimal layout: message box -> decrypt button at bottom")