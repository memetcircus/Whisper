#!/usr/bin/env swift

import Foundation

print("=== Contact Required Policy Removal Test ===")

// Test 1: Verify SettingsView no longer has the toggle
print("\n1. Testing SettingsView...")
let settingsViewContent = try! String(contentsOfFile: "WhisperApp/UI/Settings/SettingsView.swift")

if settingsViewContent.contains("Contact Required to Send") {
    print("❌ SettingsView still contains 'Contact Required to Send' toggle")
    exit(1)
} else {
    print("✅ 'Contact Required to Send' toggle removed from SettingsView")
}

// Test 2: Verify SettingsViewModel no longer has the property
print("\n2. Testing SettingsViewModel...")
let settingsViewModelContent = try! String(contentsOfFile: "WhisperApp/UI/Settings/SettingsViewModel.swift")

if settingsViewModelContent.contains("contactRequiredToSend") {
    print("❌ SettingsViewModel still contains contactRequiredToSend property")
    exit(1)
} else {
    print("✅ contactRequiredToSend property removed from SettingsViewModel")
}

// Test 3: Verify remaining policies are still there
if settingsViewModelContent.contains("requireSignatureForVerified") &&
   settingsViewModelContent.contains("autoArchiveOnRotation") {
    print("✅ Other security policies remain intact")
} else {
    print("❌ Other security policies were accidentally removed")
    exit(1)
}

// Test 4: Verify Settings UI still has other policies
if settingsViewContent.contains("Require Signature for Verified") &&
   settingsViewContent.contains("Auto-Archive on Rotation") {
    print("✅ Other policy toggles remain in Settings UI")
} else {
    print("❌ Other policy toggles were accidentally removed from UI")
    exit(1)
}

// Test 5: Check that Security Policies section still exists
if settingsViewContent.contains("Security Policies") {
    print("✅ Security Policies section remains")
} else {
    print("❌ Security Policies section was removed")
    exit(1)
}

print("\n✅ All tests passed! Contact Required to Send policy successfully removed.")
print("\nRemoval Summary:")
print("- ❌ Removed: 'Contact Required to Send' toggle from Settings UI")
print("- ❌ Removed: contactRequiredToSend property from SettingsViewModel")
print("- ❌ Removed: contactRequiredToSend from SettingsPolicyManager protocol")
print("- ❌ Removed: contactRequiredToSend UserDefaults key")
print("- ✅ Kept: 'Require Signature for Verified' policy")
print("- ✅ Kept: 'Auto-Archive on Rotation' policy")
print("\nReason: UI already enforces contact-only messaging, making this policy redundant.")
print("Contact-only design is more secure than allowing raw key input.")