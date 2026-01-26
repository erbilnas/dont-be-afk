#!/bin/bash

# Don't Be AFK - Easy Installer for macOS
# This script installs the tool and all dependencies

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this installer script is located
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$INSTALLER_DIR/bin"
LIB_DIR="$INSTALLER_DIR/lib"
SCRIPT_NAME="dont-be-afk"
INSTALL_DIR="/usr/local/bin"

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
    echo -e "${BLUE}  Don't Be AFK - macOS Installer${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This installer is for macOS only."
        exit 1
    fi
}

# Function to check if Homebrew is installed
check_homebrew() {
    if command -v brew &> /dev/null; then
        print_success "Homebrew is already installed"
        return 0
    else
        print_warning "Homebrew is not installed"
        return 1
    fi
}

# Function to install Homebrew
install_homebrew() {
    print_info "Installing Homebrew..."
    echo ""
    
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        print_success "Homebrew installed successfully"
        
        # Add Homebrew to PATH if needed (for Apple Silicon Macs)
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            print_info "Adding Homebrew to PATH..."
            if ! grep -q '/opt/homebrew/bin' ~/.zshrc 2>/dev/null; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi
        return 0
    else
        print_error "Failed to install Homebrew"
        print_info "Please install Homebrew manually:"
        print_info "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
}

# Function to check if cliclick is installed
check_cliclick() {
    if command -v cliclick &> /dev/null; then
        print_success "cliclick is already installed"
        return 0
    else
        print_warning "cliclick is not installed"
        return 1
    fi
}

# Function to install cliclick
install_cliclick() {
    print_info "Installing cliclick via Homebrew..."
    
    if brew install cliclick; then
        print_success "cliclick installed successfully"
        return 0
    else
        print_error "Failed to install cliclick"
        print_info "Please install cliclick manually:"
        print_info "  brew install cliclick"
        exit 1
    fi
}

# Function to make scripts executable
make_executable() {
    print_info "Making scripts executable..."
    
    if [[ -f "$BIN_DIR/$SCRIPT_NAME" ]]; then
        chmod +x "$BIN_DIR/$SCRIPT_NAME"
        print_success "Made $SCRIPT_NAME executable"
    else
        print_error "Script not found: $BIN_DIR/$SCRIPT_NAME"
        exit 1
    fi
    
    # Make all library scripts executable too
    if [[ -d "$LIB_DIR" ]]; then
        chmod +x "$LIB_DIR"/*.sh 2>/dev/null || true
        print_success "Made library scripts executable"
    fi
}

# Function to install script to PATH
install_to_path() {
    print_info "Installing to $INSTALL_DIR..."
    
    # Check if we can write to install directory without sudo
    local needs_sudo=false
    if [[ ! -w "$INSTALL_DIR" ]] && [[ ! -d "$INSTALL_DIR" ]]; then
        needs_sudo=true
    elif [[ -d "$INSTALL_DIR" ]] && [[ ! -w "$INSTALL_DIR" ]]; then
        needs_sudo=true
    fi
    
    # Create install directory if it doesn't exist
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_info "Creating $INSTALL_DIR..."
        if [[ "$needs_sudo" == true ]]; then
            if sudo mkdir -p "$INSTALL_DIR"; then
                print_success "Created $INSTALL_DIR"
            else
                print_error "Failed to create $INSTALL_DIR (permission denied)"
                print_info "You can install to a local directory instead"
                return 1
            fi
        else
            mkdir -p "$INSTALL_DIR"
        fi
    fi
    
    # Check if script already exists
    if [[ -f "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
        print_warning "Script already exists at $INSTALL_DIR/$SCRIPT_NAME"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping installation to PATH"
            return 0
        fi
    fi
    
    # Create wrapper script that preserves the lib directory structure
    local wrapper_content=$(cat <<EOF
#!/bin/bash
# Wrapper script for dont-be-afk
# Installed by installer.sh

SCRIPT_DIR="$INSTALLER_DIR"
exec "\$SCRIPT_DIR/bin/$SCRIPT_NAME" "\$@"
EOF
)
    
    if [[ "$needs_sudo" == true ]]; then
        if echo "$wrapper_content" | sudo tee "$INSTALL_DIR/$SCRIPT_NAME" > /dev/null; then
            sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
            print_success "Installed to $INSTALL_DIR/$SCRIPT_NAME"
            print_info "You can now run 'dont-be-afk' from anywhere!"
            return 0
        else
            print_error "Failed to install to $INSTALL_DIR (permission denied)"
            print_info "You can run the script directly from: $BIN_DIR/$SCRIPT_NAME"
            return 1
        fi
    else
        echo "$wrapper_content" > "$INSTALL_DIR/$SCRIPT_NAME"
        chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
        print_success "Installed to $INSTALL_DIR/$SCRIPT_NAME"
        print_info "You can now run 'dont-be-afk' from anywhere!"
        return 0
    fi
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    local errors=0
    
    # Check if script is executable
    if [[ ! -x "$BIN_DIR/$SCRIPT_NAME" ]]; then
        print_error "Script is not executable"
        errors=$((errors + 1))
    fi
    
    # Check if cliclick is available
    if ! command -v cliclick &> /dev/null; then
        print_error "cliclick is not in PATH"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "Installation verified successfully!"
        return 0
    else
        print_error "Installation verification failed"
        return 1
    fi
}

# Function to show next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete! 🎉${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ -f "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
        print_success "You can now run 'dont-be-afk' from anywhere!"
        echo ""
        echo "Quick start:"
        echo "  $SCRIPT_NAME              # Interactive mode"
        echo "  $SCRIPT_NAME start        # Start automation"
        echo "  $SCRIPT_NAME help         # Show help"
    else
        print_info "To run the script, use:"
        echo "  $BIN_DIR/$SCRIPT_NAME"
        echo ""
        print_info "Or install to PATH by running this installer again"
    fi
    
    echo ""
    print_warning "IMPORTANT: You may need to grant accessibility permissions"
    print_info "1. Go to System Settings → Privacy & Security → Accessibility"
    print_info "2. Add your terminal app (Terminal, iTerm2, etc.)"
    print_info "3. Enable it in the list"
    echo ""
    print_info "For more information, see README.md"
    echo ""
}

# Main installation process
main() {
    print_header
    
    # Check macOS
    check_macos
    
    # Check/Install Homebrew
    if ! check_homebrew; then
        read -p "Install Homebrew? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_error "Homebrew is required to install cliclick"
            exit 1
        fi
        install_homebrew
    fi
    
    # Check/Install cliclick
    if ! check_cliclick; then
        install_cliclick
    fi
    
    # Make scripts executable
    make_executable
    
    # Ask about installing to PATH
    echo ""
    read -p "Install to PATH ($INSTALL_DIR)? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        install_to_path
    else
        print_info "Skipping PATH installation"
        print_info "You can run the script from: $BIN_DIR/$SCRIPT_NAME"
    fi
    
    # Verify installation
    echo ""
    verify_installation
    
    # Show next steps
    show_next_steps
}

# Run main function
main
