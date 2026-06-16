#!/bin/bash
# Build number for CFBundleVersion — total commits on the current branch.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ROOT" rev-list --count HEAD 2>/dev/null || echo "1"
else
  echo "1"
fi
