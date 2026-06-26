#!/bin/bash

# Build script for Wellbeing Mapper
# This script builds both Android and iOS versions for release

echo "🚀 Building Wellbeing Mapper for release..."

# Sync version information first to ensure correct version
echo "🔄 Syncing version information..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
if [ -f "$SCRIPT_DIR/sync-version.sh" ]; then
    (cd "$SCRIPT_DIR" && ./sync-version.sh)
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

# Initialize status variables
AAB_STATUS="Not built"
APK_STATUS="Not built"
ANDROID_NATIVE_SYMBOLS_STATUS="Not found"
ANDROID_MAPPING_STATUS="Not found"
IOS_APP_STATUS="Not built"
IOS_IPA_STATUS="Not built"
BUILD_SUCCESS=true

# Build Android App Bundle (recommended for Play Store)
echo "🤖 Building Android App Bundle..."
if fvm flutter build appbundle --flavor production; then
    AAB_STATUS="✅ build/app/outputs/bundle/production/release/app-production-release.aab"
else
    AAB_STATUS="❌ Build failed"
    BUILD_SUCCESS=false
fi
echo ""

# Build Android APKs (alternative distribution)
echo "🤖 Building Android APKs..."
if fvm flutter build apk --split-per-abi --flavor production; then
    APK_STATUS="✅ build/app/outputs/flutter-apk/ (app-*-production-release.apk)"
else
    APK_STATUS="❌ Build failed"
    BUILD_SUCCESS=false
fi
echo ""

# Collect Android symbol artifacts for Play Console crash/ANR symbolication.
echo "🧩 Collecting Android symbol artifacts..."
SYMBOLS_OUT_DIR="$SCRIPT_DIR/build_outputs/android-symbols"
mkdir -p "$SYMBOLS_OUT_DIR"

NATIVE_SYMBOLS_FILE=$(find "$SCRIPT_DIR/build/app/outputs/native-debug-symbols" -type f -name "*native-debug-symbols*.zip" 2>/dev/null | head -n 1)
if [ -n "$NATIVE_SYMBOLS_FILE" ]; then
    cp "$NATIVE_SYMBOLS_FILE" "$SYMBOLS_OUT_DIR/native-debug-symbols.zip"
    ANDROID_NATIVE_SYMBOLS_STATUS="✅ build_outputs/android-symbols/native-debug-symbols.zip"
else
    ANDROID_NATIVE_SYMBOLS_STATUS="⚠️  Not found (check Android Gradle native symbol config)"
fi

MAPPING_FILE=$(find "$SCRIPT_DIR/build/app/outputs/mapping" -type f -name "mapping.txt" 2>/dev/null | head -n 1)
if [ -n "$MAPPING_FILE" ]; then
    cp "$MAPPING_FILE" "$SYMBOLS_OUT_DIR/mapping.txt"
    ANDROID_MAPPING_STATUS="✅ build_outputs/android-symbols/mapping.txt"
else
    ANDROID_MAPPING_STATUS="⚠️  Not found"
fi
echo ""

# Install iOS dependencies
echo "🍎 Installing iOS dependencies..."
if (cd "$SCRIPT_DIR/ios" && pod install); then
    echo "✅ Pods installed successfully."
else
    echo "⚠️  Failed to install Pods."
fi
echo ""

# Build iOS (for later archiving in Xcode)
echo "🍎 Building iOS..."
if fvm flutter build ios --release --no-codesign; then
    IOS_APP_STATUS="✅ build/ios/iphoneos/Runner.app"
else
    IOS_APP_STATUS="❌ Build failed"
    BUILD_SUCCESS=false
fi
echo ""

# Build iOS IPA (for App Store distribution via Transporter)
echo "🍎 Building iOS IPA..."

# If App Store Connect API key variables are provided, allow Xcode to
# automatically download/create provisioning profiles during archive/export.
# Required env vars for this path:
#   APPSTORE_API_KEY_ID
#   APPSTORE_API_ISSUER_ID
#   APPSTORE_API_KEY_PATH
IPA_BUILD_CMD=(fvm flutter build ipa --export-options-plist=ios/ExportOptions.plist)
if [ -n "$APPSTORE_API_KEY_ID" ] && [ -n "$APPSTORE_API_ISSUER_ID" ] && [ -n "$APPSTORE_API_KEY_PATH" ]; then
    echo "🔐 Using App Store Connect API key for provisioning updates..."
    IPA_BUILD_CMD+=(
        --export-method=app-store
        --
        -allowProvisioningUpdates
        -authenticationKeyID "$APPSTORE_API_KEY_ID"
        -authenticationKeyIssuerID "$APPSTORE_API_ISSUER_ID"
        -authenticationKeyPath "$APPSTORE_API_KEY_PATH"
    )
fi

if "${IPA_BUILD_CMD[@]}"; then
    # Dynamically locate the built IPA across common output locations.
    IPA_FILE=$(find "$SCRIPT_DIR/build/ios" -type f -name "*.ipa" 2>/dev/null | head -n 1)
    if [ -n "$IPA_FILE" ]; then
        # Make path relative to script directory for cleaner display
        REL_IPA_FILE=${IPA_FILE#"$SCRIPT_DIR/"}
        IOS_IPA_STATUS="✅ $REL_IPA_FILE"
    else
        ARCHIVE_FILE=$(find "$SCRIPT_DIR/build/ios/archive" -maxdepth 2 -name "*.xcarchive" 2>/dev/null | head -n 1)
        if [ -n "$ARCHIVE_FILE" ]; then
            IOS_IPA_STATUS="⚠️  Archive created but IPA not exported (check signing/export options)"
        else
            IOS_IPA_STATUS="⚠️  Build succeeded but IPA file not found under build/ios/"
        fi
    fi
else
    PROFILE_COUNT=$(find "$HOME/Library/MobileDevice/Provisioning Profiles" -maxdepth 1 -name "*.mobileprovision" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PROFILE_COUNT" = "0" ]; then
        IOS_IPA_STATUS="❌ Build failed (no provisioning profiles installed locally)"
    else
        IOS_IPA_STATUS="❌ Build failed (check provisioning profile name/team/bundle ID alignment)"
    fi
fi
echo ""

if [ "$BUILD_SUCCESS" = true ] && [[ "$IOS_IPA_STATUS" == ✅* ]]; then
    echo "✅ Build complete!"
else
    echo "⚠️  Build finished with some errors or warnings."
fi
echo ""
echo "📁 Output files:"
echo "  Android App Bundle: $AAB_STATUS"
echo "  Android APKs:       $APK_STATUS"
echo "  Android Symbols:    $ANDROID_NATIVE_SYMBOLS_STATUS"
echo "  Android Mapping:    $ANDROID_MAPPING_STATUS"
echo "  iOS App:            $IOS_APP_STATUS"
echo "  iOS IPA:            $IOS_IPA_STATUS"
echo ""
echo "📋 Next steps:"
echo "  1. Upload Android AAB to Google Play Console"
if [[ "$ANDROID_NATIVE_SYMBOLS_STATUS" == ✅* ]]; then
    echo "  1b. Upload Android native symbols zip in Play Console:"
    echo "      build_outputs/android-symbols/native-debug-symbols.zip"
fi
if [[ "$ANDROID_MAPPING_STATUS" == ✅* ]]; then
    echo "  1c. Upload Android mapping file if requested:"
    echo "      build_outputs/android-symbols/mapping.txt"
fi
if [[ "$IOS_IPA_STATUS" == ✅* ]]; then
    echo "  2. Upload iOS IPA to App Store Connect via Transporter"
else
    echo "  2. Distribute iOS app manually in Xcode using the archive:"
    echo "     open build/ios/archive/Runner.xcarchive"
    echo "     Tip: set APPSTORE_API_KEY_ID/APPSTORE_API_ISSUER_ID/APPSTORE_API_KEY_PATH to let CI/script auto-manage profiles"
fi
echo "  3. Create GitHub release with the builds"
echo ""
echo "⚠️  Note: Android minSdkVersion updated to 23 for record package compatibility"
