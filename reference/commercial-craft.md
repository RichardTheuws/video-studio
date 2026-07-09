# Commercial-grade craft — video-studio

**Why this exists**: a technically working montage ≠ premium. This document is the **quality bar that makes work feel "expensive"** — the difference between a TikTok snippet and a film a client pays a premium for. Read this on EVERY commercial video. The three most common mistakes: (1) **hard cuts everywhere**, (2) **thin, poorly legible titles**, (3) **flat, inconsistent grade**. Below is how to avoid them.

## §0 The BOTTOM LINE — this is the minimum, not the ambition (MANDATORY)
This is the floor: **the quality Video Studio must ALWAYS deliver.** Every video must clear at least this level. What separates a good production from a weak first attempt — proven in practice — is now a hard rule:

1. **Brand ownership is non-negotiable.** Does the video sit under a brand? Then it carries **that brand's leader + outro**, and the entire wrap is in that brand (colors, type, tone). Never deliver a video "loose" without the brand bracket. (Common failure: no leader, wrong brand fonts/colors.)
2. **External / other-brand material = always an element WITHIN your context**, never loose shots dumped in. Showing someone else's footage (a trailer, a game, clips)? Frame it as *your* brand presenting something — framed, with your text around it. (Common failure: loose vignettes as filler.)
3. **Enough text/narration to actually explain the story** — calm and clear, including **over embedded segments** (explain *why* you show something; introduce a trailer/insert properly before you play it). Too few lines = the viewer doesn't get it. (Common failure: too sparse, no intro on the trailer.)
4. **A real arc that lands on the message**, not on "cool image": setup → the thing → what it means (the payoff must land on *your* point/brand, not on the borrowed material).

Test every delivery against these 4 before the premium test. Falls below this level → rebuild, don't ship.

## The premium test (does it feel paid-for)
Ask on every render: *would a high-end brand pay for this?* If not, check:
- Does the **flow** feel smooth (soft transitions, breathing room) or choppy (hard-cut staccato)?
- Are the **titles** heavy, legible, with a background — or thin text on busy footage?
- Is the **grade** consistent and rich across all shots, or does it jump?
- Does the **hero moment** get time to land (hold + music lift + breathing room)?
- Does the **rhythm** match the music (cut on the beat / on motion)?

---

## 1. Transitions — NEVER hard-cut-by-default
A hard cut is a *choice* for energy/beat accent, not laziness. Premium edits lean on **crafted transitions**. Palette:

| Transition | When | ffmpeg |
|----------|------|--------|
| **Cross-dissolve** (0.3–0.6s) | default between related shots; luxe = many dissolves | `xfade=transition=fade:duration=0.5:offset=X` |
| **Dip-to-white** (0.2–0.4s) | section break, into the reveal/hero | `xfade=transition=fadewhite:duration=0.3:offset=X` |
| **Dip-to-black** | calm section break, intro/outro | `xfade=transition=fadeblack` |
| **Speed-ramp + whip** | dynamic "premium whoosh" into the hero | slow end of A (`setpts`) → motion blur → fast start of B |
| **Match-cut** | same shape/motion shot→shot | hard cut on the exact motion moment |
| **Luma/soft-blur dissolve** | dreamy, beauty/hair | `xfade=transition=dissolve` or gblur during dissolve |

**xfade chain (N clips, overlap T):** each next `xfade.offset = (sum of clip durations so far) − (number of transitions so far)·T`. Note: overlap **compresses the timeline** by (N−1)·T → **re-time titles/audio** to the new clip starts (clip k starts at `Σd₁..d_{k-1} − (k-1)·T`). So build the montage *with* transitions, then re-time the overlays.

**J/L-cuts (audio)**: let sound / a music accent run just before (J) or after (L) the picture cut → seamless, professional flow. Never cut all audio + picture at exactly the same instant.

**Rule of thumb for a luxe mix**: ~50–70% dissolves/soft, 30–50% hard cuts (deliberately on the beat). Never 100% hard.

---

## 2. Titles & typography — legibility = premium
Thin text on moving footage reads "thin" and cheap. Premium titles are **heavy, large, with a background**.

**Non-negotiable:**
1. **Always a backing** behind text on footage — pick one and be consistent:
   - **Scrim** (subtle dark gradient under/behind the text) — most cinematic, invisible but legible.
   - **Glass-plate** (rounded semi-transparent plate, e.g. a brand color at `rgba(...,0.55–0.7)` + a thin gold hairline) — luxe, branded.
   - **Solid bar / frame** — editorial, bold.
   - NEVER naked text on busy footage (only on even, dark, calm shots — and then with a shadow).
2. **Weight & size**: display **700–900** (Black), large. Body/caption min ~46–52px on 1080-wide, **600–800**. Rather too big than too small. Thin weights (300/400) only as a micro-credit on a plate.
3. **Contrast**: cream/white on a dark backing; one accent color (gold) for rules / a single word. Text shadow `0 2–4px rgba(0,0,0,.6)` as extra.
4. **Kinetic yet legible**: motion is fine (mask-wipe, scale-pop, per-letter) but the text must **hold still long enough to read** (≥1.2s, ≥2.5s for a sentence). Motion serves legibility, not the other way around.
5. **Type system**: max 2 families (display + sans), consistent positions (lower-third left, hero center), consistent in/out animation. One system = expensive; loose styles = amateurish.
6. **Legibility test**: place the title on the **busiest/brightest frame** of its shot. Illegible there = heavier backing or reposition.

**ffmpeg (no `drawtext` in brew-ffmpeg)** → render text as a PNG with **ImageMagick** (real fonts + glow/plate), overlay with `-loop 1 -framerate 30 -i title.png` + `format=rgba,fade=...:alpha=1`. Scrim: a separate gradient PNG or `drawbox` with low alpha under the text PNG. Plate: rounded `roundrectangle` (IM) in a brand color + gold hairline, text on top, as one PNG.

---

## 3. Pacing & rhythm
- **The hero breathes**: the key moment gets time (longer hold + music lift + optional slow-mo + empty breathing room after). Don't cut it away.
- **Cut on motion or beat**: cut where something moves (a flip, a turn) or on a music accent — not on arbitrary seconds.
- **Vary shot length**: build-up = longer/calmer, climax = faster; never metronome-uniform.
- **Less is more**: 12 strong shots with flow beat 20 that flash by.
- **First 1.5s = the hook**: strongest image/motion up front.

---

## 4. Grade & finish (the "film" look)
- **One consistent grade** across all shots (same curve/LUT feel) → cohesion. Jumping color = cheap.
- **Depth**: slightly lifted/tinted shadows, rich mid-tones, not flat.
- **Bloom** on highlights (soft), **subtle vignette**, light **film grain** (dither against banding on H.264).
- **No** over-sharpening, no blown saturation, no visible banding.
- **Slow-mo** from a true high-fps source (4K60) for beauty moments — not frame-blended 30fps.

## 5. Audio finish
- Music bed **loudnorm** to the platform (−14 LUFS social, −16 YouTube), peak −1 dBTP.
- **Duck** music −6dB under VO. **J/L-cuts** for flow.
- Accent **SFX** on key hits (whoosh on the whip, a soft impact on the reveal) — subtle, synth > AI-blob (see `montage-ffmpeg.md`).
- Original / royalty-free (fal stable-audio) = no mute on social.

---

## 6. Premium QA checklist (gate before delivery)
- [ ] Transitions: ≥half soft/crafted, no hard-cut staccato.
- [ ] Titles: heavy, large, with backing, legible on the busiest frame, one system.
- [ ] Grade: consistent + rich across all shots; grain/dither against banding.
- [ ] Hero breathes; rhythm follows the music; hook in the first 1.5s.
- [ ] Audio loudnorm + duck + (J/L) flow; music fits the brand/goal.
- [ ] Logo/branding intentional (slots), end card with CTA/contact.
- [ ] Does it feel worth paying for? If not: name what's wrong and fix it, don't ship an "almost".

---

## 7. Pre-delivery inspection (MANDATORY — non-negotiable)
**You do NOT judge a moving medium on a handful of loose thumbnails.** Declaring a montage "done" without this protocol = the #1 failure source (learned in production). Before you deliver or say "done":

1. **Dense frame strip**: pull frames across the *whole* clip at ≤0.7s intervals (`ffmpeg -ss t -i out.mp4 -frames:v 1`), tile them, and **view them with the Read tool**. This reveals dead time, dark/murky shots, and the rhythm.
2. **Cut-boundary inspection**: for EVERY cut/transition — view the **out-frame of shot A next to the in-frame of shot B**. A cut exists by virtue of those two frames. Murky/mid-motion/dark = rejected → re-pick in/out or the transition.
3. **In/out is chosen on frames, not arithmetic**: determine clip boundaries by looking at the actual frames, not via `frame≈k/12·duration`. Cut on a clean/stable frame, on motion or beat.
4. **Hold/legibility**: check each text card on its real duration — long enough to read (≥1.2s per line / ≥2.5s per sentence) but not so long it freezes. **Text cards together ≤ ~25% of runtime** (footage carries; cards punctuate).
5. **Audio honesty**: if you can't judge the audio, say so explicitly and note that cuts aren't frame-accurate on the beat — don't sell it as finished.
6. **Validate one cut first, THEN fan out**: validate one core segment/cut (and get sign-off) before rendering variants/languages/formats. Never build 3 versions on an unconfirmed base.

### Source hygiene (before montage, per source)
Detect and decide deliberately: **burned-in subtitles**, **watermark/logo**, **already-present titles**, **already-graded look**, **letterbox/aspect**, **shaky/too dark**. Don't double-grade; don't blindly mix watermarked with non-watermarked; crop out subs/letterbox or pick other material. A **muted testimonial** (talking head without their voice) is uncanny → use the audio (ducked) or don't make it a long shot.

> Default stance: build as if an art director is watching. Rather one shot fewer with the transition/typography right, than lots of footage flashing by. "Works technically" is not the bar — "feels expensive" is the bar.

---

## 8. The real bar — cinematic hero shots (and how to hit it)
The videos represent professional capability; amateur work costs collaborations. The bar is a film studio, not "neat motion graphics". Concrete failure lessons (learned in production, don't repeat):

1. **Wrong register = an instant fail.** Flat 2D motion graphics (fading-in bars, a drawn line, ticking digits) are not a hero moment. A hero/growth/impact shot is **cinematic 3D/VFX**: low hero camera, volumetric light/god-rays, depth, reflections, particles, lens flare, weight. **"We build with AI"** — use nano-banana + i2v for the image, not ffmpeg shapes.
2. **Motion MUST be art-directed.** A loose i2v prompt ("animate this") makes the model **spin the subject on its axis** instead of the intended motion. Direct explicitly: **camera move** (push-in / crane-up) + **object physics** (grows, erupts, accelerates, with weight) + **what crosses the lens plane** (debris/sparks along the lens). Negative-prompt against `rotating/spinning/orbiting/twisting/drift`.
3. **Curate i2v — never ship the first take.** Render a hero shot **multiple times** (vary direction/seed), review them, pick the take that hits the intended motion, **re-roll** the rest. i2v is erratic; one guess ≠ done.
4. **"Coming out of the screen" = real perspective integration**, not a flat CG burst — depth, parallax, occlusion, matched perspective (e.g. a character convincingly climbing *out of* a real laptop, gripping the bezel, standing on the keys).
5. **Study the reference before you design.** Look first at the best existing work in the portfolio and calibrate your design to it. Don't iterate wildly — **first understand what you're making**, design the money-frame, lock the keyframe, then animate.

> Hero-shot workflow: (a) study reference → (b) design the shot (camera, physics, light, timing, money-frame) → (c) generate keyframe(s) and choose critically → (d) **art-directed i2v × multiple takes, curate** → (e) data/text hits on the impact (no fade) + SFX (rumble→whoosh→boom) + grade → (f) validate one shot, then fan out.
