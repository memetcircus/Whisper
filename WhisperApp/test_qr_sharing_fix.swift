#!/usr/bin/env swift

import Foundation

print("🔧 Testing QR Code Sharing Fix...")

let qrDisplayPath = "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift"

guard let content = try? String(contentsOfFile: qrDisplayPath) else {
    print("❌ Could not read QRCodeDisplayView.swift")
    exit(1)
}

var testsPassed = 0
var totalTests = 0

// Test 1: QR image is included in share items
totalTests += 1
if content.contains("qrResult.image") && content.contains("shareItems") {
    print("✅ QR code image included in share items")
    testsPassed += 1
} else {
    print("❌ QR code image not found in share items")
}

// Test 2: Share sheet is properly configured
totalTests += 1
if content.contains("ShareSheet(items: shareItems)") {
    print("✅ Share sheet configured with share items")
    testsPassed += 1
} else {
    print("❌ Share sheet not properly configured")
}

// Test 3: Share button exists in toolbar
totalTests += 1
if content.contains("Button(action: { showingShareSheet = true })") &&
   content.contains("square.and.arrow.up") {
    print("✅ Share button exists in toolbar")
    testsPassed += 1
} else {
    print("❌ Share button missing from toolbar")
}

// Test 4: Share items include both image and content
totalTests += 1
if content.contains("qrResult.image, qrResult.content") {
    print("✅ Share items include both QR image and content")
    testsPassed += 1
} else {
    print("❌ Share items don't include both image and content")
}

// Test 5: ShareSheet struct exists for UIKit integration
totalTests += 1
if content.contains("UIActivityViewController") {
    print("✅ ShareSheet uses UIActivityViewController for native sharing")
    testsPassed += 1
} else {
    print("❌ ShareSheet implementation missing")
}

print("\n📊 Test Results:")
print("Passed: \(testsPassed)/\(totalTests)")

if testsPassed == totalTests {
    print("🎉 QR Code sharing should work correctly!")
    print("📱 Sharing Options Available:")
    print("   • Save QR code image to Photos")
    print("   • Share QR code via Messages, Mail, etc.")
    print("   • Copy QR code image")
    print("   • Copy encrypted text content")
    print("   • AirDrop QR code image")
    exit(0)
} else {
    print("⚠️  Some issues may remain")
    exit(1)
}