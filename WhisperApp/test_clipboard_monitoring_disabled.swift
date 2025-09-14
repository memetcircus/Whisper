#!/usr/bin/env swift

import Foundation

print("🔍 Testing Clipboard Monitoring Removal...")
print(String(repeating: "=", count: 50))

var allTestsPassed = true

// Test 1: Verify ClipboardMonitor is not instantiated in DecryptView
print("\n1. Testing DecryptView ClipboardMonitor removal...")
let decryptViewPath = "./WhisperApp/UI/Decrypt/DecryptView.swift"
if let content = try? String(contentsOfFile: decryptViewPath) {
    let hasClipboardMonitor = content.contains("@StateObject") && content.contains("ClipboardMonitor")
    let hasAutoPopulation = content.contains("clipboardContent") || content.contains("auto-populate")
    
    print("  ✅ No @StateObject ClipboardMonitor: \(hasClipboardMonitor ? "FAIL" : "PASS")")
    print("  ✅ No auto-population logic: \(hasAutoPopulation ? "FAIL" : "PASS")")
    print("  ✅ Updated comment: \(content.contains("Clipboard monitoring has been removed") ? "PASS" : "FAIL")")
    
    if hasClipboardMonitor || hasAutoPopulation || !content.contains("Clipboard monitoring has been removed") {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read DecryptView.swift")
    allTestsPassed = false
}

// Test 2: Verify DecryptViewModel has no clipboard properties
print("\n2. Testing DecryptViewModel clipboard properties removal...")
let decryptViewModelPath = "./WhisperApp/UI/Decrypt/DecryptViewModel.swift"
if let content = try? String(contentsOfFile: decryptViewModelPath) {
    let hasClipboardContent = content.contains("clipboardContent")
    let hasShowDetectionBanner = content.contains("showDetectionBanner")
    let hasDecryptFromClipboard = content.contains("decryptFromClipboard")
    
    print("  ✅ No clipboardContent property: \(hasClipboardContent ? "FAIL" : "PASS")")
    print("  ✅ No showDetectionBanner property: \(hasShowDetectionBanner ? "FAIL" : "PASS")")
    print("  ✅ No decryptFromClipboard method: \(hasDecryptFromClipboard ? "FAIL" : "PASS")")
    
    if hasClipboardContent || hasShowDetectionBanner || hasDecryptFromClipboard {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read DecryptViewModel.swift")
    allTestsPassed = false
}

// Test 3: Verify ContentView doesn't use clipboardBanner modifier
print("\n3. Testing ContentView clipboardBanner removal...")
let contentViewPath = "./WhisperApp/ContentView.swift"
if let content = try? String(contentsOfFile: contentViewPath) {
    let hasClipboardBanner = content.contains(".clipboardBanner()") && !content.contains("// .clipboardBanner()")
    
    print("  ✅ No clipboardBanner modifier: \(hasClipboardBanner ? "FAIL" : "PASS")")
    
    if hasClipboardBanner {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read ContentView.swift")
    allTestsPassed = false
}

// Test 4: Verify ClipboardMonitor class exists but is unused
print("\n4. Testing ClipboardMonitor class status...")
let clipboardMonitorPath = "./WhisperApp/UI/Decrypt/ClipboardMonitor.swift"
if let content = try? String(contentsOfFile: clipboardMonitorPath) {
    let hasClipboardMonitorClass = content.contains("class ClipboardMonitor")
    let hasTimerBasedPolling = content.contains("Timer.scheduledTimer")
    
    print("  ✅ ClipboardMonitor class exists: \(hasClipboardMonitorClass ? "PASS" : "FAIL")")
    print("  ✅ Timer-based polling code exists: \(hasTimerBasedPolling ? "PASS" : "FAIL")")
    print("  ℹ️  Note: Class exists but should not be instantiated anywhere")
    
    if !hasClipboardMonitorClass || !hasTimerBasedPolling {
        print("  ⚠️  ClipboardMonitor class or polling logic missing - this is unexpected")
    }
} else {
    print("  ❌ Could not read ClipboardMonitor.swift")
    allTestsPassed = false
}

// Test 5: Verify manual paste functionality is preserved
print("\n5. Testing manual paste functionality preservation...")
if let content = try? String(contentsOfFile: decryptViewPath) {
    let hasTextEditor = content.contains("TextEditor")
    let hasInputText = content.contains("inputText")
    let hasCopyMessage = content.contains("copyDecryptedMessage")
    
    print("  ✅ TextEditor for manual input: \(hasTextEditor ? "PASS" : "FAIL")")
    print("  ✅ Input text binding: \(hasInputText ? "PASS" : "FAIL")")
    print("  ✅ Copy functionality preserved: \(hasCopyMessage ? "PASS" : "FAIL")")
    
    if !hasTextEditor || !hasInputText || !hasCopyMessage {
        allTestsPassed = false
    }
}

// Test 6: Verify QR code functionality is intact
print("\n6. Testing QR code functionality preservation...")
if let content = try? String(contentsOfFile: decryptViewPath) {
    let hasQRScanner = content.contains("QRCodeCoordinatorView") || content.contains("showingQRScanner")
    let hasQRScanButton = content.contains("Scan QR") || content.contains("qrcode")
    
    print("  ✅ QR scanner functionality: \(hasQRScanner ? "PASS" : "FAIL")")
    print("  ✅ QR scan button: \(hasQRScanButton ? "PASS" : "FAIL")")
    
    if !hasQRScanner || !hasQRScanButton {
        allTestsPassed = false
    }
}

print("\n" + String(repeating: "=", count: 50))
if allTestsPassed {
    print("🎉 All clipboard monitoring removal tests PASSED!")
    print("\n✅ Summary of changes:")
    print("  • ClipboardMonitor not instantiated in DecryptView")
    print("  • Auto-population logic removed")
    print("  • Clipboard properties removed from DecryptViewModel")
    print("  • clipboardBanner modifier removed from ContentView")
    print("  • Manual paste functionality preserved")
    print("  • QR code functionality preserved")
    print("  • ClipboardMonitor class preserved but unused")
} else {
    print("❌ Some clipboard monitoring removal tests FAILED!")
    print("\nPlease review the failed tests above and ensure:")
    print("  • No @StateObject ClipboardMonitor in DecryptView")
    print("  • No clipboard-related properties in DecryptViewModel")
    print("  • No .clipboardBanner() modifier in ContentView")
    print("  • Manual paste and QR functionality preserved")
}

print("\n🔍 Task 1 verification complete.")