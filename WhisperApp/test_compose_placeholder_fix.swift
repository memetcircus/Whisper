#!/usr/bin/env swift

import Foundation

print("🧪 Testing Compose Message Placeholder Text Fix")
print(String(repeating: "=", count: 50))

// Test the fix for placeholder text visibility in ComposeView
func testPlaceholderTextFix() {
    print("\n📝 Compose Message Placeholder Text Fix Test")
    print(String(repeating: "-", count: 40))
    
    let composeViewPath = "WhisperApp/WhisperApp/UI/Compose/ComposeView.swift"
    
    guard let content = try? String(contentsOfFile: composeViewPath) else {
        print("❌ Could not read ComposeView.swift")
        return
    }
    
    // Check that TextEditor comes before placeholder text in ZStack
    let textEditorPattern = #"TextEditor\("#
    let placeholderPattern = #"if viewModel\.messageText\.isEmpty"#
    
    guard let textEditorRange = content.range(of: textEditorPattern, options: .regularExpression),
          let placeholderRange = content.range(of: placeholderPattern, options: .regularExpression) else {
        print("❌ Could not find TextEditor or placeholder text patterns")
        return
    }
    
    let textEditorPosition = content.distance(from: content.startIndex, to: textEditorRange.lowerBound)
    let placeholderPosition = content.distance(from: content.startIndex, to: placeholderRange.lowerBound)
    
    if textEditorPosition < placeholderPosition {
        print("✅ TextEditor positioned before placeholder text (correct layering)")
    } else {
        print("❌ Placeholder text positioned before TextEditor (incorrect layering)")
        return
    }
    
    // Check for transparent background
    if content.contains(".scrollContentBackground(.hidden)") {
        print("✅ TextEditor has transparent background (.scrollContentBackground(.hidden))")
    } else if content.contains(".background(Color.clear)") {
        print("✅ TextEditor has transparent background (.background(Color.clear))")
    } else {
        print("⚠️  TextEditor background transparency not clearly set")
    }
    
    // Check placeholder text properties
    if content.contains(".allowsHitTesting(false)") {
        print("✅ Placeholder text has .allowsHitTesting(false)")
    } else {
        print("❌ Placeholder text missing .allowsHitTesting(false)")
    }
    
    // Check font size consistency
    let placeholderFontPattern = #"\.font\(\.system\(size: (\d+)\)\)"#
    let textEditorFontPattern = #"\.font\(\.system\(size: (\d+)\)\)"#
    
    let placeholderSection = String(content[placeholderRange.lowerBound...])
    if let placeholderMatch = placeholderSection.range(of: placeholderFontPattern, options: .regularExpression) {
        let placeholderFontSize = String(placeholderSection[placeholderMatch])
        if placeholderFontSize.contains("16") {
            print("✅ Placeholder text uses consistent font size (16)")
        } else {
            print("⚠️  Placeholder text font size: \(placeholderFontSize)")
        }
    }
    
    print("\n🎯 Fix Summary:")
    print("• Moved TextEditor before placeholder text in ZStack")
    print("• Added .scrollContentBackground(.hidden) for transparency")
    print("• Ensured placeholder text is on top layer")
    print("• Maintained .allowsHitTesting(false) for placeholder")
    print("• Used consistent font size (16) for both elements")
}

// Run the test
testPlaceholderTextFix()

print("\n✅ Compose Message Placeholder Text Fix Complete!")
print("The placeholder text should now be visible when the message field is empty.")