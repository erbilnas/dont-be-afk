# Changesets

This repository uses [Changesets](https://github.com/changesets/changesets) to manage versions and changelogs.

## Adding a changeset

```bash
npm install
npm run changeset
```

1. Choose **patch**, **minor**, or **major**
2. Write a short summary (first line — used in changelog titles)
3. For **major** changes, expand the changeset file with **WHAT**, **WHY**, and **HOW** (see below)
4. Commit the generated `.changeset/*.md` file with your PR

Merging to `master` triggers the **Changesets** GitHub Action, which opens a **Version Packages** PR. Merging that PR tags a release and builds macOS artifacts.

## Breaking changes (major)

When you select **major**, Changesets will warn that you should document:

| Section | Include |
|--------|---------|
| **WHAT** | What changed — user-visible behavior, removed/renamed settings, CLI flags, config keys |
| **WHY** | Why it was necessary — motivation, problem solved, trade-offs |
| **HOW** | How to update — reinstall steps, config migration, new defaults, workarounds |

### Example changeset body

```md
---
"dont-be-afk": major
---

Short one-line summary for the changelog

## WHAT

- Bullet list of breaking changes

## WHY

- Why this release required a major bump

## HOW to update

**macOS app users**
1. Install the latest release from GitHub

**CLI users**
1. Re-download or pull the new tag
2. Note any config or command changes
```

## Semver guide

| Bump | When to use |
|------|-------------|
| **patch** | Bug fixes, copy tweaks, non-breaking UI polish |
| **minor** | New features, new settings panes, backward-compatible behavior |
| **major** | Breaking CLI behavior, config format changes, removed features, or incompatible app workflow changes |

## Troubleshooting

If `npm run changeset` warns about `main` not existing, ensure `baseBranch` in `config.json` matches your default branch (`master` in this repo).
