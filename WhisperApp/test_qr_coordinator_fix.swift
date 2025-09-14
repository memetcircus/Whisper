#!/usr/bin/env swift

import Foundation

print("🔧 Testing QR Coordinator Fix...")

// Test 1: Check if QRCodeCoordinatorView compiles
print("\n1. Checking QRCodeCoordinatorView compilation...")

let result = shell("cd WhisperApp && swiftc -typecheck WhisperApp/UI/QR/QRCodeCoordinatorView.swift -I WhisperApp -I WhisperApp/Core -I WhisperApp/Services -I WhisperApp/UI")

if result.exitCode == 0 {
    print("✅ QRCodeCoordinatorView compiles successfully")
} else {
    print("❌ QRCodeCoordinatorView compilation failed:")
    print(result.output)
}

// Test 2: Check if ContactPreviewView compiles
print("\n2. Checking ContactPreviewView compilation...")

let result2 = shell("cd WhisperApp && swiftc -typecheck WhisperApp/UI/QR/ContactPreviewView.swift -I WhisperApp -I WhisperApp/Core")

if result2.exitCode == 0 {
    print("✅ ContactPreviewView compiles successfully")
} else {
    print("❌ ContactPreviewView compilation failed:")
    print(result2.output)
}

// Test 3: Check if AddContactView compiles
print("\n3. Checking AddContactView compilation...")

let result3 = shell("cd WhisperApp && swiftc -typecheck WhisperApp/UI/Contacts/AddContactView.swift -I WhisperApp -I WhisperApp/Core -I WhisperApp/UI")

if result3.exitCode == 0 {
    print("✅ AddContactView compiles successfully")
} else {
    print("❌ AddContactView compilation failed:")
    print(result3.output)
}

print("\n🎯 QR Coordinator Fix Test Complete!")

// Helper function
func shell(_ command: String) -> (output: String, exitCode: Int32) {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    
    return (output, task.terminationStatus)
}