#!/usr/bin/env swift

import Foundation

print("🧪 Testing Decrypt UI Improvements...")

// Test 1: Verify DecryptView structure changes
print("\n1. Testing DecryptView structure...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let decryptContent = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that input section is conditionally shown
if decryptContent.contains("if viewModel.decryptionResult == nil {") &&
   decryptContent.contains("manualInputSection") {
    print("✅ Input section is now conditionally displayed")
} else {
    print("❌ Input section conditional display not found")
}

// Check that Clear All button is removed
if !decryptContent.contains("Clear All") {
    print("✅ Clear All button successfully removed")
} else {
    print("❌ Clear All button still present")
}

// Check for modern copy button
if decryptContent.contains("Copy to Clipboard") &&
   decryptContent.contains("doc.on.doc") {
    print("✅ Modern copy button implemented")
} else {
    print("❌ Modern copy button not found")
}

// Check for success header
if decryptContent.contains("Message Decrypted") &&
   decryptContent.contains("checkmark.circle.fill") {
    print("✅ Success header with icon added")
} else {
    print("❌ Success header not found")
}

// Check for context menu and double tap
if decryptContent.contains("contextMenu") &&
   decryptContent.contains("onTapGesture(count: 2)") {
    print("✅ Context menu and double-tap copy functionality added")
} else {
    print("❌ Advanced copy interactions not found")
}

// Check for UIKit import
if decryptContent.contains("import UIKit") {
    print("✅ UIKit import added for UIPasteboard")
} else {
    print("❌ UIKit import missing")
}

// Test 2: Verify DecryptErrorView improvements
print("\n2. Testing DecryptErrorView improvements...")

let errorViewPath = "WhisperApp/UI/Decrypt/DecryptErrorView.swift"
guard let errorContent = try? String(contentsOfFile: errorViewPath) else {
    print("❌ Could not read DecryptErrorView.swift")
    exit(1)
}

// Check that Try Again button is removed
if !errorContent.contains("Try Again") {
    print("✅ Try Again button successfully removed")
} else {
    print("❌ Try Again button still present")
}

// Check for improved error messages
if errorContent.contains("This message has already been opened once before") &&
   errorContent.contains("Make sure you've copied the complete message text") {
    print("✅ User-friendly error messages implemented")
} else {
    print("❌ Improved error messages not found")
}

// Check that only OK button remains
if errorContent.contains("Button(\"OK\")") &&
   errorContent.contains(".buttonStyle(.borderedProminent)") {
    print("✅ Single OK button with prominent style")
} else {
    print("❌ OK button styling not found")
}

print("\n🎉 Decrypt UI improvements test completed!")
print("\nSummary of changes:")
print("• Input section hidden after successful decryption")
print("• Clear All button removed")
print("• Modern copy button with icon")
print("• Success header with checkmark icon")
print("• Context menu and double-tap copy")
print("• Try Again button removed from errors")
print("• More user-friendly error messages")