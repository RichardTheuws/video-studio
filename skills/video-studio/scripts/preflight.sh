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
# Env:  VIDEO_STUDIO_ENV=<file>       extra .env to search for keys (e.g. on a headless runner)
#       VIDEO_STUDIO_PEER=<ssh-host>  also report skill/tool drift against a second render machine (warns only)
# Exit: 0 = all tools required for the mode are present; 1 = something required is missing.

set -uo pipefail
MODE="${1:-report}"
RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[1;33m'; DIM=$'\033[2m'; NC=$'\033[0m'
missing_required=0

have() { command -v "$1" >/dev/null 2>&1; }

# key present in env or in an .env? Same search order as scripts/lib/fal.sh:
# $VIDEO_STUDIO_ENV (if set) → ~/.config/video-studio/.env (canonical location); same order as scripts/lib/fal.sh key
have_key() {
  local k="$1" f
  [ -n "${!k:-}" ] && return 0
  for f in "${VIDEO_STUDIO_ENV:-}" "$HOME/.config/video-studio/.env"; do
    [ -n "$f" ] && [ -f "$f" ] && grep -qE "^${k}=" "$f" && return 0
  done
  return 1
}

prow() { # parity: $1=label $2=ok(0/1) $3=text — warns, never blocks
  if [ "$2" -eq 0 ]; then printf "  ${GRN}✓${NC} %-14s ${DIM}%s${NC}\n" "$1" "$3"; else printf "  ${YEL}⚠ %-14s DRIFT${NC} → %s\n" "$1" "$3"; fi
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
have_key FAL_AI_KEY && row FAL_AI_KEY 0 "$ai_req" "i2v + Flux/Recraft" || row FAL_AI_KEY 1 "$ai_req" "set FAL_AI_KEY in ~/.config/video-studio/.env (resolver: scripts/lib/fal.sh key)"
have_key ELEVENLABS_API_KEY && row ELEVENLABS 0 0 "voices/SFX" || row ELEVENLABS 1 0 "optional: ElevenLabs key"
have_key SUNO_API_KEY && row SUNO 0 0 "music" || row SUNO 1 0 "optional: Suno key"

# Existing-footage mode
echo "Existing-footage mode (download + auto-select):"
ft_req=$([ "$MODE" = "footage" ] || [ "$MODE" = "all" ] && echo 1 || echo 0)
have yt-dlp && row yt-dlp 0 0 "only needed to download from a URL" || row yt-dlp 1 0 "brew install yt-dlp (URL sources only)"
have ffmpeg && row "scene-detect" 0 "$ft_req" "ffmpeg select=scene + thumbnails" || row "scene-detect" 1 "$ft_req" "ffmpeg required"

# Parity with a second render machine (optional). Set VIDEO_STUDIO_PEER=<ssh-host> if a server renders the same skill
# headless: the skill must be in sync after every change and the tool versions must match — drift is not theoretical
# (a peer once produced a blurred-fill 9:16 because two reference docs had not been synced). Warns, never blocks.
if [ -n "${VIDEO_STUDIO_PEER:-}" ] && ssh -o ConnectTimeout=3 -o BatchMode=yes "$VIDEO_STUDIO_PEER" true 2>/dev/null; then
  PEER_SKILL="${VIDEO_STUDIO_PEER_SKILL_DIR:-.claude/skills/video-studio}"
  echo "Parity with ${VIDEO_STUDIO_PEER}:"
  if have rsync; then
    DRIFT=$(rsync -aic --delete --exclude .DS_Store --dry-run "$SKILL_DIR/" "$VIDEO_STUDIO_PEER:$PEER_SKILL/" 2>/dev/null | grep -vc '^\.d\.\.t')
    [ "${DRIFT:-0}" -eq 0 ] && prow "skill-sync" 0 "peer skill in parity" || prow "skill-sync" 1 "$DRIFT file(s) differ → sync the skill to $VIDEO_STUDIO_PEER:$PEER_SKILL before a client production"
  fi
  LV=$(ffmpeg -version 2>/dev/null | head -1 | awk '{print $3}'); RV=$(ssh "$VIDEO_STUDIO_PEER" 'export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; ffmpeg -version | head -1' 2>/dev/null | awk '{print $3}')
  [ "$LV" = "$RV" ] && prow "ffmpeg-version" 0 "$LV on both" || prow "ffmpeg-version" 1 "local $LV ≠ peer ${RV:-?} — align them (brew upgrade ffmpeg) before a client production"
  RN=$(ssh "$VIDEO_STUDIO_PEER" 'export PATH=/opt/homebrew/opt/node/bin:/opt/homebrew/bin:/usr/local/bin:$PATH; node -v' 2>/dev/null)
  RNM=$(echo "${RN#v}" | cut -d. -f1); [ "${RNM:-0}" -ge 22 ] 2>/dev/null && prow "peer-node>=22" 0 "$RN" || prow "peer-node>=22" 1 "${RN:-unknown} — put a node ≥ 22 first in the peer's PATH"
fi

echo "─────────────────────────────────────────────────────────────────"
if [ "$missing_required" -eq 1 ]; then
  echo "${RED}PREFLIGHT: something REQUIRED for mode '${MODE}' is missing.${NC}"
  echo "STOP — ask the user (3 options: install / different mode / cancel). Do NOT silently skip."
  exit 1
fi
echo "${GRN}PREFLIGHT OK for mode '${MODE}'.${NC}"
exit 0
