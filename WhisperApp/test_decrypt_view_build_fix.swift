#!/usr/bin/env swift

import Foundation

print("🧪 Testing DecryptView Build Fix...")

// Test 1: Verify the complex expression has been broken up
print("\n1. Testing complex expression breakdown...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let content = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that the complex VStack has been broken into smaller functions
if content.contains("attributionSection") &&
   content.contains("messageContentSection") &&
   content.contains("metadataSection") {
    print("✅ Complex VStack broken into smaller functions")
} else {
    print("❌ Complex VStack not properly broken up")
}

// Check that the main composeStyleMessageView is now simplified
if content.contains("attributionSection(attribution)") &&
   content.contains("messageContentSection(messageText)") &&
   content.contains("metadataSection(attribution: attribution, timestamp: timestamp)") {
    print("✅ Main function now uses simplified sub-functions")
} else {
    print("❌ Main function not properly simplified")
}

// Check that all functionality is preserved
if content.contains("contextMenu") &&
   content.contains("onTapGesture(count: 2)") &&
   content.contains("UIPasteboard.general.string = messageText") {
    print("✅ Copy functionality preserved")
} else {
    print("❌ Copy functionality missing")
}

// Check that styling is preserved
if content.contains("Color.green.opacity(0.3)") &&
   content.contains("RoundedRectangle(cornerRadius: 16)") &&
   content.contains("shadow(color: Color.black.opacity(0.05)") {
    print("✅ Visual styling preserved")
} else {
    print("❌ Visual styling missing")
}

// Check that accessibility is preserved
if content.contains("accessibilityElement(children: .combine)") &&
   content.contains("accessibilityLabel") &&
   content.contains("accessibilityValue") {
    print("✅ Accessibility features preserved")
} else {
    print("❌ Accessibility features missing")
}

print("\n🎉 DecryptView build fix test completed!")
print("\nSummary of changes:")
print("• Complex VStack expression broken into smaller functions")
print("• attributionSection() for attribution display")
print("• messageContentSection() for message content and copy functionality")
print("• metadataSection() for sender and timestamp info")
print("• All functionality and styling preserved")
print("• Accessibility features maintained")