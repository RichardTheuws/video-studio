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
#   REAL IMAGE: a prompt that starts with @ is an existing photo, not a generation:
#     CONTENT|The product|@/path/to/source/p04.webp :: product; slow push-in, steam only
#   The photo is shown whole on the format (the border is a blurred copy of the same photo); everything after " :: "
#   is the motion note for production. Kind 'logo' goes on a plain dark card (#151515) instead of the blurred border.
#   A real video fragment: @/path/v01.mp4#t=12.5,16.0 :: product; … → the board shows the middle frame.
#   A real photo never becomes the auto-anchor for AI frames (otherwise the AI redraws the product).
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
grep -v '^[[:space:]]*#' "${PROMPTS:-/dev/null}" 2>/dev/null | cut -d'|' -f3- | grep -qv '^@' && need nano-banana
need magick   # also for real-image beats
[ -n "$PROMPTS" ] && [ -f "$PROMPTS" ] || { echo "✗ prompts file missing: '$PROMPTS'" >&2; usage 1; }

mkdir -p "$OUT"

# ── cost estimate (stills; i2v is separate and far more expensive) ─────────────
unit() { case "$TIER/$SIZE" in
  flash/512) echo 0.045;; flash/1K) echo 0.067;; flash/2K) echo 0.101;; flash/4K) echo 0.151;;
  pro/1K)    echo 0.134;; pro/2K)   echo 0.201;; pro/4K)   echo 0.302;;
  *) echo 0.067;; esac; }

# ── a real photo as a frame ────────────────────────────────────────────────────
# Long side 1376 (like nano-banana 1K). The whole photo stays visible; the border is the same photo, blurred.
frame_wh() { case "$ASPECT" in
  16:9) echo "1376 768";; 9:16) echo "768 1376";; 1:1) echo "1024 1024";;
  4:5) echo "1100 1376";; 4:3) echo "1376 1032";; 3:4) echo "1032 1376";; *) echo "1376 768";; esac; }
real_frame() { # src out [kind]
  read -r W H <<< "$(frame_wh)"
  if [ "${3:-}" = "logo" ]; then  # a logo (often transparent): a plain dark card, never a blurred copy of itself
    magick -size "${W}x${H}" xc:'#151515' \( "$1[0]" -background none -resize "$((W*62/100))x$((H*55/100))" \) \
      -gravity center -composite -quality 92 "$2"; return
  fi
  magick "$1[0]" -auto-orient -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" -blur 0x30 -modulate 55 \
    \( "$1[0]" -auto-orient -resize "${W}x${H}" \) -gravity center -composite -quality 92 "$2"
}

# ── generate per beat ──────────────────────────────────────────────────────────
n=0; ai=0; frames=(); labels=()
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
  if [ "${prompt#@}" != "$prompt" ]; then
    src="${prompt#@}"; src="${src%% :: *}"
    if [ "${src#*#t=}" != "$src" ]; then  # a real video fragment: a frame from the middle of the fragment
      vt="${src#*#t=}"; vsrc="${src%%#t=*}"
      [ -f "$vsrc" ] || { echo "✗ real video missing: $vsrc ($name)" >&2; exit 1; }
      mid=$(awk -v a="${vt%%,*}" -v b="${vt#*,}" 'BEGIN{printf "%.2f", (a+b)/2}')
      ffmpeg -v error -y -ss "$mid" -i "$vsrc" -frames:v 1 "$OUT/$name-src.png" || { echo "✗ could not grab a frame: $vsrc@$mid" >&2; exit 1; }
      src="$OUT/$name-src.png"
    fi
    [ -f "$src" ] || { echo "✗ real photo missing: $src ($name)" >&2; exit 1; }
    kind="${prompt#* :: }"; [ "$kind" = "$prompt" ] && kind=""; kind="${kind%%;*}"; kind="${kind// /}"
    real_frame "$src" "$OUT/$name.jpeg" "$kind" || { echo "✗ could not process the real photo: $src" >&2; exit 1; }
    frames+=("$OUT/$name.jpeg"); labels+=("${section} · ${label}")
    continue
  fi
  # generation is flaky (rate limits / transient API errors) → up to 3 attempts per
  # keyframe with a short backoff; only then fail hard (a single attempt has been
  # seen to drop a keyframe silently).
  ai=$((ai+1))
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
awk -v n="$ai" -v u="$U" -v t="$TIER" -v s="$SIZE" 'BEGIN{
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
