# Scroll-video — a film played by the scrollbar

**Goal**: one continuous cinematic shot that the visitor plays *themselves* by scrolling, with text landing on top. Not an autoplay background video, not a video with scroll animations around it: the scroll position *is* the timeline. Uses: brand manifesto, founder story, product reveal, landing-page hero.

Proven reference (reverse-engineered 2026-08-01): `frankoonk.com` — 15.04s, 5 scenes, 8.4 screens of scroll. What works there we adopt; where it falls short is listed in §6 as a **hard requirement**.

> **Exception to the canon — read this first.** `lessons.md` forbids Ken Burns and unnecessary motion, and `commercial-craft.md` makes the **locked-off camera** the default. That still holds for every normal shot. Scroll-video is the explicit exception: here the camera move **is** the content — the user drives it, and a still camera makes the product pointless. The exception covers only the one continuous main move. Individual elements, titles and UI mocks in the same film stay still. Never add motion "on top"; there is exactly one move, and the user holds it.

---

## 1. The four layers

```
.stage             height: calc(var(--app-height) * (1 + N))   ← N ≈ 7.4 screens of scroll room
 └ .viewport       position: sticky; top: 0                    ← stays put; scroll scrubs time
    ├ <video>      object-fit: cover, muted, playsinline        ← the film
    ├ .grade       gradient overlay                             ← text legibility
    ├ <canvas>     optional FX layer (particles/ambient)
    └ <section>×N  REAL HTML text, absolutely positioned        ← SEO + screen reader + selectable
```

**Text stays HTML.** Never burn text into the video. The video is set dressing; the message is DOM. That gives you SEO, accessibility, translatability and crisp brand typography on every screen for free.

---

## 2. The encode — this is where scroll-videos break

Judder while scrubbing doesn't come from JavaScript but from the GOP structure. A normal MP4 has one keyframe every 2–10s; every seek has to go back to that keyframe and decode everything in between. **Solution: all-intra — every frame a keyframe.** A seek then costs exactly one frame of decoding.

```bash
# 16:9 desktop variant (1600×900 is plenty; the image sits behind a grade)
ffmpeg -i master.mov -an \
  -vf "scale=1600:900:flags=lanczos" -r 24 \
  -c:v libx264 -preset slow -crf 22 -profile:v high -pix_fmt yuv420p \
  -x264-params "keyint=1:min-keyint=1:scenecut=0:bframes=0:ref=1" \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -movflags +faststart scroll-desktop.mp4

# 9:16 mobile — ITS OWN RENDER, not a crop (see vertical-916.md)
ffmpeg -i master-916.mov -an \
  -vf "scale=720:1280:flags=lanczos" -r 24 \
  -c:v libx264 -preset slow -crf 24 -profile:v high -pix_fmt yuv420p \
  -x264-params "keyint=1:min-keyint=1:scenecut=0:bframes=0:ref=1" \
  -movflags +faststart scroll-mobile.mp4
```

**Always verify — this is the gate, not optional:**
```bash
# 1. every frame must be a keyframe: both numbers equal
ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of csv=p=0 scroll-desktop.mp4
ffprobe -v error -select_streams v:0 -show_entries frame=pict_type -of csv=p=0 scroll-desktop.mp4 | grep -c '^I'

# 2. no B-frames (must be 0)
ffprobe -v error -select_streams v:0 -show_entries stream=has_b_frames -of csv=p=0 scroll-desktop.mp4

# 3. file budget
ls -lh scroll-*.mp4
```

**Budget — measured, not estimated.** All-intra costs ~8–10× the bitrate of normal H.264. Count on **~1 MB per second** at 900p. Hard limit: **≤ 16 MB desktop / ≤ 9 MB mobile** for a ~15s film.

Calibrated 2026-08-01 (15.04s, 1600×900, 24 fps, all-intra):

| CRF | size | bitrate |
|-----|------|---------|
| 20 | 18.0 MB | 10.0 Mbit/s |
| 22 | 16.4 MB | 9.1 Mbit/s |
| 24 | 14.6 MB | 8.1 Mbit/s |

> These numbers come from re-encoding already-compressed source material; **from a clean master it comes out lower** (the reference hits 15.2 MB at 8.07 Mbit/s). Treat CRF as a knob you tune to the budget: encode, measure, adjust. Don't guess.

If it doesn't fit the budget, shorten the film — not the quality.

> **~1 MB/s holds only for dark, low-detail material.** Verified 2026-08-01 on a proof of concept: a daylight shot with gravel, brickwork and foliage cost **double** at CRF 22 (17s would have been 37 MB). With all-intra, high-frequency texture is the dominant cost — there's no previous frame to reference. Always measure on the actual intended material and tune CRF to it; the same film landed at 15 MB at CRF 26.

### Defocus the foreground — before you composite characters
The cheapest bitrate win is also the better image: put a shallow depth of field on the foreground (gravel, asphalt, grass). On the proof of concept that removed ~35% of the file size and made the image more cinematic.

Two traps, both measured:
1. **Blurring the final frame blurs your character too.** The blur belongs on the background plate, before the character overlay — not at the end of the filtergraph.
2. **A straight crop boundary leaves a visible seam.** Use a feathered mask transition, not a hard `crop` band.

A 30-second scroll-video is a design error, not an encoding problem: 12–18 seconds is the usable range.

**24 fps, not 30 or 60.** Fewer frames = fewer bytes with all-intra, and the weight of 24p reads as film. When scrubbing you don't see frame rate; you see weight.

---

## 3. The scrubber — four measures, all four required

```js
// a) Whole file in memory before start: no range requests while scrubbing.
//    Also feeds the loader percentage. Skip this under prefers-reduced-motion.
const res = await fetch(src);            // stream + count bytes for the progress bar
video.src = URL.createObjectURL(blob);   // blob URL instead of network URL

// b) Frame-rate-independent damping — this makes motion feel "heavy" instead of nervous
applied = target + (applied - target) * SMOOTH ** dt;   // SMOOTH ≈ 0.0012 per second

// c) Seek throttling with a dead zone
const DEADZONE = 1/48;   // half a frame: smaller difference → don't seek
const MIN_GAP  = 180;    // ms between seeks…
const FORCE    = 0.25;   // …unless the lag exceeds this
if (Math.abs(applied - video.currentTime) > DEADZONE) { /* … */ }

// d) One rAF loop with try/catch; on a crash set a marker on <html> instead of freezing
```

Plus: `muted`, `playsInline`, `preload="auto"`, one `play()`+`pause()` after `loadedmetadata` (unlocks seeking on iOS), and a `seeked` listener that tracks whether the previous seek has finished.

**Aspect switch, not crop.** Pick the source by viewport ratio (≤ 0.68 → 9:16) and hot-swap on rotation.

---

## 4. The camera brief — the method

This is the part you design *before* generation, not repair afterwards.

### 4.1 One unbroken move
No cuts. In the reference, the highest scene-change score over 15s is 0.34 — well below a cut. The "scenes" exist only in JavaScript; the viewer sees one journey. **Measure this after generation:**
```bash
ffmpeg -v error -i film.mp4 -vf "select='gt(scene,0.0)',metadata=print:file=-" -f null - 2>/dev/null \
  | paste - - | sed 's/.*pts_time:\([0-9.]*\).*scene_score=\([0-9.]*\)/\1 \2/' | sort -k2 -gr | head
```
Anything above **0.40** is a visible cut → fix it.

### 4.2 Portal chaining
The camera always travels *through* something: through a door, through a screen, past a head, down a corridor. Every environment is entered through a gate. That's how you link separate i2v clips into one journey.

```
space A → [THROUGH the door] → space B → [PAST the back of a head] → space C → [THROUGH the map] → …
```

### 4.3 Occluder joins
Every join falls behind a dark foreground object that fills the frame (door frame, back of a head, server rack, pillar). Direction per clip: **end on an occluder, start behind it.** That's why the cuts are unmeasurable — not a clever crossfade, but composition.

### 4.4 Luminance arc
Design brightness as dramaturgy, and measure it:
```bash
ffmpeg -v error -i film.mp4 -vf "scale=64:36,signalstats,metadata=print:file=-" -f null - 2>/dev/null \
  | grep YAVG
```
Reference: 48 (dark opening) → 103 (light ending) over 15s. Dark→light reads as ascent, light→dark as threat. Don't let it happen by accident.

### 4.5 Keep a text zone free
The composition deliberately keeps a third of the frame empty and dark — that's where the HTML text lands. The grade reinforces it:
```css
/* desktop: text on the left */
.grade { background: linear-gradient(100deg, #04070cdb 0%, #04070c80 34%, transparent 62%) }
/* mobile: text at the bottom → gradient from below */
```
**Put this in the generation prompt** ("left third of frame empty and unlit, subject right of centre"), not in the edit. A scrim pasted over a full frame afterwards costs contrast and reads as patchwork.

### 4.6 Subject on the vanishing line
The subject sits at the vanishing point and stays there. Constant speed, with at most two acceleration peaks at the dramatic moments (measurable as YDIF peaks). The user controls time — a camera that is capricious on top of that becomes unreadable.

### 4.7 Character DNA: the real risk
A continuous journey with a recognizable character is exactly where i2v fails (stylized 3D characters get reinterpreted, and negative prompts don't help — see `lessons.md`, *Image-to-video models*). For a character-driven scroll-video: **validate character consistency on one join before generating the whole journey**, and keep the subtle push-in on an approved keyframe as fallback for shots where the DNA is fixed. Plan on curating over several takes per segment, not on one run.

---

## 5. Progress mapping

```
scroll height = (1 + N) screens          N ≈ 7.4  → ~2 seconds of film per screen
0     → 0.84    video scrubs 0 → end
0.845 → 0.985   outro/CTA slides in
> 0.92          outro becomes interactive (pointer-events)
```
Budget ~1.8–2.0s of film per screen height. Faster feels rushed; slower makes the visitor "push". Scene navigation jumps to `start + (end − start) × 0.34` — the moment the text sits best, not the start of the scene.

---

## 6. Hard requirements — where we go beyond the reference

The reference is clever but not finished. These five are **required**, not optional:

1. **No blocking 15 MB loader.** A visitor watching a percentage for 5 seconds before anything moves is a visitor who leaves. Show the poster frame immediately and become scrubbable once the first ~3s are in, or ship an AV1/HEVC variant via `<source>` (halves the bytes at equal quality) with H.264 as fallback.
2. **No AI artifacts on screen.** The reference shows garbled text ("Pryptos Snlenc-Fi", "400⁄Z") — that falls below the quality bar in `commercial-craft.md`. Text doesn't belong in the i2v generation; it comes as an edit layer or as DOM. Hands, logos and screens that morph: re-roll or frame them out.
3. **Audio.** The reference has no audio track — half the impact is left on the table. A scrub-driven audio bed (or scene-bound stingers on the dramatic peaks) belongs with it. Instrumental beds are fine; no synthetic songs imitating real pop.
4. **`requestVideoFrameCallback`** where available, with the 180ms throttle as fallback. Then you know exactly when a frame was presented instead of guessing.
5. **Brand canon, not generic sci-fi.** Palette, typography and leader come from the brand kit. The UI accent color and the film's grade are one system, not two separate choices.

---

## 7. QA gate (in addition to `commercial-craft.md` §7)

- [ ] I-frames == total frame count; `has_b_frames` = 0
- [ ] desktop ≤ 15 MB, mobile ≤ 9 MB
- [ ] highest scene score < 0.40 (no visible cut)
- [ ] luminance arc measured and deliberate (not accidental)
- [ ] 9:16 is its own render, not a crop — the text zone works in both frames
- [ ] **scrub test**: scroll slowly *and* fast through the whole page; the video must never lag more than one frame and never stick on a frame
- [ ] text legible on the lightest frame of the film (test on the frame with the highest YAVG)
- [ ] `prefers-reduced-motion`: no blob preload, direct jumps, page stays readable
- [ ] without JS: a readable document (static scenes, no sticky, no canvas)
- [ ] a deep link to a scene lands on the right moment

---

## 8. Economics

A 15s film = ~2–3 i2v segments per environment × 5 environments, plus curating over several takes (plan on generating 2–3× per usable segment — see `commercial-craft.md`). The money is entirely in generation; encode, scrubber and FX layer are scripting. The 9:16 render doubles the generation cost — that's the real price of "9:16 included" in this format, and it belongs honestly in the cost report.

The skeleton (sticky stage + scrubber + grade + scene timing) is **built once, reused per brand**. Only the film and the palette change.

## Prior art
`frankoonk.com` (reverse-engineered 2026-08-01: all-intra 361/361 I-frames, blob preload, 0.0012^dt damping, 1/48s dead zone, 8.4 screens, separate 720×1280 render) · `vertical-916.md` (9:16 = its own render) · `commercial-craft.md` §hero-shot (curating over takes) · `lessons.md` (character DNA under i2v).
