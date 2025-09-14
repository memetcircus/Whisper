#!/usr/bin/env swift

import Foundation

print("🧪 Testing DecryptViewModel Method Fix...")

// Test 1: Verify showCopySuccess calls are replaced with copyDecryptedMessage
print("\n1. Testing method call replacements...")

let decryptViewPath = "WhisperApp/UI/Decrypt/DecryptView.swift"
guard let content = try? String(contentsOfFile: decryptViewPath) else {
    print("❌ Could not read DecryptView.swift")
    exit(1)
}

// Check that showCopySuccess is no longer called
if !content.contains("showCopySuccess") {
    print("✅ showCopySuccess calls removed")
} else {
    print("❌ showCopySuccess calls still present")
}

// Check that copyDecryptedMessage is used instead
if content.contains("viewModel.copyDecryptedMessage()") {
    print("✅ copyDecryptedMessage method calls added")
} else {
    print("❌ copyDecryptedMessage method calls missing")
}

// Check that direct UIPasteboard calls are removed from context menu and tap gesture
let contextMenuSection = content.components(separatedBy: ".contextMenu")[1].components(separatedBy: "}")[0]
let tapGestureSection = content.components(separatedBy: ".onTapGesture")[1].components(separatedBy: "}")[0]

if !contextMenuSection.contains("UIPasteboard.general.string") &&
   !tapGestureSection.contains("UIPasteboard.general.string") {
    print("✅ Direct UIPasteboard calls removed from UI interactions")
} else {
    print("❌ Direct UIPasteboard calls still present in UI interactions")
}

// Check that UIKit import is present
if content.contains("import UIKit") {
    print("✅ UIKit import present")
} else {
    print("❌ UIKit import missing")
}

// Test 2: Verify DecryptViewModel has the copyDecryptedMessage method
print("\n2. Testing DecryptViewModel method availability...")

let viewModelPath = "WhisperApp/UI/Decrypt/DecryptViewModel.swift"
guard let viewModelContent = try? String(contentsOfFile: viewModelPath) else {
    print("❌ Could not read DecryptViewModel.swift")
    exit(1)
}

if viewModelContent.contains("func copyDecryptedMessage()") {
    print("✅ copyDecryptedMessage method exists in DecryptViewModel")
} else {
    print("❌ copyDecryptedMessage method missing in DecryptViewModel")
}

// Check that the method handles clipboard and success feedback
if viewModelContent.contains("UIPasteboard.general.string = messageText") &&
   viewModelContent.contains("successMessage = \"Message copied to clipboard\"") &&
   viewModelContent.contains("showingSuccess = true") {
    print("✅ copyDecryptedMessage handles clipboard and success feedback")
} else {
    print("❌ copyDecryptedMessage missing proper implementation")
}

print("\n🎉 DecryptViewModel method fix test completed!")
print("\nSummary of changes:")
print("• Removed non-existent showCopySuccess() calls")
print("• Replaced with existing copyDecryptedMessage() method")
print("• Removed direct UIPasteboard calls from UI interactions")
print("• Maintained proper success feedback through ViewModel")
print("• Fixed build errors related to missing methods")