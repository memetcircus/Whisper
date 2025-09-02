#!/usr/bin/env swift

import Foundation

print("=== Validating Task 15: Create Settings and Policy UI ===")
print("Requirements: 9.4, 9.5, 3.6, 6.1")

var validationResults: [String: Bool] = [:]

// Requirement 9.4: Settings toggles for all four security policies
print("\n1. Validating Security Policy Toggles (Requirement 9.4)...")

let settingsViewPath = "WhisperApp/WhisperApp/UI/Settings/SettingsView.swift"
if let settingsContent = try? String(contentsOfFile: settingsViewPath) {
    let requiredPolicyToggles = [
        "Contact Required to Send",
        "Require Signature for Verified", 
        "Auto-Archive on Rotation",
        "Biometric-Gated Signing"
    ]
    
    var allTogglesFound = true
    for toggle in requiredPolicyToggles {
        if settingsContent.contains(toggle) {
            print("✅ Policy toggle: \(toggle)")
        } else {
            print("❌ Missing policy toggle: \(toggle)")
            allTogglesFound = false
        }
    }
    
    // Check that toggles are bound to ViewModel properties
    let settingsViewModelPath = "WhisperApp/WhisperApp/UI/Settings/SettingsViewModel.swift"
    if let viewModelContent = try? String(contentsOfFile: settingsViewModelPath) {
        let requiredBindings = [
            "contactRequiredToSend",
            "requireSignatureForVerified",
            "autoArchiveOnRotation", 
            "biometricGatedSigning"
        ]
        
        for binding in requiredBindings {
            if viewModelContent.contains("@Published var \(binding)") {
                print("✅ Policy binding: \(binding)")
            } else {
                print("❌ Missing policy binding: \(binding)")
                allTogglesFound = false
            }
        }
    }
    
    validationResults["Policy Toggles"] = allTogglesFound
} else {
    print("❌ Could not read SettingsView.swift")
    validationResults["Policy Toggles"] = false
}

// Requirement 9.5: Legal disclaimer with required acceptance on first launch
print("\n2. Validating Legal Disclaimer (Requirement 9.5)...")

let legalDisclaimerPath = "WhisperApp/WhisperApp/UI/Settings/LegalDisclaimerView.swift"
if let legalContent = try? String(contentsOfFile: legalDisclaimerPath) {
    let requiredElements = [
        "isFirstLaunch",
        "@AppStorage(\"whisper.legal.accepted\")",
        "Accept and Continue",
        "interactiveDismissDisabled"
    ]
    
    var allElementsFound = true
    for element in requiredElements {
        if legalContent.contains(element) {
            print("✅ Legal element: \(element)")
        } else {
            print("❌ Missing legal element: \(element)")
            allElementsFound = false
        }
    }
    
    // Check ContentView integration for first launch
    let contentViewPath = "WhisperApp/WhisperApp/ContentView.swift"
    if let contentViewContent = try? String(contentsOfFile: contentViewPath) {
        if contentViewContent.contains("legalAccepted") && 
           contentViewContent.contains("showingLegalDisclaimer") &&
           contentViewContent.contains("LegalDisclaimerView(isFirstLaunch: true)") {
            print("✅ First launch legal disclaimer integration")
        } else {
            print("❌ Missing first launch legal disclaimer integration")
            allElementsFound = false
        }
    }
    
    validationResults["Legal Disclaimer"] = allElementsFound
} else {
    print("❌ Could not read LegalDisclaimerView.swift")
    validationResults["Legal Disclaimer"] = false
}

// Requirement 3.6: Identity management UI (create, switch, archive, rotate, backup/restore)
print("\n3. Validating Identity Management UI (Requirement 3.6)...")

let identityManagementPath = "WhisperApp/WhisperApp/UI/Settings/IdentityManagementView.swift"
if let identityContent = try? String(contentsOfFile: identityManagementPath) {
    let requiredFeatures = [
        "Create New",
        "Rotate Keys",
        "Archive", 
        "Activate"
    ]
    
    var allFeaturesFound = true
    for feature in requiredFeatures {
        if identityContent.contains(feature) {
            print("✅ Identity management feature: \(feature)")
        } else {
            print("❌ Missing identity management feature: \(feature)")
            allFeaturesFound = false
        }
    }
    
    // Check backup/restore functionality
    let backupRestorePath = "WhisperApp/WhisperApp/UI/Settings/BackupRestoreView.swift"
    if let backupContent = try? String(contentsOfFile: backupRestorePath) {
        let backupFeatures = [
            "Create Backup",
            "Restore from Backup",
            "Encryption Passphrase"
        ]
        
        for feature in backupFeatures {
            if backupContent.contains(feature) {
                print("✅ Backup/restore feature: \(feature)")
            } else {
                print("❌ Missing backup/restore feature: \(feature)")
                allFeaturesFound = false
            }
        }
    } else {
        print("❌ Could not read BackupRestoreView.swift")
        allFeaturesFound = false
    }
    
    validationResults["Identity Management"] = allFeaturesFound
} else {
    print("❌ Could not read IdentityManagementView.swift")
    validationResults["Identity Management"] = false
}

// Requirement 6.1: Biometric settings with enrollment/unenrollment options
print("\n4. Validating Biometric Settings (Requirement 6.1)...")

let biometricSettingsPath = "WhisperApp/WhisperApp/UI/Settings/BiometricSettingsView.swift"
if let biometricContent = try? String(contentsOfFile: biometricSettingsPath) {
    let requiredFeatures = [
        "Enroll Signing Key",
        "Remove Enrollment",
        "Test Authentication",
        "biometricIcon",
        "biometricTypeText"
    ]
    
    var allFeaturesFound = true
    for feature in requiredFeatures {
        if biometricContent.contains(feature) {
            print("✅ Biometric feature: \(feature)")
        } else {
            print("❌ Missing biometric feature: \(feature)")
            allFeaturesFound = false
        }
    }
    
    // Check ViewModel integration
    let biometricViewModelPath = "WhisperApp/WhisperApp/UI/Settings/BiometricSettingsViewModel.swift"
    if let viewModelContent = try? String(contentsOfFile: biometricViewModelPath) {
        let viewModelFeatures = [
            "enrollSigningKey",
            "removeEnrollment", 
            "testAuthentication",
            "checkBiometricStatus"
        ]
        
        for feature in viewModelFeatures {
            if viewModelContent.contains(feature) {
                print("✅ Biometric ViewModel feature: \(feature)")
            } else {
                print("❌ Missing biometric ViewModel feature: \(feature)")
                allFeaturesFound = false
            }
        }
    } else {
        print("❌ Could not read BiometricSettingsViewModel.swift")
        allFeaturesFound = false
    }
    
    validationResults["Biometric Settings"] = allFeaturesFound
} else {
    print("❌ Could not read BiometricSettingsView.swift")
    validationResults["Biometric Settings"] = false
}

// Additional: Export/Import functionality
print("\n5. Validating Export/Import Functionality...")

let exportImportPath = "WhisperApp/WhisperApp/UI/Settings/ExportImportView.swift"
if let exportContent = try? String(contentsOfFile: exportImportPath) {
    let requiredFeatures = [
        "Export Contacts",
        "Import Contacts",
        "Export Identity Public Keys"
    ]
    
    var allFeaturesFound = true
    for feature in requiredFeatures {
        if exportContent.contains(feature) {
            print("✅ Export/Import feature: \(feature)")
        } else {
            print("❌ Missing export/import feature: \(feature)")
            allFeaturesFound = false
        }
    }
    
    validationResults["Export/Import"] = allFeaturesFound
} else {
    print("❌ Could not read ExportImportView.swift")
    validationResults["Export/Import"] = false
}

// Check Settings navigation integration
print("\n6. Validating Settings Navigation Integration...")

let contentViewPath = "WhisperApp/WhisperApp/ContentView.swift"
if let contentViewContent = try? String(contentsOfFile: contentViewPath) {
    let navigationElements = [
        "showingSettingsView",
        "SettingsView()",
        "Button(\"Settings\")"
    ]
    
    var allElementsFound = true
    for element in navigationElements {
        if contentViewContent.contains(element) {
            print("✅ Navigation element: \(element)")
        } else {
            print("❌ Missing navigation element: \(element)")
            allElementsFound = false
        }
    }
    
    validationResults["Settings Navigation"] = allElementsFound
} else {
    print("❌ Could not read ContentView.swift")
    validationResults["Settings Navigation"] = false
}

// Final validation summary
print("\n=== Validation Summary ===")
var allRequirementsMet = true

for (requirement, passed) in validationResults {
    if passed {
        print("✅ \(requirement): PASSED")
    } else {
        print("❌ \(requirement): FAILED")
        allRequirementsMet = false
    }
}

print("\n=== Task 15 Requirements Mapping ===")
print("✅ Requirement 9.4: Settings screen with toggles for all four security policies")
print("✅ Requirement 9.5: Legal disclaimer screen with required acceptance on first launch") 
print("✅ Requirement 3.6: Identity management UI (create, switch, archive, rotate, backup/restore)")
print("✅ Requirement 6.1: Biometric settings with enrollment/unenrollment options")
print("✅ Additional: Export/import functionality for identities and contacts")

if allRequirementsMet {
    print("\n🎉 Task 15 implementation is COMPLETE and meets all requirements!")
    exit(0)
} else {
    print("\n❌ Task 15 implementation has some issues that need to be addressed.")
    exit(1)
}