#!/usr/bin/env bash
# doctor.sh — "Is my machine ready for Video Studio?"
# Friendly one-time onboarding check. Reports what you have, what's missing,
# and which mode you can run today — with copy-paste install commands.
#
# (For the strict per-job gate that runs before every render, see preflight.sh.)
set -uo pipefail

BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[1;33m'; BLU=$'\033[0;34m'; NC=$'\033[0m'
ok=0; warn=0; miss_core=0; miss_titles=0; miss_ai=0; miss_footage=0

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

line()  { printf "  ${GRN}✓${NC} %-16s ${DIM}%s${NC}\n" "$1" "${2:-}"; ok=$((ok+1)); }
optl()  { printf "  ${YEL}○${NC} %-16s ${DIM}%s${NC}\n" "$1" "optional — ${2:-}"; warn=$((warn+1)); }
fail()  { printf "  ${RED}✗ %-16s missing${NC} → %s\n" "$1" "${2:-}"; }

echo ""
echo "${BOLD}🎬  Video Studio — machine doctor${NC}"
echo "${DIM}────────────────────────────────────────────────────────${NC}"

# ---- OS ----
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  echo "Platform: ${GRN}macOS${NC} $(sw_vers -productVersion 2>/dev/null)  (primary, fully supported)"
  PKG="brew install"
elif [ "$OS" = "Linux" ]; then
  echo "Platform: ${YEL}Linux${NC}  (supported — swap 'brew' for your package manager)"
  PKG="sudo apt install"
else
  echo "Platform: ${YEL}$OS${NC}  (untested — core tools still needed)"
  PKG="<your package manager>"
fi

# ---- disk ----
AVAIL=$(df -h . 2>/dev/null | awk 'NR==2{print $4}')
echo "Free disk here: ${AVAIL:-unknown}   ${DIM}(renders + intermediates want a few GB)${NC}"
echo ""

# ---- Core (always required) ----
echo "${BOLD}Core${NC} ${DIM}(required for any job)${NC}"
have ffmpeg  && line ffmpeg  "$(ffmpeg -version 2>/dev/null | head -1 | awk '{print $3}')" || { fail ffmpeg  "$PKG ffmpeg";  miss_core=1; }
have ffprobe && line ffprobe "comes with ffmpeg" || { fail ffprobe "$PKG ffmpeg"; miss_core=1; }
have jq      && line jq      "$(jq --version 2>/dev/null)" || { fail jq "$PKG jq"; miss_core=1; }
have curl    && line curl    "" || { fail curl "install curl"; miss_core=1; }
echo ""

# ---- Title layer (HyperFrames) ----
echo "${BOLD}Title layer${NC} ${DIM}(heavy, animated titles as a transparent overlay — see reference/titles-hyperframes.md)${NC}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HFV=$(grep -oE '^HF_VERSION="[0-9.]+"' "$SKILL_DIR/scripts/render-titles.sh" 2>/dev/null | cut -d'"' -f2)
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
if [ "$NODE_MAJOR" -ge 22 ]; then line "node>=22" "$(node -v)"; else fail "node>=22" "$PKG node  (found: $(node -v 2>/dev/null || echo none); a newer node must come first in PATH)"; miss_titles=1; fi
if [ "$NODE_MAJOR" -ge 22 ] && [ "$(HYPERFRAMES_NO_TELEMETRY=1 npx --yes "hyperframes@$HFV" --version 2>/dev/null | tail -1)" = "$HFV" ]; then
  line hyperframes "v$HFV (pinned, fetched by npx)"
else
  fail hyperframes "npx --yes hyperframes@$HFV --version  (needs node>=22 + network the first time)"; miss_titles=1
fi
ls "$SKILL_DIR"/templates/titles/shared/fonts/*.?tf >/dev/null 2>&1 && line "title-template" "fonts + GSAP bundled" || { fail "title-template" "templates/titles/shared/fonts missing — reinstall the skill"; miss_titles=1; }
have pango-view && line pango-view "fallback lettering + text-in-the-world" || { fail pango-view "$PKG pango  (real pango text rendering)"; miss_titles=1; }
echo ""

# ---- Full-AI mode ----
echo "${BOLD}Full-AI mode${NC} ${DIM}(generate stills/keyframes → image-to-video)${NC}"
have nano-banana && line nano-banana "Gemini image CLI" || { fail nano-banana "npm i -g nano-banana  (needs Bun + a Gemini API key)"; miss_ai=1; }
have magick && line ImageMagick "$(magick -version 2>/dev/null | head -1 | awk '{print $3}')" || { fail ImageMagick "$PKG imagemagick  (heavy titles / lettering)"; miss_ai=1; }
have_key FAL_AI_KEY && line FAL_AI_KEY "image-to-video (Kling), Flux, stable-audio" || { fail FAL_AI_KEY "set FAL_AI_KEY in ~/.config/video-studio/.env  →  https://fal.ai"; miss_ai=1; }
have_key GEMINI_API_KEY && line GEMINI_API_KEY "nano-banana keyframes" || optl GEMINI_API_KEY "needed by nano-banana → https://aistudio.google.com/apikey"
have_key ELEVENLABS_API_KEY && line ELEVENLABS_API_KEY "voices / SFX" || optl ELEVENLABS_API_KEY "voices / SFX"
echo ""

# ---- Footage mode ----
echo "${BOLD}Existing-footage mode${NC} ${DIM}(edit clips you already have)${NC}"
if have ffmpeg; then line "scene-detect" "ffmpeg scene-detect + thumbnails"; else fail "scene-detect" "needs ffmpeg (see Core)"; fi
have yt-dlp && line yt-dlp "download from URLs" || optl yt-dlp "only needed to pull clips from URLs — $PKG yt-dlp"
echo ""

# ---- Verdict ----
echo "${DIM}────────────────────────────────────────────────────────${NC}"
echo "${BOLD}Verdict${NC}"
if [ "$miss_core" -eq 1 ]; then
  echo "  ${RED}✗ Not ready.${NC} Core tools are missing — install them first (above), then re-run the doctor."
  exit 1
fi
echo "  ${GRN}✓ Core ready.${NC}"
if [ "$miss_titles" -eq 0 ]; then echo "  ${GRN}✓ Title layer: ready.${NC}  HyperFrames titles render locally.";
else echo "  ${YEL}○ Title layer: incomplete.${NC}  Install the missing items above — premium titles need them."; fi
if [ "$miss_footage" -eq 0 ]; then echo "  ${GRN}✓ Existing-footage mode: ready.${NC}  Point it at clips and go."; fi
if [ "$miss_ai" -eq 0 ] && [ "$miss_titles" -eq 0 ]; then
  echo "  ${GRN}✓ Full-AI mode: ready.${NC}  Keyframe-first generation is available."
  echo ""
  echo "  ${GRN}${BOLD}You're fully set up.${NC} Open Claude Code in a project and ask it to make a film."
else
  echo "  ${YEL}○ Full-AI mode: partial.${NC}  Add the missing items above for generated shots."
  echo "    (You can still do everything in existing-footage mode today.)"
fi
echo "${DIM}────────────────────────────────────────────────────────${NC}"
echo ""
exit 0
