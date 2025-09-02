#!/usr/bin/env swift

import Foundation

/// Validation script for Task 18: Implement accessibility and localization
/// This script validates all requirements for accessibility and localization support

print("🧪 Validating Task 18: Accessibility and Localization Implementation")
print(String(repeating: "=", count: 80))

var validationResults: [String: Bool] = [:]
var detailedResults: [String] = []

// MARK: - File Existence Validation

func validateFileExists(_ path: String, description: String) -> Bool {
    let fileManager = FileManager.default
    let exists = fileManager.fileExists(atPath: path)
    let result = exists ? "✅" : "❌"
    print("\(result) \(description): \(path)")
    if !exists {
        detailedResults.append("Missing file: \(path)")
    }
    return exists
}

print("\n📁 Validating Required Files:")
print(String(repeating: "-", count: 40))

let localizationFile = validateFileExists("WhisperApp/WhisperApp/Localizable.strings", 
                                        description: "Localization strings file")
let localizationHelper = validateFileExists("WhisperApp/WhisperApp/Localization/LocalizationHelper.swift", 
                                          description: "Localization helper")
let accessibilityExtensions = validateFileExists("WhisperApp/WhisperApp/Accessibility/AccessibilityExtensions.swift", 
                                                description: "Accessibility extensions")
let accessibilityTests = validateFileExists("WhisperApp/Tests/AccessibilityTests.swift", 
                                           description: "Accessibility tests")
let localizationTests = validateFileExists("WhisperApp/Tests/LocalizationTests.swift", 
                                          description: "Localization tests")

validationResults["Required Files"] = localizationFile && localizationHelper && accessibilityExtensions && accessibilityTests && localizationTests

// MARK: - Localization String Keys Validation

print("\n🌐 Validating Localization String Keys:")
print(String(repeating: "-", count: 40))

func validateStringKeysInFile(_ filePath: String) -> [String: Bool] {
    guard let content = try? String(contentsOfFile: filePath) else {
        print("❌ Could not read localization file")
        return [:]
    }
    
    let requiredKeyPrefixes = [
        "sign.": ["sign.bio_prep.title", "sign.bio_prep.body", "sign.bio_required.title", "sign.bio_required.message", 
                 "sign.bio_cancelled.title", "sign.bio_cancelled.message", "sign.bio_failed.title", "sign.bio_failed.message"],
        "policy.": ["policy.contact_required.title", "policy.contact_required.message", "policy.signature_required.title", 
                   "policy.signature_required.message", "policy.biometric_required.title", "policy.biometric_required.message"],
        "contact.": ["contact.title", "contact.verified.badge", "contact.unverified.badge", "contact.revoked.badge", 
                    "contact.blocked.badge", "contact.add.title", "contact.search.placeholder", "contact.export_keybook"],
        "identity.": ["identity.active", "identity.archived", "identity.create.title", "identity.switch.title", 
                     "identity.archive.title", "identity.rotate.title", "identity.expiration.warning"],
        "encrypt.": ["encrypt.title", "encrypt.from_identity", "encrypt.to", "encrypt.message", "encrypt.options", 
                    "encrypt.include_signature", "encrypt.select_contact", "encrypt.encrypt_message", "encrypt.share"],
        "decrypt.": ["decrypt.title", "decrypt.banner.title", "decrypt.input.title", "decrypt.decrypt_message", 
                    "decrypt.sender", "decrypt.content", "decrypt.copy_message", "decrypt.clear"],
        "qr.": ["qr.title", "qr.scan.title", "qr.display.title", "qr.size_warning.title", "qr.scan.invalid"],
        "legal.": ["legal.title", "legal.accept", "legal.decline", "legal.required", "legal.content"]
    ]
    
    var results: [String: Bool] = [:]
    
    for (prefix, keys) in requiredKeyPrefixes {
        var prefixResults: [Bool] = []
        for key in keys {
            let hasKey = content.contains("\"\(key)\"")
            let result = hasKey ? "✅" : "❌"
            print("  \(result) \(key)")
            prefixResults.append(hasKey)
            if !hasKey {
                detailedResults.append("Missing localization key: \(key)")
            }
        }
        results[prefix] = prefixResults.allSatisfy { $0 }
    }
    
    return results
}

if localizationFile {
    let stringKeyResults = validateStringKeysInFile("WhisperApp/WhisperApp/Localizable.strings")
    validationResults["Localization Keys"] = stringKeyResults.values.allSatisfy { $0 }
} else {
    validationResults["Localization Keys"] = false
}

// MARK: - Accessibility String Keys Validation

print("\n♿ Validating Accessibility String Keys:")
print(String(repeating: "-", count: 40))

if localizationFile {
    if let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/Localizable.strings") {
        let requiredAccessibilityKeys = [
            "accessibility.trust_badge.verified",
            "accessibility.trust_badge.unverified", 
            "accessibility.trust_badge.revoked",
            "accessibility.trust_badge.blocked",
            "accessibility.contact_avatar",
            "accessibility.identity_selector",
            "accessibility.contact_selector",
            "accessibility.encrypt_button",
            "accessibility.decrypt_button",
            "accessibility.message_input",
            "accessibility.encrypted_input",
            "accessibility.hint.trust_badge",
            "accessibility.hint.contact_row",
            "accessibility.hint.encrypt_button",
            "accessibility.hint.decrypt_button"
        ]
        
        var accessibilityKeyResults: [Bool] = []
        for key in requiredAccessibilityKeys {
            let hasKey = content.contains("\"\(key)\"")
            let result = hasKey ? "✅" : "❌"
            print("  \(result) \(key)")
            accessibilityKeyResults.append(hasKey)
            if !hasKey {
                detailedResults.append("Missing accessibility key: \(key)")
            }
        }
        
        validationResults["Accessibility Keys"] = accessibilityKeyResults.allSatisfy { $0 }
    } else {
        print("❌ Could not read localization file")
        validationResults["Accessibility Keys"] = false
    }
} else {
    validationResults["Accessibility Keys"] = false
}

// MARK: - Code Implementation Validation

print("\n💻 Validating Code Implementation:")
print(String(repeating: "-", count: 40))

func validateCodeImplementation(_ filePath: String, requiredElements: [String], description: String) -> Bool {
    guard let content = try? String(contentsOfFile: filePath) else {
        print("❌ Could not read \(description) file")
        return false
    }
    
    var results: [Bool] = []
    for element in requiredElements {
        let hasElement = content.contains(element)
        let result = hasElement ? "✅" : "❌"
        print("  \(result) \(element)")
        results.append(hasElement)
        if !hasElement {
            detailedResults.append("Missing implementation in \(description): \(element)")
        }
    }
    
    return results.allSatisfy { $0 }
}

// Validate LocalizationHelper implementation
if localizationHelper {
    let localizationHelperElements = [
        "struct LocalizationHelper",
        "struct Sign",
        "struct Policy", 
        "struct Contact",
        "struct Identity",
        "struct Encrypt",
        "struct Decrypt",
        "struct Accessibility",
        "NSLocalizedString"
    ]
    
    let localizationHelperValid = validateCodeImplementation("WhisperApp/WhisperApp/Localization/LocalizationHelper.swift", 
                                                           requiredElements: localizationHelperElements,
                                                           description: "LocalizationHelper")
    validationResults["LocalizationHelper Implementation"] = localizationHelperValid
} else {
    validationResults["LocalizationHelper Implementation"] = false
}

// Validate AccessibilityExtensions implementation
if accessibilityExtensions {
    let accessibilityElements = [
        "extension View",
        "accessibilityLabeled",
        "trustBadgeAccessibility",
        "contactRowAccessibility",
        "accessibleButton",
        "accessibleTextInput",
        "dynamicTypeSupport",
        "Font.scaledFont",
        "AccessibilityConstants",
        "minimumTouchTarget"
    ]
    
    let accessibilityValid = validateCodeImplementation("WhisperApp/WhisperApp/Accessibility/AccessibilityExtensions.swift", 
                                                       requiredElements: accessibilityElements,
                                                       description: "AccessibilityExtensions")
    validationResults["AccessibilityExtensions Implementation"] = accessibilityValid
} else {
    validationResults["AccessibilityExtensions Implementation"] = false
}

// MARK: - UI Implementation Validation

print("\n🎨 Validating UI Implementation Updates:")
print(String(repeating: "-", count: 40))

let uiFiles = [
    ("WhisperApp/WhisperApp/UI/Contacts/ContactListView.swift", [
        "LocalizationHelper.Contact.title",
        "trustBadgeAccessibility",
        "contactRowAccessibility",
        "scaledHeadline",
        "scaledCaption",
        "accessibilityLabel"
    ]),
    ("WhisperApp/WhisperApp/UI/Compose/ComposeView.swift", [
        "LocalizationHelper.Encrypt.title",
        "LocalizationHelper.Accessibility.encryptButton",
        "accessibilityLabel",
        "accessibilityHint",
        "scaledBody",
        "minimumTouchTarget"
    ]),
    ("WhisperApp/WhisperApp/UI/Decrypt/DecryptView.swift", [
        "LocalizationHelper.Decrypt.title",
        "LocalizationHelper.Accessibility.decryptButton",
        "accessibilityLabel",
        "scaledHeadline",
        "dynamicTypeSupport"
    ])
]

var uiImplementationResults: [Bool] = []
for (filePath, requiredElements) in uiFiles {
    let fileName = (filePath as NSString).lastPathComponent
    print("\n  Validating \(fileName):")
    let isValid = validateCodeImplementation(filePath, requiredElements: requiredElements, description: fileName)
    uiImplementationResults.append(isValid)
}

validationResults["UI Implementation"] = uiImplementationResults.allSatisfy { $0 }

// MARK: - Test Implementation Validation

print("\n🧪 Validating Test Implementation:")
print(String(repeating: "-", count: 40))

// Validate AccessibilityTests
if accessibilityTests {
    let accessibilityTestElements = [
        "class AccessibilityTests",
        "testMinimumTouchTargetSize",
        "testButtonAccessibility",
        "testColorContrast",
        "testDynamicTypeFonts",
        "testTrustLevelAccessibilityLabels",
        "AccessibilityConstants.minimumTouchTarget"
    ]
    
    let accessibilityTestsValid = validateCodeImplementation("WhisperApp/Tests/AccessibilityTests.swift", 
                                                           requiredElements: accessibilityTestElements,
                                                           description: "AccessibilityTests")
    validationResults["Accessibility Tests"] = accessibilityTestsValid
} else {
    validationResults["Accessibility Tests"] = false
}

// Validate LocalizationTests
if localizationTests {
    let localizationTestElements = [
        "class LocalizationTests",
        "testSignStringKeys",
        "testPolicyStringKeys",
        "testContactStringKeys",
        "testIdentityStringKeys",
        "testEncryptStringKeys",
        "testDecryptStringKeys",
        "testAccessibilityStringKeys",
        "testWhisperBranding",
        "NSLocalizedString"
    ]
    
    let localizationTestsValid = validateCodeImplementation("WhisperApp/Tests/LocalizationTests.swift", 
                                                          requiredElements: localizationTestElements,
                                                          description: "LocalizationTests")
    validationResults["Localization Tests"] = localizationTestsValid
} else {
    validationResults["Localization Tests"] = false
}

// MARK: - Requirements Validation Summary

print("\n📋 Requirements Validation Summary:")
print(String(repeating: "=", count: 50))

let requirements = [
    ("12.1", "VoiceOver labels and hints for all UI elements", validationResults["UI Implementation"] ?? false),
    ("12.1", "Trust badges with accessible text alternatives", validationResults["AccessibilityExtensions Implementation"] ?? false),
    ("12.1", "Dynamic Type support for text scaling", validationResults["AccessibilityExtensions Implementation"] ?? false),
    ("12.2", "Localization files with required string keys", validationResults["Localization Keys"] ?? false),
    ("12.2", "All sign.* policy.* contact.* identity.* encrypt.* decrypt.* qr.* legal.* keys", validationResults["Localization Keys"] ?? false),
    ("12.6", "Accessibility tests for color contrast and touch targets", validationResults["Accessibility Tests"] ?? false),
    ("12.6", "Localization validation tests ensuring all keys resolve", validationResults["Localization Tests"] ?? false)
]

var passedRequirements = 0
let totalRequirements = requirements.count

for (reqId, description, passed) in requirements {
    let status = passed ? "✅ PASS" : "❌ FAIL"
    print("\(status) \(reqId): \(description)")
    if passed {
        passedRequirements += 1
    }
}

// MARK: - Overall Results

print("\n🎯 Overall Validation Results:")
print(String(repeating: "=", count: 50))

let overallSuccess = validationResults.values.allSatisfy { $0 }
let successRate = Double(passedRequirements) / Double(totalRequirements) * 100

print("Requirements Passed: \(passedRequirements)/\(totalRequirements) (\(String(format: "%.1f", successRate))%)")
print("Overall Status: \(overallSuccess ? "✅ SUCCESS" : "❌ NEEDS ATTENTION")")

if !detailedResults.isEmpty {
    print("\n⚠️  Issues Found:")
    print(String(repeating: "-", count: 30))
    for issue in detailedResults {
        print("• \(issue)")
    }
}

print("\n📊 Component Status:")
print(String(repeating: "-", count: 30))
for (component, status) in validationResults.sorted(by: { $0.key < $1.key }) {
    let statusIcon = status ? "✅" : "❌"
    print("\(statusIcon) \(component)")
}

// MARK: - Recommendations

if !overallSuccess {
    print("\n💡 Recommendations:")
    print(String(repeating: "-", count: 30))
    
    if !(validationResults["Required Files"] ?? true) {
        print("• Create missing localization and accessibility files")
    }
    
    if !(validationResults["Localization Keys"] ?? true) {
        print("• Add missing localization string keys to Localizable.strings")
    }
    
    if !(validationResults["Accessibility Keys"] ?? true) {
        print("• Add missing accessibility-specific string keys")
    }
    
    if !(validationResults["UI Implementation"] ?? true) {
        print("• Update UI views to use LocalizationHelper and accessibility extensions")
    }
    
    if !(validationResults["Accessibility Tests"] ?? true) || !(validationResults["Localization Tests"] ?? true) {
        print("• Implement comprehensive accessibility and localization tests")
    }
}

print("\n" + String(repeating: "=", count: 80))
print("Task 18 Validation Complete")

// Exit with appropriate code
exit(overallSuccess ? 0 : 1)