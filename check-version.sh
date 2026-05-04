#!/bin/bash
# check-version.sh - Validates version consistency between pubspec.yaml and git tags

set -e

echo "🔍 Checking version consistency..."

# Get version from pubspec.yaml (remove build number)
PUBSPEC_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d ' ')
echo "📄 pubspec.yaml version: $PUBSPEC_VERSION"

# Get latest git tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
if [ "$LATEST_TAG" = "none" ]; then
    echo "📋 No git tags found. This will be the first release."
    echo "✅ Ready to create tag: v$PUBSPEC_VERSION"
    exit 0
fi

LATEST_TAG_VERSION=${LATEST_TAG#v}  # Remove 'v' prefix
echo "🏷️  Latest git tag: $LATEST_TAG (version: $LATEST_TAG_VERSION)"

# Compare versions
if [ "$PUBSPEC_VERSION" = "$LATEST_TAG_VERSION" ]; then
    echo "⚠️  Versions match current tag!"
    echo "💡 If you want to create a new release, update the version in pubspec.yaml first"
    exit 1
else
    echo "✅ Versions are different - ready for new release!"
    echo "📋 Suggested next steps:"
    echo "   1. git add pubspec.yaml"
    echo "   2. git commit -m 'Bump version to $PUBSPEC_VERSION'"
    echo "   3. git tag v$PUBSPEC_VERSION"
    echo "   4. git push origin main"
    echo "   5. git push origin v$PUBSPEC_VERSION"
    exit 0
fi
