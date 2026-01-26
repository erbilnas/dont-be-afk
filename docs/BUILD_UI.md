# Building the macOS UI App

## Prerequisites

- macOS 13.0 or later
- Xcode 14.0 or later
- The bash script must be installed (run `./install.sh` first)

## Setting Up the Project

**IMPORTANT:** If you encounter project file errors, see [SETUP_XCODE.md](SETUP_XCODE.md) for detailed setup instructions.

The easiest way is to create the project in Xcode:
1. Open Xcode → File → New → Project
2. Choose macOS → App
3. Product Name: `DontBeAFK`, Language: Swift, Interface: SwiftUI
4. Save in the project directory
5. Replace default files with the files from `DontBeAFK/` directory

## Building with Xcode

1. **Open the project:**
   ```bash
   open DontBeAFK.xcodeproj
   ```

2. **Select a scheme:**
   - Choose "DontBeAFK" from the scheme dropdown
   - Select "My Mac" as the destination

3. **Build and run:**
   - Press `Cmd+R` or click the Run button
   - The app will launch and appear in your menu bar

## Building from Command Line

```bash
xcodebuild -project DontBeAFK.xcodeproj \
           -scheme DontBeAFK \
           -configuration Release \
           -derivedDataPath ./build

# The app will be in: ./build/Build/Products/Release/DontBeAFK.app
```

## Installing the App

After building, you can:

1. **Copy to Applications:**
   ```bash
   cp -R DontBeAFK.app /Applications/
   ```

2. **Or run directly from build location**

## Troubleshooting

### Script Not Found

If the app can't find the `dont-be-afk` script:

1. Make sure the script is installed: `./install.sh`
2. Or ensure the script is in the same directory structure as the app
3. The app will try to find the script in multiple locations automatically

### Permission Issues

The app needs the same accessibility permissions as the terminal:
1. Go to **System Settings** → **Privacy & Security** → **Accessibility**
2. Add the DontBeAFK app to the allowed list

### Build Errors

If you encounter build errors:
- **Project file errors:** See [SETUP_XCODE.md](SETUP_XCODE.md) for instructions to create the project properly in Xcode
- Make sure you're using Xcode 14.0 or later
- Ensure macOS 13.0+ is installed
- Clean build folder: `Product` → `Clean Build Folder` (Shift+Cmd+K)
- If the project file is corrupted, delete `DontBeAFK.xcodeproj` and recreate it using the instructions in [SETUP_XCODE.md](SETUP_XCODE.md)
