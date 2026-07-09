#!/usr/bin/env bash
# install.sh — install Video Studio as a Claude Code skill.
# Copies the skill into ~/.claude/skills/video-studio/ (user-level, available in every project).
set -euo pipefail

DEST="${1:-$HOME/.claude/skills/video-studio}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎬  Installing Video Studio → $DEST"
mkdir -p "$DEST"
# copy the skill payload (not git/readme/license bloat)
for item in SKILL.md CHANGELOG.md reference scripts; do
  [ -e "$SRC/$item" ] && cp -R "$SRC/$item" "$DEST/"
done
chmod +x "$DEST/scripts/"*.sh 2>/dev/null || true

echo "✓ Installed."
echo ""
echo "Next:"
echo "  1) Check your machine:   bash $DEST/scripts/doctor.sh"
echo "  2) Add keys (AI mode):   ~/.config/video-studio/.env   (FAL_AI_KEY, GEMINI_API_KEY, …)"
echo "  3) In Claude Code, just ask it to make a video — the skill activates automatically."
