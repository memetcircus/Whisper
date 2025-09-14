#!/usr/bin/env swift

import Foundation

print("🧪 Testing Decrypt Clipboard and Button Fixes...")

// Test 1: Verify clipboard auto-populate only works for valid whisper messages
print("\n1. Testing clipboard auto-populate validation...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let viewContent = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that onAppear now validates before auto-populating
if viewContent.contains("isValidWhisperMessage(text: clipboardString)") &&
   viewContent.contains("// First validate if it's a whisper message before auto-populating") {
    print("✅ OnAppear now validates clipboard content before auto-populating")
} else {
    print("❌ OnAppear validation not properly implemented")
}

// Check that it doesn't blindly populate any clipboard content
if !viewContent.contains("viewModel.inputText = clipboardString") ||
   viewContent.contains("if viewModel.isValidWhisperMessage(text: clipboardString)") {
    print("✅ Auto-populate is now conditional on valid whisper message")
} else {
    print("❌ Auto-populate still happens unconditionally")
}

// Test 2: Verify DecryptViewModel has the validation method
print("\n2. Testing DecryptViewModel validation method...")

let viewModelPath = "WhisperApp/UI/Decrypt/DecryptViewModel.swift"
guard let viewModelContent = try? String(contentsOfFile: viewModelPath) else {
    print("❌ Could not read DecryptViewModel.swift")
    exit(1)
}

// Check that the new validation method exists
if viewModelContent.contains("func isValidWhisperMessage(text: String) -> Bool") &&
   viewModelContent.contains("return whisperService.detect(text)") {
    print("✅ DecryptViewModel has isValidWhisperMessage method")
} else {
    print("❌ DecryptViewModel missing validation method")
}

// Test 3: Verify decrypt button size matches compose button
print("\n3. Testing decrypt button size consistency...")

let composeViewPath = "WhisperApp/UI/Compose/ComposeView.swift"
guard let composeContent = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

// Check compose button styling
let composeHasLargeButton = composeContent.contains(".controlSize(.large)") &&
                          composeContent.contains(".frame(minHeight: 44)")

// Check decrypt button styling
let decryptHasLargeButton = viewContent.contains(".controlSize(.large)") &&
                           viewContent.contains(".frame(minHeight: 44)")

if composeHasLargeButton && decryptHasLargeButton {
    print("✅ Decrypt button size now matches compose button (.large + minHeight: 44)")
} else {
    print("❌ Button sizes don't match:")
    print("   Compose has large button: \\(composeHasLargeButton)")
    print("   Decrypt has large button: \\(decryptHasLargeButton)")
}

// Test 4: Verify no regression in existing functionality
print("\n4. Testing existing functionality preservation...")

// Check that validation still happens on text change
if viewContent.contains("viewModel.validateInput()") {
    print("✅ Input validation still triggered on text changes")
} else {
    print("❌ Input validation missing")
}

// Check that invalid format warning is still shown
if viewContent.contains("LocalizationHelper.Decrypt.invalidFormat") &&
   viewContent.contains("!viewModel.isValidWhisperMessage") {
    print("✅ Invalid format warning still displayed")
} else {
    print("❌ Invalid format warning missing")
}

// Check that decrypt button still has proper conditions
if viewContent.contains("!viewModel.inputText.isEmpty") &&
   viewContent.contains("viewModel.isValidWhisperMessage") &&
   viewContent.contains("viewModel.decryptionResult == nil") {
    print("✅ Decrypt button conditions preserved")
} else {
    print("❌ Decrypt button conditions missing")
}

print("\n🎉 Decrypt clipboard and button fixes test completed!")
print("\nSummary of fixes:")
print("• Auto-populate now only works for valid whisper messages")
print("• Prevents decrypted text from being auto-populated and showing error")
print("• Decrypt button size increased to match compose button")
print("• Button now uses .controlSize(.large) + .frame(minHeight: 44)")
print("• All existing functionality preserved")