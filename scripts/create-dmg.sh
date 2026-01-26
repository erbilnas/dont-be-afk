#!/bin/bash

# Create DMG disk image for Don't Be AFK
# This script creates a DMG from the built app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APP_NAME="DontBeAFK"
VERSION="1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="${PROJECT_ROOT}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${PROJECT_ROOT}/${DMG_NAME}"
TEMP_DMG_DIR="${PROJECT_ROOT}/dmg_temp"

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    print_error "App not found at $APP_PATH"
    print_info "Please build the app first using: ./scripts/build-ui.sh"
    exit 1
fi

print_info "Creating DMG disk image..."

# Clean up previous DMG
rm -f "$DMG_PATH"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# Copy app to temp directory
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# Create a symbolic link to Applications
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Create DMG using hdiutil
hdiutil create -volname "Don't Be AFK" \
               -srcfolder "$TEMP_DMG_DIR" \
               -ov \
               -format UDZO \
               "$DMG_PATH"

# Clean up
rm -rf "$TEMP_DMG_DIR"

if [ -f "$DMG_PATH" ]; then
    print_success "DMG created: $DMG_NAME"
    print_info "Size: $(du -h "$DMG_PATH" | cut -f1)"
else
    print_error "Failed to create DMG"
    exit 1
fi
