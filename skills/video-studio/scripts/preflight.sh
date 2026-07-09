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

# AI mode (image-gen + i2v)
echo "Full-AI mode (image generation + image-to-video):"
ai_req=$([ "$MODE" = "ai" ] || [ "$MODE" = "all" ] && echo 1 || echo 0)
have nano-banana && row nano-banana 0 "$ai_req" || row nano-banana 1 "$ai_req" "install nano-banana (Bun + Gemini key)"
have magick      && row magick 0 0               || row magick 1 0 "brew install imagemagick (lettering/compositing)"
have_key FAL_AI_KEY && row FAL_AI_KEY 0 "$ai_req" "i2v + Flux/Recraft" || row FAL_AI_KEY 1 "$ai_req" "set FAL_AI_KEY in ~/.config/video-studio/.env"
have_key ELEVENLABS_API_KEY && row ELEVENLABS 0 0 "voices/SFX" || row ELEVENLABS 1 0 "optional: ElevenLabs key"

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
