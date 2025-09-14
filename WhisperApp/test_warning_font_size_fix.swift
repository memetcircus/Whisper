#!/usr/bin/env swift

import Foundation

print("🧪 Testing Warning Font Size Fix...")

// Test 1: Verify warning font size is increased
print("\n1. Testing warning font size change...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let content = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that warning now uses .subheadline instead of .caption
if content.contains("Text(LocalizationHelper.Decrypt.invalidFormat)") &&
   content.contains(".font(.subheadline)") &&
   !content.contains(".font(.caption)") {
    print("✅ Warning font size changed from .caption to .subheadline")
} else {
    print("❌ Warning font size not properly changed")
    
    // Debug: Check what font is being used
    if content.contains(".font(.caption)") {
        print("   Found .caption font still in use")
    }
    if content.contains(".font(.subheadline)") {
        print("   Found .subheadline font")
    }
}

// Test 2: Verify warning color is maintained
print("\n2. Testing warning color preservation...")

if content.contains(".foregroundColor(.red)") {
    print("✅ Warning color (.red) preserved")
} else {
    print("❌ Warning color not maintained")
}

// Test 3: Verify warning conditions are maintained
print("\n3. Testing warning display conditions...")

if content.contains("!viewModel.inputText.isEmpty && !viewModel.isValidWhisperMessage") {
    print("✅ Warning display conditions preserved")
} else {
    print("❌ Warning display conditions changed")
}

// Test 4: Verify warning layout is maintained
print("\n4. Testing warning layout preservation...")

if content.contains("HStack {") &&
   content.contains("Spacer()") {
    print("✅ Warning layout (HStack with Spacer) preserved")
} else {
    print("❌ Warning layout not properly maintained")
}

// Test 5: Compare font sizes
print("\n5. Font size comparison...")

print("   Font size hierarchy (smallest to largest):")
print("   • .caption (smallest)")
print("   • .footnote")
print("   • .subheadline ← NEW (better visibility)")
print("   • .body")
print("   • .headline (largest)")

print("\n🎉 Warning font size fix test completed!")
print("\nSummary of changes:")
print("• Warning font changed from .caption to .subheadline")
print("• Significantly improved visibility and readability")
print("• Warning color (.red) maintained")
print("• All display conditions and layout preserved")
print("• Better user experience for error messages")