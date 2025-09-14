#!/usr/bin/env swift

import Foundation

print("=== Settings ViewModel Build Fix Test ===")

// Test 1: Verify the file compiles
print("\n1. Testing Swift compilation...")
let compileResult = shell("swiftc -typecheck WhisperApp/UI/Settings/SettingsViewModel.swift")
if compileResult.exitCode == 0 {
    print("✅ SettingsViewModel compiles successfully")
} else {
    print("❌ SettingsViewModel compilation failed:")
    print(compileResult.output)
    exit(1)
}

// Test 2: Check that the file contains the expected fixes
print("\n2. Checking for expected fixes...")
let fileContent = try! String(contentsOfFile: "WhisperApp/UI/Settings/SettingsViewModel.swift")

// Check that policyManager is declared as var
if fileContent.contains("private var policyManager: SettingsPolicyManager") {
    print("✅ policyManager is correctly declared as 'var'")
} else {
    print("❌ policyManager should be declared as 'var'")
    exit(1)
}

// Check that we have the simple protocol
if fileContent.contains("protocol SettingsPolicyManager") {
    print("✅ SettingsPolicyManager protocol is defined")
} else {
    print("❌ SettingsPolicyManager protocol is missing")
    exit(1)
}

// Check that we have the UserDefaults implementation
if fileContent.contains("class UserDefaultsSettingsPolicyManager: SettingsPolicyManager") {
    print("✅ UserDefaultsSettingsPolicyManager implementation is present")
} else {
    print("❌ UserDefaultsSettingsPolicyManager implementation is missing")
    exit(1)
}

// Check that we use guard let self pattern
if fileContent.contains("guard let self = self else { return }") {
    print("✅ Proper guard let self pattern is used")
} else {
    print("❌ Guard let self pattern is missing")
    exit(1)
}

print("\n✅ All tests passed! SettingsViewModel build fix is complete.")

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