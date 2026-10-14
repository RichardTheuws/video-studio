#!/bin/bash
# pick-window.sh — pick the STRONGEST window from an i2v clip.
#
# i2v clips (Veo/Kling) almost always have a dead run-up (the keyframe is still static)
# and a decay at the end (drift, morphing hands). Dropping them 1:1 into the edit is
# why a film feels slow. This measures motion energy per frame and returns the best
# start time for a window of the requested length.
#
#   pick-window.sh clip.mp4 2.5                 -> "ss=1.20 (motion 4.81, clip 6.00s, window 2.5s)"
#   pick-window.sh clip.mp4 2.5 --cut out.mp4   -> also cuts that window out right away
#
set -uo pipefail
CLIP="${1:?usage: pick-window.sh <clip.mp4> <window-sec> [--cut <out.mp4>]}"
LEN="${2:?window length in seconds}"
DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$CLIP")
FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=nw=1:nk=1 "$CLIP" | awk -F/ '{printf "%.4f", $1/($2?$2:1)}')

# motion energy per frame: difference image -> mean luma
# metadata=print writes to the LOG (info level) -> with -v error you'd see nothing.
# file=- sends it to stdout; that's the reliable form.
MOT=$(ffmpeg -v error -i "$CLIP" -vf "scale=160:90,tblend=all_mode=difference,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-" -f null - 2>/dev/null \
      | awk -F= '/YAVG/{print $2}')
N=$(echo "$MOT" | grep -c .)
[ "$N" -lt 4 ] && { echo "ss=0 (too few frames measured)"; exit 0; }

read -r BEST_SS BEST_SC <<<"$(echo "$MOT" | awk -v fps="$FPS" -v len="$LEN" -v n="$N" '
  {m[NR]=$1}
  END{
    w=int(len*fps); if(w<1)w=1; if(w>=n){printf "0.00 %.3f", 0; exit}
    # the first 0.4 s count half: the keyframe is often still static there
    skip=int(0.4*fps)
    s=0; for(i=1;i<=w;i++) s+=m[i]
    best=-1; bi=1
    for(i=1;i+w-1<=n;i++){
      if(i>1) s += m[i+w-1]-m[i-1]
      pen = (i<=skip) ? 0.5 : 1.0
      v = (s/w)*pen
      if(v>best){best=v; bi=i}
    }
    printf "%.2f %.3f", (bi-1)/fps, best
  }')"

printf 'ss=%s (motion %s, clip %.2fs, window %ss)\n' "$BEST_SS" "$BEST_SC" "$DUR" "$LEN"

if [ "${3:-}" = "--cut" ]; then
  OUT="${4:?give an output file}"
  ffmpeg -y -v error -ss "$BEST_SS" -t "$LEN" -i "$CLIP" -c:v libx264 -crf 18 -pix_fmt yuv420p -an "$OUT"
  echo "  -> $OUT"
fi
