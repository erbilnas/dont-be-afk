# Creating macOS Installer

This guide explains how to create a macOS installer package (.pkg) and disk image (.dmg) for Don't Be AFK.

## Prerequisites

- macOS 13.0 or later
- Xcode 14.0 or later (includes Command Line Tools)
- The app must be built first (see [BUILD_UI.md](BUILD_UI.md))

## Quick Start

### Option 1: Create PKG Installer (Recommended)

```bash
./scripts/create-installer.sh
```

This will:
1. Build the app in Release configuration
2. Create a `.pkg` installer package
3. Optionally create a `.dmg` disk image

The installer will be created as: `DontBeAFK-Installer-1.0.pkg`

### Option 2: Create DMG Only

If you already have the built app:

```bash
./scripts/create-dmg.sh
```

This creates a `.dmg` disk image: `DontBeAFK-1.0.dmg`

## What Gets Installed

The installer places the app in `/Applications/DontBeAFK.app` and sets proper permissions.

## Installing the Package

Users can install the app by:

1. **Double-clicking the `.pkg` file**
   - Follow the installer wizard
   - Enter admin password when prompted
   - The app will be installed to `/Applications`

2. **Or using command line:**
   ```bash
   sudo installer -pkg DontBeAFK-Installer-1.0.pkg -target /
   ```

## Installing from DMG

Users can install from DMG by:

1. **Double-clicking the `.dmg` file**
2. **Dragging the app to Applications folder**
3. **Ejecting the DMG**

## Code Signing (Optional)

To sign the installer and app for distribution:

1. **Get a Developer ID certificate** from Apple Developer Program
2. **Update the build script** to include signing:

```bash
# In create-installer.sh, modify build_app():
xcodebuild -project "${SCRIPT_DIR}/${APP_NAME}.xcodeproj" \
           -scheme "${APP_NAME}" \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           clean build \
           CODE_SIGN_IDENTITY="Developer ID Application: Your Name" \
           CODE_SIGN_STYLE=Manual
```

3. **Sign the package:**
```bash
productsign --sign "Developer ID Installer: Your Name" \
            DontBeAFK-Installer-1.0.pkg \
            DontBeAFK-Installer-1.0-signed.pkg
```

## Notarization (Optional)

For distribution outside the Mac App Store, you should notarize the app:

```bash
# Notarize the app
xcrun notarytool submit DontBeAFK.app \
    --apple-id your@email.com \
    --team-id YOUR_TEAM_ID \
    --password YOUR_APP_SPECIFIC_PASSWORD \
    --wait

# Staple the notarization
xcrun stapler staple DontBeAFK.app
```

## Troubleshooting

### "pkgbuild: command not found"

Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### "Build failed"

Make sure:
- Xcode is properly installed
- The Xcode project builds successfully
- You have write permissions in the project directory

### "Permission denied"

Make sure the scripts are executable:
```bash
chmod +x create-installer.sh
chmod +x create-dmg.sh
```

### Installer doesn't work

- Check that the app builds successfully first
- Verify the bundle identifier matches: `com.dontbeafk.app`
- Ensure macOS 13.0+ is the minimum deployment target

## Distribution

After creating the installer:

1. **Test the installer** on a clean macOS system
2. **Verify the app works** after installation
3. **Check permissions** are set correctly
4. **Upload** to your distribution platform (GitHub Releases, website, etc.)

## File Structure

After running the installer script:

```
dont-be-afk/
├── DontBeAFK-Installer-1.0.pkg    # Installer package
├── DontBeAFK-1.0.dmg               # Disk image (if created)
├── build/                           # Build artifacts
├── pkg/                             # Package components
└── dmg/                             # DMG temp files
```

## Advanced: Custom Installer Branding

To customize the installer appearance, edit:
- `pkg/resources/welcome.html` - Welcome screen
- `pkg/resources/conclusion.html` - Completion screen
- `pkg/distribution.xml` - Installer configuration

Then rebuild the installer.
