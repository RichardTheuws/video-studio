#!/usr/bin/env bash
# Regression test of the story, legibility and voice gates (+ the Extended checks in qa-check.sh). Self-contained: every
# fixture is in this folder or synthesised here with ffmpeg; no production, no voice, no LLM call.
#   bash run.sh
#   VS_VO_PY=<python with numpy/scipy>  also runs the music-bed gate (qa-check.sh --bed); otherwise that case is skipped
# Whisper-dependent parts (language ID, WER, subtitle sync) need speech and are covered by the unit tests in scripts/tests
# (test_voice_check.py, test_names.py) and by running the gates on your own production.
set -uo pipefail
S="$(cd "$(dirname "$0")/../../.." && pwd)"; G="$(cd "$(dirname "$0")" && pwd)"; ST="$G/story"
ok=0; bad=0; skip=0
expect() { # name expected-exit command…
  local name="$1" want="$2"; shift 2
  local out; out=$("$@" 2>&1); local got=$?
  if [ "$got" = "$want" ]; then echo "  ok    $name (exit $got)"; ok=$((ok+1))
  else echo "  ERROR $name: exit $got, expected $want"; echo "$out" | tail -12 | sed 's/^/        /'; bad=$((bad+1)); fi
}
has() { # name pattern command… — the reason itself, not just the exit code
  local name="$1" pat="$2"; shift 2
  local out; out=$("$@" 2>&1)
  if echo "$out" | grep -q -- "$pat"; then echo "  ok    $name"; ok=$((ok+1))
  else echo "  ERROR $name: '$pat' not in the output"; echo "$out" | tail -12 | sed 's/^/        /'; bad=$((bad+1)); fi
}
command -v ffmpeg >/dev/null || { echo "ffmpeg missing"; exit 2; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# a light frame without titles (contrast must fail) and a frame with a dark plate + white 'text' bars where the plate sits
ffmpeg -v error -y -f lavfi -i color=c=0xdedede:s=1920x1080:d=5:r=25 -pix_fmt yuv420p "$T/light.mp4"
ffmpeg -v error -y -f lavfi -i color=c=0xdedede:s=1920x1080:d=5:r=25 \
  -vf "drawbox=x=90:y=420:w=820:h=180:color=0x111111:t=fill,drawbox=x=160:y=480:w=520:h=44:color=white:t=fill" \
  -pix_fmt yuv420p "$T/plate.mp4"

echo "── legibility-check (synthetic)"
L() { python3 -I "$S/scripts/legibility-check.py" "$@"; }
has "contrast fails on a frame without a plate" "contrast 1"        L "$G/synth-contrast.json" "$T/light.mp4"
has "more than two lines fails"                 "lines (≤ 2"        L "$G/synth-lines.json" "$T/light.mp4"
has "overlap with the AI label fails"           "overlaps ailabel"  L "$G/synth-overlap.json" "$T/light.mp4"
has "too short to read fails"                   "reading time"      L "$G/synth-readtime.json" "$T/plate.mp4"
printf '2.5\n2.5\n' > "$T/seg-hard.txt"
has "a cut inside the build-up fails"           "falls in the build-up" L "$G/synth-transition.json" "$T/plate.mp4" --cuts "$T/seg-hard.txt" --xfade 0
printf '3\n3\n3\n' > "$T/seg-wrong.txt"
expect "segments that don't fill the film are refused" 1 L "$G/synth-pass.json" "$T/plate.mp4" --cuts "$T/seg-wrong.txt" --xfade 0.4
printf '2.7\n2.7\n' > "$T/seg-ok.txt"
expect "a readable plate on a dark plate passes" 0 L "$G/synth-pass.json" "$T/plate.mp4" --cuts "$T/seg-ok.txt" --xfade 0.4

echo "── story-check (deterministic half)"
SC() { python3 -I "$S/scripts/story-check.py" "$@"; }
expect "rejected greeting fails (storyboard)" 1 SC --brief "$ST/brief-fail.md" --phase storyboard --titles "$ST/titles-fail.json" --script "$ST/script-fail.txt" --prompts "$ST/prompts-fail.txt" --lang nl --no-llm
OUT=$(SC --brief "$ST/brief-fail.md" --phase storyboard --titles "$ST/titles-fail.json" --script "$ST/script-fail.txt" --prompts "$ST/prompts-fail.txt" --lang nl --no-llm)
for r in "FAIL  D1_address" "FAIL  D2_length" "FAIL  D3_repetition" "FAIL  D4_season"; do
  echo "$OUT" | grep -q "$r" && { echo "  ok    reason: $r"; ok=$((ok+1)); } || { echo "  ERROR reason missing: $r"; bad=$((bad+1)); }
done
expect "a clean script without the rubric is INCOMPLETE, never PASS" 3 SC --brief "$ST/brief-pass.md" --phase storyboard --titles "$ST/titles-pass.json" --script "$ST/script-pass.txt" --prompts "$ST/prompts-pass.txt" --no-llm
expect "no LLM reachable = FAIL, not skipped" 1 env STORY_CHECK_LLM=/nonexistent/llm python3 -I "$S/scripts/story-check.py" --brief "$ST/brief-pass.md" --phase storyboard --titles "$ST/titles-pass.json" --script "$ST/script-pass.txt"

echo "── voice-check (list gate, no whisper needed)"
mkdir -p "$T/prod/audio"; printf 'not a voice' > "$T/prod/audio/ref.wav"
cat > "$T/prod/audio/vo.json" <<EOF
{"engine": "elevenlabs eleven_multilingual_v2", "anchor": "ref.wav", "lines": [{"file": "vo/01.wav", "text": "Hello."}]}
EOF
has "a voice that is not on the list fails" "FAIL  list" python3 -I "$S/scripts/voice-check.py" "$T/prod/audio/vo.json"
expect "…and exits 1" 1 python3 -I "$S/scripts/voice-check.py" "$T/prod/audio/vo.json"

echo "── qa-check.sh Extended options (synthetic master)"
ffmpeg -v error -y -f lavfi -i color=c=0x202020:s=1920x1080:d=5:r=25 -f lavfi -i sine=f=330:d=5 -shortest \
  -vf "setparams=colorspace=bt709:color_trc=bt709:color_primaries=bt709:range=tv,format=yuv420p" -c:v libx264 -preset veryfast \
  -c:a aac -metadata comment="AI-generated imagery and voice — Example, EU AI Act art. 50" "$T/master.mp4"
printf '1\n00:00:00,500 --> 00:00:02,400\nAt the top you see three counts.\n\n2\n00:00:02,500 --> 00:00:04,500\nEight out of eight checks.\n' > "$T/good.srt"
printf '1\n00:00:00,500 --> 00:00:01,000\nOne\nTwo\nThree lines and this one is far longer than forty-two characters\n\n2\n00:00:00,800 --> 00:00:02,000\nOverlap.\n' > "$T/bad.srt"
has "subtitles: structure passes"   "PASS  subtitles"  "$S/scripts/qa-check.sh" "$T/master.mp4" --srt "$T/good.srt" --srt-nosync
has "subtitles: structure fails"    "FAIL  subtitles"  "$S/scripts/qa-check.sh" "$T/master.mp4" --srt "$T/bad.srt" --srt-nosync
has "length band 45-90 fails at 5 s" "FAIL  length"    "$S/scripts/qa-check.sh" "$T/master.mp4" --length 45-90
has "length band 3-10 passes at 5 s" "PASS  length"    "$S/scripts/qa-check.sh" "$T/master.mp4" --length 3-10
PYB="${VS_VO_PY:-python3}"
if "$PYB" -c "import numpy, scipy" 2>/dev/null; then
  ffmpeg -v error -y -f lavfi -i "sine=f=220:d=20,volume=0.3" -f lavfi -i "anoisesrc=d=20:c=white:a=0.9,aeval='val(0)*lt(mod(t\,0.05)\,0.0004)':c=same" \
    -filter_complex "[0][1]amix=inputs=2:normalize=0" -ar 48000 "$T/bed.wav"
  has "a clicking music bed fails" "FAIL  bed" env VS_VO_PY="$PYB" "$S/scripts/qa-check.sh" "$T/master.mp4" --bed "$T/bed.wav"
else echo "  skip  music-bed gate (set VS_VO_PY to a python with numpy + scipy)"; skip=$((skip+1)); fi

echo "── $ok ok, $bad errors, $skip skipped"; [ "$bad" = 0 ]
