# GitHub Release Guide

This guide explains how to create releases on GitHub with both the macOS installer (.pkg) and command line version.

## Quick Release

### Option 1: Automated Release (Recommended)

1. **Create a version tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically:**
   - Build the macOS app
   - Create the installer package (.pkg)
   - Package the command line version (.tar.gz and .zip)
   - Create a GitHub release with all files

### Option 2: Manual Release (One Command)

```bash
./create-release.sh 1.0.0
```

This automatically:
1. Builds the macOS installer (.pkg)
2. Packages the CLI version (.tar.gz and .zip)
3. Creates all release files ready for upload

Then:
- Go to your GitHub repository
- Click "Releases" → "Draft a new release"
- Tag: `v1.0.0`
- Title: `Release v1.0.0`
- Upload the created files
- Publish release

### Option 3: Manual Release (Step by Step)

1. **Build the installer:**
   ```bash
   ./create-installer.sh
   ```
   This creates: `DontBeAFK-Installer-1.0.pkg`

2. **Package the CLI version:**
   ```bash
   ./package-cli.sh 1.0.0
   ```
   This creates:
   - `release/dont-be-afk-cli-macos-1.0.0.tar.gz`

3. **Create a GitHub release:**
   - Go to your GitHub repository
   - Click "Releases" → "Draft a new release"
   - Tag: `v1.0.0`
   - Title: `Release v1.0.0`
   - Upload files:
     - `DontBeAFK-Installer-1.0.pkg`
     - `release/dont-be-afk-cli-macos-1.0.0.tar.gz`
   - Publish release

## Release Files

### macOS Installer (.pkg)
- **File:** `DontBeAFK-Installer-1.0.pkg`
- **Description:** macOS installer package for the UI app
- **Installation:** Double-click to install, or use `sudo installer -pkg DontBeAFK-Installer-1.0.pkg -target /`

### Command Line Version (macOS)
- **File:** `dont-be-afk-cli-macos-1.0.0.tar.gz`
- **Description:** macOS command line version for terminal use
- **Requirements:** macOS 13.0+, Homebrew
- **Installation:** Extract and run `./install.sh` or follow manual installation steps

## Release Notes Template

```markdown
## What's New

- macOS installer package for easy installation
- Command line version for terminal users
- Beautiful SwiftUI interface
- Menu bar integration

## Installation

### macOS App (Recommended)

1. Download `DontBeAFK-Installer-1.0.pkg`
2. Double-click to install
3. Open from Applications folder
4. Grant accessibility permissions when prompted

### Command Line Version (macOS)

1. Download `dont-be-afk-cli-macos-1.0.0.tar.gz`
2. Extract the archive
3. Run `./install.sh` or follow manual installation in README

## Requirements

- macOS 13.0 or later
- Homebrew (for CLI version, installed automatically)

## Documentation

- [README.md](README.md) - Full documentation
- [INSTALL.md](INSTALL.md) - Installation guide
- [INSTALLER.md](INSTALLER.md) - Installer creation guide
```

## Version Numbering

Use semantic versioning:
- `v1.0.0` - Major release
- `v1.1.0` - Minor release (new features)
- `v1.0.1` - Patch release (bug fixes)

## Testing Before Release

1. **Test the installer:**
   ```bash
   # Install on a test system
   sudo installer -pkg DontBeAFK-Installer-1.0.pkg -target /
   ```

2. **Test the CLI package:**
   ```bash
   # Extract and test
   tar -xzf release/dont-be-afk-cli-macos-1.0.0.tar.gz
   cd dont-be-afk-cli
   ./install.sh
   ```

3. **Verify both versions work correctly**

## Automated Workflow

The GitHub Actions workflow (`.github/workflows/release.yml`) automatically:
- Builds the app when you push a version tag
- Creates the installer package
- Packages the CLI version
- Creates a GitHub release with all files

Just tag and push:
```bash
git tag v1.0.0
git push origin v1.0.0
```
