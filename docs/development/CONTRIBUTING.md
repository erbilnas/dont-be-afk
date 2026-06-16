# Contributing to Don't Be AFK

Thank you for your interest in contributing to Don't Be AFK! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/dont-be-afk.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit your changes: `git commit -m "Add your feature"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Open a Pull Request

## Development Setup

### Bash Script Development

The main script is in `bin/dont-be-afk` and uses modules from `lib/`. To test:

```bash
# Make scripts executable
chmod +x bin/dont-be-afk
chmod +x lib/*.sh

# Run in interactive mode
./bin/dont-be-afk
```

### macOS UI App Development

1. Create the Xcode project (see [SETUP_XCODE.md](SETUP_XCODE.md))
2. Open `DontBeAFK.xcodeproj` in Xcode
3. Build and run (Cmd+R)

## Code Style

- **Bash scripts**: Follow shellcheck guidelines, use 4-space indentation
- **Swift code**: Follow Swift API Design Guidelines, use 4-space indentation
- **Comments**: Write clear, concise comments explaining why, not what

## Testing

Before submitting a PR, please:

1. Test the bash script functionality
2. Test the macOS UI app (if applicable)
3. Test on different macOS versions if possible
4. Ensure no regressions in existing functionality

## Pull Request Process

1. Add a [Changeset](https://github.com/changesets/changesets) when your PR includes a user-facing change:

   ```bash
   npm install
   npm run changeset
   ```

   Choose the semver bump and write a short summary. Commit the generated `.changeset/*.md` file.

   For **major** (breaking) changes, edit the changeset file and add **WHAT**, **WHY**, and **HOW to update** sections. See [`.changeset/README.md`](../../.changeset/README.md).

2. Update documentation if needed
3. Add tests if applicable
4. Ensure all checks pass
5. Request review from maintainers
6. Address any feedback

Merged changesets are versioned automatically via the **Changesets** GitHub Action, which opens a version PR and tags releases.

## Reporting Issues

When reporting issues, please include:

- macOS version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant logs or error messages

## Questions?

Feel free to open an issue for questions or discussions!
