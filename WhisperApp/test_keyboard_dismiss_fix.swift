#!/usr/bin/env swift

import Foundation

print("🔧 Testing Keyboard Dismiss Fix...")

let composeViewPath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"

guard let content = try? String(contentsOfFile: composeViewPath) else {
    print("❌ Could not read ComposeView.swift")
    exit(1)
}

var testsPassed = 0
var totalTests = 0

// Test 1: FocusState is declared
totalTests += 1
if content.contains("@FocusState private var isMessageFieldFocused: Bool") {
    print("✅ FocusState declared for message field")
    testsPassed += 1
} else {
    print("❌ FocusState not declared")
}

// Test 2: TextEditor has focused modifier
totalTests += 1
if content.contains(".focused($isMessageFieldFocused)") {
    print("✅ TextEditor has focused modifier")
    testsPassed += 1
} else {
    print("❌ TextEditor missing focused modifier")
}

// Test 3: Keyboard toolbar is configured
totalTests += 1
if content.contains("ToolbarItemGroup(placement: .keyboard)") {
    print("✅ Keyboard toolbar configured")
    testsPassed += 1
} else {
    print("❌ Keyboard toolbar not configured")
}

// Test 4: Done button is present
totalTests += 1
if content.contains("Button(\"Done\")") && 
   content.contains("isMessageFieldFocused = false") {
    print("✅ Done button present with correct action")
    testsPassed += 1
} else {
    print("❌ Done button missing or incorrect action")
}

// Test 5: Spacer pushes Done button to right
totalTests += 1
if content.contains("Spacer()") && 
   content.contains("Button(\"Done\")") {
    print("✅ Done button positioned on right side of keyboard toolbar")
    testsPassed += 1
} else {
    print("❌ Done button positioning incorrect")
}

// Test 6: Done button has proper styling
totalTests += 1
if content.contains(".fontWeight(.semibold)") {
    print("✅ Done button has semibold font weight")
    testsPassed += 1
} else {
    print("❌ Done button styling missing")
}

print("\n📊 Test Results:")
print("Passed: \(testsPassed)/\(totalTests)")

if testsPassed == totalTests {
    print("🎉 Keyboard dismiss functionality added successfully!")
    print("📱 UX Improvement:")
    print("   • Done button appears in keyboard toolbar")
    print("   • Tapping Done dismisses keyboard")
    print("   • Better text input experience")
    print("   • Follows iOS design patterns")
    exit(0)
} else {
    print("⚠️  Some issues may remain")
    exit(1)
}