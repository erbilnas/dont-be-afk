# GitHub Release Guide

This guide explains how to create releases on GitHub with both the macOS installer (.pkg) and command line version.

## Automatic Releases (Recommended)

This repository uses **[Changesets](https://github.com/changesets/changesets)** for versioning. The canonical version lives in [`package.json`](../package.json) at the repo root.

### How It Works

1. **Contributors add a changeset** in pull requests with user-facing changes:

   ```bash
   npm install
   npm run changeset
   ```

   Commit the generated `.changeset/*.md` file with your PR.

2. **On merge to `master`**, the [Changesets workflow](../.github/workflows/changesets.yml) opens a **Version Packages** pull request that:
   - Bumps `package.json`
   - Updates `CHANGELOG.md`

3. **When the Version Packages PR merges**, Changesets tags `v{version}` and pushes it.

4. **The tag triggers** the [Release workflow](../.github/workflows/release.yml), which builds and publishes:
   - macOS `.pkg` installer
   - `.dmg` disk image
   - CLI `.tar.gz`

### Version in the App

At build time, Xcode reads the marketing version from `package.json` and sets the build number from the git commit count. The menu bar footer, About pane, and native About panel all display this stamped version.

### Manual Release

You can trigger a release manually from the Actions tab using **workflow_dispatch** on the Release workflow, optionally passing a version override.

## Local Release Scripts

```bash
# Build installer using package.json version
./scripts/release/create-installer.sh

# Build everything for GitHub
./scripts/release/create-release.sh
```

## Semantic Versioning

Changesets uses [Semantic Versioning](https://semver.org/):

- **patch** — bug fixes, small improvements
- **minor** — new features, backward compatible
- **major** — breaking changes

Choose the bump when you run `npm run changeset`. For **major** releases, document **WHAT**, **WHY**, and **HOW to update** in the changeset file — see [`.changeset/README.md`](../../.changeset/README.md).
