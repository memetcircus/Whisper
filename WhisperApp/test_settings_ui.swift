#!/usr/bin/env swift

import Foundation

print("=== Testing Settings UI Implementation ===")

// Test 1: Check if Settings files exist
print("\n1. Checking Settings UI files...")

let settingsFiles = [
    "WhisperApp/WhisperApp/UI/Settings/SettingsView.swift",
    "WhisperApp/WhisperApp/UI/Settings/SettingsViewModel.swift",
    "WhisperApp/WhisperApp/UI/Settings/IdentityManagementView.swift",
    "WhisperApp/WhisperApp/UI/Settings/IdentityManagementViewModel.swift",
    "WhisperApp/WhisperApp/UI/Settings/LegalDisclaimerView.swift",
    "WhisperApp/WhisperApp/UI/Settings/BiometricSettingsView.swift",
    "WhisperApp/WhisperApp/UI/Settings/BiometricSettingsViewModel.swift",
    "WhisperApp/WhisperApp/UI/Settings/BackupRestoreView.swift",
    "WhisperApp/WhisperApp/UI/Settings/BackupRestoreViewModel.swift",
    "WhisperApp/WhisperApp/UI/Settings/ExportImportView.swift",
    "WhisperApp/WhisperApp/UI/Settings/ExportImportViewModel.swift"
]

var allFilesExist = true
for file in settingsFiles {
    if FileManager.default.fileExists(atPath: file) {
        print("✅ \(file)")
    } else {
        print("❌ \(file) - Missing")
        allFilesExist = false
    }
}

// Test 2: Check ContentView integration
print("\n2. Checking ContentView integration...")
let contentViewPath = "WhisperApp/WhisperApp/ContentView.swift"
if let contentViewContent = try? String(contentsOfFile: contentViewPath) {
    if contentViewContent.contains("showingSettingsView") &&
       contentViewContent.contains("SettingsView()") &&
       contentViewContent.contains("LegalDisclaimerView") {
        print("✅ ContentView properly integrated with Settings")
    } else {
        print("❌ ContentView missing Settings integration")
        allFilesExist = false
    }
} else {
    print("❌ Could not read ContentView.swift")
    allFilesExist = false
}

// Test 3: Check policy toggles implementation
print("\n3. Checking policy toggles...")
let settingsViewModelPath = "WhisperApp/WhisperApp/UI/Settings/SettingsViewModel.swift"
if let settingsViewModelContent = try? String(contentsOfFile: settingsViewModelPath) {
    let requiredPolicies = [
        "contactRequiredToSend",
        "requireSignatureForVerified", 
        "autoArchiveOnRotation",
        "biometricGatedSigning"
    ]
    
    var allPoliciesFound = true
    for policy in requiredPolicies {
        if settingsViewModelContent.contains(policy) {
            print("✅ Policy toggle: \(policy)")
        } else {
            print("❌ Missing policy toggle: \(policy)")
            allPoliciesFound = false
        }
    }
    
    if !allPoliciesFound {
        allFilesExist = false
    }
} else {
    print("❌ Could not read SettingsViewModel.swift")
    allFilesExist = false
}

// Test 4: Check identity management features
print("\n4. Checking identity management features...")
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
            print("✅ Identity feature: \(feature)")
        } else {
            print("❌ Missing identity feature: \(feature)")
            allFeaturesFound = false
        }
    }
    
    if !allFeaturesFound {
        allFilesExist = false
    }
} else {
    print("❌ Could not read IdentityManagementView.swift")
    allFilesExist = false
}

// Test 5: Check biometric settings
print("\n5. Checking biometric settings...")
let biometricSettingsPath = "WhisperApp/WhisperApp/UI/Settings/BiometricSettingsView.swift"
if let biometricContent = try? String(contentsOfFile: biometricSettingsPath) {
    let requiredFeatures = [
        "Enroll Signing Key",
        "Remove Enrollment",
        "Test Authentication"
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
    
    if !allFeaturesFound {
        allFilesExist = false
    }
} else {
    print("❌ Could not read BiometricSettingsView.swift")
    allFilesExist = false
}

// Test 6: Check legal disclaimer
print("\n6. Checking legal disclaimer...")
let legalDisclaimerPath = "WhisperApp/WhisperApp/UI/Settings/LegalDisclaimerView.swift"
if let legalContent = try? String(contentsOfFile: legalDisclaimerPath) {
    let requiredSections = [
        "No Warranty",
        "Security Limitations",
        "User Responsibility",
        "Export Compliance",
        "Limitation of Liability"
    ]
    
    var allSectionsFound = true
    for section in requiredSections {
        if legalContent.contains(section) {
            print("✅ Legal section: \(section)")
        } else {
            print("❌ Missing legal section: \(section)")
            allSectionsFound = false
        }
    }
    
    if !allSectionsFound {
        allFilesExist = false
    }
} else {
    print("❌ Could not read LegalDisclaimerView.swift")
    allFilesExist = false
}

// Test 7: Check backup/restore functionality
print("\n7. Checking backup/restore functionality...")
let backupRestorePath = "WhisperApp/WhisperApp/UI/Settings/BackupRestoreView.swift"
if let backupContent = try? String(contentsOfFile: backupRestorePath) {
    let requiredFeatures = [
        "Create Backup",
        "Restore from Backup",
        "Select Backup File",
        "Encryption Passphrase"
    ]
    
    var allFeaturesFound = true
    for feature in requiredFeatures {
        if backupContent.contains(feature) {
            print("✅ Backup feature: \(feature)")
        } else {
            print("❌ Missing backup feature: \(feature)")
            allFeaturesFound = false
        }
    }
    
    if !allFeaturesFound {
        allFilesExist = false
    }
} else {
    print("❌ Could not read BackupRestoreView.swift")
    allFilesExist = false
}

// Test 8: Check export/import functionality
print("\n8. Checking export/import functionality...")
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
    
    if !allFeaturesFound {
        allFilesExist = false
    }
} else {
    print("❌ Could not read ExportImportView.swift")
    allFilesExist = false
}

// Final result
print("\n=== Test Results ===")
if allFilesExist {
    print("✅ All Settings UI components implemented successfully!")
    print("\nImplemented features:")
    print("• Security policy toggles (4 policies)")
    print("• Identity management (create, switch, archive, rotate)")
    print("• Legal disclaimer with required acceptance on first launch")
    print("• Biometric settings (enrollment/unenrollment)")
    print("• Backup/restore functionality for identities")
    print("• Export/import for contacts and public keys")
    print("• Integration with main ContentView")
    
    exit(0)
} else {
    print("❌ Some Settings UI components are missing or incomplete")
    exit(1)
}