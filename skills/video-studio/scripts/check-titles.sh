#!/usr/bin/env bash
# check-titles.sh — layout gate on a title spec before rendering: text running out of its plate or out of frame,
# blocks touching each other, fonts/files that fail to load, JS errors, visible "undefined" and unknown item kinds.
# Engine: `hyperframes check` of the pinned HyperFrames (same Chrome, SwiftShader, as render-titles.sh). Fully local.
#
# Usage:
#   check-titles.sh <916|169|entry-dir> <spec.json> [--json out.json]
#   FONTS_DIR=<dir>  custom brand fonts, as with render-titles.sh (otherwise a FAIL on 404 fonts: exactly the point)
# Exit 0 = PASS. 1 = FAIL with time, element and text per finding. 2/3 = usage error/environment.
#
# Filtered (measured 2026-11-15 on a real client spec, 13/13 false): `content_overlap` between two words of the same
# paragraph. titles.js puts every word in its own inline-block span and plates use line-height 1.08, so the word boxes
# of lines 1 and 2 overlap while the glyphs don't. Overlap between different blocks or items is still a FAIL.
set -uo pipefail
HF_VERSION="0.8.99"   # same as render-titles.sh
DIR=${1:?usage: check-titles.sh <916|169|entry-dir> <spec.json> [--json out.json]}
case "$DIR" in 916|169) DIR="$(cd "$(dirname "$0")/../templates/titles/$DIR" && pwd)";; esac
SPEC=${2:?spec.json missing}; shift 2; JSON_OUT=""
while [ $# -gt 0 ]; do case "$1" in --json) JSON_OUT="${2:?--json needs a file}"; shift 2;; *) echo "unknown option $1" >&2; exit 2;; esac; done

[ -f "$DIR/index.html" ] || { echo "ERROR: no index.html in $DIR" >&2; exit 2; }
jq -e '.duration > 0 and (.items | length) > 0' "$SPEC" >/dev/null || { echo "ERROR: spec lacks duration/items" >&2; exit 2; }
# unknown kind: titles.js silently turns it into a full-frame paper card that covers everything (measured 2026-11-15,
# a production's own spec with extra kinds). Only against the skill template; your own entry may define its own kinds.
if [ "$DIR" = "$(cd "$(dirname "$0")/../templates/titles" && pwd)/${DIR##*/}" ]; then
  UNKNOWN=$(jq -r '[.items[].kind | select(IN("plate","pair","card","figure","credit","ailabel","sub") | not)] | unique | join(", ")' "$SPEC")
  [ -n "$UNKNOWN" ] && { echo "── check-titles: $SPEC"; echo "  FAIL  unknown kind: $UNKNOWN (the template knows plate, pair, card, figure, credit, ailabel, sub)"; echo "QA: FAIL"; exit 1; }
fi
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
[ "$NODE_MAJOR" -ge 22 ] || { echo "ERROR: node $(node -v 2>/dev/null) in PATH, HyperFrames needs ≥ 22 (put a newer node earlier in PATH)" >&2; exit 3; }

export HYPERFRAMES_NO_TELEMETRY=1 HYPERFRAMES_NO_UPDATE_CHECK=1   # no telemetry, no version ping to npm
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
cp -RL "$DIR/." "$WORK/"
[ -n "${FONTS_DIR:-}" ] && cp "$FONTS_DIR"/*.[ot]tf "$FONTS_DIR"/*.woff2 "$WORK/fonts/" 2>/dev/null
# `check` has no --variables-file: the spec goes in as window.__hfVariables (the runtime reads it as a fallback)
python3 -I - "$WORK/index.html" "$SPEC" <<'PY' || { echo "ERROR: could not inject the spec" >&2; exit 2; }
import json, re, sys
page, spec = sys.argv[1:]
s = json.load(open(spec)); h = open(page).read()
v = json.dumps({"spec": json.dumps(s)}).replace("</", "<\\/")
h = h.replace("<head>", "<head>\n    <script>window.__hfVariables = " + v + ";</script>", 1)
# content check: a missing field renders as "undefined" inside the plate, so the layout pass doesn't see it
# (measured 2026-11-15: a template regression showed "“undefined”" in a plate). An error here = page_error = FAIL.
guard = ("<script>(function(){var m=(document.getElementById('root').textContent||'').match(/undefined|NaN|\\[object \\w+\\]/);"   # no \\b: textContent glues blocks together ("undefinedwithout")
         "if(m)throw new Error('title layer shows \"'+m[0]+'\": missing field in spec or template');})();</script>")
h = h.replace("</body>", "    " + guard + "\n  </body>", 1)
h = re.sub(r'data-duration="[0-9.]+"', 'data-duration="%s"' % s["duration"], h)
open(page, "w").write(h)
PY

npx --yes "hyperframes@$HF_VERSION" check "$WORK" --no-browser-gpu --at-transitions --frame-check="severity=error" \
  --json > "$WORK/check.json" 2> "$WORK/check.log"
jq -e .lint "$WORK/check.json" >/dev/null 2>&1 || { echo "ERROR: hyperframes check returned no report" >&2; tail -10 "$WORK/check.log" >&2; exit 3; }
[ -n "$JSON_OUT" ] && cp "$WORK/check.json" "$JSON_OUT"

# every error from every pass, except word-against-word within one paragraph (see header). Contrast doesn't count: the
# overlay is transparent, so it measures against nothing (measured 2026-11-15: a FAIL mid fade-out on a teal plate).
jq -r '
  def para: sub(" > span:nth-of-type\\([0-9]+\\)$"; "");
  [ (.lint, .runtime, .layout, .motion) | .findings[]?
    | select(.severity == "error")
    | select((.code == "content_overlap" and .containerSelector != null and (.selector | para) == (.containerSelector | para)
              and (.selector | test(" > span:nth-of-type")) and (.containerSelector | test(" > span:nth-of-type"))) | not) ]
  | .[] | "  FAIL  \(.code)  t=\(.time // "-")s  \(.selector // "")  \((.text // .message) | tostring | .[0:80])"
' "$WORK/check.json" > "$WORK/fails.txt"
SAMPLES=$(jq '(.layout.samples | length) + (.layout.transitionSamples | length)' "$WORK/check.json")

if [ -s "$WORK/fails.txt" ]; then
  echo "── check-titles: $SPEC"; cat "$WORK/fails.txt"
  echo "QA: FAIL — do not render this title layer (shorter text, a larger plate, or fonts via FONTS_DIR)"; exit 1
fi
echo "OK: titles $SPEC — $SAMPLES moments, no overflow/overlap/load error (hyperframes $HF_VERSION)"
