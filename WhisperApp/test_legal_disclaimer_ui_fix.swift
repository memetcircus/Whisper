#!/usr/bin/env swift

import Foundation

print("🧪 Testing Legal Disclaimer UI Fix...")

// Test 1: Verify the UI changes in LegalDisclaimerView
print("\n1️⃣ Verifying Legal Disclaimer UI changes...")

let legalDisclaimerView = try String(contentsOfFile: "WhisperApp/WhisperApp/UI/Settings/LegalDisclaimerView.swift")

var uiTests: [(String, Bool)] = []

// Check centered alignment
uiTests.append(("VStack alignment changed to center", legalDisclaimerView.contains("VStack(alignment: .center, spacing: 12)")))

// Check larger font size
uiTests.append(("Font changed to .title", legalDisclaimerView.contains(".font(.title)")))

// Check multiline text alignment
uiTests.append(("Legal Disclaimer text centered", legalDisclaimerView.contains(".multilineTextAlignment(.center)")))

// Check frame for full width centering
uiTests.append(("Frame set to maxWidth", legalDisclaimerView.contains(".frame(maxWidth: .infinity)")))

// Verify old styling is removed
uiTests.append(("No left alignment", !legalDisclaimerView.contains("VStack(alignment: .leading, spacing: 12)")))
uiTests.append(("No .title2 font", !legalDisclaimerView.contains(".font(.title2)")))

var allPassed = true
for (test, passed) in uiTests {
    let status = passed ? "✅" : "❌"
    print("\(status) \(test)")
    if !passed { allPassed = false }
}

if allPassed {
    print("\n🎉 All Legal Disclaimer UI updates verified successfully!")
    print("\n📝 Summary of Changes:")
    print("• Text alignment: Left → Center")
    print("• Font size: .title2 → .title (bigger)")
    print("• Added multilineTextAlignment(.center)")
    print("• Added frame(maxWidth: .infinity) for proper centering")
    print("• Both title and subtitle are now centered")
    print("\n✨ The Legal Disclaimer header now has a more prominent, centered appearance!")
} else {
    print("\n❌ Some Legal Disclaimer UI updates are missing!")
    exit(1)
}

print("\n🎯 Legal Disclaimer UI improvements complete!")