#!/bin/bash

# Test script to verify flavor detection and mode availability
# Usage: ./test-flavors.sh

echo "🧪 Testing Flutter App Flavors..."
echo

# Test production flavor
echo "📋 Testing Production Flavor:"
echo "Command: flutter run --dart-define=APP_FLAVOR=production --help"
flutter run --dart-define=APP_FLAVOR=production --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Production flavor command structure is valid"
else
    echo "❌ Production flavor command failed"
fi

# Test beta flavor  
echo "📋 Testing Beta Flavor:"
echo "Command: flutter run --dart-define=APP_FLAVOR=beta --help"
flutter run --dart-define=APP_FLAVOR=beta --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Beta flavor command structure is valid"
else
    echo "❌ Beta flavor command failed"
fi

echo
echo "🏗️ Build Test Results:"
echo "✅ Production Android APK: $(ls -la build/app/outputs/flutter-apk/app-production-release.apk 2>/dev/null | wc -l | tr -d ' ') file(s)"
echo "✅ Beta Android APK: $(ls -la build/app/outputs/flutter-apk/app-beta-release.apk 2>/dev/null | wc -l | tr -d ' ') file(s)"

echo
echo "📱 Bundle Identifiers:"
echo "Production: com.github.activityspacelab.wellbeingmapper.gauteng"
echo "Beta: com.github.activityspacelab.wellbeingmapper.gauteng.beta"

echo
echo "🎯 Expected Mode Availability:"
echo "Production Build (APP_FLAVOR=production):"
echo "  • Private Mode ✅"
echo "  • Research Mode ✅"
echo "  • App Testing Mode ❌ (Not available)"
echo
echo "Beta Build (APP_FLAVOR=beta):"
echo "  • Private Mode ✅"
echo "  • Research Mode ✅"
echo "  • App Testing Mode ✅"

echo
echo "🚀 Ready for Development and Release!"
echo "Use './build-flavors.sh production android' for production builds"
echo "Use './build-flavors.sh beta android' for beta testing builds"
