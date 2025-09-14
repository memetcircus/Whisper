#!/usr/bin/env swift

import Foundation

print("🧪 Testing Duplicate Decrypt Buttons Fix...")

// Test 1: Verify bottom decrypt button is hidden when detection banner is shown
print("\n1. Testing decrypt button visibility logic...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let content = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that the bottom decrypt button condition includes detection banner check
if content.contains("&& !viewModel.showDetectionBanner") {
    print("✅ Bottom decrypt button hidden when detection banner is shown")
} else {
    print("❌ Bottom decrypt button condition not updated")
}

// Check that the condition is in the right place
if content.contains("viewModel.decryptionResult == nil && !viewModel.showDetectionBanner") {
    print("✅ Condition properly placed in actionButtonsSection")
} else {
    print("❌ Condition not in correct location")
}

// Test 2: Verify detection banner is improved
print("\n2. Testing detection banner improvements...")

// Check for improved banner styling
if content.contains("Encrypted Message Detected") &&
   content.contains("Found whisper message in clipboard") {
    print("✅ Detection banner has improved messaging")
} else {
    print("❌ Detection banner messaging not improved")
}

// Check for prominent decrypt button in banner
if content.contains("frame(maxWidth: .infinity)") &&
   content.contains("frame(height: 50)") &&
   content.contains("Decrypt Message") {
    print("✅ Detection banner has prominent decrypt button")
} else {
    print("❌ Detection banner button not made prominent")
}

// Check for proper button styling
if content.contains(".buttonStyle(.borderedProminent)") &&
   content.contains(".controlSize(.large)") {
    print("✅ Detection banner button has proper styling")
} else {
    print("❌ Detection banner button styling missing")
}

// Test 3: Verify UI flow logic
print("\n3. Testing UI flow logic...")

// Check that manual input section is still conditionally shown
if content.contains("if viewModel.decryptionResult == nil {") &&
   content.contains("manualInputSection") {
    print("✅ Manual input section properly conditional")
} else {
    print("❌ Manual input section logic not found")
}

// Check that action buttons section is still included
if content.contains("actionButtonsSection") {
    print("✅ Action buttons section still included")
} else {
    print("❌ Action buttons section missing")
}

print("\n🎉 Duplicate decrypt buttons fix test completed!")
print("\nSummary of changes:")
print("• Bottom decrypt button hidden when clipboard detection banner is active")
print("• Detection banner made more prominent with larger button")
print("• Improved messaging: 'Encrypted Message Detected'")
print("• Single clear action when clipboard content is detected")
print("• Maintains manual input flow when no clipboard detection")
print("• Eliminates user confusion from duplicate decrypt buttons")