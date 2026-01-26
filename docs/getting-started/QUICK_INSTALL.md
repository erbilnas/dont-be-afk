# Quick Installation Guide

Choose your preferred installation method:

## 🎯 Option 1: macOS App (PKG Installer) - Recommended

**Best for:** Users who want a graphical interface with menu bar integration

### Install from Pre-built Package

1. **Download the installer:**
   ```bash
   # From GitHub Releases, download:
   # DontBeAFK-Installer-1.0.pkg
   ```

2. **Install:**
   - Double-click `DontBeAFK-Installer-1.0.pkg`
   - Follow the installer wizard
   - Enter your admin password when prompted
   - App will be installed to `/Applications`

3. **Launch:**
   - Open `/Applications/DontBeAFK.app`
   - Grant accessibility permissions when prompted
   - Use the menu bar icon to control the app

### Build PKG Installer from Source

```bash
# 1. Build the installer
./scripts/create-installer.sh

# 2. Install the created package
open DontBeAFK-Installer-1.0.pkg
```

---

## 💻 Option 2: Command Line (CLI) - For Terminal Users

**Best for:** Users who prefer terminal/command line interface

### Install from Pre-built Package

1. **Download the CLI package:**
   ```bash
   # From GitHub Releases, download:
   # dont-be-afk-cli-macos-1.0.0.tar.gz
   ```

2. **Extract and install:**
   ```bash
   tar -xzf dont-be-afk-cli-macos-1.0.0.tar.gz
   cd dont-be-afk-cli
   ./install.sh
   ```

3. **Use it:**
   ```bash
   dont-be-afk              # Interactive mode
   dont-be-afk start -x 100 -y 200 -i 5m
   ```

### Install from Source (CLI)

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/dont-be-afk.git
cd dont-be-afk

# 2. Run the installer
./install.sh

# 3. Use it
dont-be-afk
```

---

## 📦 Create Release Packages

If you want to create your own installers:

### Create PKG Installer (macOS App)
```bash
./scripts/create-installer.sh 1.0
# Creates: DontBeAFK-Installer-1.0.pkg
```

### Create CLI Package
```bash
./package-cli.sh 1.0.0
# Creates: release/dont-be-afk-cli-macos-1.0.0.tar.gz
```

### Create Both (Full Release)
```bash
./scripts/create-release.sh 1.0.0
# Creates both PKG installer and CLI package
```

---

## 🔐 Permissions Required

Both installation methods require accessibility permissions:

1. **System Settings** → **Privacy & Security** → **Accessibility**
2. Add your terminal app (for CLI) or DontBeAFK.app (for PKG)
3. Enable it in the list

---

## ✅ Verify Installation

### For PKG Installer:
```bash
# Check if app is installed
ls /Applications/DontBeAFK.app

# Launch it
open /Applications/DontBeAFK.app
```

### For CLI:
```bash
# Check if command is available
which dont-be-afk

# Test it
dont-be-afk --help
```

---

## 🆘 Troubleshooting

### PKG Installer Issues
- **Can't open PKG:** Right-click → Open (to bypass Gatekeeper)
- **Installation fails:** Check you have admin rights
- **App won't launch:** Grant accessibility permissions

### CLI Issues
- **Command not found:** Make sure `/usr/local/bin` is in your PATH
- **cliclick not found:** Run `brew install cliclick`
- **Permission denied:** Run `chmod +x bin/dont-be-afk`

---

## 📚 More Information

- **Full Documentation:** See [../README.md](../README.md)
- **Manual Installation:** See [INSTALL.md](INSTALL.md)
- **Installer Creation:** See [INSTALLER.md](INSTALLER.md)
