#!/usr/bin/env swift

import Foundation

// Validation script for Task 2: Remove clipboard properties from DecryptViewModel
// This script verifies that clipboard monitoring properties have been properly removed

print("🔍 TASK 2 VALIDATION: Checking DecryptViewModel clipboard monitoring removal...")

let decryptViewModelPath = "WhisperApp/UI/Decrypt/DecryptViewModel.swift"

guard let content = try? String(contentsOfFile: decryptViewModelPath) else {
    print("❌ Could not read DecryptViewModel.swift")
    exit(1)
}

// Check 1: Verify clipboardContent property is commented out
let hasCommentedClipboardContent = content.contains("// @Published var clipboardContent: String = \"\"")
print("✅ Clipboard content property commented out: \(hasCommentedClipboardContent)")

// Check 2: Verify no active clipboard monitoring properties
let hasActiveClipboardContent = content.contains("@Published var clipboardContent") && !content.contains("// @Published var clipboardContent")
print("✅ No active clipboard content property: \(!hasActiveClipboardContent)")

// Check 3: Verify no ClipboardMonitor dependencies
let hasClipboardMonitorDependency = content.contains("ClipboardMonitor") || content.contains("clipboardMonitor")
print("✅ No ClipboardMonitor dependencies: \(!hasClipboardMonitorDependency)")

// Check 4: Verify no clipboard monitoring state management
let hasClipboardStateManagement = content.contains("hasWhisperMessage") || content.contains("detectedMessage")
print("✅ No clipboard monitoring state management: \(!hasClipboardStateManagement)")

// Check 5: Verify copyDecryptedMessage method still exists (this should remain)
let hasCopyMethod = content.contains("func copyDecryptedMessage()")
print("✅ Copy decrypted message method preserved: \(hasCopyMethod)")

// Check 6: Verify no clipboard monitoring methods
let hasClipboardMonitoringMethods = content.contains("startMonitoring") || content.contains("stopMonitoring") || content.contains("checkClipboard")
print("✅ No clipboard monitoring methods: \(!hasClipboardMonitoringMethods)")

let allChecksPass = hasCommentedClipboardContent && 
                   !hasActiveClipboardContent && 
                   !hasClipboardMonitorDependency && 
                   !hasClipboardStateManagement && 
                   hasCopyMethod && 
                   !hasClipboardMonitoringMethods

if allChecksPass {
    print("\n🎉 TASK 2 VALIDATION PASSED: DecryptViewModel clipboard monitoring properties successfully removed!")
    print("✅ @Published clipboardContent property is commented out")
    print("✅ No clipboard monitoring dependencies remain")
    print("✅ No clipboard-related state management occurs")
    print("✅ Copy functionality preserved for output operations")
} else {
    print("\n❌ TASK 2 VALIDATION FAILED: Some clipboard monitoring code may still be present")
    exit(1)
}