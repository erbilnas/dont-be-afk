# Setting Up Xcode Project

The Xcode project file needs to be created properly. Here's the easiest way:

## Option 1: Create Project in Xcode (Recommended)

1. **Open Xcode**

2. **Create New Project:**
   - File → New → Project (or Cmd+Shift+N)
   - Choose **macOS** → **App**
   - Click **Next**

3. **Configure Project:**
   - Product Name: `DontBeAFK`
   - Team: (your team or None)
   - Organization Identifier: `com.dontbeafk`
   - Bundle Identifier: `com.dontbeafk.app` (will auto-fill)
   - Language: **Swift**
   - Interface: **SwiftUI**
   - Storage: **None**
   - Click **Next**

4. **Save Location:**
   - Navigate to the cloned repository directory
   - **IMPORTANT:** Uncheck "Create Git repository" if you already have one
   - Click **Create**

5. **Replace Default Files:**
   - Delete the default `DontBeAFKApp.swift` file Xcode created
   - Delete the default `ContentView.swift` file if it exists
   - In Xcode, right-click the `DontBeAFK` folder → **Add Files to "DontBeAFK"...**
   - Select all files from the `DontBeAFK/` directory:
     - `DontBeAFKApp.swift`
     - `ScriptController.swift`
     - `MainView.swift`
     - `MenuBarView.swift`
     - `Info.plist`
     - `Assets.xcassets` (folder)
   - Make sure "Copy items if needed" is **unchecked** (files already exist)
   - Make sure "Create groups" is selected
   - Click **Add**

6. **Build Settings:**
   - Select the project in the navigator
   - Select the **DontBeAFK** target
   - Go to **Build Settings** tab
   - Search for "Info.plist File"
   - Set it to: `DontBeAFK/Info.plist`
   - Search for "Generate Info.plist File"
   - Set it to **NO**

7. **Build and Run:**
   - Press `Cmd+B` to build
   - Press `Cmd+R` to run

## Option 2: Use xcodegen (If Installed)

If you have `xcodegen` installed via Homebrew:

```bash
brew install xcodegen
xcodegen generate
```

This will use the `project.yml` file to generate the project.

## Option 3: Manual Project File Fix

If you want to fix the existing project file manually, the issue is likely with missing or incorrect references. The safest approach is Option 1 above.

## After Setup

Once the project is created properly, you can:

```bash
# Build from command line
xcodebuild -project DontBeAFK.xcodeproj \
           -scheme DontBeAFK \
           -configuration Release \
           clean build

# Or use the build script
./scripts/build-ui.sh
```
