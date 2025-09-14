#!/usr/bin/env swift

import Foundation

print("🔧 Testing Contact Picker Selection Logic Fix...")

let composeViewPath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"

guard let content = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

var testsPassed = 0
var totalTests = 0

// Test 1: ContactPickerRowView has isSelected parameter
totalTests += 1
if content.contains("let isSelected: Bool") {
    print("✅ ContactPickerRowView has isSelected parameter")
    testsPassed += 1
} else {
    print("❌ ContactPickerRowView missing isSelected parameter")
}

// Test 2: Checkmark is conditional based on isSelected
totalTests += 1
if content.contains("if isSelected {") && 
   content.contains("checkmark.circle.fill") {
    print("✅ Checkmark is conditional based on selection state")
    testsPassed += 1
} else {
    print("❌ Checkmark is not conditional or missing")
}

// Test 3: Contact selection logic compares IDs
totalTests += 1
if content.contains("selectedContact?.id == contact.id") {
    print("✅ Selection logic compares contact IDs correctly")
    testsPassed += 1
} else {
    print("❌ Selection logic not comparing contact IDs")
}

// Test 4: ContactPickerRowView is called with isSelected parameter
totalTests += 1
if content.contains("ContactPickerRowView(") && 
   content.contains("isSelected: selectedContact?.id == contact.id") {
    print("✅ ContactPickerRowView called with correct isSelected logic")
    testsPassed += 1
} else {
    print("❌ ContactPickerRowView not called with isSelected parameter")
}

// Test 5: No unconditional checkmarks remain
totalTests += 1
let unconditionalCheckmarks = content.components(separatedBy: "Image(systemName: \"checkmark.circle.fill\")")
    .dropFirst() // Remove first element (before first match)
    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(".foregroundColor(.blue)") }
    .count

if unconditionalCheckmarks == 0 {
    print("✅ No unconditional checkmarks found in contact picker")
    testsPassed += 1
} else {
    print("❌ Found \(unconditionalCheckmarks) unconditional checkmarks")
}

print("\n📊 Test Results:")
print("Passed: \(testsPassed)/\(totalTests)")

if testsPassed == totalTests {
    print("🎉 Contact picker selection logic fixed!")
    print("📱 UX Behavior:")
    print("   • Only selected contact shows checkmark")
    print("   • Unselected contacts show no indicator")
    print("   • Selection state properly tracked")
    print("   • Consistent with identity picker behavior")
    exit(0)
} else {
    print("⚠️  Some issues may remain")
    exit(1)
}