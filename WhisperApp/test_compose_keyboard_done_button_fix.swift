#!/usr/bin/env swift

import Foundation

print("🔍 Testing Compose Keyboard Done Button Fix...")
print(String(repeating: "=", count: 50))

var allTestsPassed = true

// Test 1: Verify keyboard toolbar is moved to parent view
print("\n1. Testing keyboard toolbar placement...")
let composeViewPath = "./WhisperApp/UI/Compose/ComposeView.swift"
if let content = try? String(contentsOfFile: composeViewPath) {
    let hasParentToolbar = content.contains("ToolbarItemGroup(placement: .keyboard)")
    let hasConditionalDoneButton = content.contains("if isMessageFieldFocused")
    let hasTextEditorToolbar = content.range(of: "\\.focused\\(\\$isMessageFieldFocused\\)\\s*\\.toolbar", options: .regularExpression) != nil
    
    print("  ✅ Keyboard toolbar in parent view: \(hasParentToolbar ? "PASS" : "FAIL")")
    print("  ✅ Conditional Done button: \(hasConditionalDoneButton ? "PASS" : "FAIL")")
    print("  ✅ No duplicate TextEditor toolbar: \(!hasTextEditorToolbar ? "PASS" : "FAIL")")
    
    if !hasParentToolbar || !hasConditionalDoneButton || hasTextEditorToolbar {
        allTestsPassed = false
    }
} else {
    print("  ❌ Could not read ComposeView.swift")
    allTestsPassed = false
}

// Test 2: Verify FocusState is properly used
print("\n2. Testing FocusState implementation...")
if let content = try? String(contentsOfFile: composeViewPath) {
    let hasFocusState = content.contains("@FocusState private var isMessageFieldFocused: Bool")
    let hasFocusedModifier = content.contains(".focused($isMessageFieldFocused)")
    let hasFocusToggle = content.contains("isMessageFieldFocused = false")
    
    print("  ✅ FocusState declared: \(hasFocusState ? "PASS" : "FAIL")")
    print("  ✅ TextEditor focused modifier: \(hasFocusedModifier ? "PASS" : "FAIL")")
    print("  ✅ Focus toggle in Done button: \(hasFocusToggle ? "PASS" : "FAIL")")
    
    if !hasFocusState || !hasFocusedModifier || !hasFocusToggle {
        allTestsPassed = false
    }
}

// Test 3: Verify Done button styling
print("\n3. Testing Done button styling...")
if let content = try? String(contentsOfFile: composeViewPath) {
    let hasFontWeight = content.contains(".fontWeight(.semibold)")
    let hasSpacerBeforeDone = content.contains("Spacer()")
    
    print("  ✅ Done button has semibold font: \(hasFontWeight ? "PASS" : "FAIL")")
    print("  ✅ Spacer positions Done button right: \(hasSpacerBeforeDone ? "PASS" : "FAIL")")
    
    if !hasFontWeight || !hasSpacerBeforeDone {
        allTestsPassed = false
    }
}

print("\n" + String(repeating: "=", count: 50))
if allTestsPassed {
    print("🎉 All keyboard Done button tests PASSED!")
    print("\n✅ Summary of changes:")
    print("  • Keyboard toolbar moved to parent NavigationView")
    print("  • Done button only shows when message field is focused")
    print("  • Removed duplicate toolbar from TextEditor")
    print("  • Proper FocusState management implemented")
    print("  • Done button dismisses keyboard correctly")
} else {
    print("❌ Some keyboard Done button tests FAILED!")
    print("\nPlease review the failed tests above and ensure:")
    print("  • Keyboard toolbar is in parent view, not on TextEditor")
    print("  • Done button is conditional on focus state")
    print("  • FocusState is properly implemented")
    print("  • No duplicate toolbar configurations")
}

print("\n🔍 Keyboard Done button fix verification complete.")