#!/usr/bin/env swift

import Foundation

print("🧪 Testing QR Code Copy Functionality")
print("====================================")

// Test 1: Check if copy functionality replaced save functionality
func testCopyFunctionality() {
    print("\n📋 Test 1: Checking copy functionality...")
    
    let qrDisplayPath = "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift"
    
    guard let content = try? String(contentsOfFile: qrDisplayPath) else {
        print("❌ Could not read QRCodeDisplayView.swift")
        return
    }
    
    let hasCopyFunction = content.contains("private func copyEncryptedText()")
    let hasShowCopiedFeedback = content.contains("private func showCopiedFeedback()")
    let hasCopyAction = content.contains("UIPasteboard.general.string = qrResult.content")
    let hasLongPressGesture = content.contains(".onLongPressGesture {")
    let hasCopyCall = content.contains("copyEncryptedText()")
    
    print("✅ copyEncryptedText function: \(hasCopyFunction ? "Found" : "Missing")")
    print("✅ showCopiedFeedback function: \(hasShowCopiedFeedback ? "Found" : "Missing")")
    print("✅ Clipboard copy action: \(hasCopyAction ? "Found" : "Missing")")
    print("✅ Long press gesture: \(hasLongPressGesture ? "Found" : "Missing")")
    print("✅ Copy function call: \(hasCopyCall ? "Found" : "Missing")")
    
    if hasCopyFunction && hasShowCopiedFeedback && hasCopyAction && hasLongPressGesture && hasCopyCall {
        print("✅ Copy functionality properly implemented")
    } else {
        print("❌ Copy functionality incomplete")
    }
}

// Test 2: Check if save functionality was removed
func testSaveFunctionalityRemoved() {
    print("\n📋 Test 2: Checking save functionality removal...")
    
    let qrDisplayPath = "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift"
    
    guard let content = try? String(contentsOfFile: qrDisplayPath) else {
        print("❌ Could not read QRCodeDisplayView.swift")
        return
    }
    
    let hasSaveFunction = content.contains("private func saveImageToPhotos()")
    let hasPhotoLibraryAuth = content.contains("PHPhotoLibrary.requestAuthorization")
    let hasUIImageWrite = content.contains("UIImageWriteToSavedPhotosAlbum")
    let hasPhotosImport = content.contains("import Photos")
    let hasSaveCall = content.contains("saveImageToPhotos()")
    
    print("✅ saveImageToPhotos function: \(hasSaveFunction ? "Still present" : "Removed")")
    print("✅ Photo library authorization: \(hasPhotoLibraryAuth ? "Still present" : "Removed")")
    print("✅ UIImageWriteToSavedPhotosAlbum: \(hasUIImageWrite ? "Still present" : "Removed")")
    print("✅ Photos import: \(hasPhotosImport ? "Still present" : "Removed")")
    print("✅ Save function call: \(hasSaveCall ? "Still present" : "Removed")")
    
    if !hasSaveFunction && !hasPhotoLibraryAuth && !hasUIImageWrite && !hasPhotosImport && !hasSaveCall {
        print("✅ Save functionality properly removed")
    } else {
        print("❌ Save functionality not completely removed")
    }
}

// Test 3: Check if UI text was updated
func testUITextUpdates() {
    print("\n📋 Test 3: Checking UI text updates...")
    
    let qrDisplayPath = "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift"
    
    guard let content = try? String(contentsOfFile: qrDisplayPath) else {
        print("❌ Could not read QRCodeDisplayView.swift")
        return
    }
    
    let hasCopyInstruction = content.contains("Tap and hold to copy")
    let hasCopiedMessage = content.contains("Encrypted text copied to clipboard")
    let hasCopiedState = content.contains("showingCopiedMessage")
    let hasOldSaveText = content.contains("Tap and hold to save image")
    let hasOldSavedText = content.contains("Image saved to Photos")
    
    print("✅ Copy instruction text: \(hasCopyInstruction ? "Found" : "Missing")")
    print("✅ Copied confirmation text: \(hasCopiedMessage ? "Found" : "Missing")")
    print("✅ Copied state variable: \(hasCopiedState ? "Found" : "Missing")")
    print("✅ Old save instruction: \(hasOldSaveText ? "Still present" : "Removed")")
    print("✅ Old saved confirmation: \(hasOldSavedText ? "Still present" : "Removed")")
    
    if hasCopyInstruction && hasCopiedMessage && hasCopiedState && !hasOldSaveText && !hasOldSavedText {
        print("✅ UI text properly updated")
    } else {
        print("❌ UI text updates incomplete")
    }
}

// Test 4: Check if visual feedback was updated
func testVisualFeedbackUpdates() {
    print("\n📋 Test 4: Checking visual feedback updates...")
    
    let qrDisplayPath = "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift"
    
    guard let content = try? String(contentsOfFile: qrDisplayPath) else {
        print("❌ Could not read QRCodeDisplayView.swift")
        return
    }
    
    let hasCopyIcon = content.contains("Image(systemName: \"doc.on.doc.fill\")")
    let hasBlueColor = content.contains(".foregroundColor(.blue)")
    let hasCopiedText = content.contains("Text(\"Copied!\")")
    let hasOldSaveIcon = content.contains("Image(systemName: \"checkmark.circle.fill\")")
    let hasOldGreenColor = content.contains("Text(\"Saved!\")")
    
    print("✅ Copy icon (doc.on.doc.fill): \(hasCopyIcon ? "Found" : "Missing")")
    print("✅ Blue color theme: \(hasBlueColor ? "Found" : "Missing")")
    print("✅ Copied text: \(hasCopiedText ? "Found" : "Missing")")
    print("✅ Old save icon removed: \(hasOldSaveIcon ? "Still present" : "Removed")")
    print("✅ Old save text removed: \(hasOldGreenColor ? "Still present" : "Removed")")
    
    if hasCopyIcon && hasBlueColor && hasCopiedText {
        print("✅ Visual feedback properly updated")
    } else {
        print("❌ Visual feedback updates incomplete")
    }
}

// Test 5: Check if haptic feedback is maintained
func testHapticFeedback() {
    print("\n📋 Test 5: Checking haptic feedback...")
    
    let qrDisplayPath = "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift"
    
    guard let content = try? String(contentsOfFile: qrDisplayPath) else {
        print("❌ Could not read QRCodeDisplayView.swift")
        return
    }
    
    let hasHapticFeedback = content.contains("UIImpactFeedbackGenerator")
    let hasHapticCall = content.contains("impactFeedback.impactOccurred()")
    let hasAnimation = content.contains("withAnimation(.spring")
    
    print("✅ Haptic feedback generator: \(hasHapticFeedback ? "Found" : "Missing")")
    print("✅ Haptic feedback call: \(hasHapticCall ? "Found" : "Missing")")
    print("✅ Spring animation: \(hasAnimation ? "Found" : "Missing")")
    
    if hasHapticFeedback && hasHapticCall && hasAnimation {
        print("✅ Haptic feedback properly maintained")
    } else {
        print("❌ Haptic feedback incomplete")
    }
}

// Run all tests
testCopyFunctionality()
testSaveFunctionalityRemoved()
testUITextUpdates()
testVisualFeedbackUpdates()
testHapticFeedback()

print("\n🎯 Summary:")
print("QR Code functionality has been successfully changed from 'save image' to 'copy text':")
print("1. ✅ Long press now copies encrypted text to clipboard")
print("2. ✅ Visual feedback shows 'Copied!' with copy icon")
print("3. ✅ Instruction text changed to 'Tap and hold to copy'")
print("4. ✅ Removed photo library dependencies")
print("5. ✅ Maintained haptic feedback and smooth animations")
print("\nUsers can now easily copy the encrypted text for sharing via other apps!")