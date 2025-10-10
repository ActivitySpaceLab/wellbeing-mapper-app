#!/bin/bash

# Build script for Wellbeing Mapper
# This script builds both Android and iOS versions for release

echo "🚀 Building Wellbeing Mapper for release..."

# Sync version information first to ensure correct version
echo "🔄 Syncing version information..."
if [ -f "./sync-version.sh" ]; then
    ./sync-version.sh
else
    echo "⚠️  sync-version.sh not found, proceeding with current version..."
fi
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
fvm flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
fvm flutter pub get

# Build Android App Bundle (recommended for Play Store)
echo "🤖 Building Android App Bundle..."
fvm flutter build appbundle --flavor production --dart-define=APP_FLAVOR=production

# Build Android APKs (alternative distribution)
echo "🤖 Building Android APKs..."
fvm flutter build apk --split-per-abi --flavor production --dart-define=APP_FLAVOR=production

# Install iOS dependencies
echo "🍎 Installing iOS dependencies..."
cd ios && pod install && cd ..

# Build iOS (for later archiving in Xcode)
echo "🍎 Building iOS..."
fvm flutter build ios --release --no-codesign --dart-define=APP_FLAVOR=production

# Build iOS IPA (for App Store distribution via Transporter)
echo "🍎 Building iOS IPA..."
fvm flutter build ipa --dart-define=APP_FLAVOR=production

echo "✅ Build complete!"
echo ""
echo "📁 Output files:"
echo "  Android App Bundle: build/app/outputs/bundle/productionRelease/app-production-release.aab"
echo "  Android APKs: build/app/outputs/flutter-apk/ (app-*-production-release.apk)"
echo "  iOS App: build/ios/iphoneos/Runner.app"
echo "  iOS IPA: build/ios/ipa/Runner.ipa"
echo ""
echo "📋 Next steps:"
echo "  1. Upload Android AAB to Google Play Console"
echo "  2. Upload iOS IPA to App Store Connect via Transporter"
echo "  3. Create GitHub release with both builds and update release notes"
echo ""
echo "⚠️  Note: Android minSdkVersion updated to 23 for record package compatibility"
