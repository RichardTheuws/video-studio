# Titles in HyperFrames — the canonical title layer (since 2026-10-14)

**Why:** titles, cards and kinetic typography used to be built with `pango-view` → PNG → `magick` → ffmpeg overlays.
That gave good stills, but motion cost handwork per production, and the filtergraph broke silently on a regular basis
(`#` comments, a PNG sequence that kills `enable` timing, commas in expressions, pango width in points). Two formats
meant two layout scripts. HyperFrames (HeyGen, Apache 2.0) puts layout, typography and motion into **one HTML
composition** that headless Chrome renders frame by frame. Proven in a proof-of-concept: **PASS on quality (judged
side by side against the pango version), one source for 9:16 + 16:9, 980/980 frames bit-identical across two machines,
and running unattended on a headless render server.**

**Pango stays the fallback** (`tooling.md`, `title-sequence.md` §6) until three productions have shipped via HyperFrames.
Text *in* the world (a billboard, a doormat with a perspective warp) stays pango/magick regardless: that is compositing
onto a surface, not a title layer.

## 1. Shape: variant A — transparent overlay

ffmpeg does the montage as always (clips, grade, xfades, audio). HyperFrames renders **only the title layer**, as one
transparent ProRes 4444 MOV spanning the whole film, laid over it in **one** overlay. No dozens of PNG inputs, no
`enable` expressions.

```
montage (ffmpeg)  ──► video.mp4 ─┐
measured offsets  ──► spec.json ─┴─► render-titles.sh ──► titles.mov ──► overlay ──► film.mp4
```

Variant B (clips as `<video>` inside the composition) works technically (frame-accurate seeking measured), but moves
grade/montage/audio into HyperFrames without solving anything. Don't use it.

## 2. The template (ships with the skill)

One composition in this skill's **`templates/titles/`**. It lives in the skill on purpose, not in a project repo: a
headless render machine that only has the skill installed still has the template. The brand comes in via the spec (§3),
not via a copy of the template.

| Path | What |
|---|---|
| `shared/titles.js` | logic: builds plates/pairs/cards from the `spec`, the timeline, the font-size ladder |
| `shared/titles.css` | brand tokens + layout per format (`.portrait` / `.landscape`) |
| `shared/fonts/` | the brand fonts as files (`@font-face`), **never** rely on system fonts |
| `shared/vendor/gsap.min.js` | GSAP bundled locally (no CDN during rendering) |
| `916/`, `169/` | thin entries: only `index.html` + `meta.json` + symlinks to `shared/` |

Default = the Theuws Consulting house style (teal/amber, Fraunces + Inter Display + JetBrains Mono). **Another brand:**
set `brand` in the spec (colour and font tokens from `titles.css` `:root`: `teal`, `amber`, `glow`, `paper`, `ink`,
`muted`, `sage`, `plate`, `font-head`, `font-ui`, `font-mono`) and, for custom fonts, `fontFaces` + `FONTS_DIR=<dir>`
when rendering. Keep a per-brand preset (a `titles.json` with a `brand` block + `fontFaces`) next to that brand's style
guide and paste it into the spec. Look at one test render per format before the first production.

## 3. The spec (one source of content + timing)

```json
{ "duration": 40.8, "brand": { "teal": "#0F4C4A", "amber": "#D97A2C" }, "items": [
  { "kind": "card",  "in": 2.2, "out": 8.1, "kicker": "THEUWS CONSULTING · DEMO", "head": "This is everything\nI typed.",
    "panel": "<the literal prompt>", "typewriter": 3.4, "counter": "words" },
  { "kind": "plate", "in": 9.6, "out": 12.25, "text": "Behind those 68 words:\n2,635 notes." },
  { "kind": "pair",  "in": 12.2, "out": 15.1, "typed": "LinkedIn", "knew": "Plays without sound. So all text on screen." },
  { "kind": "plate", "in": 25.3, "out": 27.2, "text": "A short prompt only works when there is a *memory* behind it.", "glow": 26.0 },
  { "kind": "card",  "in": 32.6, "out": 36.1, "head": "*68 words*\n→ this video", "foot": ["Production cost: $5.92", "Made with AI."] }
] }
```

- **Times are absolute seconds** and come from the montage: `in = offset(segment) + local`, using the offsets your
  xfade chain computes itself. **Never copy them by hand** (timing drift is exactly what this removes).
- `out` = the moment the element is fully gone. A card that dissolves along: `out = xfade offset + xfade duration`.
  A plate must be gone **before** a dissolve (plates double up in a dissolve, `lessons.md` 2026-10-14 II).
- Text is **plain text** and gets escaped (`& < > ' “ ”` are safe). Markup: `*word*` = accent, `\n` = line break.
- `glow` = the moment the accent word lights up amber (the escalation that couldn't be built in pango). Put it on the
  beat in the picture it refers to.
- `pair` takes optional `labels` (two kickers, default `["YOU TYPED", "IT KNEW"]`); set them for your own copy.
- Long client copy: the **font-size ladder** (`fitTitles`) steps down 4 px at a time until the plate fits (min 36 px).
  It runs after the fonts have loaded.

## 4. Rendering

```bash
scripts/render-titles.sh 916|169 spec.json build/titles.mov [fps]
# custom brand fonts: FONTS_DIR=path/to/brand/fonts scripts/render-titles.sh …
```

The script pins the HyperFrames version (`npx hyperframes@0.8.99`), always renders with `--no-browser-gpu` (otherwise
edge pixels drift by up to 4/255 between machines), turns telemetry off, sets `data-duration` from the spec, runs under
a timeout, and **checks the output** (alpha channel + duration) instead of trusting the exit status. Render time
≈ 45 s for a 40 s film.

Then one overlay:

```bash
ffmpeg -i video.mp4 -i titles.mov -i audio.wav -filter_complex \
  "[1:v]format=yuva444p,setpts=PTS-STARTPTS[t];[0:v][t]overlay=0:0:shortest=1:format=auto,format=yuv420p[v]" \
  -map "[v]" -map 2:a -c:v libx264 -preset slow -crf 17 -c:a aac -b:a 192k -shortest -movflags +faststart film.mp4
```

The full chain is: montage → offsets → title times → render → overlay. Have your montage script write `spec.json`
from the same offsets it hands to `xfade`, then call `render-titles.sh`, then the overlay above.

## 5. Writing rules for the composition (pitfalls from the PoC)

- **One entry file per project** → hence the thin `916/`/`169/` folders with symlinks; `render-titles.sh` copies with
  `cp -RL`, so the symlinks become real files.
- **Register the timeline inline** (`window.__timelines["main"] = tl` in `index.html`), otherwise the linter complains.
  The script renders with `--strict`: lint errors break the render.
- **GSAP overwrites `transform`** → never centre with `translate`; use `inset` + `margin: auto` + `height: fit-content`.
- **GSAP doesn't interpolate `var(--x)`** → read a CSS variable first (`getComputedStyle(root).getPropertyValue`).
- **Words hidden with `opacity`** keep their space (good: no reflow); a following cursor must therefore be positioned
  absolutely per word.
- **No network during rendering**: fonts and GSAP come from the folder. Don't use `snapshot`/`describe`
  (`--describe false`): those send frames to an external model.
- **Use only the Apache 2.0 parts** of HyperFrames; no catalogue assets under a different licence in client videos.

## 6. QA (same bar as always, `commercial-craft.md` §2)

A strip on the busiest frame per plate, both formats. Check: legible, heavy, with backing; nothing outside the safe band
(9:16: plates in the upper band); no plate doubling up in a dissolve; the colour of a flat part of the plate
= teal `15,76,74` (alpha 0.84). View a frame from the MOV like this (flatten before viewing, or you only see alpha):
`ffmpeg -ss T -i titles.mov -frames:v 1 -pix_fmt rgba o.png && magick o.png -background '#556066' -flatten o.jpg`.
