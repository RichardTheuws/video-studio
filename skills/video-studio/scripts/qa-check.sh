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
#     --beats <music>[@offset]  MEASURES (not a gate) for each cut from --cuts the distance to the nearest beat, in frames;
#                         offset = where the bed starts in the film (s, default 0). Beats from the bare bed, not the mix
#                         (ticks/stings are no beat). Cutting on the beat is style without a measured effect (scenario.md),
#                         so this is the honest note from commercial-craft.md §7 point 5, not a PASS/FAIL.
#     --bed <bed.wav>     GATE: audible clicks in the music bed as it goes into the mix (≤ 200/min, scripts/vo/clean.py --bed)
#     --length <min-max>  the duration must fall inside the band (Extended: 45-90, reference/extended.md; 90 s is a hard cap)
#     --srt <file.srt>    subtitles (Extended): ≤ 2 lines, ≤ 42 characters/line, ≥ 1.0 s, ≤ 17 characters/s, no overlap, and SYNC:
#                         mlx-whisper on the audio track, first word per cue within ±0.6 s, median ≤ 0.25 s, ≥ 80% found.
#                         No mlx-whisper = FAIL (never skipped silently); structure only: --srt-nosync.
#                         Language for the sync: env VO_LANG (default en). Python with mlx-whisper: env VS_VO_PY.
#   Exit 0 = every check PASS. Every FAIL names the measurement and the rule it comes from.
set -uo pipefail
F="${1:?usage: qa-check.sh <deliverable.mp4> [--expect s] [--cuts f] [--clips dir] [--social] [--lufs n] [--genre teaser|explainer] [--titles spec.json] [--beats music.wav[@offset]] [--bed bed.wav] [--length min-max] [--srt f.srt] [--srt-nosync]}"; shift
EXPECT=""; CUTS=""; CLIPS=""; TITLES=""; BEATS=""; BED=""; LENGTH=""; SRT=""; SRTSYNC=1; SOCIAL=0; LUFS=-16; LUFS_SET=0; GENRE="explainer"
while [ $# -gt 0 ]; do case "$1" in
  --expect) EXPECT="${2:?--expect needs a value}"; shift 2;; --cuts) CUTS="${2:?--cuts needs a file}"; shift 2;; --clips) CLIPS="${2:?--clips needs a dir}"; shift 2;;
  --social) SOCIAL=1; shift;; --lufs) LUFS="${2:?--lufs needs a value}"; LUFS_SET=1; shift 2;; --genre) GENRE="${2:?--genre needs a value}"; shift 2;; --titles) TITLES="${2:?--titles needs a spec.json}"; shift 2;; --beats) BEATS="${2:?--beats needs an audio file}"; shift 2;;
  --bed) BED="${2:?--bed needs the bed as mixed}"; shift 2;; --length) LENGTH="${2:?--length needs min-max}"; shift 2;; --srt) SRT="${2:?--srt needs a file}"; shift 2;; --srt-nosync) SRTSYNC=0; shift;;
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
    parts = [it.get(k) for k in ("kicker", "head", "text", "typed", "knew", "num", "noemer", "label")]   # "bron" doesn't count: metadata, not reading text
    for k in ("foot", "lines"):                          # card foot and credit lines count
        v = it.get(k) or []
        parts += v if isinstance(v, list) else [v]
    txt = " ".join(str(p) for p in parts if p).replace("*", "").replace("\n", " ")
    chars = len(" ".join(txt.split()))
    if not chars or "in" not in it or "out" not in it: continue
    n += 1; dur = float(it["out"]) - float(it["in"])
    need = max(1.0, chars / 17.0) if it.get("kind") == "sub" else max(1.5, chars / 15.0)   # a subtitle follows the speech: 17 chars/s, min 1.0 s
    if dur + 1e-6 < need:
        bad.append("#%d %s %d chars in %.1fs (needs %.1fs)" % (i, it.get("kind", "?"), chars, dur, need))
print("OK %d" % n if not bad else "BAD " + "; ".join(bad))
PY
)
    case "$LT" in OK*) pass "reading time" "${LT#OK } titles ≥ chars÷15 and ≥ 1.5 s";; ERR*) failm "reading time" "${LT#ERR }";; *) failm "reading time" "${LT#BAD } — hold longer or shorten the line (scenario.md S-A05)";; esac
  fi
fi
# 8b. beat distance of the cuts (a measurement, not a gate — see header). Engine: `hyperframes beats` of the pinned version, local.
if [ -n "$BEATS" ]; then
  BF="${BEATS%@*}"; BOFF=0; [ "$BF" != "$BEATS" ] && BOFF="${BEATS##*@}"
  if [ ! -f "$BF" ]; then failm beats "music $BF does not exist"
  elif [ -z "$CUTS" ] || [ ! -f "$CUTS" ]; then failm beats "--beats needs --cuts (the cut points)"
  else
    BW=$(mktemp -d); cp "$BF" "$BW/"; BN=$(basename "$BF"); BD=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$BF")
    printf '<!doctype html><html><body><div id="root" data-composition-id="main" data-start="0" data-duration="%s" data-width="1920" data-height="1080"><audio id="music" data-timeline-role="music" src="%s" data-start="0" data-duration="%s" data-track-index="0"></audio></div></body></html>' "$BD" "$BN" "$BD" > "$BW/index.html"
    ( cd "$BW" && HYPERFRAMES_NO_TELEMETRY=1 HYPERFRAMES_NO_UPDATE_CHECK=1 npx --yes hyperframes@0.8.99 beats . --json >/dev/null 2>&1 )
    BJ=$(ls "$BW"/beats/*.json 2>/dev/null | head -1)
    if [ -z "$BJ" ]; then failm beats "beat detection returned nothing (node ≥ 22 in PATH?)"
    else
      FPSN=$(awk -F/ -v r="$FPS" 'BEGIN{split(r,a,"/"); printf "%.3f", (a[2]?a[1]/a[2]:a[1])}')
      BT=$(python3 -I - "$BJ" "$CUTS" "$BOFF" "$FPSN" <<'PY'
import json, sys
bj, cuts, off, fps = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
b = [x["time"] + off for x in json.load(open(bj))["beats"]]
lens = [float(l) for l in open(cuts) if l.strip()]
pts, t = [], 0.0
for l in lens: t += l; pts.append(t)
if not b: print("no beats found"); sys.exit(0)
fr = [round(min(abs(p - x) for x in b) * fps, 1) for p in pts]
gaps = sorted(b[i+1] - b[i] for i in range(len(b) - 1)); bpm = 60 / gaps[len(gaps)//2] if gaps else 0
print("%d/%d cuts ≤ 2 frames from a beat (~%d BPM) — per cut: %s frames" % (sum(f <= 2 for f in fr), len(fr), round(bpm), ", ".join("%g" % f for f in fr)))
PY
)
      printf '  INFO  %-18s %s\n' beats "$BT"
    fi
    rm -rf "$BW"
  fi
fi
# 3b. length band (Extended, reference/extended.md: 45–90 s, 90 is a hard cap)
if [ -n "$LENGTH" ]; then LMIN=${LENGTH%-*}; LMAX=${LENGTH#*-}
  awk -v a="$DUR" -v lo="$LMIN" -v hi="$LMAX" 'BEGIN{exit !(a>=lo && a<=hi)}' && pass length "${DUR}s within ${LMIN}–${LMAX} s" || failm length "${DUR}s outside ${LMIN}–${LMAX} s (Extended cap, extended.md §1)"
fi
# 8c. subtitles: structure + sync against the real speech (extended.md §4)
if [ -n "$SRT" ]; then
  if [ ! -f "$SRT" ]; then failm subtitles "$SRT does not exist"
  else
    ST=$(python3 -I - "$SRT" <<'PY'
import re, sys
raw = open(sys.argv[1], encoding="utf-8").read().replace("\r", "")
def t(x): h, m, r = x.split(":"); s, ms = r.split(","); return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000
cues, bad = [], []
for blk in [b for b in raw.strip().split("\n\n") if b.strip()]:
    ls = blk.strip().split("\n")
    m = re.match(r"(\d\d:\d\d:\d\d,\d{3}) --> (\d\d:\d\d:\d\d,\d{3})", ls[1] if len(ls) > 1 else "")
    if not m: bad.append("unreadable cue: %r" % ls[:2]); continue
    a, b, txt = t(m.group(1)), t(m.group(2)), ls[2:]
    cues.append((a, b, txt)); chars = len(" ".join(txt)); d = b - a
    if len(txt) > 2: bad.append("%.1fs: %d lines" % (a, len(txt)))
    if any(len(l) > 42 for l in txt): bad.append("%.1fs: line > 42 characters" % a)
    if d < 1.0 - 1e-6: bad.append("%.1fs: %.2f s < 1.0" % (a, d))
    if chars / max(d, 0.01) > 17.0 + 1e-6: bad.append("%.1fs: %.1f characters/s > 17" % (a, chars / d))
for (a1, b1, _), (a2, b2, _) in zip(cues, cues[1:]):
    if a2 < b1 - 1e-6: bad.append("overlap at %.1fs" % a2)
print(("OK %d cues" % len(cues)) if not bad else "BAD " + "; ".join(bad[:6]))
PY
)
    case "$ST" in OK*) pass subtitles "${ST#OK } — ≤2 lines, ≤42 chars, ≥1.0 s, ≤17 chars/s";; *) failm subtitles "${ST#BAD }";; esac
    if [ "$SRTSYNC" = 1 ]; then
      PYW="${VS_VO_PY:-python3}"
      if ! "$PYW" -c "import mlx_whisper" 2>/dev/null; then failm sync "mlx-whisper not found ($PYW) — set VS_VO_PY (extended.md §5b) or deliberately --srt-nosync"
      else SY=$("$PYW" -I - "$F" "$SRT" "${VO_LANG:-en}" <<'PY'
import re, sys, unicodedata, statistics, mlx_whisper
F, S, LANG = sys.argv[1], sys.argv[2], sys.argv[3]
norm = lambda w: re.sub(r"[^a-z0-9]", "", unicodedata.normalize("NFKD", w.lower()).encode("ascii", "ignore").decode())
def t(x): h, m, r = x.split(":"); s, ms = r.split(","); return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000
cues = []
for blk in open(S, encoding="utf-8").read().strip().split("\n\n"):
    ls = blk.strip().split("\n"); m = re.match(r"(\S+) --> (\S+)", ls[1]); cues.append((t(m.group(1)), " ".join(ls[2:])))
r = mlx_whisper.transcribe(F, path_or_hf_repo="mlx-community/whisper-large-v3-turbo", language=LANG, word_timestamps=True, temperature=0.0)
# whisper pulls the pause before the first word after a silence into that word (a word stamped 27.88–29.00 s while the voice
# starts at 28.78; measured). A word longer than 0.6 s therefore starts at max(start, end − 0.45): the end IS reliable.
words = [(norm(w["word"]), max(w["start"], w["end"] - 0.45) if w["end"] - w["start"] > 0.6 else w["start"])
         for seg in r["segments"] for w in seg.get("words", []) if norm(w["word"])]
found, deltas = 0, []
for a, txt in cues:
    # the REAL first word of the cue (also "so", "in", "8"): comparing a later word with the cue start gives a fixed
    # positive offset (measured: +0.3 to +0.8 s). Found = the nearest match.
    cw = next((norm(x) for x in txt.split() if norm(x)), "")
    cand = [ws - a for wn, ws in words if abs(ws - a) <= 1.5 and cw and (wn == cw or (len(cw) >= 5 and wn[:5] == cw[:5]))]
    best = min(cand, key=abs) if cand else None
    if best is not None: found += 1; deltas.append(abs(best))
share = found / max(len(cues), 1); med = statistics.median(deltas) if deltas else 9; mx = max(deltas) if deltas else 9
ok = share >= 0.8 and med <= 0.25 and mx <= 0.6
print(("OK " if ok else "BAD ") + "%d/%d cues found in the speech, offset median %.2f s, max %.2f s" % (found, len(cues), med, mx))
PY
)
        case "$SY" in OK*) pass sync "${SY#OK }";; *) failm sync "${SY#BAD } — put the cues on the measured VO times (extended.md §4)";; esac
      fi
    fi
  fi
fi
# music bed: audible clicks (a stable-audio bed measured ~2000 clicks per minute; scripts/vo/clean.py)
if [ -n "$BED" ]; then
  BR=$("${VS_VO_PY:-python3}" "$(dirname "$0")/vo/clean.py" --bed "$BED" 2>&1 | tail -1)
  case "$BR" in "BED: PASS"*) pass bed "${BR#BED: PASS — }";; *) failm bed "${BR#BED: FAIL — } — adeclick + lowpass on the bed (extended.md §3)";; esac
fi
# 9. AI label in the metadata (EU AI Act art. 50): the visible label on the end card is a visual check; this is the machine-readable half
CM=$(ffprobe -v error -show_entries format_tags=comment -of csv=p=0 "$F")
shopt -s nocasematch; case "$CM" in *AI-gegenereerd*|*AI-generated*|*"Made with AI"*|*"Gemaakt met AI"*|*"AI Act"*) pass "AI label" "metadata: ${CM:0:60}";; *) failm "AI label" "no AI marking in the metadata — encode with -metadata comment=\"AI-generated imagery — <brand>, EU AI Act art. 50\" (montage-ffmpeg.md)";; esac; shopt -u nocasematch
echo "──"; [ "$fail" = 0 ] && { echo "QA: PASS"; exit 0; } || { echo "QA: FAIL — do not deliver (commercial-craft.md §7)"; exit 1; }
