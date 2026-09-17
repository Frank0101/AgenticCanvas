#!/usr/bin/env bash
# One-time setup: point git at this repo's committed hooks under .githooks/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

git config core.hooksPath .githooks
echo "core.hooksPath set to .githooks"
