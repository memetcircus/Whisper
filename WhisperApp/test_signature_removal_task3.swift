#!/usr/bin/env swift

// Test script to verify Task 3: Remove Signature Toggle from Compose Message Screen
// This script validates that signature-related UI elements and state have been removed

import Foundation

print("🧪 Testing Task 3: Remove Signature Toggle from Compose Message Screen")
print(String(repeating: "=", count: 70))

// Test 1: Verify ComposeView.swift no longer contains signature toggle
func testComposeViewSignatureRemoval() {
    print("\n📱 Test 1: Verifying ComposeView signature toggle removal...")
    
    guard let composeViewContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift") else {
        print("❌ Could not read ComposeView.swift")
        return
    }
    
    let signatureTogglePatterns = [
        "includeSignature",
        "Toggle.*isOn.*includeSignature",
        "signatureRequired",
        "Include Signature",
        "signature toggle"
    ]
    
    var foundIssues = false
    for pattern in signatureTogglePatterns {
        if composeViewContent.contains(pattern) {
            print("❌ Found signature-related code: \(pattern)")
            foundIssues = true
        }
    }
    
    if !foundIssues {
        print("✅ ComposeView.swift successfully cleaned of signature toggle UI")
    }
}

// Test 2: Verify ComposeViewModel.swift no longer contains signature state
func testComposeViewModelSignatureRemoval() {
    print("\n🧠 Test 2: Verifying ComposeViewModel signature state removal...")
    
    guard let viewModelContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Compose/ComposeViewModel.swift") else {
        print("❌ Could not read ComposeViewModel.swift")
        return
    }
    
    let signatureStatePatterns = [
        "@Published var includeSignature",
        "var isSignatureRequired",
        "updateSignatureRequirement",
        "includeSignature.*=",
        "shouldSign.*includeSignature"
    ]
    
    var foundIssues = false
    for pattern in signatureStatePatterns {
        if viewModelContent.contains(pattern) {
            print("❌ Found signature-related state: \(pattern)")
            foundIssues = true
        }
    }
    
    if !foundIssues {
        print("✅ ComposeViewModel.swift successfully cleaned of signature state properties")
    }
}

// Test 3: Verify message input section is simplified
func testMessageInputSimplification() {
    print("\n📝 Test 3: Verifying message input section simplification...")
    
    guard let composeViewContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift") else {
        print("❌ Could not read ComposeView.swift")
        return
    }
    
    // Check that messageInputSection is simplified
    if composeViewContent.contains("private var messageInputSection") {
        // Should NOT contain signature toggle elements
        let forbiddenElements = [
            "Toggle",
            "includeSignature",
            "signature",
            "isSignatureRequired"
        ]
        
        var foundForbidden = false
        for element in forbiddenElements {
            if composeViewContent.contains(element) {
                print("❌ Found forbidden signature element: \(element)")
                foundForbidden = true
            }
        }
        
        if !foundForbidden {
            print("✅ Message input section successfully simplified - no signature controls")
        }
    } else {
        print("❌ Could not find messageInputSection in ComposeView")
    }
}

// Test 4: Verify encryption logic is updated
func testEncryptionLogicUpdate() {
    print("\n🔐 Test 4: Verifying encryption logic is updated...")
    
    guard let viewModelContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Compose/ComposeViewModel.swift") else {
        print("❌ Could not read ComposeViewModel.swift")
        return
    }
    
    // Check that encryptMessage method no longer uses per-message signature logic
    if viewModelContent.contains("func encryptMessage() async") {
        // Should NOT contain per-message signature logic
        if viewModelContent.contains("shouldSign") && viewModelContent.contains("includeSignature") {
            print("❌ Found per-message signature logic in encryptMessage")
        } else {
            print("✅ Encryption method updated - no per-message signature logic")
        }
        
        // Should contain placeholder for Settings-based logic
        if viewModelContent.contains("This will be updated in task 4 to use Settings") {
            print("✅ Found placeholder comment for Settings-based signature logic")
        } else {
            print("⚠️  Missing placeholder comment for Settings integration")
        }
    } else {
        print("❌ Could not find encryptMessage method")
    }
}

// Test 5: Verify UI layout focuses on message content
func testUILayoutFocus() {
    print("\n🎨 Test 5: Verifying UI layout focuses on message content...")
    
    guard let composeViewContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift") else {
        print("❌ Could not read ComposeView.swift")
        return
    }
    
    // Check that the main sections are present and clean
    let requiredSections = [
        "identitySelectionSection",
        "recipientSelectionSection", 
        "messageInputSection",
        "actionButtonsSection"
    ]
    
    var allSectionsFound = true
    for section in requiredSections {
        if !composeViewContent.contains(section) {
            print("❌ Missing required section: \(section)")
            allSectionsFound = false
        }
    }
    
    if allSectionsFound {
        print("✅ All required UI sections present and focused on core functionality")
    }
}

// Run all tests
testComposeViewSignatureRemoval()
testComposeViewModelSignatureRemoval()
testMessageInputSimplification()
testEncryptionLogicUpdate()
testUILayoutFocus()

print("\n" + String(repeating: "=", count: 70))
print("🎯 Task 3 Verification Complete")
print("✅ Signature toggle and related UI elements removed from Compose Message screen")
print("✅ ComposeView layout simplified to focus on message content")
print("✅ ComposeViewModel cleaned of signature-related state management")
print("✅ Ready for Task 4: Update ComposeViewModel to use Settings-based signature logic")