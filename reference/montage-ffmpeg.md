# Montage & audio (ffmpeg) — video-studio

Proven recipes + gotchas from real trailer production. Applies to both modes (AI shots and existing clips both end up here).

## Workflow
1. Per shot: render the graded video separately.
2. Build audio separately (music bed + synth SFX).
3. **Mux decoupled** with `-c:a copy`.
4. Inspect frames (`ffmpeg -ss <t> -frames:v 1 out.png`) — never assume "looks done".

## Gotchas (don't rediscover these)
- **Mux audio and video DECOUPLED.** A combined `filter_complex` with video grade + `amix` mysteriously swallows SFX. Render video separately, audio separately, then `-c:a copy`.
- **`amix`**: use `amix=normalize=0`; **no `weights=` with spaces** (breaks parsing). `amix=duration=first` cuts to the shortest → give each segment an audio track, or do audio as one separate track.
- **Synth SFX > AI SFX** for sharp hits (AI produced broad "whoosh" blobs). Logo impact = `sine` (sub-thump) + `anoisesrc` (transient/crack) + `lowpass` rumble + `aecho` (reverb tail), attack at t=0. Place it on the visual hit via `adelay` (offset = sum of segment durations); duplicate with `asplit`.
- **drawtext**: `fontfile=<path>` failed in some builds ("text must be provided") → use **`font=Impact`** (fontconfig). **Commas** in expressions (`alpha='if(lt(t,0.2)...'`) break the filtergraph → avoid or escape.
- **zsh pitfall**: `"[0:v]$GRADE[v]"` → zsh reads `$GRADE[v]` as an array subscript ("No such filter ''") → write **`${GRADE}[v]`**.
- **FX overlays generated on pure BLACK** → composite with `blend=all_mode=screen` (black→transparent) or `lumakey`. Flash-cut: `fade=t=in:d=0.06:color=white` per segment. Camera shake: `crop` with `sin/cos(t)`.
- **Let the logo move independently** from the bg: separate overlay layer with `scale=eval=frame` (no shake/RGB on the logo → stays sharp).

## Building blocks
```bash
# concat of clips (same codec/dims) via demuxer
printf "file '%s'\n" clip1.mp4 clip2.mp4 > list.txt
ffmpeg -f concat -safe 0 -i list.txt -c copy out.mp4

# trim without re-encode
ffmpeg -ss 00:00:03 -to 00:00:09 -i in.mp4 -c copy cut.mp4

# crossfade between two clips (xfade) + audio (acrossfade)
ffmpeg -i a.mp4 -i b.mp4 -filter_complex \
  "[0:v][1:v]xfade=transition=fade:duration=0.5:offset=4[v];[0:a][1:a]acrossfade=d=0.5[a]" \
  -map "[v]" -map "[a]" out.mp4

# music bed + synth impact, decoupled mux
ffmpeg -i video_graded.mp4 -i bed.wav -i impact.wav -filter_complex \
  "[1:a][2:a]amix=inputs=2:normalize=0[a]" -map 0:v -map "[a]" -c:v copy -shortest final.mp4
```

## Scale to the request
Social clip (9:16) ≠ cinematic (2.39:1) ≠ web trailer (16:9). Choose the aspect for the destination; for vertical: `crop`/`pad` or generate keyframes already in 9:16. Also deliver a poster frame (`-ss`).
