# Montage & audio (ffmpeg) — video-studio

Proven recipes + gotchas from real trailer production (~37s hype trailer for ~€17). Applies to both modes (AI shots and existing clips both end up here).

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

## Music bed — measure it, don't listen for it

You can't listen to audio. So never claim a bed is "more upbeat" or "faster";
measure it and compare against a reference. Three measures are enough, and they only need numpy/scipy:

```python
# brightness = spectral centroid (Hz) | onsets/s = peaks in the spectral flux
# >2kHz share = energy above 2 kHz (distortion, cymbals and brass live there)
S = |rfft(frames * hanning)| ; centroid = (S*freqs).sum()/S.sum()
flux = max(diff(S, axis=0), 0).sum(axis=1) ; peaks via find_peaks(height=0.6, distance=0.12s)
```

Three rules, all three measured on a real episodic series:

1. **Never reuse the bed from a previous episode.** What a series shares is the *attitude*
   of the music, not the recording. The same track under different footage reads as the same film.
2. **Asking for upbeat is not getting upbeat.** Two consecutive attempts ("lazy shuffle",
   "surf punk") measured practically identical to the existing bed — brightness 2532 vs 2524 Hz,
   and even *fewer* onsets per second. So pull **3 variants** with clearly different
   instrumentation and choose on the measurement:

   | variant | brightness | onsets/s | >2 kHz |
   |---------|-----------:|---------:|-------:|
   | existing bed (bossa) | 2524 Hz | 4.36 | 43.6% |
   | pop punk | 2493 Hz | 4.04 | 45.2% |
   | **ska punk + brass** | **2931 Hz** | **5.06** | **54.3%** |
   | surf punk | 2792 Hz | 4.68 | 50.3% |

   Costs three cheap generations and replaces a guess with a choice.
3. **Match loudness across a series.** Measure `ffmpeg -i out.mp4 -af ebur128 -f null -`
   on *every* episode. Ep2 came out at **-19.6 LUFS** against ep1 at **-15.4** — 4 dB weaker, and
   you hear that immediately when they play back to back. Work back from the master: if there's still a
   `volume=0.85` in the montage, that's -1.4 dB, so `loudnorm=I=-14` delivers -15.4.
   A `loudnorm` target you don't trace back to the master is a target for the wrong file.

## Scale to the request
Social clip (9:16) ≠ cinematic (2.39:1) ≠ web trailer (16:9). Choose the aspect for the destination; for vertical: `crop`/`pad` or generate keyframes already in 9:16. Also deliver a poster frame (`-ss`).
