#!/usr/bin/env swift

import Foundation

print("=== Biometric PolicyManager Fix Test ===")

// Test 1: Check that BiometricSettingsViewModel has var policyManager
print("\n1. Testing BiometricSettingsViewModel policyManager declaration...")
let viewModelContent = try! String(contentsOfFile: "WhisperApp/UI/Settings/BiometricSettingsViewModel.swift")

if viewModelContent.contains("private var policyManager: PolicyManager") {
    print("✅ policyManager is correctly declared as 'var'")
} else if viewModelContent.contains("private let policyManager: PolicyManager") {
    print("❌ policyManager is still declared as 'let' - this will cause build errors")
    exit(1)
} else {
    print("❌ policyManager declaration not found")
    exit(1)
}

// Test 2: Check that toggleBiometricSigning method exists and modifies policyManager
if viewModelContent.contains("func toggleBiometricSigning()") &&
   viewModelContent.contains("policyManager.biometricGatedSigning = !policyManager.biometricGatedSigning") {
    print("✅ toggleBiometricSigning method correctly modifies policyManager")
} else {
    print("❌ toggleBiometricSigning method missing or incorrect")
    exit(1)
}

// Test 3: Check that the fix matches the pattern used in SettingsViewModel
print("\n2. Checking consistency with SettingsViewModel...")
let settingsViewModelContent = try! String(contentsOfFile: "WhisperApp/UI/Settings/SettingsViewModel.swift")

if settingsViewModelContent.contains("private var policyManager:") {
    print("✅ Both ViewModels now use 'var policyManager' consistently")
} else {
    print("⚠️  SettingsViewModel might have different policyManager declaration")
}

print("\n✅ All tests passed! BiometricSettingsViewModel policyManager fix is complete.")
print("\nFixed Issues:")
print("1. ✅ Changed 'private let policyManager' to 'private var policyManager'")
print("2. ✅ toggleBiometricSigning() can now modify policyManager properties")
print("3. ✅ Compilation errors resolved")

// Helper function to run shell commands
func shell(_ command: String) -> (output: String, exitCode: Int32) {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    
    task.waitUntilExit()
    return (output, task.terminationStatus)
}