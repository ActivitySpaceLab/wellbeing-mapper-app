#!/bin/bash

# Barcelona Wellbeing Mapper - Demo Build Script
# Uses the existing beta flavor which is already configured for demonstrations

set -e

echo "🎭 Building Barcelona Wellbeing Mapper Demo (Beta Flavor)..."
echo ""
echo "💡 The beta flavor automatically provides:"
echo "   • No research mode (no server data transmission)"
echo "   • App testing mode available for safe demos" 
echo "   • Data export functionality"
echo "   • Different app ID (won't conflict with production)"
echo ""

# Clean and prepare
echo "🧹 Cleaning and preparing..."
flutter clean
flutter pub get

# Build APK using beta flavor
echo "📱 Building beta APK for demonstrations..."
flutter build apk --flavor beta

# Check if build was successful
if [ $? -eq 0 ]; then
    APK_PATH="build/app/outputs/flutter-apk/app-beta-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        
        echo ""
        echo "🎉 Demo build completed successfully!"
        echo "📦 APK: $APK_PATH"
        echo "📏 Size: $APK_SIZE"
        echo ""
        echo "🎭 Ready for demonstration!"
        echo "   • App name: Barcelona Wellbeing Mapper Demo"
        echo "   • Package: com.github.activityspacelab.wellbeingmapper.barcelona.beta"
        echo "   • Safe for demos: No research data transmission"
        echo ""
        echo "📱 To install: adb install \"$APK_PATH\""
        echo ""
        
        # Copy to convenient location
        DEMO_DIR="demo_builds"
        mkdir -p "$DEMO_DIR"
        DEMO_APK="$DEMO_DIR/barcelona_demo_$(date +%Y%m%d_%H%M).apk"
        cp "$APK_PATH" "$DEMO_APK"
        echo "📋 Demo APK saved: $DEMO_APK"
        
    else
        echo "❌ APK not found at: $APK_PATH"
        exit 1
    fi
else
    echo "❌ Build failed!"
    exit 1
fi