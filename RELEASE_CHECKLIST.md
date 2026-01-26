# Release Checklist

Use this checklist when preparing a new release on GitHub.

## Pre-Release

- [ ] Update version numbers in relevant files
- [ ] Update CHANGELOG.md with new version and changes
- [ ] Ensure all tests pass
- [ ] Update README.md if needed
- [ ] Review and update documentation
- [ ] Check for any hardcoded paths or user-specific content
- [ ] Verify LICENSE file is correct
- [ ] Ensure .gitignore is comprehensive

## Code Quality

- [ ] Run shellcheck on all bash scripts
- [ ] Test bash script functionality
- [ ] Test macOS UI app (if applicable)
- [ ] Test on multiple macOS versions if possible
- [ ] Verify installation script works
- [ ] Check for any security issues

## Documentation

- [ ] README.md is up to date
- [ ] CONTRIBUTING.md is accurate
- [ ] SETUP_XCODE.md instructions are clear
- [ ] BUILD_UI.md is accurate
- [ ] All code examples work
- [ ] Screenshots are current (if any)

## GitHub Preparation

- [ ] Create release branch: `git checkout -b release/vX.Y.Z`
- [ ] Tag the release: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
- [ ] Push tags: `git push origin vX.Y.Z`
- [ ] Create GitHub Release with:
  - [ ] Release title: `vX.Y.Z`
  - [ ] Release notes from CHANGELOG.md
  - [ ] Attach any build artifacts (if distributing binaries)

## Post-Release

- [ ] Merge release branch to main/master
- [ ] Update any external documentation
- [ ] Announce release (if applicable)
- [ ] Monitor for issues

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality
- **PATCH** version for backwards-compatible bug fixes
