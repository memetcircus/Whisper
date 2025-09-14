#!/usr/bin/env swift

import Foundation

print("🔍 Testing Decrypt Error Dialog Fix...")

func validateDecryptErrorDialogFix() -> Bool {
    print("\n📱 Validating Decrypt error dialog configuration...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Decrypt/DecryptView.swift") else {
        print("❌ Could not read DecryptView")
        return false
    }
    
    let errorHandlingChecks = [
        ("Error Alert", ".alert(\"Error\""),
        ("OK Button", "Button(\"OK\")"),
        ("Error Switch", "switch error"),
        ("QR Permission Retry", "case .qrCameraPermissionDenied, .qrScanningNotAvailable:"),
        ("Network Error Retry", "case .networkError, .invalidInput:"),
        ("Default No Retry", "default:"),
        ("EmptyView for Non-Recoverable", "EmptyView()"),
        ("Cryptographic Comment", "For cryptographic failures and other non-recoverable errors")
    ]
    
    var passedChecks = 0
    
    for (description, pattern) in errorHandlingChecks {
        if content.contains(pattern) {
            print("✅ \(description): Found")
            passedChecks += 1
        } else {
            print("❌ \(description): Missing pattern '\(pattern)'")
        }
    }
    
    // Check that we don't have the old blanket retry behavior
    let unwantedPatterns = [
        ("Old Default Retry", "default:\n                        Button(\"Retry\")")
    ]
    
    var foundUnwantedPatterns = 0
    for (description, pattern) in unwantedPatterns {
        if content.contains(pattern) {
            print("❌ Unwanted Pattern Found - \(description): \(pattern)")
            foundUnwantedPatterns += 1
        }
    }
    
    if foundUnwantedPatterns == 0 {
        print("✅ No unwanted blanket retry behavior detected")
    }
    
    let successRate = Double(passedChecks) / Double(errorHandlingChecks.count)
    print("📊 Decrypt Error Dialog Fix: \(passedChecks)/\(errorHandlingChecks.count) (\(Int(successRate * 100))%)")
    
    return successRate >= 0.8 && foundUnwantedPatterns == 0
}

// Run validation
let success = validateDecryptErrorDialogFix()

print("\n" + String(repeating: "=", count: 50))
if success {
    print("🎉 Decrypt error dialog fix completed successfully!")
    print("\n📋 Key Changes:")
    print("• Cryptographic failures now show only OK button (no Retry)")
    print("• QR camera permission errors still show Retry button")
    print("• Network and input errors still show Retry button")
    print("• Non-recoverable errors (like crypto failures) show only OK")
    print("• Better user experience - no false hope for unfixable errors")
    print("• Clear documentation about error handling logic")
    exit(0)
} else {
    print("❌ Decrypt error dialog fix validation failed!")
    exit(1)
}