# Don't Be AFK



[macOS](https://www.apple.com/macos/)
[License](LICENSE)
[Swift](https://swift.org/)

A powerful bash script with a beautiful macOS UI that automatically clicks at custom coordinates with a custom interval using cliclick to prevent your macOS system from going idle or AFK.

Perfect for keeping your Mac active during long-running tasks, preventing screen savers, or maintaining online status.

## ✨ Features

- ✅ **macOS Native UI** - Beautiful SwiftUI app with menu bar integration
- ✅ **Configuration Persistence** - Saves your settings automatically
- ✅ **Simple Configuration** - Set intervals in seconds
- ✅ **Background Mode** - Run in the background as a daemon
- ✅ **Status Checking** - Check if an instance is already running
- ✅ **File Logging** - Optional logging to file with timestamps
- ✅ **Screen Validation** - Warns if coordinates are outside screen bounds
- ✅ **Better Error Handling** - Graceful error handling and cleanup
- ✅ **Command-Line Interface** - Use via CLI or interactive mode
- ✅ **Multiple Instances Prevention** - Prevents running multiple instances simultaneously

## Requirements

- macOS 13.0 or later (for the UI app)
- Xcode 14.0 or later (for building the UI app)
- Homebrew (for automatic installation, optional)
- cliclick (installed automatically via installer)

## Installation & Usage

> **📖 Quick Start:** See [docs/getting-started/QUICK_INSTALL.md](docs/getting-started/QUICK_INSTALL.md) for a simple installation guide

### Quick Start - Download from GitHub Releases

**Option 1: macOS App with UI (PKG Installer) - Recommended**

1. Go to [Releases](https://github.com/YOUR_USERNAME/dont-be-afk/releases)
2. Download `DontBeAFK-Installer-1.0.pkg`
3. Double-click to install
4. Open from Applications folder
5. Grant accessibility permissions when prompted

**Option 2: Command Line Version (CLI)**

1. Go to [Releases](https://github.com/YOUR_USERNAME/dont-be-afk/releases)
2. Download `dont-be-afk-cli-macos-1.0.0.tar.gz`
3. Extract: `tar -xzf dont-be-afk-cli-macos-1.0.0.tar.gz`
4. Install: `cd dont-be-afk-cli && ./install.sh`
5. Use: `dont-be-afk`

### Build from Source

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/dont-be-afk.git
cd dont-be-afk

# Run the CLI installer (installs dependencies and makes scripts executable)
./cli/install.sh

# Start using it!
dont-be-afk
```

### Installation Methods

**Option 1: Automated Installer (Recommended)**

```bash
./cli/install.sh
```

The installer automatically:

- ✅ Checks and installs Homebrew (if needed)
- ✅ Installs cliclick dependency
- ✅ Makes all scripts executable
- ✅ Optionally installs to `/usr/local/bin` for global access

**Option 2: Manual Installation**
See [docs/getting-started/INSTALL.md](docs/getting-started/INSTALL.md) for step-by-step manual installation instructions.

After installation, you can run `dont-be-afk` from anywhere!

### macOS UI App (Recommended)

The project includes a native macOS SwiftUI app for easy control:

#### Option A: Install from GitHub Releases (Easiest)

1. **Download the installer:**
  - Go to [Releases](https://github.com/YOUR_USERNAME/dont-be-afk/releases)
  - Download `DontBeAFK-Installer-1.0.pkg`
2. **Install:**
  - Double-click the `.pkg` file
  - Follow the installer wizard
  - Enter your admin password when prompted
  - The app will be installed to `/Applications`

#### Option B: Build from Source

1. **Open the project in Xcode:**
  ```bash
   open app/DontBeAFK.xcodeproj
  ```
2. **Build and run:**
  - Press `Cmd+R` or click the Run button in Xcode
  - The app will appear in your menu bar with a cursor icon
3. **Or build from command line:**
  ```bash
   ./scripts/build/build-app.sh
  ```

#### Option C: Create Installer Package

To create your own installer package:

```bash
./scripts/release/create-installer.sh
```

This creates a `.pkg` installer and optionally a `.dmg` disk image. See [docs/release/INSTALLER.md](docs/release/INSTALLER.md) for details.

#### Using the UI:

- Click the menu bar icon to see quick status and controls
- Click "Open Settings" to access the full control panel
- Configure coordinates, interval, and logging preferences
- Start/stop the automation with a single click
- View logs directly from the app

The UI app provides:

- 🎯 **Visual Status Indicator** - See at a glance if automation is running
- ⚙️ **Easy Configuration** - Set coordinates and interval with a friendly interface
- 📊 **Log Viewer** - View logs without opening terminal
- 🚀 **Quick Start/Stop** - Control automation from menu bar or main window
- 💾 **Auto-save Settings** - Your preferences are saved automatically

### Manual Installation

1. **Clone or download this repository**
2. **Make the script executable:**
  ```bash
   chmod +x cli/bin/dont-be-afk
  ```
3. **Install dependencies:**
  ```bash
   brew install cliclick
  ```
4. **Run the script:**
  ```bash
   ./cli/bin/dont-be-afk
  ```

## Usage Modes

### Interactive Mode (Default)

Simply run the script without arguments:

```bash
./dont-be-afk.sh
```

The script will:

- ✅ Check if cliclick is installed
- 🔧 Offer to install cliclick via Homebrew if not found
- 📍 Prompt you to set custom click coordinates (or use saved ones)
- ⏰ Prompt you to set custom click interval (or use saved ones)
- 🖱️ Start clicking at your specified coordinates with your specified interval
- 📝 Log each click with timestamp
- ⏹️ Run continuously until stopped with `Ctrl+C`

### Command-Line Mode

Start with specific settings:

```bash
./dont-be-afk.sh start -x 100 -y 200 -i 300
```

Start in background mode with logging:

```bash
./dont-be-afk.sh start --background --log
```

### Commands

- `start` - Start the automation (default command)
- `stop` - Stop a running instance
- `status` - Check if an instance is running
- `help` - Show help message

### Options

- `-x, --x-coord NUM` - X coordinate (default: 500)
- `-y, --y-coord NUM` - Y coordinate (default: 300)
- `-i, --interval SECONDS` - Interval in seconds (default: 600)
- `-b, --background` - Run in background mode
- `-l, --log` - Enable logging to file (`~/.dont-be-afk.log`)
- `-c, --config` - Show current configuration

## Examples

```bash
# Interactive mode (recommended for first-time use)
./dont-be-afk.sh

# Start with specific coordinates and interval
./dont-be-afk.sh start -x 100 -y 200 -i 300

# Start in background with logging
./dont-be-afk.sh start --background --log

# Start with 30-minute interval (1800 seconds)
./dont-be-afk.sh start -i 1800

# Check if instance is running
./dont-be-afk.sh status

# Stop running instance
./dont-be-afk.sh stop

# View current configuration
./dont-be-afk.sh --config
```

## Interval Format

Intervals are specified in seconds only. Examples:

- `300` = 5 minutes
- `600` = 10 minutes (default)
- `1800` = 30 minutes
- `3600` = 1 hour

## Configuration

The script automatically saves your configuration to `~/.dont-be-afk-config`. This includes:

- Click coordinates (X, Y)
- Click interval
- Logging preference

On subsequent runs, the script will offer to use your saved settings, making it faster to start.

## Files Created

- `~/.dont-be-afk-config` - Configuration file (coordinates, interval, etc.)
- `~/.dont-be-afk.pid` - Process ID file (created when running, removed on exit)
- `~/.dont-be-afk.log` - Log file (only if logging is enabled)

## Permissions

You may need to grant accessibility permissions to your terminal app:

1. Go to **System Preferences** → **Security & Privacy** → **Accessibility**
2. Add your terminal app (Terminal, iTerm2, etc.) to the allowed list

Without these permissions, the script will fail to click and log errors.

## Background Mode

When running in background mode:

```bash
./dont-be-afk.sh start --background
```

- The script runs as a background process
- You can close your terminal without stopping it
- Use `./dont-be-afk.sh stop` to stop it
- Use `./dont-be-afk.sh status` to check if it's running

## Logging

Enable file logging to track all clicks:

```bash
./dont-be-afk.sh start --log
```

Logs are written to `~/.dont-be-afk.log` with timestamps:

```
[2026-01-26 10:30:45] 🚀 Starting automation
[2026-01-26 10:30:45] 📍 Coordinates: (500, 300)
[2026-01-26 10:30:45] ⏰ Interval: 600 seconds
[2026-01-26 10:40:45] ✅ Click #1 at (500, 300)
[2026-01-26 10:50:45] ✅ Click #2 at (500, 300)
```

## Safety Features

- **Screen Bounds Validation**: Warns if coordinates are outside screen resolution
- **Multiple Instance Prevention**: Prevents running multiple instances simultaneously
- **Graceful Shutdown**: Proper cleanup on exit (Ctrl+C)
- **Error Handling**: Handles cliclick failures and permission issues gracefully

## Troubleshooting

### Script won't click

1. Check accessibility permissions (see Permissions section above)
2. Verify coordinates are within screen bounds
3. Check logs: `cat ~/.dont-be-afk.log`

### Can't stop background instance

```bash
./dont-be-afk.sh stop
```

If that doesn't work, find and kill the process:

```bash
ps aux | grep dont-be-afk
kill <PID>
```

### Configuration issues

Delete the config file to reset:

```bash
rm ~/.dont-be-afk-config
```

## Project Structure

```
dont-be-afk/
├── cli/                          # Command Line Interface
│   ├── bin/
│   │   └── dont-be-afk           # Main executable script
│   ├── lib/                      # Script modules
│   │   ├── click.sh              # Click automation
│   │   ├── config.sh             # Configuration management
│   │   ├── input.sh              # User input handling
│   │   ├── install.sh            # Installation helpers
│   │   ├── logger.sh             # Logging functionality
│   │   ├── process.sh            # Process management
│   │   ├── source-all.sh         # Module loader
│   │   ├── utils.sh              # Utility functions
│   │   └── validation.sh         # Input validation
│   └── install.sh                # CLI installer
│
├── app/                          # macOS UI Application
│   ├── DontBeAFK/                # Swift source files
│   │   ├── App/                  # App entry point
│   │   ├── Assets.xcassets/      # App icons and assets
│   │   ├── Components/           # Reusable UI components
│   │   ├── Controllers/          # Script controller
│   │   ├── Overlay/              # Overlay window
│   │   └── Views/                # SwiftUI views
│   ├── DontBeAFK.xcodeproj/      # Xcode project
│   └── project.yml               # xcodegen configuration
│
├── scripts/                      # Build & release scripts
│   ├── build/
│   │   ├── build-app.sh          # Build macOS app
│   │   └── setup-project.sh      # Setup Xcode project
│   ├── release/
│   │   ├── create-dmg.sh         # Create .dmg disk image
│   │   ├── create-installer.sh   # Create .pkg installer
│   │   ├── create-release.sh     # Create release files
│   │   └── package-cli.sh        # Package CLI for release
│   └── pkg/                      # Installer resources
│       ├── distribution.xml
│       ├── resources/
│       └── scripts/
│
├── docs/                         # Documentation
│   ├── getting-started/
│   │   ├── INSTALL.md            # Installation guide
│   │   └── QUICK_INSTALL.md      # Quick start guide
│   ├── development/
│   │   ├── BUILD_UI.md           # Building the UI app
│   │   ├── CONTRIBUTING.md       # Contributing guidelines
│   │   ├── SECURITY.md           # Security policy
│   │   └── SETUP_XCODE.md        # Xcode setup guide
│   └── release/
│       ├── GITHUB_RELEASE.md     # GitHub release guide
│       ├── INSTALLER.md          # Installer creation guide
│       └── RELEASE_CHECKLIST.md  # Release checklist
│
├── .github/                      # GitHub configuration
│   ├── ISSUE_TEMPLATE/
│   ├── workflows/
│   └── pull_request_template.md
│
├── README.md
├── LICENSE
└── CHANGELOG.md
```

## Contributing

Contributions are welcome! Please see [docs/development/CONTRIBUTING.md](docs/development/CONTRIBUTING.md) for guidelines.

Before contributing:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security

Please see [docs/development/SECURITY.md](docs/development/SECURITY.md) for information about security vulnerabilities and reporting.

## Author

**Erbil Nas** - Creator and maintainer

## License

This project is **free and open source** software, licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

You are free to use, modify, and distribute this software for any purpose, including commercial use.

## Acknowledgments

- Built with [cliclick](https://www.bluem.net/en/projects/cliclick/) for macOS automation
- Uses SwiftUI for the native macOS interface

## Star History

If you find this project useful, please consider giving it a ⭐ on GitHub!