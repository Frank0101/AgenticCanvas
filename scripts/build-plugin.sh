#!/usr/bin/env bash
# Regenerates .build/agentic-canvas (the distributable Claude Code plugin) from
# .claude/agents and .claude/skills, which remain the source of truth.
#
# Deterministic: given the same .claude/ contents and VERSION, this always
# produces the same .build/agentic-canvas/ output. Never edit .build/ by hand.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SRC_AGENTS=".claude/agents"
SRC_SKILLS=".claude/skills"
OUT_DIR=".build/agentic-canvas"
VERSION="$(tr -d '[:space:]' <VERSION)"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/.claude-plugin" "$OUT_DIR/agents" "$OUT_DIR/skills"

cp -R "$SRC_AGENTS/." "$OUT_DIR/agents/"
cp -R "$SRC_SKILLS/." "$OUT_DIR/skills/"

cat >"$OUT_DIR/.claude-plugin/plugin.json" <<EOF
{
  "name": "agentic-canvas",
  "displayName": "AgenticCanvas",
  "version": "$VERSION",
  "description": "Planner -> Coder -> Tester build pipeline as Claude Code agents and skills.",
  "author": {
    "name": "Francesco Cossu"
  },
  "repository": "https://github.com/Frank0101/AgenticCanvas"
}
EOF

echo "Built $OUT_DIR at version $VERSION"
