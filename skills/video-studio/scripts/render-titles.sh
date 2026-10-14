#!/usr/bin/env bash
# render-titles.sh — render a HyperFrames title layer as a transparent ProRes 4444 MOV (variant A).
# Recipe + spec format: reference/titles-hyperframes.md. Template: templates/titles/ (brand via spec.brand).
#
# Usage:
#   render-titles.sh <916|169|entry-dir> <spec.json> <out.mov> [fps]
#     916 / 169   the skill template (templates/titles/916 = 1080×1920, 169 = 1920×1080); or your own entry dir
#     spec.json   {"duration": s, "items": [...]}  — times from the measured montage offsets, never by hand
#     fps         default 24 (same as the montage)
# Exit 0 = the MOV exists, has alpha and the right duration. Otherwise ≠ 0 with a reason.
#
# Fixed, not optional: pinned HyperFrames version, --no-browser-gpu (980/980 frames bit-identical across two
# machines; with GPU, edge pixels drift by up to 4/255), telemetry off, and a timeout (headless Chrome can hang).
# Custom brand fonts: FONTS_DIR=<dir> → the files are copied into fonts/, register them via spec.fontFaces.
set -uo pipefail
HF_VERSION="0.8.99"
TIMEOUT_S="${HF_TIMEOUT_S:-600}"
DIR=${1:?usage: render-titles.sh <916|169|entry-dir> <spec.json> <out.mov> [fps]}
case "$DIR" in 916|169) DIR="$(cd "$(dirname "$0")/../templates/titles/$DIR" && pwd)";; esac
SPEC=${2:?spec.json missing}; OUT=${3:?out.mov missing}; FPS=${4:-24}

[ -f "$DIR/index.html" ] || { echo "ERROR: no index.html in $DIR" >&2; exit 2; }
jq -e '.duration > 0 and (.items | length) > 0' "$SPEC" >/dev/null || { echo "ERROR: spec lacks duration/items" >&2; exit 2; }
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
[ "$NODE_MAJOR" -ge 22 ] || { echo "ERROR: node $(node -v 2>/dev/null) in PATH, HyperFrames needs ≥ 22 (put a newer node earlier in PATH)" >&2; exit 3; }

export HYPERFRAMES_NO_TELEMETRY=1
DUR=$(jq -r .duration "$SPEC")
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
# copy the entry (following symlinks) so data-duration can be set per production without touching the template
cp -RL "$DIR/." "$WORK/"
[ -n "${FONTS_DIR:-}" ] && cp "$FONTS_DIR"/*.[ot]tf "$FONTS_DIR"/*.woff2 "$WORK/fonts/" 2>/dev/null
sed -E "s/data-duration=\"[0-9.]+\"/data-duration=\"$DUR\"/" "$WORK/index.html" > "$WORK/i.tmp" && mv "$WORK/i.tmp" "$WORK/index.html"   # portable (no sed -i)
jq -n --rawfile s "$SPEC" '{spec: ($s | fromjson | tojson)}' > "$WORK/vars.json"

mkdir -p "$(dirname "$OUT")"; OUT_ABS="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
T0=$(date +%s)
npx --yes "hyperframes@$HF_VERSION" render "$WORK" --format mov --fps "$FPS" --no-browser-gpu --strict \
  --variables-file "$WORK/vars.json" -o "$OUT_ABS" --quiet > "$WORK/render.log" 2>&1 &
PID=$!
# timeout as a poll loop: a background `sleep` watchdog lingers as an orphan holding stdout open
# (a caller over ssh or `claude -p` would then wait out the full timeout)
while kill -0 "$PID" 2>/dev/null; do
  [ $(( $(date +%s) - T0 )) -ge "$TIMEOUT_S" ] && { kill "$PID" 2>/dev/null; echo "ERROR: timeout after $TIMEOUT_S s" >&2; }
  sleep 1
done
wait "$PID"; RC=$?
[ "$RC" -eq 0 ] || { echo "ERROR: render exit $RC" >&2; tail -15 "$WORK/render.log" >&2; exit 4; }

# QA gate on the output, not on the exit status
PIX=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$OUT_ABS")
GOT=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT_ABS")
[[ "$PIX" == yuva* ]] || { echo "ERROR: no alpha channel ($PIX)" >&2; exit 5; }
awk -v a="$GOT" -v b="$DUR" 'BEGIN{d=a-b; if (d<0) d=-d; exit !(d < 0.1)}' || { echo "ERROR: duration $GOT s, expected $DUR s" >&2; exit 5; }
echo "OK: $OUT ($GOT s, $PIX, hyperframes $HF_VERSION, $(( $(date +%s) - T0 )) s)"
