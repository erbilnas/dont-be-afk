# Don't Be AFK

A powerful bash script that automatically clicks at custom coordinates with a custom interval using cliclick to prevent your macOS system from going idle or AFK.

## ✨ Features

- ✅ **Configuration Persistence** - Saves your settings automatically
- ✅ **Human-Readable Intervals** - Use formats like `5m`, `10m`, `1h` instead of just seconds
- ✅ **Background Mode** - Run in the background as a daemon
- ✅ **Status Checking** - Check if an instance is already running
- ✅ **File Logging** - Optional logging to file with timestamps
- ✅ **Screen Validation** - Warns if coordinates are outside screen bounds
- ✅ **Better Error Handling** - Graceful error handling and cleanup
- ✅ **Command-Line Interface** - Use via CLI or interactive mode
- ✅ **Multiple Instances Prevention** - Prevents running multiple instances simultaneously

## Requirements

- macOS (cliclick is macOS-specific)
- Homebrew (for automatic installation, optional)

## Installation & Usage

### Easy Installer (Recommended)

The easiest way to install Don't Be AFK on macOS:

```bash
# Clone or download this repository
git clone <repository-url>
cd dont-be-afk

# Run the installer
./install.sh
```

The installer will:
- ✅ Check and install Homebrew (if needed)
- ✅ Install cliclick dependency
- ✅ Make all scripts executable
- ✅ Optionally install to `/usr/local/bin` for global access

After installation, you can run `dont-be-afk` from anywhere!

### Manual Installation

1. **Clone or download this repository**
2. **Make the script executable:**
   ```bash
   chmod +x bin/dont-be-afk
   ```
3. **Install dependencies:**
   ```bash
   brew install cliclick
   ```
4. **Run the script:**
   ```bash
   ./bin/dont-be-afk
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
./dont-be-afk.sh start -x 100 -y 200 -i 5m
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
- `-i, --interval TIME` - Interval in seconds or format like `5m`, `10m`, `1h` (default: 600)
- `-b, --background` - Run in background mode
- `-l, --log` - Enable logging to file (`~/.dont-be-afk.log`)
- `-c, --config` - Show current configuration

## Examples

```bash
# Interactive mode (recommended for first-time use)
./dont-be-afk.sh

# Start with specific coordinates and interval
./dont-be-afk.sh start -x 100 -y 200 -i 5m

# Start in background with logging
./dont-be-afk.sh start --background --log

# Start with 30-minute interval
./dont-be-afk.sh start -i 30m

# Check if instance is running
./dont-be-afk.sh status

# Stop running instance
./dont-be-afk.sh stop

# View current configuration
./dont-be-afk.sh --config
```

## Interval Formats

You can specify intervals in multiple formats:

- **Seconds**: `300`, `600`, `1800`
- **Minutes**: `5m`, `10m`, `30m`
- **Hours**: `1h`, `2h`
- **Days**: `1d` (not recommended for this use case!)

Examples:

- `5m` = 5 minutes = 300 seconds
- `10m` = 10 minutes = 600 seconds
- `1h` = 1 hour = 3600 seconds
- `30m` = 30 minutes = 1800 seconds

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
[2026-01-26 10:30:45] ⏰ Interval: 10m (600 seconds)
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

## License

Open source - feel free to modify and use as needed.
