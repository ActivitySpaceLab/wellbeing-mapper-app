#!/bin/bash
# ios-entitlements-check.sh - Validates iOS entitlements configuration

set -e

EXPECTED_PRODUCTION_BUNDLE_ID="com.github.activityspacelab.wellbeingmapper.barcelona"
EXPECTED_BETA_BUNDLE_ID="com.github.activityspacelab.wellbeingmapper.barcelona.beta"

print_plist_value() {
    local plist_path="$1"
    local key="$2"
    /usr/libexec/PlistBuddy -c "Print :$key" "$plist_path" 2>/dev/null
}

check_plist_for_keys() {
    local plist_path="$1"
    shift
    local keys=("$@")
    local missing=0

    for key in "${keys[@]}"; do
        if print_plist_value "$plist_path" "$key" >/dev/null; then
            echo "✅ $key present"
        else
            echo "❌ $key missing"
            missing=1
        fi
    done

    return $missing
}

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

# Check Info.plist files for location permissions
REQUIRED_KEYS=(
    "NSLocationAlwaysAndWhenInUseUsageDescription"
    "NSLocationAlwaysUsageDescription" 
    "NSLocationWhenInUseUsageDescription"
    "NSLocationUsageDescription"
)

INFO_PLISTS=(
    "ios/Runner/Info.plist"
    "ios/Runner/Info-Production.plist"
    "ios/Runner/Info-Beta.plist"
)

echo ""
echo "🔍 Checking Info.plist files for required keys and bundle IDs..."

plist_fail=0
for plist in "${INFO_PLISTS[@]}"; do
    echo ""
    echo "📦 Inspecting $plist"
    if [ ! -f "$plist" ]; then
        echo "❌ Missing plist: $plist"
        plist_fail=1
        continue
    fi

    check_plist_for_keys "$plist" "${REQUIRED_KEYS[@]}" || plist_fail=1

    background_modes=$(print_plist_value "$plist" "UIBackgroundModes" | tr '\n' ' ' || true)
    if echo "$background_modes" | grep -q "location"; then
        echo "✅ Location background mode enabled"
    else
        echo "❌ Location background mode missing"
        plist_fail=1
    fi

    bundle_id=$(print_plist_value "$plist" "CFBundleIdentifier" || true)
    case "$plist" in
        *Info-Production.plist)
            if [ "$bundle_id" = "$EXPECTED_PRODUCTION_BUNDLE_ID" ]; then
                echo "✅ Production bundle identifier matches ($bundle_id)"
            else
                echo "❌ Production bundle identifier mismatch (found $bundle_id)"
                plist_fail=1
            fi
            ;;
        *Info-Beta.plist)
            if [ "$bundle_id" = "$EXPECTED_BETA_BUNDLE_ID" ]; then
                echo "✅ Beta bundle identifier matches ($bundle_id)"
            else
                echo "❌ Beta bundle identifier mismatch (found $bundle_id)"
                plist_fail=1
            fi
            ;;
        *)
            echo "ℹ️  Info.plist bundle identifier: ${bundle_id:-unknown}";
            ;;
    esac
done

# Final verification
echo ""
echo "🏗️ Build configuration test..."
echo "To test if entitlements work in release builds:"
echo "  1. flutter build ios --release --no-codesign"
echo "  2. Check if build succeeds without entitlement errors"
echo "  3. Archive in Xcode and verify entitlements are included"

echo ""
echo "📋 Summary:"
if [ -f "$ENTITLEMENTS_FILE" ] && grep -q "CODE_SIGN_ENTITLEMENTS" "$XCODE_PROJECT" && [ "$plist_fail" -eq 0 ]; then
    echo "✅ iOS entitlements configuration appears correct"
    echo "💡 If TestFlight build still has location issues, the problem may be:"
    echo "   1. App Store Connect provisioning profile doesn't include location"
    echo "   2. Xcode archiving process not including entitlements"
    echo "   3. Different code signing between local and archive builds"
else
    echo "❌ iOS entitlements configuration has issues"
fi
