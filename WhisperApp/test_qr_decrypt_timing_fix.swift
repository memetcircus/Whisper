#!/usr/bin/env swift

import Foundation

// Test script to validate the QR decrypt timing fix

print("🧪 Testing QR Decrypt Timing Fix")
print("====================================================")

// Read the DecryptViewModel file
let fileURL = URL(fileURLWithPath: "WhisperApp/UI/Decrypt/DecryptViewModel.swift")

do {
    let content = try String(contentsOf: fileURL)
    
    // Test 1: Check if success alert is removed from QR scan success flow
    let hasSuccessAlert = content.contains("self.showingSuccess = true") && 
                         content.contains("QR code scanned successfully")
    print("✅ Test 1 - Success alert removed from QR flow: \(hasSuccessAlert ? "FAIL" : "PASS")")
    
    // Test 2: Check if immediate scanner dismissal is implemented
    let hasImmediateDismissal = content.contains("showingQRScanner = false") && 
                               content.contains("QR scanner dismissed, message populated")
    print("✅ Test 2 - Immediate scanner dismissal: \(hasImmediateDismissal ? "PASS" : "FAIL")")
    
    // Test 3: Check if delayed success alert cleanup is removed
    let hasDelayedCleanup = content.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 5.0)")
    print("✅ Test 3 - Delayed success alert cleanup removed: \(hasDelayedCleanup ? "FAIL" : "PASS")")
    
    // Test 4: Check if scan complete state reset is still present
    let hasScanCompleteReset = content.contains("self.isQRScanComplete = false") && 
                              content.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 3.0)")
    print("✅ Test 4 - Scan complete state reset: \(hasScanCompleteReset ? "PASS" : "FAIL")")
    
    // Test 5: Check if haptic feedback is still present
    let hasHapticFeedback = content.contains("UIImpactFeedbackGenerator") && 
                           content.contains("impactOccurred()")
    print("✅ Test 5 - Haptic feedback preserved: \(hasHapticFeedback ? "PASS" : "FAIL")")
    
    let allTestsPassed = !hasSuccessAlert && hasImmediateDismissal && 
                        !hasDelayedCleanup && hasScanCompleteReset && hasHapticFeedback
    
    print("\n🎯 Overall Result: \(allTestsPassed ? "ALL TESTS PASSED ✅" : "SOME TESTS FAILED ❌")")
    
    if allTestsPassed {
        print("\n🎉 SUCCESS: The QR decrypt timing fix has been properly implemented!")
        print("\n📋 Changes made:")
        print("1. Removed success alert from QR scan flow to avoid presentation conflicts")
        print("2. Implemented immediate scanner dismissal after successful scan")
        print("3. Removed delayed success alert cleanup")
        print("4. Kept scan complete visual feedback with 3-second reset")
        print("5. Preserved haptic feedback for better UX")
        print("\n🔧 This should fix the DecryptView auto-dismissal issue!")
    } else {
        print("\n❌ FAILURE: The fix was not properly applied. Please check the implementation.")
    }
    
} catch {
    print("❌ Error reading file: \(error)")
}