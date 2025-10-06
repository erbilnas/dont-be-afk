#!/bin/bash

# Script to run cliclick m:500,300 every 10 minutes
# This will click at coordinates (500, 300) every 10 minutes

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
    else
        echo "✅ cliclick is installed and ready to use"
    fi
}

# Function to get user input for coordinates
get_coordinates() {
    echo ""
    echo "📍 Set click coordinates"
    echo "Current default: (500, 300)"
    echo ""
    
    while true; do
        read -p "Enter X coordinate (or press Enter for default 500): " x_coord
        if [[ -z "$x_coord" ]]; then
            x_coord=500
        elif [[ ! "$x_coord" =~ ^[0-9]+$ ]] || [[ "$x_coord" -lt 0 ]]; then
            echo "❌ Please enter a valid positive number for X coordinate"
            continue
        fi
        break
    done
    
    while true; do
        read -p "Enter Y coordinate (or press Enter for default 300): " y_coord
        if [[ -z "$y_coord" ]]; then
            y_coord=300
        elif [[ ! "$y_coord" =~ ^[0-9]+$ ]] || [[ "$y_coord" -lt 0 ]]; then
            echo "❌ Please enter a valid positive number for Y coordinate"
            continue
        fi
        break
    done
    
    echo "✅ Coordinates set to: ($x_coord, $y_coord)"
}

# Function to get user input for interval
get_interval() {
    echo ""
    echo "⏰ Set click interval"
    echo "Current default: 10 minutes (600 seconds)"
    echo ""
    echo "Examples:"
    echo "  - 5 minutes: 300"
    echo "  - 10 minutes: 600"
    echo "  - 15 minutes: 900"
    echo "  - 30 minutes: 1800"
    echo ""
    
    while true; do
        read -p "Enter interval in seconds (or press Enter for default 600): " interval
        if [[ -z "$interval" ]]; then
            interval=600
        elif [[ ! "$interval" =~ ^[0-9]+$ ]] || [[ "$interval" -lt 1 ]]; then
            echo "❌ Please enter a valid positive number for interval (minimum 1 second)"
            continue
        fi
        break
    done
    
    # Convert to minutes for display
    minutes=$((interval / 60))
    if [[ $minutes -eq 0 ]]; then
        echo "✅ Interval set to: $interval seconds"
    else
        echo "✅ Interval set to: $interval seconds ($minutes minutes)"
    fi
}

# Check cliclick installation
check_cliclick

# Get user preferences
get_coordinates
get_interval

echo ""
echo "🚀 Starting cliclick automation"
echo "📍 Clicking at coordinates ($x_coord, $y_coord)"
echo "⏰ Every $interval seconds"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    echo "$(date): Clicking at coordinates ($x_coord, $y_coord)"
    cliclick m:$x_coord,$y_coord
    sleep $interval
done