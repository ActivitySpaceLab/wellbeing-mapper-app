#!/bin/bash
# ios-entitlements-check.sh - Validates iOS entitlements configuration

set -e

echo "🔍 Checking iOS entitlements configuration..."
echo ""

# Check if entitlements file exists
ENTITLEMENTS_FILE="ios/Runner/Runner.entitlements"
if [ -f "$ENTITLEMENTS_FILE" ]; then
    echo "✅ Entitlements file exists: $ENTITLEMENTS_FILE"
else
    echo "❌ Entitlements file missing: $ENTITLEMENTS_FILE"
    exit 1
fi

# Check entitlements file content
echo "📄 Entitlements file content:"
cat "$ENTITLEMENTS_FILE"
echo ""

# Check if entitlements are linked in Xcode project
XCODE_PROJECT="ios/Runner.xcodeproj/project.pbxproj"
if grep -q "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements" "$XCODE_PROJECT"; then
    echo "✅ Entitlements are linked in Xcode project"
    
    # Count how many build configurations have entitlements linked
    ENTITLEMENT_COUNT=$(grep -c "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements" "$XCODE_PROJECT")
    echo "📊 Found entitlements linked in $ENTITLEMENT_COUNT build configurations"
    
    if [ "$ENTITLEMENT_COUNT" -ge 3 ]; then
        echo "✅ Entitlements linked in all expected configurations (Debug, Release, Profile)"
    else
        echo "⚠️  Entitlements may not be linked in all configurations"
    fi
else
    echo "❌ Entitlements NOT linked in Xcode project"
    echo "💡 Need to add 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' to build configurations"
    exit 1
fi

# Check Info.plist for location permissions
INFO_PLIST="ios/Runner/Info.plist"
echo ""
echo "🔍 Checking location permissions in Info.plist..."

REQUIRED_KEYS=(
    "NSLocationAlwaysAndWhenInUseUsageDescription"
    "NSLocationAlwaysUsageDescription" 
    "NSLocationWhenInUseUsageDescription"
    "NSLocationUsageDescription"
)

for key in "${REQUIRED_KEYS[@]}"; do
    if grep -q "$key" "$INFO_PLIST"; then
        echo "✅ $key present"
    else
        echo "❌ $key missing"
    fi
done

# Check background modes
echo ""
echo "🔍 Checking background modes..."
if grep -q "<string>location</string>" "$INFO_PLIST"; then
    echo "✅ Location background mode enabled"
else
    echo "❌ Location background mode missing"
fi

# Final verification
echo ""
echo "🏗️ Build configuration test..."
echo "To test if entitlements work in release builds:"
echo "  1. flutter build ios --release --no-codesign"
echo "  2. Check if build succeeds without entitlement errors"
echo "  3. Archive in Xcode and verify entitlements are included"

echo ""
echo "📋 Summary:"
if [ -f "$ENTITLEMENTS_FILE" ] && grep -q "CODE_SIGN_ENTITLEMENTS" "$XCODE_PROJECT"; then
    echo "✅ iOS entitlements configuration appears correct"
    echo "💡 If TestFlight build still has location issues, the problem may be:"
    echo "   1. App Store Connect provisioning profile doesn't include location"
    echo "   2. Xcode archiving process not including entitlements"
    echo "   3. Different code signing between local and archive builds"
else
    echo "❌ iOS entitlements configuration has issues"
fi
