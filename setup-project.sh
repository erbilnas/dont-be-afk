#!/bin/bash

# Script to help set up the Xcode project

set -e

echo "🔧 Setting up Xcode project for Don't Be AFK"
echo ""

# Check if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo "✅ Found xcodegen, generating project..."
    xcodegen generate
    echo "✅ Project generated successfully!"
    echo ""
    echo "You can now build with:"
    echo "  xcodebuild -project DontBeAFK.xcodeproj -scheme DontBeAFK -configuration Release build"
    exit 0
fi

# Check if project already exists and is valid
if [ -d "DontBeAFK.xcodeproj" ]; then
    echo "⚠️  Project directory exists. Testing if it's valid..."
    if xcodebuild -project DontBeAFK.xcodeproj -list &> /dev/null; then
        echo "✅ Project appears to be valid!"
        exit 0
    else
        echo "❌ Project file is invalid or corrupted."
        echo ""
        read -p "Delete and recreate? (y/N): " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf DontBeAFK.xcodeproj
        else
            echo "Please fix the project manually or see SETUP_XCODE.md"
            exit 1
        fi
    fi
fi

echo ""
echo "📋 To set up the project, you have two options:"
echo ""
echo "Option 1: Install xcodegen (recommended)"
echo "  brew install xcodegen"
echo "  ./setup-project.sh"
echo ""
echo "Option 2: Create project manually in Xcode"
echo "  See SETUP_XCODE.md for detailed instructions"
echo ""
echo "The manual process takes about 2 minutes:"
echo "  1. Open Xcode"
echo "  2. File → New → Project → macOS → App"
echo "  3. Product Name: DontBeAFK, Swift, SwiftUI"
echo "  4. Save in this directory"
echo "  5. Replace default files with files from DontBeAFK/ directory"
echo ""
