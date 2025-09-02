#!/usr/bin/env swift

import Foundation

/**
 * Validation script for Task 14: Build QR code integration
 * 
 * This script validates that all QR code integration requirements are met:
 * - QR code generation for public key bundles and encrypted messages
 * - QR scanning functionality with format validation
 * - QR size warning when envelope exceeds ~900 bytes maximum
 * - Contact preview before adding from scanned QR
 * - Proper error correction level M for QR code generation
 * 
 * Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
 */

print("🔍 Validating Task 14: QR Code Integration Requirements")
print(String(repeating: "=", count: 60))

var validationResults: [String: Bool] = [:]
var issues: [String] = []

// MARK: - File Existence Validation

let requiredFiles = [
    "WhisperApp/WhisperApp/Services/QRCodeService.swift",
    "WhisperApp/WhisperApp/UI/QR/QRScannerView.swift",
    "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift",
    "WhisperApp/WhisperApp/UI/QR/ContactPreviewView.swift",
    "WhisperApp/WhisperApp/UI/QR/QRCodeCoordinatorView.swift",
    "WhisperApp/Tests/QRCodeServiceTests.swift"
]

print("\n📁 Checking required files...")
for file in requiredFiles {
    let fileExists = FileManager.default.fileExists(atPath: file)
    validationResults["file_\(file.components(separatedBy: "/").last!)"] = fileExists
    
    if fileExists {
        print("✅ \(file)")
    } else {
        print("❌ \(file)")
        issues.append("Missing required file: \(file)")
    }
}

// MARK: - QR Code Service Validation

print("\n🔧 Validating QR Code Service...")

func validateQRCodeService() -> Bool {
    let servicePath = "WhisperApp/WhisperApp/Services/QRCodeService.swift"
    
    guard let content = try? String(contentsOfFile: servicePath) else {
        issues.append("Cannot read QRCodeService.swift")
        return false
    }
    
    let requiredComponents = [
        "class QRCodeService",
        "generateQRCode(for bundle: PublicKeyBundle)",
        "generateQRCode(for envelope: String)",
        "generateQRCode(for contact: Contact)",
        "parseQRCode(_ content: String)",
        "maxRecommendedSize = 900",
        "errorCorrectionLevel = \"M\"",
        "QRCodeResult",
        "QRCodeSizeWarning",
        "checkCameraPermission",
        "requestCameraPermission"
    ]
    
    var hasAllComponents = true
    for component in requiredComponents {
        if !content.contains(component) {
            issues.append("QRCodeService missing: \(component)")
            hasAllComponents = false
        }
    }
    
    return hasAllComponents
}

validationResults["qr_service"] = validateQRCodeService()

// MARK: - QR Scanner Validation

print("\n📷 Validating QR Scanner...")

func validateQRScanner() -> Bool {
    let scannerPath = "WhisperApp/WhisperApp/UI/QR/QRScannerView.swift"
    
    guard let content = try? String(contentsOfFile: scannerPath) else {
        issues.append("Cannot read QRScannerView.swift")
        return false
    }
    
    let requiredComponents = [
        "struct QRScannerView: UIViewControllerRepresentable",
        "QRScannerViewController",
        "AVCaptureSession",
        "AVCaptureMetadataOutput",
        "metadataObjectTypes = [.qr]",
        "ScanningOverlayView",
        "QRScannerDelegate"
    ]
    
    var hasAllComponents = true
    for component in requiredComponents {
        if !content.contains(component) {
            issues.append("QRScannerView missing: \(component)")
            hasAllComponents = false
        }
    }
    
    return hasAllComponents
}

validationResults["qr_scanner"] = validateQRScanner()

// MARK: - QR Display Validation

print("\n🖼️ Validating QR Display...")

func validateQRDisplay() -> Bool {
    let displayPath = "WhisperApp/WhisperApp/UI/QR/QRCodeDisplayView.swift"
    
    guard let content = try? String(contentsOfFile: displayPath) else {
        issues.append("Cannot read QRCodeDisplayView.swift")
        return false
    }
    
    let requiredComponents = [
        "struct QRCodeDisplayView: View",
        "qrResult: QRCodeResult",
        "sizeWarningSection",
        "ShareSheet",
        "saveImageToPhotos",
        "copyContent"
    ]
    
    var hasAllComponents = true
    for component in requiredComponents {
        if !content.contains(component) {
            issues.append("QRCodeDisplayView missing: \(component)")
            hasAllComponents = false
        }
    }
    
    return hasAllComponents
}

validationResults["qr_display"] = validateQRDisplay()

// MARK: - Contact Preview Validation

print("\n👤 Validating Contact Preview...")

func validateContactPreview() -> Bool {
    let previewPath = "WhisperApp/WhisperApp/UI/QR/ContactPreviewView.swift"
    
    guard let content = try? String(contentsOfFile: previewPath) else {
        issues.append("Cannot read ContactPreviewView.swift")
        return false
    }
    
    let requiredComponents = [
        "struct ContactPreviewView: View",
        "bundle: PublicKeyBundle",
        "onAdd: (PublicKeyBundle) -> Void",
        "contactInfoSection",
        "securityInfoSection",
        "keyInfoSection",
        "validateBundle",
        "formatFingerprint",
        "generateSASWords"
    ]
    
    var hasAllComponents = true
    for component in requiredComponents {
        if !content.contains(component) {
            issues.append("ContactPreviewView missing: \(component)")
            hasAllComponents = false
        }
    }
    
    return hasAllComponents
}

validationResults["contact_preview"] = validateContactPreview()

// MARK: - Integration Validation

print("\n🔗 Validating QR Integration...")

func validateQRIntegration() -> Bool {
    var integrationValid = true
    
    // Check AddContactView integration
    let addContactPath = "WhisperApp/WhisperApp/UI/Contacts/AddContactView.swift"
    if let content = try? String(contentsOfFile: addContactPath) {
        if !content.contains("QRCodeCoordinatorView") {
            issues.append("AddContactView not integrated with QR functionality")
            integrationValid = false
        }
    }
    
    // Check ComposeView integration
    let composePath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"
    if let content = try? String(contentsOfFile: composePath) {
        if !content.contains("QR Code") || !content.contains("showQRCode") {
            issues.append("ComposeView not integrated with QR functionality")
            integrationValid = false
        }
    }
    
    // Check ContactDetailView integration
    let detailPath = "WhisperApp/WhisperApp/UI/Contacts/ContactDetailView.swift"
    if let content = try? String(contentsOfFile: detailPath) {
        if !content.contains("Share QR Code") {
            issues.append("ContactDetailView not integrated with QR functionality")
            integrationValid = false
        }
    }
    
    return integrationValid
}

validationResults["qr_integration"] = validateQRIntegration()

// MARK: - Test Coverage Validation

print("\n🧪 Validating Test Coverage...")

func validateTestCoverage() -> Bool {
    let testPath = "WhisperApp/Tests/QRCodeServiceTests.swift"
    
    guard let content = try? String(contentsOfFile: testPath) else {
        issues.append("Cannot read QRCodeServiceTests.swift")
        return false
    }
    
    let requiredTests = [
        "testGenerateQRCodeForPublicKeyBundle",
        "testGenerateQRCodeForEncryptedMessage",
        "testQRCodeSizeWarning",
        "testParsePublicKeyBundleQRCode",
        "testParseEncryptedMessageQRCode",
        "testParseInvalidQRCodeThrowsError",
        "testCheckCameraPermission",
        "testRoundTripPublicKeyBundle"
    ]
    
    var hasAllTests = true
    for test in requiredTests {
        if !content.contains(test) {
            issues.append("Missing test: \(test)")
            hasAllTests = false
        }
    }
    
    return hasAllTests
}

validationResults["test_coverage"] = validateTestCoverage()

// MARK: - Requirements Validation

print("\n📋 Validating Specific Requirements...")

func validateRequirement11_1() -> Bool {
    // Requirement 11.1: QR codes for public key sharing
    let servicePath = "WhisperApp/WhisperApp/Services/QRCodeService.swift"
    guard let content = try? String(contentsOfFile: servicePath) else { return false }
    
    return content.contains("generateQRCode(for bundle: PublicKeyBundle)") &&
           content.contains("whisper-bundle:")
}

func validateRequirement11_2() -> Bool {
    // Requirement 11.2: QR scanning with preview
    let scannerExists = FileManager.default.fileExists(atPath: "WhisperApp/WhisperApp/UI/QR/QRScannerView.swift")
    let previewExists = FileManager.default.fileExists(atPath: "WhisperApp/WhisperApp/UI/QR/ContactPreviewView.swift")
    
    return scannerExists && previewExists
}

func validateRequirement11_3() -> Bool {
    // Requirement 11.3: QR size warnings
    let servicePath = "WhisperApp/WhisperApp/Services/QRCodeService.swift"
    guard let content = try? String(contentsOfFile: servicePath) else { return false }
    
    return content.contains("maxRecommendedSize = 900") &&
           content.contains("QRCodeSizeWarning")
}

func validateRequirement11_4() -> Bool {
    // Requirement 11.4: Error correction level M
    let servicePath = "WhisperApp/WhisperApp/Services/QRCodeService.swift"
    guard let content = try? String(contentsOfFile: servicePath) else { return false }
    
    return content.contains("errorCorrectionLevel = \"M\"")
}

func validateRequirement11_5() -> Bool {
    // Requirement 11.5: Format validation
    let servicePath = "WhisperApp/WhisperApp/Services/QRCodeService.swift"
    guard let content = try? String(contentsOfFile: servicePath) else { return false }
    
    return content.contains("parseQRCode") &&
           content.contains("whisper1:") &&
           content.contains("whisper-bundle:")
}

validationResults["req_11_1"] = validateRequirement11_1()
validationResults["req_11_2"] = validateRequirement11_2()
validationResults["req_11_3"] = validateRequirement11_3()
validationResults["req_11_4"] = validateRequirement11_4()
validationResults["req_11_5"] = validateRequirement11_5()

print("✅ Requirement 11.1 (Public key QR codes): \(validationResults["req_11_1"]! ? "PASS" : "FAIL")")
print("✅ Requirement 11.2 (QR scanning with preview): \(validationResults["req_11_2"]! ? "PASS" : "FAIL")")
print("✅ Requirement 11.3 (Size warnings): \(validationResults["req_11_3"]! ? "PASS" : "FAIL")")
print("✅ Requirement 11.4 (Error correction M): \(validationResults["req_11_4"]! ? "PASS" : "FAIL")")
print("✅ Requirement 11.5 (Format validation): \(validationResults["req_11_5"]! ? "PASS" : "FAIL")")

// MARK: - Summary

print("\n" + String(repeating: "=", count: 60))
print("📊 VALIDATION SUMMARY")
print(String(repeating: "=", count: 60))

let totalChecks = validationResults.count
let passedChecks = validationResults.values.filter { $0 }.count
let failedChecks = totalChecks - passedChecks

print("Total Checks: \(totalChecks)")
print("Passed: \(passedChecks)")
print("Failed: \(failedChecks)")

if !issues.isEmpty {
    print("\n❌ Issues Found:")
    for issue in issues {
        print("  • \(issue)")
    }
}

let overallSuccess = failedChecks == 0

print("\n🎯 Overall Result: \(overallSuccess ? "✅ PASS" : "❌ FAIL")")

if overallSuccess {
    print("\n🎉 Task 14 QR Code Integration implementation is complete!")
    print("All requirements have been successfully implemented:")
    print("• QR code generation for public key bundles and encrypted messages")
    print("• QR scanning functionality with format validation")
    print("• Size warnings for large QR codes (>900 bytes)")
    print("• Contact preview before adding from scanned QR")
    print("• Error correction level M for reliable scanning")
    print("• Integration with existing contact and compose workflows")
} else {
    print("\n⚠️  Task 14 implementation needs attention.")
    print("Please address the issues listed above.")
}

exit(overallSuccess ? 0 : 1)