#!/bin/bash

# Create release files for GitHub
# Usage: ./create-release.sh [version]
# Example: ./create-release.sh 1.0.0

set -e

VERSION="${1:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Creating Release v${VERSION}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Build installer
echo -e "${GREEN}Step 1:${NC} Building macOS installer..."
if [ -f "$SCRIPT_DIR/create-installer.sh" ]; then
    "$SCRIPT_DIR/create-installer.sh" "$VERSION"
else
    echo "Error: create-installer.sh not found"
    exit 1
fi

# Step 2: Package CLI
echo ""
echo -e "${GREEN}Step 2:${NC} Packaging command line version..."
if [ -f "$SCRIPT_DIR/package-cli.sh" ]; then
    "$SCRIPT_DIR/package-cli.sh" "$VERSION"
else
    echo "Error: package-cli.sh not found"
    exit 1
fi

# Summary
echo ""
echo -e "${GREEN}✅ Release files created!${NC}"
echo ""
echo "Files ready for GitHub release:"
echo "  📦 DontBeAFK-Installer-${VERSION}.pkg"
echo "  📦 release/dont-be-afk-cli-macos-${VERSION}.tar.gz"
echo ""
echo "Next steps:"
echo "  1. Create a GitHub release:"
echo "     git tag v${VERSION}"
echo "     git push origin v${VERSION}"
echo ""
echo "  2. Or manually upload files to GitHub Releases"
echo ""
echo "See docs/GITHUB_RELEASE.md for details"
