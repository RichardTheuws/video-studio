#!/usr/bin/env bash
# video-studio storyboard — generates a VISUAL keyframe storyboard (stills) as a
# cheap gate BEFORE the expensive image-to-video step. Keyframes are stills (nano-banana);
# the money is in i2v — so this board costs cents and de-risks the i2v spend.
#
# Principle: generate at DELIVERY QUALITY (not prettier) → the board is the personalised
# floor, a promise the final video meets by definition. Consistency via one anchor
# (keyframe-first, see reference/consistency.md): the first frame automatically becomes
# the anchor for the rest, unless you pass an explicit --anchor.
#
# Usage:
#   storyboard.sh -p prompts.txt [-o out] [-r anchor.png] [-m flash|pro] [-s 1K] [-a 16:9]
#
# prompts.txt — one beat per line:  SECTION|LABEL|prompt
#   SECTION ∈ {LEADER, CONTENT, OUTRO}   (default split 3/5/2, but free)
#   lines starting with # or empty are ignored
#   example:
#     LEADER|Logo reveal|dark studio, brand periwinkle glow, no text, cinematic
#     CONTENT|Product hero|clean SaaS dashboard on desk, warm key light, no text
#     OUTRO|CTA card|empty branded end-card, periwinkle gradient, no text
#
# Output: out/kf-NN-<section>.png per beat + out/board.png (labelled grid) + a cost line.

set -euo pipefail

PROMPTS=""; OUT="storyboard"; TIER="flash"; SIZE="1K"; ASPECT="16:9"
ANCHOR=""; AUTO_ANCHOR=1; MAKE_BOARD=1; TITLE="Storyboard"

usage() { grep '^# ' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--prompts) PROMPTS="$2"; shift 2;;
    -o|--out)     OUT="$2"; shift 2;;
    -r|--anchor)  ANCHOR="$2"; AUTO_ANCHOR=0; shift 2;;
    -m|--tier)    TIER="$2"; shift 2;;
    -s|--size)    SIZE="$2"; shift 2;;
    -a|--aspect)  ASPECT="$2"; shift 2;;
    -t|--title)   TITLE="$2"; shift 2;;
    --no-board)   MAKE_BOARD=0; shift;;
    --no-auto-anchor) AUTO_ANCHOR=0; shift;;
    -h|--help)    usage 0;;
    *) echo "Unknown option: $1" >&2; usage 1;;
  esac
done

# ── preflight (iron rule: never degrade silently) ──────────────────────────────
need() { command -v "$1" >/dev/null 2>&1 || { echo "✗ '$1' is missing — STOP and ask (A/B/C: install / other route / cancel)." >&2; exit 1; }; }
need nano-banana
[ "$MAKE_BOARD" -eq 1 ] && need magick
[ -n "$PROMPTS" ] && [ -f "$PROMPTS" ] || { echo "✗ prompts file missing: '$PROMPTS'" >&2; usage 1; }

mkdir -p "$OUT"

# ── cost estimate (stills; i2v is separate and far more expensive) ─────────────
unit() { case "$TIER/$SIZE" in
  flash/512) echo 0.045;; flash/1K) echo 0.067;; flash/2K) echo 0.101;; flash/4K) echo 0.151;;
  pro/1K)    echo 0.134;; pro/2K)   echo 0.201;; pro/4K)   echo 0.302;;
  *) echo 0.067;; esac; }

# ── generate per beat ──────────────────────────────────────────────────────────
n=0; frames=(); labels=()
while IFS='|' read -r section label prompt || [ -n "${section:-}" ]; do
  case "$section" in ''|\#*) continue;; esac
  [ -n "${prompt:-}" ] || continue
  n=$((n+1)); idx=$(printf "%02d" "$n")
  sec_lc=$(echo "$section" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
  name="kf-${idx}-${sec_lc}"

  # anchor: passed explicitly → always; otherwise auto (the first frame anchors the rest)
  ref_args=()
  [ -n "$ANCHOR" ] && ref_args=(-r "$ANCHOR")

  echo "→ [$idx] ${section} — ${label}"
  # generation is flaky (rate limits / transient API errors) → up to 3 attempts per
  # keyframe with a short backoff; only then fail hard (a single attempt has been
  # seen to drop a keyframe silently).
  frame=""
  for attempt in 1 2 3; do
    nano-banana "$prompt" -o "$name" -d "$OUT" -m "$TIER" -s "$SIZE" -a "$ASPECT" "${ref_args[@]+"${ref_args[@]}"}" >/dev/null || true
    frame="$OUT/$name.png"
    [ -f "$frame" ] || frame=$(ls -t "$OUT/$name".* 2>/dev/null | head -1 || true)
    [ -n "$frame" ] && [ -f "$frame" ] && break
    frame=""
    echo "  ⚠ attempt $attempt for $name failed — retry in $((attempt*5))s" >&2
    sleep $((attempt*5))
  done
  [ -n "$frame" ] && [ -f "$frame" ] || { echo "✗ keyframe not found after 3 attempts: $name" >&2; exit 1; }
  frames+=("$frame"); labels+=("${section} · ${label}")

  # auto-anchor: the first successful frame becomes the reference for all following ones
  if [ "$AUTO_ANCHOR" -eq 1 ] && [ -z "$ANCHOR" ]; then ANCHOR="$frame"; fi
done < "$PROMPTS"

[ "$n" -gt 0 ] || { echo "✗ no valid beats in $PROMPTS" >&2; exit 1; }

# ── cost line ──────────────────────────────────────────────────────────────────
U=$(unit)
awk -v n="$n" -v u="$U" -v t="$TIER" -v s="$SIZE" 'BEGIN{
  usd=n*u; eur=usd*0.92;
  printf "\n💶 Storyboard cost: ~$%.2f (%d × $%.3f, %s/%s) ≈ €%.2f — stills only, i2v comes only after approval.\n", usd, n, u, t, s, eur }'

# ── assemble the board (labelled grid) ─────────────────────────────────────────
if [ "$MAKE_BOARD" -eq 1 ]; then
  # on macOS, montage needs an explicit font path (default = empty → RenderFreetype error)
  FONT=""
  for f in /System/Library/Fonts/Helvetica.ttc /System/Library/Fonts/HelveticaNeue.ttc \
           /System/Library/Fonts/Supplemental/Arial.ttf /Library/Fonts/Arial.ttf; do
    [ -f "$f" ] && FONT="$f" && break
  done
  font_args=(); [ -n "$FONT" ] && font_args=(-font "$FONT")
  margs=(-background '#0e0e12' -fill '#e8e8ea' "${font_args[@]+"${font_args[@]}"}" -pointsize 22)
  i=0; while [ "$i" -lt "$n" ]; do margs+=(-label "${labels[$i]}" "${frames[$i]}"); i=$((i+1)); done
  magick montage "${margs[@]}" -tile 5x -geometry '+12+12>' \
    -title "$TITLE" "$OUT/board.png"
  echo "🖼  Board: $OUT/board.png ($n keyframes)"
fi
