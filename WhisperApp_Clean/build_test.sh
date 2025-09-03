#!/bin/bash

echo "🔧 Testing Whisper App Build..."
echo "================================"

# Check if we're in the right directory
if [ ! -f "WhisperApp.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: WhisperApp.xcodeproj not found"
    echo "Please run this script from the WhisperApp_Clean directory"
    exit 1
fi

echo "📁 Project structure check..."
if [ -d "WhisperApp/Core" ] && [ -d "WhisperApp/Services" ] && [ -d "WhisperApp/UI" ]; then
    echo "✅ Project structure looks good"
else
    echo "❌ Missing required directories"
    exit 1
fi

echo ""
echo "🔨 Attempting to build for iOS Simulator..."
xcodebuild -project WhisperApp.xcodeproj \
           -scheme WhisperApp \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
           clean build

BUILD_RESULT=$?

echo ""
echo "================================"
if [ $BUILD_RESULT -eq 0 ]; then
    echo "🎉 BUILD SUCCESSFUL!"
    echo "✅ The app compiled without errors"
    echo ""
    echo "📱 Next Steps:"
    echo "1. Open WhisperApp.xcodeproj in Xcode"
    echo "2. Select your physical iOS device"
    echo "3. Set your development team in project settings"
    echo "4. Build and run on device (Cmd+R)"
    echo ""
    echo "🧪 Testing Checklist:"
    echo "- [ ] Legal disclaimer appears on first launch"
    echo "- [ ] Can create identity"
    echo "- [ ] Can encrypt/decrypt messages"
    echo "- [ ] Biometric authentication works"
    echo "- [ ] QR code scanning works"
else
    echo "❌ BUILD FAILED"
    echo "Please check the error messages above"
    echo ""
    echo "🔧 Common Solutions:"
    echo "1. Open project in Xcode and check for missing files"
    echo "2. Ensure all Swift files are added to the target"
    echo "3. Check for syntax errors in the code"
    echo "4. Verify iOS deployment target is set to 15.0+"
fi

echo ""
echo "📋 Project Information:"
echo "- Bundle ID: com.whisper.app"
echo "- iOS Target: 15.0+"
echo "- Language: Swift"
echo "- UI Framework: SwiftUI"
echo "- Core Data: Yes"
echo "- Networking: None (Local Only)"