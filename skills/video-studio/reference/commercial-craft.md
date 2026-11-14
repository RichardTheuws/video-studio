# Commercial-grade craft — video-studio

**Why this exists**: a technically working montage ≠ premium. This document is the **quality bar that makes work feel "expensive"** — the difference between a TikTok snippet and a film a client pays a premium for. Read this on EVERY commercial video. The three most common mistakes: (1) **hard cuts everywhere**, (2) **thin, poorly legible titles**, (3) **flat, inconsistent grade**. Below is how to avoid them.

## §0 The BOTTOM LINE — this is the minimum, not the ambition (MANDATORY)
This is the floor: **the quality Video Studio must ALWAYS deliver.** Every video must clear at least this level. What separates a good production from a weak first attempt — proven in practice — is now a hard rule:

1. **Brand ownership is non-negotiable.** Does the video sit under a brand? Then it carries **that brand's leader + outro**, and the entire wrap is in that brand (colors, type, tone). Never deliver a video "loose" without the brand bracket. (Common failure: no leader, wrong brand fonts/colors.)
2. **External / other-brand material = always an element WITHIN your context**, never loose shots dumped in. Showing someone else's footage (a trailer, a game, clips)? Frame it as *your* brand presenting something — framed, with your text around it. (Common failure: loose vignettes as filler.)
3. **Enough text/narration to actually explain the story** — calm and clear, including **over embedded segments** (explain *why* you show something; introduce a trailer/insert properly before you play it). Too few lines = the viewer doesn't get it. (Common failure: too sparse, no intro on the trailer.)
4. **A real arc that lands on the message**, not on "cool image": setup → the thing → what it means (the payoff must land on *your* point/brand, not on the borrowed material). The arc is the *content*; the *telling order* may open on the payoff and then show how (`scenario.md` S-A01), and it always ends *on* a high that is resolved on screen (S-A04).
5. **NEVER Ken Burns / zoompan — nowhere, on nothing.** Panning/zooming a still or a capture reads as PowerPoint, not film. If a still has to move, the motion comes from one of two sources, in this order:
   - **A real photo (a scene with natural elements)** → **art-directed i2v** that brings one real element to life (water ripples, ornamental grasses/plumes sway, clouds/light drift). Prompt a **locked-off / static camera** and explicitly forbid `zoom/pan/push-in/drift` — otherwise the model adds camera motion anyway. i2v is cheap (~$0.56/clip on Kling v3 Pro, 5 s; see `models.md`) and reusable across every video for that brand. **Curate**: compare first vs. last frame — identical framing = camera locked (good); grown/zoomed-in = rejected, re-roll or fall back to static.
   - **A UI screenshot, text strip, letterbox collage or any other composite *without* a natural element** → **a static hold**; i2v morphs a screen/composition strangely (Veo stretches letterbox bars, hallucinates content). The **crafted cross-dissolves + heavy titles + grade** supply the motion. Static is the premium choice here, not a compromise.

6. **Every video with AI imagery or AI audio carries the label.** Visible: the official **EU label** (European Commission icons shipped in `templates/titles/shared/eu-ai-label/`, spec item `{"kind":"ailabel"}`: `generated` for fully AI imagery, `modified` for edited real footage) with the text "Made with AI", on the end card; if real people appear in i2v-animated footage, also briefly at their first appearance. Machine-readable: `-metadata comment="AI-generated imagery — <brand>, EU AI Act art. 50"` on the master (`scripts/qa-check.sh` checks it). This is law in the EU since 2 August 2026 (Regulation 2024/1689, art. 50) and plain honesty everywhere else; the client does not get to strip the label — put that in the engagement terms.

Test every delivery against these 6 before the premium test. Falls below this level → rebuild, don't ship.

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

**Canonical route: the HyperFrames title layer** (`titles-hyperframes.md`): one transparent MOV rendered from a brand template, 9:16 and 16:9 from one source, words that build up, one overlay. The PNG route below is the fallback.
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

0. **The measurable gate first**: `scripts/qa-check.sh <deliverable> --expect <s> [--social] [--cuts cutlengths.txt] [--clips clips/]`. A FAIL here (colour tags, size, loudness, rhythm, dead cuts, AI label) is by definition not finished; only then is the visual inspection below worth doing.
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

## 8. The real bar — Hollywood / Pixar / Marvel (and how to hit it)
The videos represent professional capability; amateur work costs collaborations. The bar is **Hollywood / Pixar / Marvel**, not "neat motion graphics". Concrete failure lessons (learned in production, don't repeat):

1. **Wrong register = an instant fail.** Flat 2D motion graphics (fading-in bars, a drawn line, ticking digits) are not a hero moment. A hero/growth/impact shot is **cinematic 3D/VFX**: low hero camera, volumetric light/god-rays, depth, reflections, particles, lens flare, weight. **"We build with AI"** — use nano-banana + i2v for the image, not ffmpeg shapes.
2. **Motion MUST be art-directed.** A loose i2v prompt ("animate this") makes the model **spin the subject on its axis** instead of the intended motion. Direct explicitly: **camera move** (push-in / crane-up) + **object physics** (grows, erupts, accelerates, with weight) + **what crosses the lens plane** (debris/sparks along the lens). Negative-prompt against `rotating/spinning/orbiting/twisting/drift`.
3. **Curate i2v — never ship the first take.** Render a hero shot **multiple times** (vary direction/seed), review them, pick the take that hits the intended motion, **re-roll** the rest. i2v is erratic; one guess ≠ done.
4. **"Coming out of the screen" = real perspective integration**, not a flat CG burst — depth, parallax, occlusion, matched perspective (e.g. a character convincingly climbing *out of* a real laptop, gripping the bezel, standing on the keys).
5. **Study the reference before you design.** Look first at the best existing work in the portfolio and calibrate your design to it. Don't iterate wildly — **first understand what you're making**, design the money-frame, lock the keyframe, then animate.

> Hero-shot workflow: (a) study reference → (b) design the shot (camera, physics, light, timing, money-frame) → (c) generate keyframe(s) and choose critically → (d) **art-directed i2v × multiple takes, curate** → (e) data/text hits on the impact (no fade) + SFX (rumble→whoosh→boom) + grade → (f) validate one shot, then fan out.

## 9. Measurement discipline — how we judge without fooling ourselves (consolidated 2026-11-08)
The rules in this document are only worth something if the measurement is right. Each of these lessons came out of a near-false verdict.
1. **Inspect at native resolution and check SAR.** A strip that resizes frames hides framing *and* aspect errors (an empty letterboxed leader and a clashing hero were only visible at full res; 2026-07-10). At least one native frame per segment; `sample_aspect_ratio ≠ 1:1` = stretched.
2. **Sample the last quarter densely**: late action (Kling) and late intruders don't show on 6 frames (2026-10-14, 10-16). Read frames with `-i file -ss t`, not `-ss t -i file` (half-decoded frame), and test a transition at several points — one frame in the middle of a dip-to-black always looks fine (2026-09-22).
3. **Measure segments and intermediates, not only the final film**: a correct final duration proved nothing about 33× too-long segments (2026-09-22); a `| tail -1` hid the same un-rebuilt `tour.mp4` three times — check the mtime (2026-08-21). `qa-check.sh` measures the deliverable; the segment guard belongs in the build.
4. **A positive control is not optional.** Without the colour control, "negative prompt does nothing" would have read as "claim false" instead of "knob not connected" (2026-08-19).
5. **Validate the tracker before the metric**: an NCC tracker sat on a brown door that slipped through the skin mask and gave a false negative; threshold NCC ≥ 0.70 (2026-08-19).
6. **Test the sensitivity**: a known σ=0.5 blur dropped the measure by 0.09 — as large as the between-arm difference; so the instrument could see the effect, it just wasn't there (2026-08-19).
7. **Calibrate a style metric on a content-matched ground truth** (the same scene in the target style and photoreal): flatness (cel 0.635 vs photo 0.395, but a photoreal billboard 0.749), palette compactness and local uniformity (0.239 vs 0.158) measure the scene; mid/edge (cel 3.13 vs photo 5.39) measures the style. At 720p that measure had +14 % range against +72 % at 1080p (2026-08-19).
8. **An area measure measures framing, not compliance**: "how much yellow is in frame" (U=44/64) turned out to be a larger figure (U=52/64, +32 %) at equal hue (43.0° vs 40.8°, U=40/64). Split size from property (2026-08-19).
9. **Measure alpha, motion and loudness instead of looking or listening**: torso alpha ≥ 98 % (`consistency.md` §7), motion energy (`directing.md` §2/§7), `ebur128` per episode (`montage-ffmpeg.md`). You cannot hear audio: say so, deliver with a caveat.
10. **Thumbnail from the source frame**, not composited: a crop of the outro via multiply/divide gave a fringe three times; a 1280×720 crop of the frame itself is seamless (2026-11-01).
11. **A rule in a document is not a gate.** Three rules from this log (bt709 tags, ≤ 16 MB social, −14 LUFS) had stood for months and a delivered client video failed all three (2026-11-08) → `scripts/qa-check.sh` before every delivery (§7 step 0).
