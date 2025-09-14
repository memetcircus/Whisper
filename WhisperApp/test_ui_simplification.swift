#!/usr/bin/env swift

import Foundation

print("🔧 Testing UI Simplification...")

let composeViewPath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"
let qrDisplayPath = "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift"

guard let composeContent = try? String(contentsOfFile: composeViewPath),
      let qrContent = try? String(contentsOfFile: qrDisplayPath) else {
    print("❌ Could not read files")
    exit(1)
}

var testsPassed = 0
var totalTests = 0

// Test 1: QR Code button removed from ComposeView
totalTests += 1
if !composeContent.contains("LocalizationHelper.Encrypt.qrCode") {
    print("✅ QR Code button removed from ComposeView")
    testsPassed += 1
} else {
    print("❌ QR Code button still present in ComposeView")
}

// Test 2: Only Share button remains in ComposeView post-encryption
totalTests += 1
let shareButtonCount = composeContent.components(separatedBy: "LocalizationHelper.Encrypt.share").count - 1
if shareButtonCount == 1 {
    print("✅ Only Share button remains in ComposeView")
    testsPassed += 1
} else {
    print("❌ Incorrect share button count: \(shareButtonCount)")
}

// Test 3: Share button uses prominent style (single button)
totalTests += 1
let postEncryptionSection = composeContent.components(separatedBy: "showPostEncryptionButtons")[1]
if postEncryptionSection.contains(".buttonStyle(.borderedProminent)") &&
   !postEncryptionSection.contains("HStack(spacing: 12)") {
    print("✅ Share button uses prominent style as single button")
    testsPassed += 1
} else {
    print("❌ Share button styling incorrect")
}

// Test 4: Content Type section removed from QRCodeDisplayView
totalTests += 1
if !qrContent.contains("// Content Type Info") &&
   !qrContent.contains("contentInfoSection") {
    print("✅ Content Type section removed from QRCodeDisplayView")
    testsPassed += 1
} else {
    print("❌ Content Type section still present")
}

// Test 5: Action buttons section removed from QRCodeDisplayView
totalTests += 1
if !qrContent.contains("// Action Buttons") &&
   !qrContent.contains("actionButtonsSection") {
    print("✅ Redundant action buttons removed from QRCodeDisplayView")
    testsPassed += 1
} else {
    print("❌ Redundant action buttons still present")
}

// Test 6: ShareLink used instead of custom sheet
totalTests += 1
if qrContent.contains("ShareLink(items: shareItems)") {
    print("✅ ShareLink used instead of custom share sheet")
    testsPassed += 1
} else {
    print("❌ ShareLink not properly implemented")
}

// Test 7: Unused methods removed
totalTests += 1
if !qrContent.contains("func copyContent()") &&
   !qrContent.contains("func saveImageToPhotos()") &&
   !qrContent.contains("saveImageToPhotos()") {
    print("✅ Unused action methods removed")
    testsPassed += 1
} else {
    print("❌ Unused methods still present")
}

print("\n📊 Test Results:")
print("Passed: \(testsPassed)/\(totalTests)")

if testsPassed == totalTests {
    print("🎉 UI simplification successful!")
    print("📱 Improvements:")
    print("   • Removed redundant QR Code button from ComposeView")
    print("   • Single prominent Share button in ComposeView")
    print("   • Removed unnecessary Content Type description")
    print("   • Removed redundant action buttons from QR view")
    print("   • Uses native ShareLink for better integration")
    print("   • Cleaner, more focused user interface")
    exit(0)
} else {
    print("⚠️  Some issues may remain")
    exit(1)
}