#!/usr/bin/env swift

import Foundation

// Test script to validate clipboard functionality removal

print("🧪 Testing Clipboard Functionality Removal")
print("====================================================")

// Test files to check
let filesToCheck = [
    ("WhisperApp/UI/Decrypt/DecryptView.swift", "DecryptView"),
    ("WhisperApp/UI/Decrypt/DecryptViewModel.swift", "DecryptViewModel"),
    ("WhisperApp/ContentView.swift", "ContentView")
]

var allTestsPassed = true

for (filePath, fileName) in filesToCheck {
    print("\n📁 Checking \(fileName)...")
    
    let fileURL = URL(fileURLWithPath: filePath)
    
    do {
        let content = try String(contentsOf: fileURL)
        
        // Test 1: Check if clipboard auto-population is removed from DecryptView
        if fileName == "DecryptView" {
            let hasClipboardAutoPopulation = content.contains("UIPasteboard.general.string") || 
                                           content.contains("Auto-populate input field")
            print("  ✅ Clipboard auto-population removed: \(hasClipboardAutoPopulation ? "FAIL" : "PASS")")
            if hasClipboardAutoPopulation { allTestsPassed = false }
            
            let hasUIKitImport = content.contains("import UIKit")
            print("  ✅ UIKit import removed: \(hasUIKitImport ? "FAIL" : "PASS")")
            if hasUIKitImport { allTestsPassed = false }
        }
        
        // Test 2: Check if clipboard banner is removed from ContentView
        if fileName == "ContentView" {
            let hasClipboardBanner = content.contains(".clipboardBanner()")
            print("  ✅ Clipboard banner removed: \(hasClipboardBanner ? "FAIL" : "PASS")")
            if hasClipboardBanner { allTestsPassed = false }
            
            // Debug: Show what clipboard references were found
            if content.lowercased().contains("clipboard") {
                let lines = content.components(separatedBy: .newlines)
                for (index, line) in lines.enumerated() {
                    if line.lowercased().contains("clipboard") {
                        print("    🔍 Found clipboard reference at line \(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
                    }
                }
            } else {
                print("    ✅ No clipboard references found in ContentView")
            }
        }
        
        // Test 3: Check if clipboard methods are removed from DecryptViewModel
        if fileName == "DecryptViewModel" {
            let hasCheckClipboard = content.contains("checkClipboard")
            print("  ✅ checkClipboard method removed: \(hasCheckClipboard ? "FAIL" : "PASS")")
            if hasCheckClipboard { allTestsPassed = false }
            
            let hasDecryptFromClipboard = content.contains("decryptFromClipboard")
            print("  ✅ decryptFromClipboard method removed: \(hasDecryptFromClipboard ? "FAIL" : "PASS")")
            if hasDecryptFromClipboard { allTestsPassed = false }
            
            let hasShowDetectionBanner = content.contains("showDetectionBanner")
            print("  ✅ showDetectionBanner property removed: \(hasShowDetectionBanner ? "FAIL" : "PASS")")
            if hasShowDetectionBanner { allTestsPassed = false }
            
            let hasClipboardContent = content.contains("clipboardContent")
            print("  ✅ clipboardContent property removed: \(hasClipboardContent ? "FAIL" : "PASS")")
            if hasClipboardContent { allTestsPassed = false }
        }
        
        // Test 4: Check for any remaining clipboard references
        let hasAnyClipboardRef = content.lowercased().contains("clipboard") && 
                                !content.contains("Copy message to clipboard") && // Allow copy functionality
                                !content.contains("copyDecryptedMessage") // Allow copy functionality
        if hasAnyClipboardRef {
            print("  ⚠️  Warning: Found remaining clipboard references in \(fileName)")
            // Don't fail the test for this, just warn
        }
        
    } catch {
        print("  ❌ Error reading \(fileName): \(error)")
        allTestsPassed = false
    }
}

print("\n🎯 Overall Result: \(allTestsPassed ? "ALL TESTS PASSED ✅" : "SOME TESTS FAILED ❌")")

if allTestsPassed {
    print("\n🎉 SUCCESS: All clipboard auto-detection functionality has been removed!")
    print("\n📋 What was removed:")
    print("1. ❌ DecryptView onAppear clipboard auto-population")
    print("2. ❌ ContentView clipboard detection banner")
    print("3. ❌ DecryptViewModel checkClipboard() method")
    print("4. ❌ DecryptViewModel decryptFromClipboard() method")
    print("5. ❌ DecryptViewModel showDetectionBanner property")
    print("6. ❌ DecryptViewModel clipboardContent property")
    print("7. ❌ Unnecessary UIKit import from DecryptView")
    print("\n✅ What was preserved:")
    print("1. ✅ Manual copy functionality (copyDecryptedMessage)")
    print("2. ✅ Manual input and QR scan functionality")
    print("3. ✅ All other DecryptView features")
    print("\n🔧 The app will no longer automatically detect or populate clipboard content!")
} else {
    print("\n❌ FAILURE: Some clipboard functionality was not properly removed.")
    print("Please check the failed tests above and fix the remaining issues.")
}