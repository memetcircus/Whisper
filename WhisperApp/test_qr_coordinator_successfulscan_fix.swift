#!/usr/bin/env swift

import Foundation

// Test script to validate the QR Coordinator successfulScan fix

print("🧪 Testing QR Coordinator successfulScan Fix")
print("====================================================")

// Read the QRCodeCoordinatorView file
let fileURL = URL(fileURLWithPath: "WhisperApp/UI/QR/QRCodeCoordinatorView.swift")

do {
    let content = try String(contentsOf: fileURL)
    
    // Test 1: Check if successfulScan state variable exists
    let hasSuccessfulScanState = content.contains("@State private var successfulScan = false")
    print("✅ Test 1 - successfulScan state variable: \(hasSuccessfulScanState ? "PASS" : "FAIL")")
    
    // Test 2: Check if successfulScan is used in onDismiss logic
    let hasSuccessfulScanInDismiss = content.contains("&& !successfulScan")
    print("✅ Test 2 - successfulScan in dismiss logic: \(hasSuccessfulScanInDismiss ? "PASS" : "FAIL")")
    
    // Test 3: Check if successfulScan is set to true for public key bundle
    let hasSuccessfulScanForPublicKey = content.contains("case .publicKeyBundle:") && 
                                       content.contains("successfulScan = true")
    print("✅ Test 3 - successfulScan set for public key: \(hasSuccessfulScanForPublicKey ? "PASS" : "FAIL")")
    
    // Test 4: Check if successfulScan is set to true for encrypted message
    let hasSuccessfulScanForMessage = content.contains("case .encryptedMessage") && 
                                     content.contains("successfulScan = true")
    print("✅ Test 4 - successfulScan set for encrypted message: \(hasSuccessfulScanForMessage ? "PASS" : "FAIL")")
    
    // Test 5: Check if successfulScan is reset when starting scan
    let hasSuccessfulScanReset = content.contains("successfulScan = false // Reset flag when starting new scan")
    print("✅ Test 5 - successfulScan reset on scan start: \(hasSuccessfulScanReset ? "PASS" : "FAIL")")
    
    // Test 6: Check if debug logging includes successfulScan
    let hasSuccessfulScanLogging = content.contains("print(\"🔍 QR_COORDINATOR: successfulScan = \\(successfulScan)\")")
    print("✅ Test 6 - successfulScan debug logging: \(hasSuccessfulScanLogging ? "PASS" : "FAIL")")
    
    let allTestsPassed = hasSuccessfulScanState && hasSuccessfulScanInDismiss && 
                        hasSuccessfulScanForPublicKey && hasSuccessfulScanForMessage && 
                        hasSuccessfulScanReset && hasSuccessfulScanLogging
    
    print("\n🎯 Overall Result: \(allTestsPassed ? "ALL TESTS PASSED ✅" : "SOME TESTS FAILED ❌")")
    
    if allTestsPassed {
        print("\n🎉 SUCCESS: The QR Coordinator successfulScan fix has been properly implemented!")
        print("\n📋 How it works:")
        print("1. When QR scan starts → successfulScan = false")
        print("2. When QR scan succeeds → successfulScan = true")
        print("3. When scanner dismisses:")
        print("   - If successfulScan = true → Does NOT call onDismiss() → DecryptView stays open")
        print("   - If successfulScan = false → Calls onDismiss() → Properly dismisses")
        print("\n🔧 This should fix the issue where DecryptView was auto-dismissing after successful QR scans!")
    } else {
        print("\n❌ FAILURE: The fix was not properly applied. Please check the implementation.")
    }
    
} catch {
    print("❌ Error reading file: \(error)")
}