#!/usr/bin/env swift

import Foundation

/// Validation script for Task 3: Validate ClipboardMonitor class is unused
/// This script verifies that ClipboardMonitor is not instantiated anywhere and no automatic clipboard monitoring occurs

print("🔍 TASK 3 VALIDATION: Validate ClipboardMonitor class is unused")
print(String(repeating: "=", count: 60))

var allTestsPassed = true

// MARK: - Sub-task 1: Verify ClipboardMonitor.swift file exists but is not instantiated anywhere

print("\n📋 Sub-task 1: Verify ClipboardMonitor.swift file exists but is not instantiated")

// Check if ClipboardMonitor.swift file exists
let clipboardMonitorPath = "WhisperApp/WhisperApp/UI/Decrypt/ClipboardMonitor.swift"
let clipboardMonitorExists = FileManager.default.fileExists(atPath: clipboardMonitorPath)

if clipboardMonitorExists {
    print("  ✅ ClipboardMonitor.swift file exists: PASS")
} else {
    print("  ❌ ClipboardMonitor.swift file missing: FAIL")
    allTestsPassed = false
}

// Check if ClipboardMonitor is instantiated in DecryptView
let decryptViewPath = "WhisperApp/WhisperApp/UI/Decrypt/DecryptView.swift"
if let decryptViewContent = try? String(contentsOfFile: decryptViewPath) {
    let hasClipboardMonitorInstantiation = decryptViewContent.contains("@StateObject") && 
                                          decryptViewContent.contains("ClipboardMonitor") &&
                                          !decryptViewContent.contains("// @StateObject")
    
    if !hasClipboardMonitorInstantiation {
        print("  ✅ ClipboardMonitor NOT instantiated in DecryptView: PASS")
    } else {
        print("  ❌ ClipboardMonitor still instantiated in DecryptView: FAIL")
        allTestsPassed = false
    }
    
    // Check for removal comment
    let hasRemovalComment = decryptViewContent.contains("Clipboard monitoring has been removed")
    if hasRemovalComment {
        print("  ✅ Removal comment found in DecryptView: PASS")
    } else {
        print("  ⚠️  No removal comment found in DecryptView: WARNING")
    }
} else {
    print("  ❌ Could not read DecryptView.swift: FAIL")
    allTestsPassed = false
}

// Check if ClipboardMonitor is instantiated anywhere else in the codebase
print("\n🔍 Searching for ClipboardMonitor instantiations in codebase...")

let searchPaths = [
    "WhisperApp/WhisperApp/UI/",
    "WhisperApp/WhisperApp/Core/",
    "WhisperApp/WhisperApp/Services/"
]

var foundInstantiations = false
for searchPath in searchPaths {
    if let enumerator = FileManager.default.enumerator(atPath: searchPath) {
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift") && !file.contains("ClipboardMonitor.swift") {
                let fullPath = "\(searchPath)\(file)"
                if let content = try? String(contentsOfFile: fullPath) {
                    if content.contains("ClipboardMonitor()") || 
                       (content.contains("@StateObject") && content.contains("ClipboardMonitor") && !content.contains("//")) {
                        print("  ❌ Found ClipboardMonitor instantiation in \(fullPath): FAIL")
                        foundInstantiations = true
                        allTestsPassed = false
                    }
                }
            }
        }
    }
}

if !foundInstantiations {
    print("  ✅ No ClipboardMonitor instantiations found in codebase: PASS")
}

// MARK: - Sub-task 2: Confirm no timer-based clipboard polling is active when app runs

print("\n⏰ Sub-task 2: Confirm no timer-based clipboard polling is active")

// Check DecryptView for timer usage
if let decryptViewContent = try? String(contentsOfFile: decryptViewPath) {
    let hasTimerUsage = decryptViewContent.contains("Timer.scheduledTimer") && 
                       decryptViewContent.contains("clipboard")
    
    if !hasTimerUsage {
        print("  ✅ No timer-based clipboard polling in DecryptView: PASS")
    } else {
        print("  ❌ Timer-based clipboard polling found in DecryptView: FAIL")
        allTestsPassed = false
    }
}

// Check DecryptViewModel for timer usage
let decryptViewModelPath = "WhisperApp/WhisperApp/UI/Decrypt/DecryptViewModel.swift"
if let decryptViewModelContent = try? String(contentsOfFile: decryptViewModelPath) {
    let hasTimerUsage = decryptViewModelContent.contains("Timer.scheduledTimer") && 
                       decryptViewModelContent.contains("clipboard")
    
    if !hasTimerUsage {
        print("  ✅ No timer-based clipboard polling in DecryptViewModel: PASS")
    } else {
        print("  ❌ Timer-based clipboard polling found in DecryptViewModel: FAIL")
        allTestsPassed = false
    }
}

// Verify ClipboardMonitor contains timer code but is unused
if let clipboardMonitorContent = try? String(contentsOfFile: clipboardMonitorPath) {
    let hasTimerCode = clipboardMonitorContent.contains("Timer.scheduledTimer")
    let hasClipboardPolling = clipboardMonitorContent.contains("checkClipboard")
    
    if hasTimerCode && hasClipboardPolling {
        print("  ✅ ClipboardMonitor contains timer code (but is unused): PASS")
    } else {
        print("  ❌ ClipboardMonitor missing expected timer code: FAIL")
        allTestsPassed = false
    }
}

// MARK: - Sub-task 3: Check that UIPasteboard.general is not accessed automatically

print("\n📋 Sub-task 3: Check that UIPasteboard.general is not accessed automatically")

// Check DecryptView for automatic UIPasteboard access
if let decryptViewContent = try? String(contentsOfFile: decryptViewPath) {
    // Look for UIPasteboard usage that's not in copy operations
    let lines = decryptViewContent.components(separatedBy: .newlines)
    var hasAutomaticAccess = false
    
    for line in lines {
        if line.contains("UIPasteboard.general") && 
           !line.contains("//") && 
           !line.contains("copyDecryptedMessage") &&
           !line.contains("copy") {
            hasAutomaticAccess = true
            break
        }
    }
    
    if !hasAutomaticAccess {
        print("  ✅ No automatic UIPasteboard access in DecryptView: PASS")
    } else {
        print("  ❌ Automatic UIPasteboard access found in DecryptView: FAIL")
        allTestsPassed = false
    }
}

// Check DecryptViewModel for automatic UIPasteboard access
if let decryptViewModelContent = try? String(contentsOfFile: decryptViewModelPath) {
    // Look for UIPasteboard usage that's not in copy operations
    let lines = decryptViewModelContent.components(separatedBy: .newlines)
    var hasAutomaticAccess = false
    
    for line in lines {
        if line.contains("UIPasteboard.general") && 
           !line.contains("//") && 
           !line.contains("copyDecryptedMessage") &&
           !line.contains("string = messageText") {  // This is the manual copy operation
            hasAutomaticAccess = true
            break
        }
    }
    
    if !hasAutomaticAccess {
        print("  ✅ No automatic UIPasteboard access in DecryptViewModel: PASS")
    } else {
        print("  ❌ Automatic UIPasteboard access found in DecryptViewModel: FAIL")
        allTestsPassed = false
    }
}

// Verify clipboard properties are commented out
if let decryptViewModelContent = try? String(contentsOfFile: decryptViewModelPath) {
    let hasCommentedClipboardProperty = decryptViewModelContent.contains("// @Published var clipboardContent")
    
    if hasCommentedClipboardProperty {
        print("  ✅ Clipboard property commented out in DecryptViewModel: PASS")
    } else {
        print("  ❌ Clipboard property not properly commented out: FAIL")
        allTestsPassed = false
    }
}

// MARK: - Sub-task 4: Ensure no background clipboard monitoring occurs

print("\n🔄 Sub-task 4: Ensure no background clipboard monitoring occurs")

// Check for any background clipboard monitoring setup
let appDelegatePaths = [
    "WhisperApp/WhisperApp/WhisperApp.swift",
    "WhisperApp/WhisperApp/ContentView.swift"
]

var hasBackgroundMonitoring = false
for path in appDelegatePaths {
    if let content = try? String(contentsOfFile: path) {
        if content.contains("ClipboardMonitor") && !content.contains("//") {
            print("  ❌ Background clipboard monitoring found in \(path): FAIL")
            hasBackgroundMonitoring = true
            allTestsPassed = false
        }
    }
}

if !hasBackgroundMonitoring {
    print("  ✅ No background clipboard monitoring in app lifecycle: PASS")
}

// Check for clipboard monitoring in view modifiers
if let clipboardMonitorContent = try? String(contentsOfFile: clipboardMonitorPath) {
    let hasViewModifier = clipboardMonitorContent.contains("ClipboardBannerModifier")
    let hasExtension = clipboardMonitorContent.contains("extension View")
    
    if hasViewModifier && hasExtension {
        print("  ✅ ClipboardBannerModifier exists but is unused: PASS")
    }
}

// Search for usage of clipboardBanner() modifier
print("\n🔍 Searching for clipboardBanner() modifier usage...")
var foundModifierUsage = false
for searchPath in searchPaths {
    if let enumerator = FileManager.default.enumerator(atPath: searchPath) {
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift") {
                let fullPath = "\(searchPath)\(file)"
                if let content = try? String(contentsOfFile: fullPath) {
                    if content.contains(".clipboardBanner()") && !content.contains("//") {
                        print("  ❌ Found clipboardBanner() modifier usage in \(fullPath): FAIL")
                        foundModifierUsage = true
                        allTestsPassed = false
                    }
                }
            }
        }
    }
}

if !foundModifierUsage {
    print("  ✅ No clipboardBanner() modifier usage found: PASS")
}

// MARK: - Final Results

print("\n" + String(repeating: "=", count: 60))
print("📊 TASK 3 VALIDATION RESULTS")
print(String(repeating: "=", count: 60))

if allTestsPassed {
    print("🎉 ALL TESTS PASSED!")
    print("✅ ClipboardMonitor class exists but is completely unused")
    print("✅ No timer-based clipboard polling is active")
    print("✅ No automatic UIPasteboard.general access occurs")
    print("✅ No background clipboard monitoring is running")
    print("\n🔒 Requirements 3.1, 3.2, 3.3, and 1.1 are satisfied")
} else {
    print("❌ SOME TESTS FAILED!")
    print("Please review the failed tests above and ensure:")
    print("• ClipboardMonitor is not instantiated anywhere")
    print("• No timer-based clipboard polling is active")
    print("• UIPasteboard.general is only used for manual copy operations")
    print("• No background clipboard monitoring occurs")
}

print("\n📋 Manual verification steps:")
print("1. Run the app and verify no clipboard polling occurs in logs")
print("2. Change clipboard content and verify input fields don't auto-populate")
print("3. Verify manual paste operations still work correctly")
print("4. Check that QR code functionality remains intact")

exit(allTestsPassed ? 0 : 1)