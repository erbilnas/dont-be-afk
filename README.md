# Don't Be AFK

A simple bash script that automatically clicks at custom coordinates with a custom interval using cliclick to prevent your system from going idle or AFK.

## Requirements

- macOS (cliclick is macOS-specific)
- Homebrew (for automatic installation)

## Installation & Usage

1. **Clone or download this repository**
2. **Make the script executable:**
   ```bash
   chmod +x dont-be-afk.sh
   ```
3. **Run the script:**
   ```bash
   ./dont-be-afk.sh
   ```

The script will automatically:

- ✅ Check if cliclick is installed
- 🔧 Offer to install cliclick via Homebrew if not found
- 📍 Prompt you to set custom click coordinates
- ⏰ Prompt you to set custom click interval
- 🖱️ Start clicking at your specified coordinates with your specified interval
- 📝 Log each click with timestamp
- ⏹️ Run continuously until stopped with `Ctrl+C`

## What it does

- Prompts you to set custom click coordinates (default: 500, 300)
- Prompts you to set custom click interval (default: 10 minutes)
- Clicks at your specified coordinates with your specified interval
- Displays timestamp for each click
- Runs continuously until stopped with `Ctrl+C`
- Prevents your system from going idle/AFK

## Permissions

You may need to grant accessibility permissions to your terminal app:

1. Go to **System Preferences** → **Security & Privacy** → **Accessibility**
2. Add your terminal app (Terminal, iTerm2, etc.) to the allowed list

## Usage

When you run the script, it will prompt you for:

1. **Click Coordinates:**

   - X coordinate (default: 500)
   - Y coordinate (default: 300)
   - Press Enter to use defaults

2. **Click Interval:**
   - Interval in seconds (default: 600 = 10 minutes)
   - Examples: 300 (5 min), 600 (10 min), 900 (15 min), 1800 (30 min)
   - Press Enter to use default

The script includes input validation to ensure you enter valid positive numbers.

## License

Open source - feel free to modify and use as needed.
