#!/bin/bash

# Sync local.properties version with pubspec.yaml version
# This ensures Android builds use the correct version information

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"

echo "🔄 Syncing local.properties with pubspec.yaml version..."

# Check if pubspec.yaml exists
if [ ! -f "$APP_DIR/pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found at $APP_DIR/pubspec.yaml"
    exit 1
fi

# Extract version information from pubspec.yaml
FULL_VERSION=$(grep "version:" "$APP_DIR/pubspec.yaml" | sed 's/version: //' | tr -d ' ')
VERSION_NAME=$(echo "$FULL_VERSION" | cut -d'+' -f1)
VERSION_CODE=$(echo "$FULL_VERSION" | cut -d'+' -f2)

echo "📋 Version information from pubspec.yaml:"
echo "   Full version: $FULL_VERSION"
echo "   Version name: $VERSION_NAME"
echo "   Version code: $VERSION_CODE"

# Get current Flutter SDK path
FLUTTER_SDK_PATH=""
if command -v flutter >/dev/null 2>&1; then
    # Try to get Flutter SDK path from flutter command
    FLUTTER_SDK_PATH=$(which flutter 2>/dev/null | sed 's|/bin/flutter||')
    if [ -z "$FLUTTER_SDK_PATH" ] && [ -n "$FLUTTER_ROOT" ]; then
        FLUTTER_SDK_PATH="$FLUTTER_ROOT"
    elif [ -z "$FLUTTER_SDK_PATH" ]; then
        # Fallback to common Flutter locations
        if [ -d "$HOME/fvm/versions/3.27.1" ]; then
            FLUTTER_SDK_PATH="$HOME/fvm/versions/3.27.1"
        elif [ -d "/opt/hostedtoolcache/flutter" ]; then
            FLUTTER_SDK_PATH="/opt/hostedtoolcache/flutter"
        else
            FLUTTER_SDK_PATH="/opt/flutter"
        fi
    fi
else
    FLUTTER_SDK_PATH="/opt/flutter"
fi

# Get Android SDK path (try multiple common locations)
ANDROID_SDK_PATH=""
if [ -n "$ANDROID_HOME" ]; then
    ANDROID_SDK_PATH="$ANDROID_HOME"
elif [ -n "$ANDROID_SDK_ROOT" ]; then
    ANDROID_SDK_PATH="$ANDROID_SDK_ROOT"
elif [ -d "$HOME/Library/Android/sdk" ]; then
    ANDROID_SDK_PATH="$HOME/Library/Android/sdk"
elif [ -d "$HOME/Android/Sdk" ]; then
    ANDROID_SDK_PATH="$HOME/Android/Sdk"
else
    echo "⚠️  Warning: Android SDK path not found. Using placeholder."
    ANDROID_SDK_PATH="/opt/android-sdk"
fi

echo "🛠️  SDK paths:"
echo "   Flutter SDK: $FLUTTER_SDK_PATH"
echo "   Android SDK: $ANDROID_SDK_PATH"

# Create/update local.properties
LOCAL_PROPS_FILE="$APP_DIR/android/local.properties"

echo "📝 Updating $LOCAL_PROPS_FILE..."

cat > "$LOCAL_PROPS_FILE" << EOF
sdk.dir=$ANDROID_SDK_PATH
flutter.sdk=$FLUTTER_SDK_PATH
flutter.buildMode=release
flutter.versionName=$VERSION_NAME
flutter.versionCode=$VERSION_CODE
EOF

echo "✅ local.properties updated successfully!"
echo ""
echo "📄 Content of local.properties:"
cat "$LOCAL_PROPS_FILE"

echo ""
echo "🚀 Ready for Android builds with correct version information!"
echo "   You can now run: flutter build apk --release"