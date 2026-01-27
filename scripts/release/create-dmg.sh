#!/bin/bash

# Create DMG disk image for Don't Be AFK
# This script creates a beautifully designed DMG with proper icon positioning and styling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APP_NAME="Don't Be AFK"
VERSION="1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_PATH="${PROJECT_ROOT}/${APP_NAME}.app"
DMG_NAME="DontBeAFK-${VERSION}.dmg"
DMG_PATH="${PROJECT_ROOT}/${DMG_NAME}"
TEMP_DMG_DIR="${PROJECT_ROOT}/dmg_temp"
TEMP_DMG="${PROJECT_ROOT}/temp_dmg.dmg"
VOLUME_NAME="Don't Be AFK"
MOUNT_DIR=""

# Cleanup function
cleanup() {
    if [ -n "$MOUNT_DIR" ] && [ -d "$MOUNT_DIR" ]; then
        print_info "Cleaning up mounted DMG..."
        hdiutil detach "$MOUNT_DIR" 2>/dev/null || true
    fi
    rm -f "$TEMP_DMG"
    rm -rf "$TEMP_DMG_DIR"
}

# Set trap to cleanup on exit
trap cleanup EXIT

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    print_error "App not found at $APP_PATH"
    print_info "Please build the app first using: ./scripts/build/build-app.sh"
    exit 1
fi

print_info "Creating DMG disk image..."

# Clean up previous DMG and temp files
rm -f "$DMG_PATH" "$TEMP_DMG"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# Copy app to temp directory
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# Create a symbolic link to Applications
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Calculate DMG size (add 50MB overhead for metadata)
DMG_SIZE=$(du -sm "$TEMP_DMG_DIR" | cut -f1)
DMG_SIZE=$((DMG_SIZE + 50))

print_info "Creating temporary DMG..."

# Create a temporary read-write DMG
hdiutil create -srcfolder "$TEMP_DMG_DIR" \
               -volname "$VOLUME_NAME" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDRW \
               -size ${DMG_SIZE}m \
               "$TEMP_DMG"

# Mount the DMG
print_info "Mounting DMG for customization..."
ATTACH_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" 2>&1)
ATTACH_EXIT_CODE=$?

if [ $ATTACH_EXIT_CODE -ne 0 ]; then
    print_error "Failed to mount DMG"
    echo "Error output:" >&2
    echo "$ATTACH_OUTPUT" >&2
    exit 1
fi

# Extract mount point from hdiutil output
# hdiutil attach output format: /dev/diskXsY    /Volumes/VolumeName
MOUNT_DIR=$(echo "$ATTACH_OUTPUT" | grep -E '^/dev/' | head -1 | awk '{print $3}')

# Alternative method: try to find mount point by volume name
if [ -z "$MOUNT_DIR" ]; then
    MOUNT_DIR=$(echo "$ATTACH_OUTPUT" | grep -oE '/Volumes/[^[:space:]]+' | head -1)
fi

# Final fallback: check if volume is mounted by name
if [ -z "$MOUNT_DIR" ] || [ ! -d "$MOUNT_DIR" ]; then
    MOUNT_DIR="/Volumes/$VOLUME_NAME"
    if [ ! -d "$MOUNT_DIR" ]; then
        print_error "Failed to mount DMG - could not determine mount point"
        echo "hdiutil attach output:" >&2
        echo "$ATTACH_OUTPUT" >&2
        exit 1
    fi
fi

print_info "DMG mounted at: $MOUNT_DIR"

print_info "Customizing DMG appearance..."

# Create a background image directory
BACKGROUND_DIR="$MOUNT_DIR/.background"
mkdir -p "$BACKGROUND_DIR"

# Create a simple gradient background image (640x480)
# Try multiple methods to create the background
BACKGROUND_CREATED=false

# Method 1: Try ImageMagick (best quality)
if command -v convert &> /dev/null; then
    convert -size 640x480 gradient:'#f5f5f5-#ffffff' "$BACKGROUND_DIR/background.png" 2>/dev/null && BACKGROUND_CREATED=true
fi

# Method 2: Try Python PIL
if [ "$BACKGROUND_CREATED" = false ] && command -v python3 &> /dev/null; then
    BACKGROUND_DIR="$BACKGROUND_DIR" python3 << 'PYTHON_SCRIPT'
import os
try:
    from PIL import Image, ImageDraw
    background_dir = os.environ.get('BACKGROUND_DIR')
    if background_dir:
        background_path = os.path.join(background_dir, 'background.png')
        img = Image.new('RGB', (640, 480), color='#f5f5f5')
        draw = ImageDraw.Draw(img)
        # Create a subtle gradient effect
        for y in range(480):
            color_val = int(245 + (255 - 245) * (y / 480))
            draw.rectangle([(0, y), (640, y+1)], fill=(color_val, color_val, color_val))
        img.save(background_path)
except ImportError:
    pass
PYTHON_SCRIPT
    [ -f "$BACKGROUND_DIR/background.png" ] && BACKGROUND_CREATED=true
fi

# Method 3: Create a simple solid color background using sips (fallback)
if [ "$BACKGROUND_CREATED" = false ]; then
    # Create a simple 1x1 PNG file using base64 (always works)
    # This is a minimal valid 1x1 white PNG
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -D > "$BACKGROUND_DIR/background.png" 2>/dev/null || \
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$BACKGROUND_DIR/background.png" 2>/dev/null || true
    
    # Scale it to the desired size and recolor if sips is available
    if [ -f "$BACKGROUND_DIR/background.png" ]; then
        sips -z 480 640 "$BACKGROUND_DIR/background.png" 2>/dev/null || true
        BACKGROUND_CREATED=true
    fi
fi

# If background creation failed, we'll proceed without it (DMG will still look good)
if [ "$BACKGROUND_CREATED" = false ]; then
    print_info "Note: Custom background image not created, using default DMG styling"
fi

# Use AppleScript to customize the DMG window appearance
print_info "Applying custom window styling..."
set +e  # Temporarily disable exit on error for AppleScript
osascript <<EOF 2>/dev/null
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 120, 860, 620}
        set view options of container window to icon view options
        set arrangement of icon view options of container window to not arranged
        set icon size of icon view options of container window to 128
        set text size of icon view options of container window to 12
        set label position of icon view options of container window to bottom
        set shows item info of icon view options of container window to false
        
        -- Set background picture if it exists
        try
            set background picture of icon view options of container window to file ".background:background.png"
        on error
            -- Background image not found, use default
        end try
        
        -- Position the app icon (left side, centered vertically)
        try
            set position of item "${APP_NAME}.app" of container window to {200, 280}
        on error
            -- Icon positioning failed, continue
        end try
        
        -- Position the Applications symlink (right side, centered vertically)
        try
            set position of item "Applications" of container window to {500, 280}
        on error
            -- Icon positioning failed, continue
        end try
        
        -- Update the window
        update without registering applications
        delay 2
    end tell
end tell
EOF
APPLE_SCRIPT_RESULT=$?
set -e  # Re-enable exit on error
if [ $APPLE_SCRIPT_RESULT -ne 0 ]; then
    print_warning "Could not customize DMG window appearance (DMG will still be created)"
fi

# Make sure the background image is hidden
chflags hidden "$BACKGROUND_DIR/background.png" 2>/dev/null || true

# Unmount the DMG
print_info "Unmounting DMG..."
hdiutil detach "$MOUNT_DIR" 2>/dev/null || true
MOUNT_DIR=""  # Clear mount dir so cleanup trap won't try to unmount again

# Convert to compressed read-only DMG
print_info "Compressing DMG..."
hdiutil convert "$TEMP_DMG" \
                -format UDZO \
                -imagekey zlib-level=9 \
                -o "$DMG_PATH"

# Clean up temp files (mount already handled above)
rm -f "$TEMP_DMG"
rm -rf "$TEMP_DMG_DIR"

if [ -f "$DMG_PATH" ]; then
    print_success "DMG created: $DMG_NAME"
    print_info "Size: $(du -h "$DMG_PATH" | cut -f1)"
    print_info "Design features:"
    print_info "  • App icon positioned on the left"
    print_info "  • Applications folder symlink on the right"
    print_info "  • Custom background styling"
    print_info "  • Optimized window size and icon layout"
else
    print_error "Failed to create DMG"
    exit 1
fi
