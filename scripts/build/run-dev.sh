#!/bin/bash

# Build and run the UI app from a stable path so Accessibility permission persists
# across rebuilds (Xcode Cmd+R uses DerivedData paths that change each build).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"
BUILD_DIR="$APP_DIR/build"
PRODUCT_NAME="Don't Be AFK"
DEV_APP="$HOME/Applications/${PRODUCT_NAME} Dev.app"
BUILT_APP="$BUILD_DIR/Build/Products/Debug/${PRODUCT_NAME}.app"

cd "$PROJECT_ROOT"

if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild not found. Install Xcode."
    exit 1
fi

echo "Building debug app (fixed DerivedData: $BUILD_DIR)..."
xcodebuild -project "$APP_DIR/DontBeAFK.xcodeproj" \
           -scheme DontBeAFK \
           -configuration Debug \
           -derivedDataPath "$BUILD_DIR" \
           build

if [ ! -d "$BUILT_APP" ]; then
    echo "Error: Build succeeded but app not found at:"
    echo "  $BUILT_APP"
    exit 1
fi

mkdir -p "$HOME/Applications"
echo "Installing dev app to stable location:"
echo "  $DEV_APP"
rm -rf "$DEV_APP"
ditto "$BUILT_APP" "$DEV_APP"

echo "Launching..."
open "$DEV_APP"

echo ""
echo "Grant Accessibility once for '${PRODUCT_NAME} Dev' in System Settings."
echo "Rebuilds will reuse the same install path."
