#!/bin/bash

# Installation Check Module
# Handles dependency checks and installation

# Function to check if cliclick is installed
check_cliclick() {
    if ! command -v cliclick &> /dev/null; then
        echo "❌ cliclick is not installed."
        echo ""
        echo "This script requires cliclick to automate mouse clicks."
        echo "Would you like to install it using Homebrew? (y/n)"
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "Installing cliclick via Homebrew..."
            
            # Check if Homebrew is installed
            if ! command -v brew &> /dev/null; then
                echo "❌ Homebrew is not installed. Please install Homebrew first:"
                echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            
            # Install cliclick
            if brew install cliclick; then
                echo "✅ cliclick installed successfully!"
            else
                echo "❌ Failed to install cliclick. Please install it manually:"
                echo "   brew install cliclick"
                exit 1
            fi
        else
            echo "Please install cliclick manually:"
            echo "   brew install cliclick"
            exit 1
        fi
    fi
}
