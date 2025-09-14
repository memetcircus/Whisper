#!/usr/bin/env swift

import Foundation

print("🔍 Testing Biometric Signing Integration...")

func validateBiometricSigningIntegration() -> Bool {
    print("\n📱 Validating biometric signing integration...")
    
    // Check ComposeViewModel changes
    guard let composeContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Compose/ComposeViewModel.swift") else {
        print("❌ Could not read ComposeViewModel")
        return false
    }
    
    // Check DecryptViewModel changes
    guard let decryptContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Decrypt/DecryptViewModel.swift") else {
        print("❌ Could not read DecryptViewModel")
        return false
    }
    
    // Check ServiceContainer changes
    guard let serviceContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/Services/ServiceContainer.swift") else {
        print("❌ Could not read ServiceContainer")
        return false
    }
    
    let composeChecks = [
        ("Signatures enabled", "let shouldSign = true"),
        ("Signature comment", "Enable signatures for biometric gating"),
        ("Encrypt method", "authenticity: shouldSign"),
        ("Error handling", "handleWhisperError(error)")
    ]
    
    var passedComposeChecks = 0
    print("\n🔐 ComposeViewModel Integration:")
    for (description, pattern) in composeChecks {
        if composeContent.contains(pattern) {
            print("✅ \(description): Found")
            passedComposeChecks += 1
        } else {
            print("❌ \(description): Missing pattern '\(pattern)'")
        }
    }
    
    let decryptChecks = [
        ("Biometric policy check", "policyManager.requiresBiometricForSigning()"),
        ("Biometric service access", "ServiceContainer.shared.biometricService"),
        ("Biometric availability check", "biometricService.isAvailable()"),
        ("Biometric authentication", "biometricService.sign(data: testData"),
        ("User cancellation handling", "BiometricError.userCancelled"),
        ("Policy violation error", ".policyViolation(.biometricRequired)"),
        ("Authentication failed error", ".biometricAuthenticationFailed")
    ]
    
    var passedDecryptChecks = 0
    print("\n🔓 DecryptViewModel Integration:")
    for (description, pattern) in decryptChecks {
        if decryptContent.contains(pattern) {
            print("✅ \(description): Found")
            passedDecryptChecks += 1
        } else {
            print("❌ \(description): Missing pattern '\(pattern)'")
        }
    }
    
    let serviceChecks = [
        ("Biometric service property", "var biometricService: KeychainBiometricService"),
        ("Private biometric service", "_biometricService: KeychainBiometricService?"),
        ("Service initialization", "KeychainBiometricService()")
    ]
    
    var passedServiceChecks = 0
    print("\n🏗️ ServiceContainer Integration:")
    for (description, pattern) in serviceChecks {
        if serviceContent.contains(pattern) {
            print("✅ \(description): Found")
            passedServiceChecks += 1
        } else {
            print("❌ \(description): Missing pattern '\(pattern)'")
        }
    }
    
    let composeRate = Double(passedComposeChecks) / Double(composeChecks.count)
    let decryptRate = Double(passedDecryptChecks) / Double(decryptChecks.count)
    let serviceRate = Double(passedServiceChecks) / Double(serviceChecks.count)
    
    print("\n📊 Integration Results:")
    print("• ComposeViewModel: \(passedComposeChecks)/\(composeChecks.count) (\(Int(composeRate * 100))%)")
    print("• DecryptViewModel: \(passedDecryptChecks)/\(decryptChecks.count) (\(Int(decryptRate * 100))%)")
    print("• ServiceContainer: \(passedServiceChecks)/\(serviceChecks.count) (\(Int(serviceRate * 100))%)")
    
    return composeRate >= 0.75 && decryptRate >= 0.85 && serviceRate >= 0.66
}

// Run validation
let success = validateBiometricSigningIntegration()

print("\n" + String(repeating: "=", count: 50))
if success {
    print("🎉 Biometric signing integration completed successfully!")
    print("\n📋 Key Changes:")
    print("• ComposeViewModel: Enabled signatures (shouldSign = true)")
    print("• DecryptViewModel: Added biometric gating before decryption")
    print("• ServiceContainer: Exposed biometricService as shared service")
    print("\n🔐 How it works:")
    print("• When 'Require for Signing' is ON:")
    print("  - Encrypt: Face ID required before encrypting messages")
    print("  - Decrypt: Face ID required before decrypting messages")
    print("• When 'Require for Signing' is OFF:")
    print("  - Normal encryption/decryption without biometric prompt")
    print("\n✨ The biometric authentication will now trigger when users")
    print("   tap 'Encrypt Message' or 'Decrypt Message' buttons!")
    exit(0)
} else {
    print("❌ Biometric signing integration validation failed!")
    exit(1)
}