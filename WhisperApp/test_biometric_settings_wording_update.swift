#!/usr/bin/env swift

import Foundation

print("🧪 Testing Biometric Settings Wording Updates...")

// Test 1: Build the project
print("\n1️⃣ Building project...")
let buildResult = shell("cd WhisperApp && xcodebuild -project WhisperApp.xcodeproj -scheme WhisperApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build")

if buildResult.contains("BUILD SUCCEEDED") {
    print("✅ Build successful!")
} else {
    print("❌ Build failed:")
    print(buildResult)
    exit(1)
}

// Test 2: Check that the wording changes are correct
print("\n2️⃣ Verifying wording changes...")

let biometricSettingsView = try String(contentsOfFile: "WhisperApp/WhisperApp/UI/Settings/BiometricSettingsView.swift")
let biometricSettingsViewModel = try String(contentsOfFile: "WhisperApp/WhisperApp/UI/Settings/BiometricSettingsViewModel.swift")

var wordingTests: [(String, String, Bool)] = []

// Check BiometricSettingsView changes
wordingTests.append(("BiometricSettingsView", "Require for Encryption", biometricSettingsView.contains("Require for Encryption")))
wordingTests.append(("BiometricSettingsView", "encrypting and decrypting messages", biometricSettingsView.contains("encrypting and decrypting messages")))
wordingTests.append(("BiometricSettingsView", "encryption keys with biometric", biometricSettingsView.contains("encryption keys with biometric")))
wordingTests.append(("BiometricSettingsView", "encrypt or decrypt a message", biometricSettingsView.contains("encrypt or decrypt a message")))
wordingTests.append(("BiometricSettingsView", "Enroll Encryption Key", biometricSettingsView.contains("Enroll Encryption Key")))

// Check BiometricSettingsViewModel changes  
wordingTests.append(("BiometricSettingsViewModel", "Encryption key enrolled successfully", biometricSettingsViewModel.contains("Encryption key enrolled successfully")))
wordingTests.append(("BiometricSettingsViewModel", "Failed to enroll encryption key", biometricSettingsViewModel.contains("Failed to enroll encryption key")))

// Verify old wording is removed
wordingTests.append(("BiometricSettingsView", "No 'Require for Signing'", !biometricSettingsView.contains("Require for Signing")))
wordingTests.append(("BiometricSettingsView", "No 'signing messages'", !biometricSettingsView.contains("signing messages")))
wordingTests.append(("BiometricSettingsViewModel", "No 'Signing key enrolled'", !biometricSettingsViewModel.contains("Signing key enrolled successfully")))

var allPassed = true
for (file, test, passed) in wordingTests {
    let status = passed ? "✅" : "❌"
    print("\(status) \(file): \(test)")
    if !passed { allPassed = false }
}

if allPassed {
    print("\n🎉 All wording updates verified successfully!")
    print("\n📝 Summary of Changes:")
    print("• 'Require for Signing' → 'Require for Encryption'")
    print("• 'signing messages' → 'encrypting and decrypting messages'") 
    print("• 'signing keys' → 'encryption keys'")
    print("• 'sign a message' → 'encrypt or decrypt a message'")
    print("• 'Enroll Signing Key' → 'Enroll Encryption Key'")
    print("• Updated all alert messages and success/error text")
    print("\n✨ The biometric settings now accurately reflect that Face ID is used for both encryption and decryption operations!")
} else {
    print("\n❌ Some wording updates are missing!")
    exit(1)
}

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}