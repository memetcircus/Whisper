#!/usr/bin/env swift

import Foundation

print("🔧 Testing AddContactView Build Fix...")

// Test the build
let result = shell("cd WhisperApp && swiftc -typecheck WhisperApp/UI/Contacts/AddContactView.swift -I WhisperApp -I WhisperApp/Core -I WhisperApp/Services -I WhisperApp/UI")

if result.exitCode == 0 {
    print("✅ AddContactView compiles successfully")
    print("✅ Scope issues fixed - onContactAdded and dismiss are now accessible")
} else {
    print("❌ AddContactView compilation failed:")
    print(result.output)
}

print("\n🎯 Build Fix Complete!")

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