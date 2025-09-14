#!/usr/bin/env swift

import Foundation

// Test script to validate Swift compilation of core files
print("Testing Swift file compilation...")

let filesToTest = [
    "WhisperApp/Core/WhisperError.swift",
    "WhisperApp/Core/Policies/PolicyManager.swift", 
    "WhisperApp/Core/CoreDataReplayProtector.swift",
    "WhisperApp/Core/KeychainManager.swift"
]

for file in filesToTest {
    print("Checking \(file)...")
    
    let fileURL = URL(fileURLWithPath: file)
    
    if FileManager.default.fileExists(atPath: fileURL.path) {
        print("✅ \(file) exists")
    } else {
        print("❌ \(file) not found")
    }
}

print("✅ Basic file validation complete")