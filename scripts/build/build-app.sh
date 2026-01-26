#!/bin/bash

# Build script for macOS UI app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"

cd "$PROJECT_ROOT"

echo "🔨 Building Don't Be AFK macOS App..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# Get version from git tag
echo "🏷️  Getting version from git tag..."
GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
VERSION="${GIT_TAG#v}"  # Remove 'v' prefix if present

# Default version if no tag found
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
    echo "   No git tag found, using default version: $VERSION"
else
    echo "   Found git tag: $GIT_TAG -> Version: $VERSION"
fi

# Get commit count for build number
COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "1")
echo "   Build number (commit count): $COMMIT_COUNT"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$APP_DIR/build"
rm -rf "$PROJECT_ROOT/Don't Be AFK.app"
rm -rf "$PROJECT_ROOT/DontBeAFK.app"

# Build the app with version from git tag
echo "📦 Building app..."
xcodebuild -project "$APP_DIR/DontBeAFK.xcodeproj" \
           -scheme DontBeAFK \
           -configuration Release \
           -derivedDataPath "$APP_DIR/build" \
           MARKETING_VERSION="$VERSION" \
           CURRENT_PROJECT_VERSION="$COMMIT_COUNT" \
           clean build

# Copy app to project root
if [ -d "$APP_DIR/build/Build/Products/Release/Don't Be AFK.app" ]; then
    echo "📋 Copying app to project root..."
    cp -R "$APP_DIR/build/Build/Products/Release/Don't Be AFK.app" "$PROJECT_ROOT/"
    echo "✅ Build complete! App is available at: Don't Be AFK.app"
    echo "   Version: $VERSION (Build $COMMIT_COUNT)"
    echo ""
    echo "To run the app:"
    echo "  open \"Don't Be AFK.app\""
    echo ""
    echo "To install to Applications:"
    echo "  cp -R \"Don't Be AFK.app\" /Applications/"
else
    echo "❌ Build failed - app not found in expected location"
    exit 1
fi
