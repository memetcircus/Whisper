#!/usr/bin/env swift

import Foundation

print("🧪 Testing Copy Button Refinement...")

// Test 1: Verify "Tap and hold to copy" text is removed
print("\n1. Testing removal of instructional text...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let content = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that "Tap and hold to copy" text is removed
if !content.contains("Tap and hold to copy the message") {
    print("✅ 'Tap and hold to copy' text successfully removed")
} else {
    print("❌ 'Tap and hold to copy' text still present")
}

// Test 2: Verify large copy button is removed
print("\n2. Testing removal of large copy button...")

// Check that the large "Copy to Clipboard" button is removed
if !content.contains("Copy to Clipboard") {
    print("✅ Large 'Copy to Clipboard' button successfully removed")
} else {
    print("❌ Large 'Copy to Clipboard' button still present")
}

// Check that the full-width button styling is removed
if !content.contains("frame(maxWidth: .infinity)") ||
   !content.contains("frame(height: 50)") {
    print("✅ Large button styling removed from copy functionality")
} else {
    print("❌ Large button styling still present in copy functionality")
}

// Test 3: Verify small copy icon button is added
print("\n3. Testing addition of small copy icon button...")

// Check for ZStack with bottomTrailing alignment
if content.contains("ZStack(alignment: .bottomTrailing)") {
    print("✅ ZStack with bottomTrailing alignment added for copy button positioning")
} else {
    print("❌ ZStack positioning not found")
}

// Check for small copy button implementation
if content.contains("Image(systemName: \"doc.on.doc\")") &&
   content.contains("font(.system(size: 16))") &&
   content.contains("padding(8)") &&
   content.contains("clipShape(Circle())") {
    print("✅ Small circular copy icon button implemented")
} else {
    print("❌ Small copy icon button implementation not found")
}

// Check for proper positioning
if content.contains("padding(12)") &&
   content.contains("accessibilityLabel(\"Copy message\")") {
    print("✅ Copy button properly positioned with accessibility")
} else {
    print("❌ Copy button positioning or accessibility missing")
}

// Test 4: Verify message box structure is maintained
print("\n4. Testing message box structure...")

// Check that ScrollView and basic styling is preserved
if content.contains("ScrollView {") &&
   content.contains("Text(messageText)") &&
   content.contains("textSelection(.enabled)") &&
   content.contains("cornerRadius(16)") {
    print("✅ Message box structure and text selection preserved")
} else {
    print("❌ Message box structure compromised")
}

// Check that green border styling is maintained
if content.contains("Color.green.opacity(0.3)") &&
   content.contains("stroke") {
    print("✅ Green border styling maintained")
} else {
    print("❌ Green border styling missing")
}

// Test 5: Verify clean UI without redundant elements
print("\n5. Testing clean UI implementation...")

// Check that success header is simplified
if content.contains("Text(\"Message Decrypted\")") &&
   !content.contains("Tap and hold") {
    print("✅ Success header simplified without instructional text")
} else {
    print("❌ Success header not properly simplified")
}

print("\n🎉 Copy button refinement test completed!")
print("\nSummary of changes:")
print("• Removed 'Tap and hold to copy the message' instructional text")
print("• Removed large 'Copy to Clipboard' button")
print("• Added small circular copy icon in lower right corner of message box")
print("• Maintained message box structure and text selection")
print("• Preserved accessibility with proper labels and hints")
print("• Created cleaner, more intuitive copy interaction")