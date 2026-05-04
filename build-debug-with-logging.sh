#!/bin/bash

# Debug build script with enhanced logging for troubleshooting
# This creates debug builds that can update release versions while preserving logging
# Usage: ./build-debug-with-logging.sh [production|beta] [android|ios|all]

set -e

FLAVOR=${1:-production}
PLATFORM=${2:-all}

if [[ "$FLAVOR" != "production" && "$FLAVOR" != "beta" ]]; then
    echo "Error: Flavor must be 'production' or 'beta'"
    echo "Usage: $0 [production|beta] [android|ios|all]"
    exit 1
fi

if [[ "$PLATFORM" != "android" && "$PLATFORM" != "ios" && "$PLATFORM" != "all" ]]; then
    echo "Error: Platform must be 'android', 'ios', or 'all'"
    echo "Usage: $0 [production|beta] [android|ios|all]"
    exit 1
fi

echo "🔍 Building DEBUG $FLAVOR flavor for $PLATFORM with enhanced logging..."
echo "📋 This debug build can update your existing release app while showing logs"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Verify we're on the correct branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📂 Current branch: $CURRENT_BRANCH"

if [[ "$CURRENT_BRANCH" != "fix/data-upload-debugging" ]]; then
    echo "⚠️  Warning: You're not on the fix/data-upload-debugging branch"
    echo "⚠️  Current branch: $CURRENT_BRANCH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Build cancelled"
        exit 1
    fi
fi

# Build Android DEBUG with logging
if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
    echo "📱 Building Android $FLAVOR DEBUG APK with enhanced logging..."
    
    # Build debug APK that can update release version
    flutter build apk --debug \
        --flavor=$FLAVOR \
        --dart-define=APP_FLAVOR=$FLAVOR \
        --target-platform android-arm,android-arm64,android-x64
    
    echo "✅ Android $FLAVOR DEBUG build complete!"
    echo "📁 APK Location: build/app/outputs/flutter-apk/app-$FLAVOR-debug.apk"
    
    # Check if ADB is available and devices are connected
    if command -v adb &> /dev/null; then
        echo ""
        echo "📱 Checking connected Android devices..."
        ANDROID_DEVICES=$(adb devices | grep -E "device$" | wc -l)
        if [[ $ANDROID_DEVICES -gt 0 ]]; then
            echo "✅ Found $ANDROID_DEVICES Android device(s) connected"
            echo ""
            echo "🔧 To install on Android device:"
            echo "   adb install -r build/app/outputs/flutter-apk/app-$FLAVOR-debug.apk"
            echo ""
            echo "📋 To view logs after installation:"
            echo "   adb logcat | grep -E '(main\\.dart|AppModeService|EncryptedSurveyService|ParticipationSelection)'"
            echo ""
        else
            echo "⚠️  No Android devices found. Make sure:"
            echo "   1. Device is connected via USB"
            echo "   2. Developer options are enabled"
            echo "   3. USB debugging is enabled"
            echo "   4. You've authorized the computer on the device"
        fi
    else
        echo "⚠️  ADB not found. Install Android SDK to use ADB commands."
    fi
fi

# Build iOS DEBUG with logging
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
    echo "📱 Building iOS $FLAVOR DEBUG with enhanced logging..."
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "❌ iOS builds require macOS"
        exit 1
    fi
    
    # Build iOS debug
    flutter build ios --debug \
        --flavor=$FLAVOR \
        --dart-define=APP_FLAVOR=$FLAVOR
    
    echo "✅ iOS $FLAVOR DEBUG build complete!"
    echo "📁 iOS build: build/ios/iphoneos/Runner.app"
    echo ""
    echo "🔧 To install on iOS device:"
    echo "   1. Open Xcode"
    echo "   2. Go to Window > Devices and Simulators"
    echo "   3. Select your device"
    echo "   4. Click 'Add App...' and select: build/ios/iphoneos/Runner.app"
    echo ""
    echo "📋 To view logs on iOS device:"
    echo "   1. Keep device connected"
    echo "   2. Open Console.app on Mac"
    echo "   3. Select your device"
    echo "   4. Filter by 'Runner' or search for: main.dart AppModeService"
    echo ""
fi

echo ""
echo "🎯 DEBUG BUILD SUMMARY"
echo "======================"
echo "Flavor: $FLAVOR"
echo "Platform: $PLATFORM"
echo "Branch: $CURRENT_BRANCH"
echo "Enhanced Logging: ✅ Enabled"
echo ""
echo "🔍 What to look for in logs:"
echo "   • App mode detection during startup"
echo "   • Build flavor validation"
echo "   • Mode storage and validation"
echo "   • Data upload decision logic"
echo ""
echo "🚨 Key log patterns to search for:"
echo "   • '[main.dart] ======= APP MODE DEBUG INFO =======' (startup)"
echo "   • '[AppModeService]' (mode operations)"
echo "   • '[EncryptedSurveyService]' (data upload attempts)"
echo "   • '⚠️' or '❌' (warnings and errors)"
echo ""