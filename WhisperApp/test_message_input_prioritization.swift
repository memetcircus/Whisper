#!/usr/bin/env swift

import Foundation

print("🧪 Testing Message Input Prioritization Improvements...")

// Test the ComposeView file for the improvements
let composeViewPath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"

guard let composeContent = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

var testsPassed = 0
var totalTests = 0

// Test 1: Message input height increased
totalTests += 1
if composeContent.contains(".frame(minHeight: 240)") {
    print("✅ Message input height increased to 240pt (was 120pt)")
    testsPassed += 1
} else {
    print("❌ Message input height not increased")
}

// Test 2: Signature toggle moved inline
totalTests += 1
if composeContent.contains("HStack(spacing: 8)") && 
   composeContent.contains("Toggle(\"\", isOn: $viewModel.includeSignature)") &&
   composeContent.contains(".labelsHidden()") {
    print("✅ Signature toggle moved inline and made compact")
    testsPassed += 1
} else {
    print("❌ Signature toggle not properly compacted")
}

// Test 3: Separate options section removed
totalTests += 1
if !composeContent.contains("// Options Section") || 
   !composeContent.contains("optionsSection") {
    print("✅ Separate options section removed")
    testsPassed += 1
} else {
    print("❌ Separate options section still exists")
}

// Test 4: Signature note made more compact
totalTests += 1
if composeContent.contains("Image(systemName: \"info.circle.fill\")") &&
   composeContent.contains(".font(.caption)") {
    print("✅ Signature note made more compact with icon")
    testsPassed += 1
} else {
    print("❌ Signature note not properly compacted")
}

// Test 5: Toggle scale reduced
totalTests += 1
if composeContent.contains(".scaleEffect(0.8)") {
    print("✅ Toggle scale reduced for compact appearance")
    testsPassed += 1
} else {
    print("❌ Toggle scale not reduced")
}

print("\n📊 Test Results:")
print("Passed: \(testsPassed)/\(totalTests)")

if testsPassed == totalTests {
    print("🎉 All message input prioritization improvements implemented successfully!")
    exit(0)
} else {
    print("⚠️  Some improvements may need attention")
    exit(1)
}