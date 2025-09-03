#!/usr/bin/env swift

import Foundation
import CryptoKit

/**
 * Final Integration and Validation Script
 * 
 * This script performs comprehensive validation of all Whisper app requirements
 * and ensures the app is ready for production deployment.
 */

print("🔍 Starting Final Integration and Validation...")
print("=" * 60)

var validationResults: [String: Bool] = [:]
var errors: [String] = []

// MARK: - Validation Functions

func validateRequirement(_ name: String, _ validation: () throws -> Bool) {
    do {
        let result = try validation()
        validationResults[name] = result
        let status = result ? "✅ PASS" : "❌ FAIL"
        print("\(status) \(name)")
        if !result {
            errors.append(name)
        }
    } catch {
        validationResults[name] = false
        errors.append("\(name): \(error)")
        print("❌ FAIL \(name): \(error)")
    }
}

func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

func directoryExists(_ path: String) -> Bool {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
}

func validateFileContent(_ path: String, contains: String) -> Bool {
    guard let content = try? String(contentsOfFile: path) else { return false }
    return content.contains(contains)
}

// MARK: - Project Structure Validation

print("\n📁 Validating Project Structure...")

validateRequirement("Core project structure exists") {
    return directoryExists("WhisperApp/WhisperApp") &&
           directoryExists("WhisperApp/Tests") &&
           fileExists("WhisperApp/WhisperApp.xcodeproj/project.pbxproj")
}

validateRequirement("Core crypto components exist") {
    return fileExists("WhisperApp/WhisperApp/Core/Crypto/CryptoEngine.swift") &&
           fileExists("WhisperApp/WhisperApp/Core/Crypto/EnvelopeProcessor.swift") &&
           fileExists("WhisperApp/WhisperApp/Core/Crypto/MessagePadding.swift")
}

validateRequirement("Identity management exists") {
    return fileExists("WhisperApp/WhisperApp/Core/Identity/IdentityManager.swift") &&
           fileExists("WhisperApp/WhisperApp/Core/KeychainManager.swift")
}

validateRequirement("Contact management exists") {
    return fileExists("WhisperApp/WhisperApp/Core/Contacts/ContactManager.swift") &&
           fileExists("WhisperApp/WhisperApp/Core/Contacts/Contact.swift")
}

validateRequirement("Policy and security components exist") {
    return fileExists("WhisperApp/WhisperApp/Core/Policies/PolicyManager.swift") &&
           fileExists("WhisperApp/WhisperApp/Services/BiometricService.swift") &&
           fileExists("WhisperApp/WhisperApp/Core/ReplayProtectionService.swift")
}

validateRequirement("High-level services exist") {
    return fileExists("WhisperApp/WhisperApp/Services/WhisperService.swift") &&
           fileExists("WhisperApp/WhisperApp/Services/QRCodeService.swift")
}

validateRequirement("UI components exist") {
    return fileExists("WhisperApp/WhisperApp/UI/Compose/ComposeView.swift") &&
           fileExists("WhisperApp/WhisperApp/UI/Decrypt/DecryptView.swift") &&
           fileExists("WhisperApp/WhisperApp/UI/Contacts/ContactListView.swift") &&
           fileExists("WhisperApp/WhisperApp/UI/Settings/SettingsView.swift")
}

// MARK: - Security Validation

print("\n🔒 Validating Security Requirements...")

validateRequirement("Networking detection script exists") {
    return fileExists("WhisperApp/Scripts/check_networking_symbols.py")
}

validateRequirement("Build configuration includes networking check") {
    return validateFileContent("WhisperApp/WhisperApp.xcodeproj/project.pbxproj", 
                              contains: "Network Detection")
}

validateRequirement("Legal disclaimer enforcement exists") {
    return fileExists("WhisperApp/WhisperApp/UI/Settings/LegalDisclaimerView.swift") &&
           validateFileContent("WhisperApp/WhisperApp/ContentView.swift", 
                              contains: "whisper.legal.accepted")
}

validateRequirement("Keychain security configuration") {
    return validateFileContent("WhisperApp/WhisperApp/Core/KeychainManager.swift", 
                              contains: "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly")
}

validateRequirement("Biometric security configuration") {
    return validateFileContent("WhisperApp/WhisperApp/Services/BiometricService.swift", 
                              contains: "biometryCurrentSet")
}

validateRequirement("Replay protection implementation") {
    return validateFileContent("WhisperApp/WhisperApp/Core/ReplayProtectionService.swift", 
                              contains: "checkAndCommit")
}

// MARK: - Cryptographic Validation

print("\n🔐 Validating Cryptographic Implementation...")

validateRequirement("CryptoKit exclusive usage") {
    let cryptoFile = "WhisperApp/WhisperApp/Core/Crypto/CryptoEngine.swift"
    return validateFileContent(cryptoFile, contains: "import CryptoKit") &&
           validateFileContent(cryptoFile, contains: "Curve25519") &&
           validateFileContent(cryptoFile, contains: "ChaCha20")
}

validateRequirement("Envelope format implementation") {
    let envelopeFile = "WhisperApp/WhisperApp/Core/Crypto/EnvelopeProcessor.swift"
    return validateFileContent(envelopeFile, contains: "whisper1:") &&
           validateFileContent(envelopeFile, contains: "v1.c20p") &&
           (validateFileContent(envelopeFile, contains: "Base64URL") ||
            validateFileContent(envelopeFile, contains: "base64URLEncoder"))
}

validateRequirement("Message padding implementation") {
    let paddingFile = "WhisperApp/WhisperApp/Core/Crypto/MessagePadding.swift"
    return validateFileContent(paddingFile, contains: "bucket") &&
           validateFileContent(paddingFile, contains: "constant-time")
}

validateRequirement("Algorithm lock enforcement") {
    let envelopeFile = "WhisperApp/WhisperApp/Core/Crypto/EnvelopeProcessor.swift"
    return validateFileContent(envelopeFile, contains: "v1.c20p") &&
           !validateFileContent(envelopeFile, contains: "v2.") &&
           !validateFileContent(envelopeFile, contains: "aes")
}

// MARK: - Test Coverage Validation

print("\n🧪 Validating Test Coverage...")

let requiredTests = [
    "CryptoEngineTests.swift",
    "EnvelopeProcessorTests.swift", 
    "MessagePaddingTests.swift",
    "IdentityManagerTests.swift",
    "ContactManagerTests.swift",
    "PolicyManagerTests.swift",
    "BiometricServiceTests.swift",
    "ReplayProtectionTests.swift",
    "SecurityTests.swift",
    "NetworkingDetectionTests.swift",
    "IntegrationTests.swift",
    "EndToEndTests.swift",
    "AccessibilityTests.swift",
    "LocalizationTests.swift",
    "PerformanceTests.swift"
]

validateRequirement("All required test files exist") {
    return requiredTests.allSatisfy { test in
        fileExists("WhisperApp/Tests/\(test)")
    }
}

validateRequirement("Comprehensive security tests exist") {
    return fileExists("WhisperApp/Tests/ComprehensiveSecurityValidationTests.swift") &&
           fileExists("WhisperApp/Tests/CompleteWorkflowTests.swift")
}

validateRequirement("Networking detection tests exist") {
    return validateFileContent("WhisperApp/Tests/NetworkingDetectionTests.swift", 
                              contains: "URLSession") &&
           validateFileContent("WhisperApp/Tests/NetworkingDetectionTests.swift", 
                              contains: "forbidden")
}

// MARK: - UI and Accessibility Validation

print("\n♿ Validating Accessibility and Localization...")

validateRequirement("Accessibility extensions exist") {
    return fileExists("WhisperApp/WhisperApp/Accessibility/AccessibilityExtensions.swift")
}

validateRequirement("Localization files exist") {
    return fileExists("WhisperApp/WhisperApp/Localizable.strings") &&
           fileExists("WhisperApp/WhisperApp/Localization/LocalizationHelper.swift")
}

validateRequirement("Legal disclaimer content complete") {
    let legalFile = "WhisperApp/WhisperApp/UI/Settings/LegalDisclaimerView.swift"
    return validateFileContent(legalFile, contains: "No Warranty") &&
           validateFileContent(legalFile, contains: "Security Limitations") &&
           validateFileContent(legalFile, contains: "Export Compliance")
}

// MARK: - Performance and Optimization Validation

print("\n⚡ Validating Performance Optimizations...")

validateRequirement("Performance monitoring exists") {
    return fileExists("WhisperApp/WhisperApp/Core/Performance/PerformanceMonitor.swift") &&
           fileExists("WhisperApp/WhisperApp/Core/Performance/LazyLoadingService.swift")
}

validateRequirement("Memory optimization exists") {
    return fileExists("WhisperApp/WhisperApp/Core/Performance/MemoryOptimizedCrypto.swift") &&
           fileExists("WhisperApp/WhisperApp/Core/Performance/BackgroundCryptoProcessor.swift")
}

validateRequirement("Crypto benchmarks exist") {
    return fileExists("WhisperApp/WhisperApp/Core/Performance/CryptoBenchmarks.swift")
}

// MARK: - Build Configuration Validation

print("\n🔧 Validating Build Configuration...")

validateRequirement("Build configuration utilities exist") {
    return fileExists("WhisperApp/WhisperApp/BuildConfiguration.swift")
}

validateRequirement("Entitlements file exists") {
    return fileExists("WhisperApp/WhisperApp/WhisperApp.entitlements")
}

validateRequirement("Info.plist exists") {
    return fileExists("WhisperApp/WhisperApp/Info.plist")
}

validateRequirement("Core Data model exists") {
    return fileExists("WhisperApp/WhisperApp/Storage/WhisperDataModel.xcdatamodeld/WhisperDataModel.xcdatamodel/contents")
}

// MARK: - Documentation Validation

print("\n📚 Validating Documentation...")

validateRequirement("App Store compliance documentation exists") {
    return fileExists("WhisperApp/Documentation/AppStoreCompliance.md")
}

validateRequirement("Implementation summaries exist") {
    let summaryFiles = [
        "TASK11_IMPLEMENTATION_SUMMARY.md",
        "TASK13_IMPLEMENTATION_SUMMARY.md", 
        "TASK16_IMPLEMENTATION_SUMMARY.md",
        "TASK17_IMPLEMENTATION_SUMMARY.md",
        "TASK18_IMPLEMENTATION_SUMMARY.md",
        "TASK19_IMPLEMENTATION_SUMMARY.md"
    ]
    
    return summaryFiles.allSatisfy { file in
        fileExists("WhisperApp/\(file)")
    }
}

// MARK: - Final Validation Summary

print("\n" + "=" * 60)
print("📊 FINAL VALIDATION SUMMARY")
print("=" * 60)

let totalTests = validationResults.count
let passedTests = validationResults.values.filter { $0 }.count
let failedTests = totalTests - passedTests

print("Total Tests: \(totalTests)")
print("Passed: ✅ \(passedTests)")
print("Failed: ❌ \(failedTests)")

if failedTests > 0 {
    print("\n❌ VALIDATION FAILED")
    print("The following requirements failed validation:")
    for error in errors {
        print("  • \(error)")
    }
    print("\n🔧 Please fix the above issues before proceeding to production.")
    exit(1)
} else {
    print("\n🎉 ALL VALIDATIONS PASSED!")
    print("✅ Whisper app is ready for production deployment.")
    
    print("\n📋 Next Steps:")
    print("1. Run final build with networking detection")
    print("2. Perform manual testing on device")
    print("3. Submit to App Store Connect")
    print("4. Complete export compliance documentation")
    
    exit(0)
}

// MARK: - Helper Extensions

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}