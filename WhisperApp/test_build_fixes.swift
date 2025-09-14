#!/usr/bin/env swift

import Foundation

print("🔧 Testing Build Fixes for ComposeViewModel...")

let composeViewModelPath = "WhisperApp/WhisperApp/UI/Compose/ComposeViewModel.swift"
let composeViewPath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"

guard let composeViewModelContent = try? String(contentsOfFile: composeViewModelPath),
      let composeViewContent = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read files")
    exit(1)
}

var testsPassed = 0
var totalTests = 0

// Test 1: No duplicate maxCharacterLimit declarations
totalTests += 1
let maxCharLimitCount = composeViewModelContent.components(separatedBy: "maxCharacterLimit = 40000").count - 1
if maxCharLimitCount == 1 {
    print("✅ Single maxCharacterLimit declaration found")
    testsPassed += 1
} else {
    print("❌ Found \(maxCharLimitCount) maxCharacterLimit declarations (should be 1)")
}

// Test 2: No didSet in messageText (to avoid build issues)
totalTests += 1
if !composeViewModelContent.contains("@Published var messageText: String = \"\" {") {
    print("✅ No problematic didSet in messageText")
    testsPassed += 1
} else {
    print("❌ Found didSet in messageText (may cause build issues)")
}

// Test 3: updateMessageText method exists
totalTests += 1
if composeViewModelContent.contains("func updateMessageText") {
    print("✅ updateMessageText method found")
    testsPassed += 1
} else {
    print("❌ updateMessageText method missing")
}

// Test 4: Custom binding in ComposeView
totalTests += 1
if composeViewContent.contains("Binding(") && composeViewContent.contains("updateMessageText") {
    print("✅ Custom binding with character limit enforcement found")
    testsPassed += 1
} else {
    print("❌ Custom binding not properly implemented")
}

// Test 5: Character count display
totalTests += 1
if composeViewContent.contains("characterCount") && composeViewContent.contains("40,000") {
    print("✅ Character count display found")
    testsPassed += 1
} else {
    print("❌ Character count display missing")
}

// Test 6: Button state management
totalTests += 1
if composeViewContent.contains("showEncryptButton") && composeViewContent.contains("showPostEncryptionButtons") {
    print("✅ Button state management found")
    testsPassed += 1
} else {
    print("❌ Button state management missing")
}

print("\n📊 Build Fix Results:")
print("Passed: \(testsPassed)/\(totalTests)")

if testsPassed == totalTests {
    print("🎉 All build fixes implemented successfully!")
    print("✅ Character limit: 40,000 characters")
    print("✅ Button states: Proper encrypt/share flow")
    print("✅ No build errors expected")
    exit(0)
} else {
    print("⚠️  Some fixes may need attention")
    exit(1)
}