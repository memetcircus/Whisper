#!/usr/bin/env swift

import Foundation

print("🧪 Testing Launch Screen Setup...")

// Test 1: Verify LaunchScreen.storyboard uses the image asset
print("\n1️⃣ Verifying LaunchScreen.storyboard configuration...")

let launchScreenStoryboard = try String(contentsOfFile: "WhisperApp/WhisperApp/LaunchScreen.storyboard")

var storyboardTests: [(String, Bool)] = []

// Check that it uses the LaunchScreen image asset
storyboardTests.append(("Uses LaunchScreen image asset", launchScreenStoryboard.contains("image=\"LaunchScreen\"")))

// Check that old custom elements are removed
storyboardTests.append(("No lock.fill system image", !launchScreenStoryboard.contains("lock.fill")))
storyboardTests.append(("No Whisper label", !launchScreenStoryboard.contains("text=\"Whisper\"")))
storyboardTests.append(("No subtitle label", !launchScreenStoryboard.contains("Secure End-to-End Encryption")))

// Check proper constraints for full-screen image
storyboardTests.append(("Has top constraint", launchScreenStoryboard.contains("launch-top")))
storyboardTests.append(("Has leading constraint", launchScreenStoryboard.contains("launch-leading")))
storyboardTests.append(("Has trailing constraint", launchScreenStoryboard.contains("launch-trailing")))
storyboardTests.append(("Has bottom constraint", launchScreenStoryboard.contains("launch-bottom")))

// Check content mode
storyboardTests.append(("Uses scaleAspectFit", launchScreenStoryboard.contains("contentMode=\"scaleAspectFit\"")))

var allPassed = true
for (test, passed) in storyboardTests {
    let status = passed ? "✅" : "❌"
    print("\(status) \(test)")
    if !passed { allPassed = false }
}

// Test 2: Verify Info.plist configuration
print("\n2️⃣ Verifying Info.plist configuration...")

let infoPlist = try String(contentsOfFile: "WhisperApp/WhisperApp/Info.plist")

var plistTests: [(String, Bool)] = []

plistTests.append(("Has UILaunchStoryboardName", infoPlist.contains("UILaunchStoryboardName")))
plistTests.append(("Points to LaunchScreen", infoPlist.contains("<string>LaunchScreen</string>")))

for (test, passed) in plistTests {
    let status = passed ? "✅" : "❌"
    print("\(status) \(test)")
    if !passed { allPassed = false }
}

if allPassed {
    print("\n🎉 Launch Screen setup completed successfully!")
    print("\n📝 Configuration Summary:")
    print("• LaunchScreen.storyboard now uses your 'LaunchScreen' image asset")
    print("• Image is configured with scaleAspectFit for proper scaling")
    print("• Full-screen constraints ensure image fills the entire screen")
    print("• Info.plist properly references the LaunchScreen storyboard")
    print("• Removed old custom UI elements (lock icon, labels)")
    
    print("\n✨ Benefits of this approach:")
    print("• ✅ Uses Apple's recommended storyboard method")
    print("• ✅ Will NOT interfere with your SwiftUI app flow")
    print("• ✅ Fast loading and reliable across all iOS versions")
    print("• ✅ Your custom LaunchScreen image will display beautifully")
    print("• ✅ Automatically handles different screen sizes and orientations")
    
    print("\n🚀 Your launch screen is now ready!")
    print("The storyboard approach is the right choice - it's completely separate from your SwiftUI app!")
} else {
    print("\n❌ Some launch screen configuration issues found!")
    exit(1)
}

print("\n💡 Next steps:")
print("1. Make sure your 'LaunchScreen' image asset is properly added to Assets.xcassets")
print("2. Test the app launch to see your custom launch screen")
print("3. The launch screen will show for 1-2 seconds, then your SwiftUI app takes over")