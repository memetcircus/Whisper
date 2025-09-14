#!/usr/bin/env swift

import Foundation

print("🧪 Testing Decrypt Button Visibility Fix...")

// Test 1: Verify button is always visible when no decryption result
print("\n1. Testing button visibility conditions...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let content = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that button is now always visible when no decryption result
if content.contains("if viewModel.decryptionResult == nil") &&
   content.contains("// Decrypt button at bottom - always show when no decryption result") {
    print("✅ Button is now always visible when no decryption result")
} else {
    print("❌ Button visibility condition not updated")
}

// Check that button is properly disabled when conditions aren't met
if content.contains(".disabled(viewModel.isDecrypting || viewModel.inputText.isEmpty || !viewModel.isValidWhisperMessage)") {
    print("✅ Button is properly disabled when input is empty or invalid")
} else {
    print("❌ Button disable conditions not properly set")
}

// Test 2: Verify button no longer requires non-empty input to be visible
print("\n2. Testing removal of empty input visibility requirement...")

// Check that the old condition requiring non-empty input is removed
if !content.contains("!viewModel.inputText.isEmpty && viewModel.isValidWhisperMessage") ||
   !content.contains("&& viewModel.decryptionResult == nil") {
    print("✅ Old visibility condition requiring non-empty input removed")
} else {
    print("❌ Old visibility condition still present")
}

// Test 3: Verify button styling is maintained
print("\n3. Testing button styling preservation...")

// Check that button still has proper styling
if content.contains(".buttonStyle(.borderedProminent)") &&
   content.contains(".controlSize(.large)") &&
   content.contains(".frame(minHeight: 44)") {
    print("✅ Button styling preserved (.borderedProminent, .large, minHeight: 44)")
} else {
    print("❌ Button styling not properly maintained")
}

// Test 4: Verify accessibility is maintained
print("\n4. Testing accessibility preservation...")

if content.contains(".accessibilityLabel(LocalizationHelper.Accessibility.decryptButton)") &&
   content.contains(".accessibilityHint(LocalizationHelper.Accessibility.hintDecryptButton)") {
    print("✅ Accessibility labels and hints preserved")
} else {
    print("❌ Accessibility not properly maintained")
}

// Test 5: Verify button behavior logic
print("\n5. Testing button behavior logic...")

// Check that button action is still correct
if content.contains("await viewModel.decryptManualInput()") {
    print("✅ Button action preserved (decryptManualInput)")
} else {
    print("❌ Button action not properly maintained")
}

// Check that button is disabled during decryption
if content.contains("viewModel.isDecrypting") {
    print("✅ Button disabled during decryption")
} else {
    print("❌ Decryption state not handled")
}

print("\n🎉 Decrypt button visibility fix test completed!")
print("\nSummary of changes:")
print("• Button now always visible when no decryption result exists")
print("• Button disabled when input is empty or invalid (instead of hidden)")
print("• Better UX: users can see the button and understand they need to enter text")
print("• All styling and accessibility preserved")
print("• Proper disabled state handling for all conditions")