#!/bin/bash

# Build script for macOS UI app

set -e

echo "🔨 Building Don't Be AFK macOS App..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build
rm -rf DontBeAFK.app

# Build the app
echo "📦 Building app..."
xcodebuild -project DontBeAFK.xcodeproj \
           -scheme DontBeAFK \
           -configuration Release \
           -derivedDataPath ./build \
           clean build

# Copy app to project root
if [ -d "./build/Build/Products/Release/DontBeAFK.app" ]; then
    echo "📋 Copying app to project root..."
    cp -R ./build/Build/Products/Release/DontBeAFK.app .
    echo "✅ Build complete! App is available at: DontBeAFK.app"
    echo ""
    echo "To run the app:"
    echo "  open DontBeAFK.app"
    echo ""
    echo "To install to Applications:"
    echo "  cp -R DontBeAFK.app /Applications/"
else
    echo "❌ Build failed - app not found in expected location"
    exit 1
fi
