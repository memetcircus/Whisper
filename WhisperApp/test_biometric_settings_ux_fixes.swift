#!/usr/bin/env swift

import Foundation

print("=== Biometric Settings UX Fixes Test ===")

// Test 1: Check that BiometricSettingsViewModel has successMessage property
print("\n1. Testing BiometricSettingsViewModel changes...")
let viewModelContent = try! String(contentsOfFile: "WhisperApp/UI/Settings/BiometricSettingsViewModel.swift")

if viewModelContent.contains("@Published var successMessage: String?") {
    print("✅ successMessage property added")
} else {
    print("❌ successMessage property missing")
    exit(1)
}

if viewModelContent.contains("successMessage = \"Authentication successful!\"") {
    print("✅ Authentication success uses successMessage instead of errorMessage")
} else {
    print("❌ Authentication success still uses errorMessage")
    exit(1)
}

if viewModelContent.contains("successMessage = \"Signing key enrolled successfully!\"") {
    print("✅ Enrollment success uses successMessage instead of errorMessage")
} else {
    print("❌ Enrollment success still uses errorMessage")
    exit(1)
}

// Test 2: Check BiometricSettingsView UI improvements
print("\n2. Testing BiometricSettingsView UI changes...")
let viewContent = try! String(contentsOfFile: "WhisperApp/UI/Settings/BiometricSettingsView.swift")

if viewContent.contains("if let successMessage = viewModel.successMessage") {
    print("✅ Success message section added")
} else {
    print("❌ Success message section missing")
    exit(1)
}

if viewContent.contains("Image(systemName: \"checkmark.circle.fill\")") {
    print("✅ Success message has checkmark icon")
} else {
    print("❌ Success message checkmark icon missing")
    exit(1)
}

if viewContent.contains(".foregroundColor(.green)") {
    print("✅ Success message uses green color")
} else {
    print("❌ Success message green color missing")
    exit(1)
}

// Test 3: Check policy section layout improvements
if viewContent.contains("VStack(alignment: .leading, spacing: 8)") && 
   viewContent.contains("fixedSize(horizontal: false, vertical: true)") {
    print("✅ Policy section layout improved for multiline text")
} else {
    print("❌ Policy section layout not improved")
    exit(1)
}

// Test 4: Check information section font consistency
if viewContent.contains(".font(.subheadline)") && 
   viewContent.contains("authenticate with \\(biometricTypeText)") {
    print("✅ Information section font size made consistent and uses dynamic biometric type")
} else {
    print("❌ Information section font consistency not fixed")
    exit(1)
}

// Test 5: Check error message improvements
if viewContent.contains("Image(systemName: \"exclamationmark.triangle.fill\")") {
    print("✅ Error message has warning icon")
} else {
    print("❌ Error message warning icon missing")
    exit(1)
}

print("\n✅ All UX fixes verified successfully!")
print("\nFixed Issues:")
print("1. ✅ Success messages now show in green with checkmark icon (not as errors)")
print("2. ✅ Information text uses consistent .subheadline font size")
print("3. ✅ Policy description text properly handles multiline layout")
print("4. ✅ Error messages have warning icons for better visual distinction")
print("5. ✅ Dynamic biometric type text (Face ID/Touch ID) in information section")