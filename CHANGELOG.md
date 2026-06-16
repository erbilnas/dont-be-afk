# Changelog

## 2.0.0

### Major Changes

- 413cb17: ## WHAT

  Redesigned the macOS menu bar popover and settings experience:

  - Menu bar UI now uses grouped Apple-style sections (Control, Navigate, Configuration) with shortcuts and a version footer
  - Added a dedicated **About** settings pane with version, build, copyright, and links
  - **About** in the menu bar opens Settings → About instead of the native About panel
  - Help window now shows a sidebar header and matches main window chrome
  - Versioning moved to Changesets (`package.json` as the canonical source)

  ## WHY

  - Make the menu bar extra clearer and faster to scan at a glance
  - Surface version and app metadata in Settings without relying only on the system About panel
  - Replace git-tag/commit-message version guessing with explicit, reviewable Changesets releases
  - Align Help and Settings with the same System Settings–style layout

  ## HOW to update

  **macOS app users**

  1. Download and install the latest `.pkg` or `.dmg` from GitHub Releases
  2. Replace the existing app in `/Applications`
  3. Re-grant **Accessibility** if macOS prompts after reinstall (same as any app update)

  **CLI users**

  1. Re-download the latest CLI archive from GitHub Releases, or pull latest `main` / checkout the new tag
  2. Re-run `cli/install.sh` if you installed via the script
  3. Existing config in Application Support (`~/Library/Application Support/DontBeAFK/config`) is unchanged — no manual migration required

  **Contributors**

  1. Run `npm run changeset` for user-facing PRs
  2. For **major** bumps, include WHAT / WHY / HOW sections in the changeset body (see [`.changeset/README.md`](./README.md))

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versions are managed with [Changesets](https://github.com/changesets/changesets). Run `npm run changeset` when contributing user-facing changes.

# dont-be-afk

## 1.0.0

### Added

- Initial release
- Bash script with CLI and interactive modes
- macOS SwiftUI app with menu bar integration
- Configuration persistence
- Background mode support
- File logging
- Screen bounds validation
- Multiple instance prevention

### Changed

- N/A

### Deprecated

- N/A

### Removed

- N/A

### Fixed

- N/A

### Security

- N/A
