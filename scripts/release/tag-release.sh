#!/bin/bash
# Changesets publish hook: tag the release and push to trigger the build workflow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION="$("$SCRIPT_DIR/get-version.sh")"
TAG="v${VERSION}"

cd "$ROOT"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Tag $TAG already exists locally, skipping."
  exit 0
fi

if git ls-remote --tags origin "$TAG" | grep -q "$TAG"; then
  echo "Tag $TAG already exists on remote, skipping."
  exit 0
fi

git config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"
git config user.email "${GIT_AUTHOR_EMAIL:-github-actions[bot]@users.noreply.github.com}"

git tag -a "$TAG" -m "Release $TAG"
git push origin "$TAG"

echo "Tagged and pushed $TAG"

# GITHUB_TOKEN tag pushes do not trigger other workflows; dispatch Release explicitly.
if [ -n "${GITHUB_TOKEN:-}" ]; then
  export GH_TOKEN="$GITHUB_TOKEN"
  gh workflow run release.yml --ref "$TAG" -f "version=${VERSION}"
  echo "Triggered Release workflow for ${TAG}"
fi
