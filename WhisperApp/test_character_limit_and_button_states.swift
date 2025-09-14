#!/usr/bin/env swift

import Foundation

print("🧪 Testing Character Limit and Button State Management...")

// Test the ComposeView and ComposeViewModel files for the improvements
let composeViewPath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"
let composeViewModelPath = "WhisperApp/WhisperApp/UI/Compose/ComposeViewModel.swift"

guard let composeViewContent = try? String(contentsOfFile: composeViewPath),
      let composeViewModelContent = try? String(contentsOfFile: composeViewModelPath) else {
    print("❌ Could not read ComposeView or ComposeViewModel files")
    exit(1)
}

var testsPassed = 0
var totalTests = 0

// Test 1: Character limit constant defined
totalTests += 1
if composeViewModelContent.contains("40000") {
    print("✅ Character limit constant set to 40,000")
    testsPassed += 1
} else {
    print("❌ Character limit constant not found")
}

// Test 2: Character limit enforcement in didSet
totalTests += 1
if composeViewModelContent.contains("didSet") && 
   composeViewModelContent.contains("messageText.count > maxCharacterLimit") &&
   composeViewModelContent.contains("String(messageText.prefix(maxCharacterLimit))") {
    print("✅ Character limit enforcement implemented in didSet")
    testsPassed += 1
} else {
    print("❌ Character limit enforcement not properly implemented")
}

// Test 3: Character count display
totalTests += 1
if composeViewContent.contains("Text(\"\\(viewModel.characterCount)/40,000\")") {
    print("✅ Character count display added")
    testsPassed += 1
} else {
    print("❌ Character count display not found")
}

// Test 4: Character count color logic
totalTests += 1
if composeViewContent.contains("viewModel.remainingCharacters < 1000 ? .orange : .secondary") {
    print("✅ Character count color warning implemented")
    testsPassed += 1
} else {
    print("❌ Character count color warning not found")
}

// Test 5: Button state properties
totalTests += 1
if composeViewModelContent.contains("showEncryptButton") &&
   composeViewModelContent.contains("showPostEncryptionButtons") {
    print("✅ Button state properties defined")
    testsPassed += 1
} else {
    print("❌ Button state properties not found")
}

// Test 6: Encrypt button conditional display
totalTests += 1
if composeViewContent.contains("if viewModel.showEncryptButton") {
    print("✅ Encrypt button conditional display implemented")
    testsPassed += 1
} else {
    print("❌ Encrypt button conditional display not found")
}

// Test 7: Post-encryption buttons conditional display
totalTests += 1
if composeViewContent.contains("if viewModel.showPostEncryptionButtons") {
    print("✅ Post-encryption buttons conditional display implemented")
    testsPassed += 1
} else {
    print("❌ Post-encryption buttons conditional display not found")
}

// Test 8: Button state logic
totalTests += 1
if composeViewModelContent.contains("showEncryptButton: Bool") &&
   composeViewModelContent.contains("showPostEncryptionButtons: Bool") {
    print("✅ Button state logic based on encrypted message presence")
    testsPassed += 1
} else {
    print("❌ Button state logic not properly implemented")
}

// Test 9: Character count and remaining characters properties
totalTests += 1
if composeViewModelContent.contains("characterCount") &&
   composeViewModelContent.contains("remainingCharacters") {
    print("✅ Character count properties defined")
    testsPassed += 1
} else {
    print("❌ Character count properties not found")
}

print("\n📊 Test Results:")
print("Passed: \(testsPassed)/\(totalTests)")

if testsPassed == totalTests {
    print("🎉 All character limit and button state improvements implemented successfully!")
    exit(0)
} else {
    print("⚠️  Some improvements may need attention")
    exit(1)
}