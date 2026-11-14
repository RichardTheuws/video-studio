#!/usr/bin/env bash
# qa-check.sh — the skill's measurable QA thresholds as a gate.
# Source of the thresholds: commercial-craft.md §5/§7, directing.md §6, lessons.md (colour tags 2026-06-26, file size
# 2026-07-20, loudness within a series 2026-08-20). This does NOT replace the frame strip — it catches what a strip can't show.
#
#   qa-check.sh <deliverable.mp4> [options]
#     --expect <s>        expected duration (±0.5 s; ±1.0 with --social)     --cuts <cutlengths.txt>  one cut length (s) per line
#     --clips <dir>       individual shots: measure dead cuts (motion energy) --social                 messenger-shareable: ≤ 16 MB, −14 LUFS
#     --lufs <target>     loudness target (default −16; --social sets −14)   --genre teaser|explainer mean shot length < 3.0 s for a teaser
#     --titles <spec.json> reading time per title from the HyperFrames spec: ≥ max(1.5 s; characters ÷ 15) (scenario.md S-A05)
#   Exit 0 = every check PASS. Every FAIL names the measurement and the rule it comes from.
set -uo pipefail
F="${1:?usage: qa-check.sh <deliverable.mp4> [--expect s] [--cuts f] [--clips dir] [--social] [--lufs n] [--genre teaser|explainer] [--titles spec.json]}"; shift
EXPECT=""; CUTS=""; CLIPS=""; TITLES=""; SOCIAL=0; LUFS=-16; LUFS_SET=0; GENRE="explainer"
while [ $# -gt 0 ]; do case "$1" in
  --expect) EXPECT="${2:?--expect needs a value}"; shift 2;; --cuts) CUTS="${2:?--cuts needs a file}"; shift 2;; --clips) CLIPS="${2:?--clips needs a dir}"; shift 2;;
  --social) SOCIAL=1; shift;; --lufs) LUFS="${2:?--lufs needs a value}"; LUFS_SET=1; shift 2;; --genre) GENRE="${2:?--genre needs a value}"; shift 2;; --titles) TITLES="${2:?--titles needs a spec.json}"; shift 2;;
  *) echo "unknown option $1" >&2; exit 2;; esac; done
[ "$SOCIAL" = 1 ] && [ "$LUFS_SET" = 0 ] && LUFS=-14   # --social implies −14 unless --lufs was given explicitly
[ -f "$F" ] || { echo "ERROR: $F does not exist" >&2; exit 2; }
fail=0; pass(){ printf '  PASS  %-18s %s\n' "$1" "$2"; }; failm(){ printf '  FAIL  %-18s %s\n' "$1" "$2"; fail=1; }

echo "── qa-check: $F"
IFS=',' read -r W H SAR PIX CS CT CP FPS <<<"$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,sample_aspect_ratio,pix_fmt,color_space,color_transfer,color_primaries,r_frame_rate -of csv=p=0 "$F")"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$F"); SIZE=$(stat -f %z "$F" 2>/dev/null || stat -c %s "$F")
MB=$(awk -v s="$SIZE" 'BEGIN{printf "%.1f", s/1048576}')

# 1. format + aspect (lessons 2026-07-10: SAR≠1:1 = stretched; 2026-06-25: never a flat scale)
case "${W}x${H}" in 1920x1080|1080x1920|3840x2160|2160x3840|1080x1080) pass format "${W}×${H}";; *) failm format "${W}×${H} is not a 16:9/9:16/1:1 master";; esac
case "$SAR" in 1:1|N/A|0:1) pass SAR "${SAR}";; *) failm SAR "$SAR ≠ 1:1 → the image is stretched (lessons 2026-07-10)";; esac
[ "$PIX" = "yuv420p" ] && pass pix_fmt "$PIX" || failm pix_fmt "$PIX — xfade upcast to 444? add format=yuv420p (lessons 2026-06-26)"
# 2. colour tags (lessons 2026-06-26: all three bt709, otherwise 'wrong colours' in SDR players)
if [ "$CS" = bt709 ] && [ "$CT" = bt709 ] && [ "$CP" = bt709 ]; then pass "colour tags" "bt709/bt709/bt709"
else failm "colour tags" "space=$CS transfer=$CT primaries=$CP — end every graph with setparams=colorspace=bt709:color_trc=bt709:color_primaries=bt709:range=tv (lessons 2026-06-26)"; fi
# 3. duration (lessons 2026-07-16: a runaway duration = a broken encode)
if [ -n "$EXPECT" ]; then tol=$([ "$SOCIAL" = 1 ] && echo 1.0 || echo 0.5)
  awk -v a="$DUR" -v b="$EXPECT" -v t="$tol" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d<=t)}' && pass duration "${DUR}s (expected ${EXPECT}±${tol})" || failm duration "${DUR}s, expected ${EXPECT}±${tol} s"
else awk -v a="$DUR" 'BEGIN{exit !(a>=3 && a<=600)}' && pass duration "${DUR}s (no --expect; 3–600 s)" || failm duration "${DUR}s outside 3–600 s"; fi
# 4. file size (lessons 2026-07-20: a social clip that doesn't fit through a messenger isn't finished)
if [ "$SOCIAL" = 1 ]; then awk -v m="$MB" 'BEGIN{exit !(m<=16)}' && pass size "${MB} MB (≤16 MB social)" || failm size "${MB} MB > 16 MB — CRF 25–26 for social (lessons 2026-07-20)"
else bitrate=$(awk -v s="$SIZE" -v d="$DUR" 'BEGIN{printf "%.1f", s*8/d/1e6}'); awk -v b="$bitrate" 'BEGIN{exit !(b<=25)}' && pass size "${MB} MB, ${bitrate} Mbit/s" || failm size "${MB} MB, ${bitrate} Mbit/s > 25 — too heavy for web delivery"; fi
# 5. loudness (commercial-craft §5: −14 social / −16 YouTube, peak −1 dBTP; montage-ffmpeg: equal within a series)
if ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "$F" | grep -q audio; then
  EB=$(ffmpeg -v info -nostats -i "$F" -af ebur128=peak=true -f null - 2>&1 | awk '/Integrated loudness/{f=1} f&&/I:/{i=$2} /True peak:/{p=1} p&&/Peak:/{tp=$2} END{print i, tp}')
  read -r I TP <<<"$EB"
  awk -v i="$I" -v t="$LUFS" 'BEGIN{d=i-t; if(d<0)d=-d; exit !(d<=1.5)}' && pass loudness "${I} LUFS (target ${LUFS}±1.5)" || failm loudness "${I} LUFS, target ${LUFS}±1.5 — loudnorm=I=${LUFS}:TP=-1 on the MASTER, trace it back (montage-ffmpeg.md)"
  awk -v p="$TP" 'BEGIN{exit !(p<=-1.0)}' && pass "true peak" "${TP} dBTP" || failm "true peak" "${TP} dBTP > −1 — clips on phones"
else failm audio "no audio track"; fi
# 6. rhythm from the cut list (directing.md §6: mean < 3.0 s for a teaser, spread > 0.6 s)
if [ -n "$CUTS" ] && [ -f "$CUTS" ]; then
  read -r N M SD <<<"$(awk 'NF{s+=$1; a[++n]=$1} END{if(!n){print "0 0 0"; exit} m=s/n; for(i=1;i<=n;i++) v+=(a[i]-m)^2; printf "%d %.2f %.2f", n, m, sqrt(v/n)}' "$CUTS")"
  if [ "$N" = 0 ]; then failm "shot length" "no cut lengths in $CUTS"; else
  lim=$([ "$GENRE" = teaser ] && echo 3.0 || echo 4.0)
  awk -v m="$M" -v l="$lim" 'BEGIN{exit !(m<l)}' && pass "shot length" "$N shots, mean ${M}s (< ${lim})" || failm "shot length" "mean ${M}s ≥ ${lim} — clips used 1-to-1? (directing.md §3, pick-window.sh)"
  awk -v s="$SD" 'BEGIN{exit !(s>0.6)}' && pass spread "${SD}s (> 0.6)" || failm spread "${SD}s ≤ 0.6 — a metronome, not directing (directing.md §6)"
  fi
fi
# 7. dead cuts (directing.md §2: motion energy < 0.5 = practically a still)
if [ -n "$CLIPS" ] && [ -d "$CLIPS" ]; then dead=""
  for c in "$CLIPS"/*.mp4; do [ -f "$c" ] || continue
    e=$(ffmpeg -v error -i "$c" -vf "scale=160:90,tblend=all_mode=difference,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-" -f null - 2>/dev/null | awk -F= '/YAVG/{s+=$2;n++} END{if(n) printf "%.2f", s/n; else print "0"}')
    awk -v e="$e" 'BEGIN{exit !(e<0.5)}' && dead="$dead $(basename "$c")=$e"
  done
  [ -z "$dead" ] && pass "dead cuts" "no shot below 0.5" || failm "dead cuts" "shots below 0.5:$dead — failed i2v → redraw the keyframe (directing.md §2); a deliberate static hold (UI/card, commercial-craft §0.5) is fine, just keep it out of --clips"
fi
# 8. title reading time (scenario.md S-A05: Mayer/Szarkowska — ≤ 15 characters/s, at least 1.5 s; sound-off reads slower)
if [ -n "$TITLES" ]; then
  if [ ! -f "$TITLES" ]; then failm "reading time" "spec $TITLES does not exist"
  else LT=$(python3 -I - "$TITLES" <<'PY'
import json, sys
try:
    items = json.load(open(sys.argv[1])).get("items", [])
except Exception as e:
    print("ERR unreadable spec: %s" % e); sys.exit(0)
bad = []; n = 0
for i, it in enumerate(items):
    if it.get("kind") == "ailabel": continue            # legal label, not reading text
    parts = [it.get(k) for k in ("kicker", "head", "text", "typed", "knew")]
    foot = it.get("foot") or []
    parts += foot if isinstance(foot, list) else [foot]
    txt = " ".join(str(p) for p in parts if p).replace("*", "").replace("\n", " ")
    chars = len(" ".join(txt.split()))
    if not chars or "in" not in it or "out" not in it: continue
    n += 1; dur = float(it["out"]) - float(it["in"]); need = max(1.5, chars / 15.0)
    if dur + 1e-6 < need:
        bad.append("#%d %s %d chars in %.1fs (needs %.1fs)" % (i, it.get("kind", "?"), chars, dur, need))
print("OK %d" % n if not bad else "BAD " + "; ".join(bad))
PY
)
    case "$LT" in OK*) pass "reading time" "${LT#OK } titles ≥ chars÷15 and ≥ 1.5 s";; ERR*) failm "reading time" "${LT#ERR }";; *) failm "reading time" "${LT#BAD } — hold longer or shorten the line (scenario.md S-A05)";; esac
  fi
fi
# 9. AI label in the metadata (EU AI Act art. 50): the visible label on the end card is a visual check; this is the machine-readable half
CM=$(ffprobe -v error -show_entries format_tags=comment -of csv=p=0 "$F")
shopt -s nocasematch; case "$CM" in *AI-gegenereerd*|*AI-generated*|*"Made with AI"*|*"Gemaakt met AI"*|*"AI Act"*) pass "AI label" "metadata: ${CM:0:60}";; *) failm "AI label" "no AI marking in the metadata — encode with -metadata comment=\"AI-generated imagery — <brand>, EU AI Act art. 50\" (montage-ffmpeg.md)";; esac; shopt -u nocasematch
echo "──"; [ "$fail" = 0 ] && { echo "QA: PASS"; exit 0; } || { echo "QA: FAIL — do not deliver (commercial-craft.md §7)"; exit 1; }
