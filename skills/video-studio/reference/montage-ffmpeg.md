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

## Encoder — measured, not assumed (audit 2026-11-08)
Measured on a 19 s 1080p master (Apple Silicon, ffmpeg 8.1.2), SSIM against the master:

| encoder | time | size | SSIM |
|---|---:|---:|---:|
| libx264 `-preset slow -crf 18` (master) | 5.8 s | 26.5 MB | 0.99998 |
| libx264 `-preset medium -crf 18` | 4.0 s | 26.7 MB | 0.99998 |
| libx264 `-preset veryfast -crf 20` | **1.3 s** | 19.3 MB | 0.99994 |
| h264_videotoolbox `-q:v 65` | 1.8 s | 28.1 MB | 0.99879 |
| hevc_videotoolbox `-q:v 65` | 1.9 s | 20.7 MB | 0.99892 |

**Verdict: hardware encoding (VideoToolbox) is KILL for this studio** — slower *and* worse than `libx264 -preset veryfast`,
and a master encode of a half-minute film takes seconds anyway. Rules: masters `libx264 -preset slow -crf 18`
(social: crf 25–26, see "Encode and delivery" below); previews, QA strips and intermediates `-preset veryfast -crf 20`. End every
graph with `setparams=colorspace=bt709:color_trc=bt709:color_primaries=bt709:range=tv` and put
`-metadata comment="AI-generated imagery — <brand>, EU AI Act art. 50"` on every master that contains AI imagery or audio
(`scripts/qa-check.sh` checks both). ffmpeg 9.0.2: xfade+settb, the ProRes 4444 overlay, tblend/signalstats, ebur128 and
pango→magick→overlay were all re-tested after the upgrade — no change.

## Pitfalls from the log (ffmpeg) — consolidated 2026-11-08
Every line below comes from a real production; the date is the day it went wrong. Details and measurements: `lessons.md` (index).

### Timebase, xfade and duration
- **Pin every input before `xfade`/concat with `fps=24,setsar=1,settb=1/24,setpts=PTS-STARTPTS`** — not only settb. Errors otherwise: `timebase 1/12288 do not match 1/12800`, `frame rate 24 do not match 25`, empty output with `-22 Invalid argument` (2026-07-12); a leader/outro with 96 kHz audio inherits an odd timebase (2026-07-10).
- **Concat demuxer with `-c copy` over separately encoded segments, then `xfade`, silently truncates the film** (26 s where 58 s was due, 2026-08-21). Always re-encode segments for an xfade chain with the same `-r`/`-pix_fmt`.
- **`zoompan` on a looping still inflates the duration**: `d` counts per *input* frame, so 3 s×25 fps×d=72 → 5400 frames = 207 s (2026-07-12). Zoompan is banned anyway (Ken Burns); a hold is `-loop 1` + fade.
- **Put `-framerate <target>` before every `-loop 1` image input**, otherwise a 25 fps input and a clip that quietly gets shorter (3.07 s instead of 6 s), shifting the whole chain forward; `format=duration` still looks right, `-ss` past the real end gives "Output file is empty" (2026-07-08). Debug a chain per building block with `-show_entries stream=duration`.
- **Reading a frame sequence faster (`-framerate 63 … fps=30`) drops frames = judder**, immediately visible on CG without motion blur (2026-07-20). Re-render at the shorter duration; `ffprobe -count_frames` must return the number of PNGs.
- **Playwright webm files carry timestamps ffmpeg mis-scales**: with `overlay=…:shortest=0` every segment became 33.4× too long (218 s instead of 6.5 s) and the final duration was *still* right, because the xfade chain cuts at fixed offsets; only the seams carried grain (2026-09-22). Three locks: `-fflags +genpts` on the webm, `shortest=1` on every overlay, `-t "$dur"` on the output, plus a guard comparing segment duration with the requested one.

### Stills, overlays and the filtergraph
- **A PNG input without `-loop 1` is one frame at t=0**: an alpha fade with `st>0` makes the title permanently invisible and the render "works" (2026-06-24, 07-08, 07-10). Always `-loop 1 -framerate N -i title.png`, end-bounded with `overlay=…:shortest=1` or an output `-t`. Without a bound a 9:16 preview became 2888 s / 48 min (2026-07-16).
- **Position expressions (`y=f(t)`) do work on a still**; only filter animations on the overlay input itself don't (2026-06-24).
- **A PNG sequence as an extra input breaks the `enable` timing of other overlays** (2026-08-13): bake the second layer into the sequence; note that `-framerate N -i seq_%03d.png` counts as one input.
- **A `#` comment inside a `filter_complex` string silently breaks the graph** (title hundreds of pixels below the frame, exit 0; 2026-08-13). Commas in expressions (`clip(a,b,c)`, `min(a,b)`) break an inline graph: escape as `\,` or use `-filter_complex_script file` (2026-06-24, 07-01). `gblur` has no per-frame `sigma`.
- **`crop=…:eval=frame` does not exist in the Homebrew build** (2026-07-01): animate with an `overlay` expression or an alpha `fade`.
- **No grade/vignette/grain over light typographic end cards**: white goes grey. Grade the chain up to the last footage clip, xfade the end card in afterwards (2026-07-08).

### Colour
- **An HDR source (phone 4K: `yuv420p10le`, `bt2020nc`, `smpte2084`/`arib-std-b67`) leaks its tags into the output** → SDR players show everything oversaturated, a muted blue goes electric while the hex is right (2026-06-26). Detect per source (`color_transfer ∈ {smpte2084, arib-std-b67}`), tonemap only HDR sources: `zscale=t=linear:npl=100,tonemap=hable,zscale=t=bt709:m=bt709:p=bt709:r=tv,format=yuv420p`. Needs zscale → `brew install ffmpeg-full` (keg-only, binary `/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg`); the `colorspace` filter has no `itrc=smpte2084`.
- **Forcing colour tags with CLI flags alone fails** and `xfade` silently upcasts to `yuv444p`: end every graph with `setparams=colorspace=bt709:color_primaries=bt709:color_trc=bt709:range=tv,format=yuv420p` and verify all three tags with ffprobe (`qa-check.sh` does). A delivered client video sat on `unknown/unknown/bt709` (2026-11-08).
- **Never `blend=all_mode=screen` directly on yuv420p** — chroma gets screened too, magenta cast. Both streams `format=gbrp`, blend, back to `format=yuv420p` (2026-07-19).
- **A cross-dissolve between a card and a screen recording hisses** (~0.45 s of grain over the app window, six times in one film; 2026-09-22): at ~50 % mix the webm's VP8 artefacts are relatively twice as strong. Shorter mixing doesn't help. `xfade=fadeblack` and a hard cut are both clean. Segment type changes → dip-to-black or cut.

### Encode and delivery
- **Deliver social at a shareable size**: CRF 19 at 1080×1920 gave 27 MB for 11 s; CRF 26 (teasers) / 25 (master) → 2.4–2.9 MB resp. 17 MB with no visible loss on a phone (2026-07-20). If it doesn't fit through WhatsApp (≤ 16 MB) it isn't finished. A delivered 9:16 sat at 19.7 MB (2026-11-08).
- **No `fade=t=in` on frame 0 of a clip shown as an embed**: frame 0 is the thumbnail and goes black (2026-07-29).
- Source orientation: phone video is often `1920x1080` + `rotation=-90` → displays 1080×1920; `scale=1920:1080` stretches people wide (2026-06-25). Check `stream_side_data=rotation`; 9:16 is then native, 16:9 via `landscape-from-vertical.md`.

### Audio and voice
- **Normalise the bed at the level the FILM must reach**, and trace any `volume=` step in the montage back: a bed at `loudnorm=I=-20` gave a −20.7 LUFS film (2026-09-22); ep2 at −19.6 against ep1 at −15.4 (2026-08-20, above).
- **Music bed longer than 190 s**: stable-audio-25 cap (`seconds_total>190` → 422 `le: 190`); two generations joined with `acrossfade=d=8` on the act break (2026-07-20).
- **VO**: measure the length before you time the shot list — two lines of 11 s and 5.5 s did not fit beats of 8 and 4 s (2026-08-21). If the VO gets replaced during the edit: let the build read `vo.json`, measure wav durations with ffprobe, derive all title/chapter times from the offsets, record captures with ~1.5 s of slack, and check the mtime of vo.json before the final render (2026-11-01). ElevenLabs `speed` ~0.85 with pauses; longer and calm beats rushed (2026-07-07). Local TTS (~25 s per take on Apple Silicon): generate a third of the take grid first across all lines, measure, then top up only the lines without a PASS (2026-11-03).
- The model cannot hear audio: deliver a bed with the caveat "not heard, replaceable", never as finished (2026-07-07); measure instead (section above).

### Building frame strips
- **`magick montage` demands a font, even without labels** (`unable to read font ''`, also with `-font Helvetica`; 2026-07-09, 07-20, 08-10). Build grids with `magick <files> -resize WxH! +append` per row and `-append` across rows, or `tile=` in ffmpeg (`-frames:v 1` when there are more frames than tiles). Labelling with `drawtext` is impossible (missing); compute timecodes from `fps=` or label with magick.
