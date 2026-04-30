#!/bin/bash

# Create macOS Installer for Don't Be AFK
# This script builds the app and creates a .pkg installer

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Don't Be AFK"
BUNDLE_ID="com.dontbeafk.app"
INSTALLER_NAME="DontBeAFK-Installer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"

cd "$PROJECT_ROOT"

# Get version from argument or git tag
if [ -n "$1" ]; then
    VERSION="$1"
else
    GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    VERSION="${GIT_TAG#v}"  # Remove 'v' prefix if present
    if [ -z "$VERSION" ]; then
        VERSION="1.0.0"
    fi
fi

# Get commit count for build number
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "1")
BUILD_DIR="$APP_DIR/build"
PKG_DIR="$SCRIPT_DIR/../pkg"
DMG_DIR="$PROJECT_ROOT/dmg"
APP_PATH="$BUILD_DIR/Build/Products/Release/${APP_NAME}.app"
RESOURCES_DIR="$PKG_DIR/resources"
SCRIPTS_DIR="$PKG_DIR/scripts"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Don't Be AFK - macOS Installer Creator${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v xcodebuild &> /dev/null; then
        print_error "xcodebuild not found. Please install Xcode."
        exit 1
    fi
    
    if ! command -v pkgbuild &> /dev/null; then
        print_error "pkgbuild not found. This is part of Xcode Command Line Tools."
        exit 1
    fi
    
    if ! command -v productbuild &> /dev/null; then
        print_error "productbuild not found. This is part of Xcode Command Line Tools."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Build the app
build_app() {
    print_info "Building ${APP_NAME} v${VERSION} (Build ${BUILD_NUMBER})..."
    
    # Clean previous builds
    rm -rf "$BUILD_DIR"
    rm -rf "${PROJECT_ROOT}/${APP_NAME}.app"
    
    # Build the app with version from git tag
    xcodebuild -project "${APP_DIR}/DontBeAFK.xcodeproj" \
               -scheme "DontBeAFK" \
               -configuration Release \
               -derivedDataPath "$BUILD_DIR" \
               clean build \
               CODE_SIGN_IDENTITY="" \
               CODE_SIGNING_REQUIRED=NO \
               CODE_SIGNING_ALLOWED=NO \
               MARKETING_VERSION="${VERSION}" \
               CURRENT_PROJECT_VERSION="${BUILD_NUMBER}"
    
    if [ ! -d "$APP_PATH" ]; then
        print_error "Build failed - app not found at $APP_PATH"
        exit 1
    fi
    
    print_success "App built successfully"
}

# Create package structure
create_package_structure() {
    print_info "Creating package structure..."
    
    rm -rf "$PKG_DIR"
    mkdir -p "$RESOURCES_DIR"
    mkdir -p "$SCRIPTS_DIR"
    
    print_success "Package structure created"
}

# Create postinstall script
create_postinstall_script() {
    print_info "Creating postinstall script..."
    
    cat > "$SCRIPTS_DIR/postinstall" << 'POSTINSTALL_EOF'
#!/bin/bash

# Postinstall script for Don't Be AFK
# This script runs after the app is installed

set -e

APP_PATH="/Applications/Don't Be AFK.app"
CLI_NAME="dont-be-afk"
CLI_DST="/usr/local/bin/${CLI_NAME}"

# Check if app was installed
if [ ! -d "$APP_PATH" ]; then
    echo "Error: Don't Be AFK.app not found in /Applications"
    exit 1
fi

# Set proper permissions
chmod -R 755 "$APP_PATH"

# Set executable permissions on the app bundle binary (name matches CFBundleExecutable)
EXEC_NAME=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "")
if [[ -n "$EXEC_NAME" ]]; then
    chmod +x "${APP_PATH}/Contents/MacOS/${EXEC_NAME}"
fi

# Bundled CLI: Resources/cli/bin (preferred) or legacy Resources/bin
CLI_SRC=""
if [ -f "${APP_PATH}/Contents/Resources/cli/bin/${CLI_NAME}" ]; then
    CLI_SRC="${APP_PATH}/Contents/Resources/cli/bin/${CLI_NAME}"
elif [ -f "${APP_PATH}/Contents/Resources/bin/${CLI_NAME}" ]; then
    CLI_SRC="${APP_PATH}/Contents/Resources/bin/${CLI_NAME}"
fi

if [ -n "$CLI_SRC" ]; then
    chmod +x "$CLI_SRC"
    for f in "${APP_PATH}/Contents/Resources/cli/lib/"*.sh; do
        [ -f "$f" ] && chmod +x "$f"
    done
    mkdir -p /usr/local/bin
    rm -f "$CLI_DST"
    ln -sf "$CLI_SRC" "$CLI_DST"
    echo "Installed CLI symlink: $CLI_DST -> $CLI_SRC"
else
    echo "Warning: bundled CLI not found in app Resources (expected cli/bin/${CLI_NAME})"
fi

# Remove quarantine attribute (allows app to run without Gatekeeper warning)
xattr -d com.apple.quarantine "$APP_PATH" 2>/dev/null || true

echo "Don't Be AFK installed successfully!"
echo ""
echo "To use the app:"
echo "  1. Open /Applications/Don't Be AFK.app"
echo "  2. Grant accessibility permissions when prompted"
echo "  3. Configure your settings and start the automation"
echo ""
echo "The command-line tool is available as: /usr/local/bin/dont-be-afk"
echo ""
echo "Note: You may need to grant accessibility permissions in:"
echo "  System Settings → Privacy & Security → Accessibility"

exit 0
POSTINSTALL_EOF

    chmod +x "$SCRIPTS_DIR/postinstall"
    print_success "Postinstall script created"
}

# Create distribution.xml
create_distribution_xml() {
    print_info "Creating distribution.xml..."
    
    cat > "$PKG_DIR/distribution.xml" << DISTRIBUTION_EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>Don't Be AFK ${VERSION}</title>
    <organization>com.dontbeafk</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="false" rootVolumeOnly="true"/>
    <welcome file="welcome.html" mime-type="text/html"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>
    <pkg-ref id="${BUNDLE_ID}"/>
    <options customize="never" require-scripts="false"/>
    <choices-outline>
        <line choice="default">
            <line choice="${BUNDLE_ID}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${BUNDLE_ID}" visible="false">
        <pkg-ref id="${BUNDLE_ID}"/>
    </choice>
    <pkg-ref id="${BUNDLE_ID}" version="${VERSION}" onConclusion="none">${APP_NAME}.pkg</pkg-ref>
</installer-gui-script>
DISTRIBUTION_EOF

    print_success "Distribution XML created"
}

# Create welcome and conclusion HTML
create_html_resources() {
    print_info "Creating installer resources..."
    
    cat > "$RESOURCES_DIR/welcome.html" << 'WELCOME_EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            padding: 20px;
            background: linear-gradient(to bottom, #f5f5f5, #ffffff);
        }
        h1 {
            color: #0066cc;
            margin-top: 0;
        }
        ul {
            line-height: 1.8;
        }
    </style>
</head>
<body>
    <h1>Welcome to Don't Be AFK</h1>
    <p>This installer will guide you through the installation of Don't Be AFK.</p>
    <h2>Features:</h2>
    <ul>
        <li>✅ Beautiful macOS native UI</li>
        <li>✅ Menu bar integration</li>
        <li>✅ Automatic click automation</li>
        <li>✅ Customizable coordinates and intervals</li>
        <li>✅ File logging support</li>
    </ul>
    <p><strong>System Requirements:</strong> macOS 13.0 or later</p>
</body>
</html>
WELCOME_EOF

    cat > "$RESOURCES_DIR/conclusion.html" << 'CONCLUSION_EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            padding: 20px;
            background: linear-gradient(to bottom, #f5f5f5, #ffffff);
        }
        h1 {
            color: #0066cc;
            margin-top: 0;
        }
    </style>
</head>
<body>
    <h1>Installation Complete!</h1>
    <p>Don't Be AFK has been successfully installed.</p>
    <h2>Next Steps:</h2>
    <ol>
        <li>Open <strong>Applications</strong> folder</li>
        <li>Launch <strong>Don't Be AFK.app</strong></li>
        <li>Grant accessibility permissions when prompted</li>
        <li>Configure your settings and start the automation</li>
    </ol>
    <p><strong>Note:</strong> You may need to grant accessibility permissions in:<br>
    System Settings → Privacy & Security → Accessibility</p>
</body>
</html>
CONCLUSION_EOF

    print_success "HTML resources created"
}

# Build the component package
build_component_package() {
    print_info "Building component package..."
    
    pkgbuild --root "$BUILD_DIR/Build/Products/Release" \
             --identifier "${BUNDLE_ID}" \
             --version "${VERSION}" \
             --install-location "/Applications" \
             --scripts "$SCRIPTS_DIR" \
             "${PKG_DIR}/${APP_NAME}.pkg"
    
    if [ ! -f "${PKG_DIR}/${APP_NAME}.pkg" ]; then
        print_error "Failed to create component package"
        exit 1
    fi
    
    print_success "Component package created"
}

# Build the product archive (installer)
build_product_archive() {
    print_info "Building product archive..."
    
    productbuild --distribution "$PKG_DIR/distribution.xml" \
                 --resources "$RESOURCES_DIR" \
                 --package-path "$PKG_DIR" \
                 "${PROJECT_ROOT}/${INSTALLER_NAME}-${VERSION}.pkg"
    
    if [ ! -f "${PROJECT_ROOT}/${INSTALLER_NAME}-${VERSION}.pkg" ]; then
        print_error "Failed to create product archive"
        exit 1
    fi
    
    print_success "Product archive created: ${INSTALLER_NAME}-${VERSION}.pkg"
}

# Create DMG (optional)
create_dmg() {
    if ! command -v create-dmg &> /dev/null; then
        print_warning "create-dmg not found. Skipping DMG creation."
        print_info "Install with: brew install create-dmg"
        return
    fi
    
    print_info "Creating DMG..."
    
    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR"
    
    # Copy app to DMG directory
    cp -R "$APP_PATH" "$DMG_DIR/"
    
    # Create DMG
    create-dmg \
        --volname "Don't Be AFK" \
        --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" 2>/dev/null || true \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 200 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 450 200 \
        "${PROJECT_ROOT}/${INSTALLER_NAME}-${VERSION}.dmg" \
        "$DMG_DIR"
    
    if [ -f "${PROJECT_ROOT}/${INSTALLER_NAME}-${VERSION}.dmg" ]; then
        print_success "DMG created: ${INSTALLER_NAME}-${VERSION}.dmg"
    else
        print_warning "DMG creation failed, but PKG installer is available"
    fi
}

# Main execution
main() {
    print_header
    
    check_prerequisites
    build_app
    create_package_structure
    create_postinstall_script
    create_distribution_xml
    create_html_resources
    build_component_package
    build_product_archive
    
    echo ""
    print_success "Installer creation complete!"
    echo ""
    echo "Installer package: ${INSTALLER_NAME}-${VERSION}.pkg"
    echo ""
    echo "To install:"
    echo "  open ${INSTALLER_NAME}-${VERSION}.pkg"
    echo ""
    
    # Optionally create DMG
    read -p "Create DMG disk image? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_dmg
    fi
    
    echo ""
    print_success "All done! 🎉"
}

# Run main function
main "$@"
