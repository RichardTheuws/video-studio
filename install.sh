#!/usr/bin/env bash
# install.sh — manual install of Video Studio as a Claude Code skill.
# (Prefer the plugin: /plugin marketplace add RichardTheuws/video-studio → /plugin install video-studio@theuws-video)
# This copies the skill into ~/.claude/skills/video-studio/ (user-level, available in every project).
set -euo pipefail

DEST="${1:-$HOME/.claude/skills/video-studio}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/video-studio"

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "✗ Can't find the skill at $SRC — run this from the repo root." >&2
  exit 1
fi

echo "🎬  Installing Video Studio → $DEST"
mkdir -p "$DEST"
cp -R "$SRC/." "$DEST/"
chmod +x "$DEST/scripts/"*.sh 2>/dev/null || true

echo "✓ Installed."
echo ""
echo "Next:"
echo "  1) Check your machine:   bash $DEST/scripts/doctor.sh"
echo "  2) Add keys (AI mode):   ~/.config/video-studio/.env   (FAL_AI_KEY, GEMINI_API_KEY, …)"
echo "  3) In Claude Code, just ask it to make a video — the skill activates automatically."
