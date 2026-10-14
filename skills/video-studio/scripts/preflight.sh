#!/usr/bin/env bash
# preflight.sh — per-job tooling/keys check, run BEFORE every video job.
# RULE: never silently degrade. If something the chosen mode needs is missing,
# the skill STOPS and asks (install / different approach / cancel) — it does not "skip".
#
# Usage:
#   preflight.sh            # report core + both modes
#   preflight.sh ai         # require full-AI mode (image-gen + i2v)
#   preflight.sh footage    # require existing-footage mode
#   preflight.sh all        # require everything
# Exit: 0 = all tools required for the mode are present; 1 = something required is missing.

set -uo pipefail
MODE="${1:-report}"
RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[1;33m'; DIM=$'\033[2m'; NC=$'\033[0m'
missing_required=0

have() { command -v "$1" >/dev/null 2>&1; }

# key present in env or in an .env (config dir, cwd, parent)?
have_key() {
  local k="$1"
  [ -n "${!k:-}" ] && return 0
  for f in "$HOME/.config/video-studio/.env" ./.env ../.env; do
    [ -f "$f" ] && grep -qE "^${k}=" "$f" && return 0
  done
  return 1
}

row() { # $1=label $2=ok(0/1) $3=req-for-this-mode(0/1) $4=hint
  if [ "$2" -eq 0 ]; then
    printf "  ${GRN}✓${NC} %-14s ${DIM}%s${NC}\n" "$1" "${4:-}"
  else
    if [ "$3" -eq 1 ]; then
      printf "  ${RED}✗ %-14s MISSING (required)${NC} → %s\n" "$1" "${4:-}"
      missing_required=1
    else
      printf "  ${YEL}○ %-14s missing (optional for this mode)${NC} → %s\n" "$1" "${4:-}"
    fi
  fi
}

echo "── video-studio preflight (mode: ${MODE}) ───────────────────────"

# Core (always required)
echo "Core:"
have ffmpeg  && row ffmpeg 0 1  || row ffmpeg 1 1 "brew install ffmpeg"
have ffprobe && row ffprobe 0 1 || row ffprobe 1 1 "comes with ffmpeg"
have jq      && row jq 0 1      || row jq 1 1 "brew install jq"
have curl    && row curl 0 1    || row curl 1 1 "system curl missing?!"

# Title layer via HyperFrames (canonical, see reference/titles-hyperframes.md).
# Needs Node >= 22; if an older node comes first in PATH, put a newer one ahead of it.
echo "Title layer (HyperFrames):"
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
[ "$NODE_MAJOR" -ge 22 ] && row "node>=22" 0 1 "$(node -v)" || row "node>=22" 1 1 "node $(node -v 2>/dev/null || echo missing) in PATH; brew install node (and put it ahead of any older node in PATH)"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HFV=$(grep -oE '^HF_VERSION="[0-9.]+"' "$SKILL_DIR/scripts/render-titles.sh" | cut -d'"' -f2)
if [ "$NODE_MAJOR" -ge 22 ] && [ "$(HYPERFRAMES_NO_TELEMETRY=1 npx --yes "hyperframes@$HFV" --version 2>/dev/null | tail -1)" = "$HFV" ]; then
  row hyperframes 0 1 "v$HFV (npx, pinned)"
else
  row hyperframes 1 1 "npx --yes hyperframes@$HFV --version (needs network the first time)"
fi
ls "$SKILL_DIR"/templates/titles/shared/fonts/*.?tf >/dev/null 2>&1 && row "title-template" 0 1 "templates/titles (fonts + GSAP bundled)" || row "title-template" 1 1 "templates/titles/shared/fonts missing — reinstall the skill"

# Lettering / title cards — pango: fallback for the title layer + text-in-the-world (perspective on a surface).
# Canonical text render: REAL pango (pango-view) → PNG → composite with ImageMagick.
# NB: Homebrew ImageMagick has no pango/fontconfig delegate → use pango-view, not `pango:`.
# PARITY: if you render on a second machine/server, it needs exactly these tools + fonts, or its output drifts.
echo "Lettering (title cards — real pango text):"
have magick     && row magick 0 1     || row magick 1 1 "brew install imagemagick (compositing/lettering)"
have pango-view && row pango-view 0 1 "real pango rendering (markup, variable fonts, letter-spacing)" || row pango-view 1 1 "brew install pango"
if have fc-list; then
  # note: `fc-list | grep -q` fails under pipefail (SIGPIPE) → match on a string instead of a pipe.
  # The families below are the default house style; swap in your own brand fonts.
  FCL="$(fc-list 2>/dev/null || true)"; miss_font=""; shopt -s nocasematch
  for fam in Fraunces Inter Outfit; do [[ "$FCL" == *"$fam"* ]] || miss_font="$miss_font $fam"; done
  shopt -u nocasematch
  [ -z "$miss_font" ] && row "brand-fonts" 0 0 "Fraunces/Inter/Outfit found" || row "brand-fonts" 1 0 "install fonts:$miss_font (fontconfig)"
else
  row fontconfig 1 0 "brew install fontconfig (fc-list; lets pango find your brand fonts)"
fi

# AI mode (image-gen + i2v)
echo "Full-AI mode (image generation + image-to-video):"
ai_req=$([ "$MODE" = "ai" ] || [ "$MODE" = "all" ] && echo 1 || echo 0)
have nano-banana && row nano-banana 0 "$ai_req" || row nano-banana 1 "$ai_req" "install nano-banana (Bun + Gemini key)"
have magick      && row magick 0 0               || row magick 1 0 "brew install imagemagick (lettering/compositing)"
have_key FAL_AI_KEY && row FAL_AI_KEY 0 "$ai_req" "i2v + Flux/Recraft" || row FAL_AI_KEY 1 "$ai_req" "set FAL_AI_KEY in ~/.config/video-studio/.env"
have_key ELEVENLABS_API_KEY && row ELEVENLABS 0 0 "voices/SFX" || row ELEVENLABS 1 0 "optional: ElevenLabs key"
have_key SUNO_API_KEY && row SUNO 0 0 "music" || row SUNO 1 0 "optional: Suno key"

# Existing-footage mode
echo "Existing-footage mode (download + auto-select):"
ft_req=$([ "$MODE" = "footage" ] || [ "$MODE" = "all" ] && echo 1 || echo 0)
have yt-dlp && row yt-dlp 0 0 "only needed to download from a URL" || row yt-dlp 1 0 "brew install yt-dlp (URL sources only)"
have ffmpeg && row "scene-detect" 0 "$ft_req" "ffmpeg select=scene + thumbnails" || row "scene-detect" 1 "$ft_req" "ffmpeg required"

echo "─────────────────────────────────────────────────────────────────"
if [ "$missing_required" -eq 1 ]; then
  echo "${RED}PREFLIGHT: something REQUIRED for mode '${MODE}' is missing.${NC}"
  echo "STOP — ask the user (3 options: install / different mode / cancel). Do NOT silently skip."
  exit 1
fi
echo "${GRN}PREFLIGHT OK for mode '${MODE}'.${NC}"
exit 0
