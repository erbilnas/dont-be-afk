#!/bin/bash
# Read the canonical marketing version from package.json (managed by Changesets).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG="${ROOT}/package.json"

if [ ! -f "$PKG" ]; then
  echo "1.0.0"
  exit 0
fi

if command -v node >/dev/null 2>&1; then
  node -p "require('${PKG}').version"
else
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PKG" | head -1
fi
