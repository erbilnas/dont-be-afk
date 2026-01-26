#!/bin/bash

# Package command line version for macOS distribution

set -e

VERSION="${1:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="${PROJECT_ROOT}/release"
CLI_DIR="${PROJECT_ROOT}/cli"
ARCHIVE_NAME="dont-be-afk-cli-macos-${VERSION}"

print_info() {
    echo "ℹ $1"
}

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is for macOS only"
    exit 1
fi

print_info "Packaging macOS command line version ${VERSION}..."

# Create release directory
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Create temporary directory for packaging
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy files to temp directory
mkdir -p "$TEMP_DIR/dont-be-afk-cli"
cp -R "$CLI_DIR/bin/" "$TEMP_DIR/dont-be-afk-cli/"
cp -R "$CLI_DIR/lib/" "$TEMP_DIR/dont-be-afk-cli/"
cp "$PROJECT_ROOT/README.md" "$TEMP_DIR/dont-be-afk-cli/"
cp "$PROJECT_ROOT/LICENSE" "$TEMP_DIR/dont-be-afk-cli/"

# Create install script
cat > "$TEMP_DIR/dont-be-afk-cli/install.sh" << 'INSTALL_EOF'
#!/bin/bash
# Quick install script for command line version

set -e

INSTALL_DIR="/usr/local/bin"

echo "Installing Don't Be AFK command line tool..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script is for macOS only"
    exit 1
fi

# Check for cliclick
if ! command -v cliclick &> /dev/null; then
    echo "cliclick not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    brew install cliclick
fi

# Copy script
sudo cp bin/dont-be-afk "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/dont-be-afk"

echo "✅ Installation complete!"
echo ""
echo "Usage:"
echo "  dont-be-afk"
echo "  dont-be-afk start -x 100 -y 200 -i 5m"
echo "  dont-be-afk status"
echo "  dont-be-afk stop"
INSTALL_EOF

chmod +x "$TEMP_DIR/dont-be-afk-cli/install.sh"

# Create README for CLI package
cat > "$TEMP_DIR/dont-be-afk-cli/CLI_README.md" << 'README_EOF'
# Don't Be AFK - macOS Command Line Version

## Requirements

- macOS 13.0 or later
- Homebrew (for installing cliclick dependency)

## Installation

### Quick Install

```bash
./install.sh
```

This will:
- Install cliclick dependency (via Homebrew)
- Copy the script to `/usr/local/bin`
- Make it available system-wide

### Manual Installation

1. **Install cliclick:**
   ```bash
   brew install cliclick
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x bin/dont-be-afk
   chmod +x lib/*.sh
   ```

3. **Add to PATH (optional):**
   ```bash
   export PATH="$PATH:$(pwd)/bin"
   ```

## Usage

### Interactive Mode
```bash
dont-be-afk
```

### Command Line Mode
```bash
# Start with specific coordinates and interval
dont-be-afk start -x 100 -y 200 -i 5m

# Start in background with logging
dont-be-afk start --background --log

# Check status
dont-be-afk status

# Stop running instance
dont-be-afk stop
```

## Permissions

You need to grant accessibility permissions:
1. System Settings → Privacy & Security → Accessibility
2. Add your terminal app (Terminal, iTerm2, etc.) to the allowed list

## More Information

See the main README.md for complete documentation.
README_EOF

# Create tarball (macOS standard)
cd "$TEMP_DIR"
tar -czf "${RELEASE_DIR}/${ARCHIVE_NAME}.tar.gz" dont-be-afk-cli

print_success "Package created:"
print_info "  ${RELEASE_DIR}/${ARCHIVE_NAME}.tar.gz"
echo ""
print_info "Ready for GitHub release!"
