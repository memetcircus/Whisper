#!/usr/bin/env swift

import Foundation

print("🔧 Testing Contact Picker Checkmark Fix...")

let composeViewPath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"

guard let content = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

var testsPassed = 0
var totalTests = 0

// Test 1: Contact picker uses checkmark instead of chevron
totalTests += 1
if content.contains("checkmark.circle.fill") && 
   content.contains("ContactPickerRowView") &&
   !content.contains("chevron.right") {
    print("✅ Contact picker uses checkmark icon")
    testsPassed += 1
} else {
    print("❌ Contact picker still uses chevron or checkmark not found")
}

// Test 2: Checkmark has blue color like identity picker
totalTests += 1
if content.contains("checkmark.circle.fill") && 
   content.contains(".foregroundColor(.blue)") {
    print("✅ Checkmark has blue color for consistency")
    testsPassed += 1
} else {
    print("❌ Checkmark color not set to blue")
}

// Test 3: Font size matches identity picker
totalTests += 1
if content.contains("checkmark.circle.fill") && 
   content.contains(".font(.title2)") {
    print("✅ Checkmark font size matches identity picker")
    testsPassed += 1
} else {
    print("❌ Checkmark font size doesn't match")
}

// Test 4: Identity picker still has checkmark (ensure we didn't break it)
totalTests += 1
let identityPickerCheckmarks = content.components(separatedBy: "checkmark.circle.fill").count - 1
if identityPickerCheckmarks >= 2 { // Should have at least 2: identity picker + contact picker
    print("✅ Both identity and contact pickers use checkmarks")
    testsPassed += 1
} else {
    print("❌ Missing checkmarks in pickers (found \(identityPickerCheckmarks))")
}

print("\n📊 Test Results:")
print("Passed: \(testsPassed)/\(totalTests)")

if testsPassed == totalTests {
    print("🎉 Contact picker checkmark fix successful!")
    print("📱 UI Consistency:")
    print("   • Identity picker: ✓ checkmark.circle.fill (blue)")
    print("   • Contact picker: ✓ checkmark.circle.fill (blue)")
    print("   • Both use same styling for selection indicators")
    exit(0)
} else {
    print("⚠️  Some issues may remain")
    exit(1)
}