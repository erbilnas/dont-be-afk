# Local Installation Guide

This guide covers **local installation** of Don't Be AFK on your macOS system. For the quickest setup, use the automated installer. For more control, follow the manual installation steps.

## Prerequisites

- macOS (any recent version)
- Terminal access
- Homebrew (will be installed automatically if missing)

## Method 1: Quick Install (Recommended)

The easiest way to install Don't Be AFK locally:

```bash
# 1. Clone or download the repository
git clone https://github.com/YOUR_USERNAME/dont-be-afk.git
cd dont-be-afk

# 2. Run the installer script
./install.sh
```

The installer will:
- ✅ Check for Homebrew and install it if needed
- ✅ Install the `cliclick` dependency via Homebrew
- ✅ Make all scripts executable
- ✅ Optionally install the script to `/usr/local/bin` for global access

After installation, you can use `dont-be-afk` from anywhere in your terminal!

## Method 2: Manual Installation

If you prefer to install manually:

### Step 1: Install Dependencies

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install cliclick
brew install cliclick
```

### Step 2: Make Scripts Executable

```bash
# Navigate to the project directory
cd dont-be-afk

# Make the main script executable
chmod +x bin/dont-be-afk

# Make all library scripts executable
chmod +x lib/*.sh

# Make the installer executable (if you want to use it later)
chmod +x install.sh
```

### Step 3: Test the Installation

```bash
# Run the script from the project directory
./bin/dont-be-afk

# Or add to PATH for global access (optional)
export PATH="$PATH:$(pwd)/bin"
dont-be-afk
```

### Step 4: Install Globally (Optional)

To use `dont-be-afk` from anywhere without specifying the full path:

```bash
# Copy to /usr/local/bin
sudo cp bin/dont-be-afk /usr/local/bin/
sudo chmod +x /usr/local/bin/dont-be-afk

# Verify installation
which dont-be-afk
dont-be-afk --help
```

## Installing the macOS UI App

### Option 1: Build from Xcode (Recommended)

1. **Create the Xcode project:**
   ```bash
   # If you have xcodegen installed
   brew install xcodegen
   xcodegen generate
   
   # OR manually create in Xcode (see docs/SETUP_XCODE.md)
   ```

2. **Open in Xcode:**
   ```bash
   open DontBeAFK.xcodeproj
   ```

3. **Build and run:**
   - Press `Cmd+R` in Xcode
   - The app will appear in your menu bar

### Option 2: Build from Command Line

```bash
# Build the app
./scripts/build-ui.sh

# Run the app
open DontBeAFK.app
```

### Option 3: Use Pre-built Binary (if available)

If a pre-built `.app` bundle is available in releases:

```bash
# Download and extract
# Then drag DontBeAFK.app to /Applications

# Or install via command line
cp -R DontBeAFK.app /Applications/
```

## Post-Installation Setup

### 1. Grant Accessibility Permissions

The script needs accessibility permissions to simulate mouse clicks:

1. Open **System Settings** (or **System Preferences** on older macOS)
2. Go to **Privacy & Security** → **Accessibility**
3. Click the lock icon and enter your password
4. Add your terminal app (Terminal, iTerm2, etc.) to the list
5. If using the UI app, also add `DontBeAFK.app` to the list

### 2. Verify Installation

```bash
# Check if script is accessible
which dont-be-afk

# Check version/help
dont-be-afk --help

# Test run (interactive mode)
dont-be-afk
```

## Local Development Setup

If you want to modify the code:

### For Bash Scripts

```bash
# Make scripts executable
chmod +x bin/dont-be-afk lib/*.sh

# Edit scripts in your preferred editor
code bin/dont-be-afk  # VS Code
vim bin/dont-be-afk   # Vim
```

### For macOS UI App

1. **Install Xcode** from the App Store
2. **Create the project** (see [SETUP_XCODE.md](SETUP_XCODE.md))
3. **Open in Xcode:**
   ```bash
   open DontBeAFK.xcodeproj
   ```
4. **Make changes** and test with `Cmd+R`

## Troubleshooting

### Script Not Found

If `dont-be-afk` command is not found:

```bash
# Check if it's in PATH
echo $PATH

# Add project bin directory to PATH (temporary)
export PATH="$PATH:$(pwd)/bin"

# Or install globally
sudo cp bin/dont-be-afk /usr/local/bin/
```

### Permission Denied

```bash
# Make scripts executable
chmod +x bin/dont-be-afk
chmod +x lib/*.sh
```

### cliclick Not Found

```bash
# Install via Homebrew
brew install cliclick

# Verify installation
which cliclick
cliclick -v
```

### Accessibility Permissions

If clicks aren't working:

1. Check System Settings → Privacy & Security → Accessibility
2. Ensure your terminal/app is enabled
3. Restart the terminal/app after granting permissions
4. Try running the script again

### Xcode Project Issues

If you have issues with the Xcode project:

1. See [SETUP_XCODE.md](SETUP_XCODE.md) for detailed setup instructions
2. Or use xcodegen: `brew install xcodegen && xcodegen generate`

## Uninstallation

To remove Don't Be AFK:

```bash
# Remove global installation
sudo rm /usr/local/bin/dont-be-afk

# Remove configuration files
rm ~/.dont-be-afk-config
rm ~/.dont-be-afk.pid
rm ~/.dont-be-afk.log

# Remove the app (if installed)
rm -rf /Applications/DontBeAFK.app

# Remove Homebrew dependency (optional)
brew uninstall cliclick
```

## Next Steps

After installation:

1. **Read the README** for usage instructions
2. **Try interactive mode:** `dont-be-afk`
3. **Set up the UI app** for easier control
4. **Configure your preferences** (coordinates, interval)

For more information, see:
- [../README.md](../README.md) - Main documentation
- [SETUP_XCODE.md](SETUP_XCODE.md) - UI app setup
- [BUILD_UI.md](BUILD_UI.md) - Building the UI app
