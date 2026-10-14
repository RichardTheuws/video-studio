# Title sequence — the leader you don't *want* to skip

**Why this exists**: a 20–35 second brand leader is the most expensive second per euro in the whole
video-studio. It sits in front of everything, it gets seen the most, and it's exactly the part a viewer
clicks away. This document is the recipe for a leader that **reads premium while being cheap to make** —
and that's not a contradiction, it's a choice of form.

The form is reverse-engineered from the opening titles of **Stuart Fails to Save the Universe** (HBO Max,
episode 1, 33.0 s). See §11 for the full teardown with timecodes. That sequence is publicly suspected of
using AI (never confirmed by the makers), and that's exactly why it's useful: it shows which form an AI
pipeline *can* reach, and which artifacts it *can't* hide.

> **Relation to the rest of the skill.** This isn't a fourth mode — it's a **form** you produce inside mode
> B (full AI). The camera method shares its foundation with `scroll-video.md` §4 (portal chaining,
> occluder joins, one continuous move); the difference is that here the viewer doesn't control time, so the
> rhythm is yours and the music's. The intake gate (`brand-intake.md`) and the storyboard gate (§1.5) apply
> in full.

---

## 1. The form in one sentence

**The joke or the promise is written *into* the world, and the camera drives toward it.**

No character performing, no story that needs animating. A billboard, a doormat, a sign on a door, a
divider card in a comic-book bin, a slip of paper in a fortune cookie. Per shot, one legible text surface
and one straight camera move toward it. That's all.

Why this works and is at the same time the cheapest thing you can build:

| What the form avoids | Why that cuts cost | Why that raises quality |
|---|---|---|
| Character animation | i2v only has to move the camera → 1 take instead of 5 | no AI fumbling with hands, gait, faces |
| Dialogue / lipsync | no audio generation per shot | no uncanny valley |
| Complex blocking | static set, symmetrical frame | reads as deliberate direction, not chance |
| Story continuity | shots don't need to know each other | every shot may be its own world |

---

## 2. The five hard rules

1. **The hero text is NEVER generated.** Generate the set with an empty, flat, well-lit text surface
   (blank billboard, blank doormat, empty sign) and put the text on in post with the pango toolchain. Every
   generator writes nonsense sooner or later. See §6.
2. **The motion comes from i2v, never from `zoompan`.** The Ken Burns ban (`commercial-craft.md` §0 rule 5)
   stands: a fake zoom on a still reads as PowerPoint. Here the dolly *is* the content — so let the model
   drive a real camera move with parallax. A generated push-in is not Ken Burns; an ffmpeg zoompan is.
3. **One visible hard cut per sequence, maximum.** Every other join is masked (§4). Measure it afterwards
   (§10) — anything above scene score 0.40 is a visible cut.
4. **One idea, one line, one move per shot.** Two jokes in one shot means the viewer reads neither. Keep
   2–3 s per shot.
5. **Tone grants the licence.** A sequence that takes itself seriously must be photoreal and loses on every
   artifact. A sequence that comments on itself may have artifacts. Choose this deliberately in the concept
   round (§1.5) and lock it in the brief — it sets the whole bar.

---

## 2.5 Spectacle doesn't carry text

Hollywood-grade imagery and a legible print surface pull against each other: a backlit silhouette, a
diagonal cloth full of folds, an oblique macro — those are gorgeous shots and poor text carriers. A print on
a silhouette reads as a smudge of light.

The reference does it the other way round: Stuart puts its text on **billboards, doormats and signs**, flat
and simply lit, while its giant legs and explosions carry nothing. Adopt that:

- **spectacle beats** carry no hero text and are the portals;
- **carrier beats** are explicitly generated flat, frontal and evenly lit, and that's where the text lives.

Forcing text onto a beautiful but oblique/dark frame costs you an afternoon and still gets rejected.
See also `print-on-product.md` §6.

## 3. Shot grammar

Every shot has the same four properties. If you deviate, that's a choice you write down.

- **Symmetrical one-point perspective.** Vanishing point in the centre, frame bilaterally mirrored. This is
  why a cheap shot still looks directed — and it makes the morph (§5) possible.
- **One straight move**: forward (push-in) or backward (pull-out). No crane, no orbit, no handheld. Two
  moves in one shot = two chances of drift.
- **The text surface is perpendicular to the axis** and fills 25–45% of the frame width at the end point of
  the move. Too small = illegible; too big = you see the compositing seam.
- **People are small, blurred, or still.** If you invite actors into the frame: keep them at a distance, in
  motion-with-blur, or in a single frozen pose of ≤2 s. Groups are backs and silhouettes.

**Prompt skeleton** (nano-banana for the keyframe, then i2v):

```
symmetrical one-point perspective, vanishing point dead centre, <location>,
a large BLANK <text carrier: billboard / doormat / sign / divider card>, empty surface,
no text, no lettering, no writing anywhere in frame,
cinematic <brand grade>, shallow depth of field, 35mm, <time of day/light>
```

```
i2v: slow steady dolly forward along the centre axis toward the <text carrier>,
camera does not rotate or tilt, constant speed, no zoom, everything else static
```

The triple negation ("no text, no lettering, no writing") is necessary — ask for a billboard and the model
writes something on it. And always curate first-vs-last frame: rotation or tilt in it = re-roll.

---

## 4. The four masks — how to stitch 13 shots together with one cut

This is the core of the form. Pick one per join and put it **in the generation prompt**, not in the edit.

| # | Mask | How | Cost |
|---|---|---|---|
| **1** | **Push through darkness** | shot A ends with the camera entering a dark opening (doorway, tunnel, mouth of a corridor); shot B starts in that same darkness and lights up | free — it's composition |
| **2** | **Whip blur** | shot A accelerates into a streak over the last ~6 frames, shot B starts out of a streak. Prompt: *"camera accelerates violently forward, extreme motion blur"* | free |
| **3** | **Occluder wipes the frame** | an object passes right past the lens (helicopter, flying book, figure walking by) and fully covers 1–2 frames | free, and gives you bonus §4b |
| **4** | **Through the geometry** | the camera goes *through* something: a door opening, a letter of the title, a window | free |

> **The best mask is bought, not edited.** Kling's `tail_image_url` (`models.md`) drives a real
> continuous move between a start and an end frame and invents the mask itself — straight through a print,
> past an occluder, through a doorway. A 4-frame `xfade` between two separate shots is *not* a mask but a
> dissolve, and that has been explicitly flagged as rejected work. Use xfade only as a bandage on a seam.

All four are the portal-chaining/occluder joins from `scroll-video.md` §4.2–4.3; the difference is that here
you set the tempo, so you may place them rhythmically (on the beat) instead of evenly.

**§4b — The occluder as a free second shot.** As soon as an object covers the frame, *everything* behind it
may change. In the reference, one billboard shot yields two different texts: a helicopter flies past and
the text is different afterwards. That's the cheapest trick in the whole repertoire:

```
one generated shot  →  N text versions in post  →  N "shots" in the edit
```

Use this deliberately in the storyboard: plan at least one occluder shot with two or three texts. It's also
your emergency brake if another shot fails — you always have an extra beat in hand with no extra generation.

**Edit.** Because the mask is in the picture, the join is often a **hard cut behind the occluder** — *no*
xfade. A cross-dissolve over a blur frame makes the join visible instead (double motion). If a visible seam
remains, use an `xfade=fade` of 3–5 frames, no more:

```bash
# join with 4 frames of overlap at 24fps (0.1667s) — both clips pinned to fps+timebase
ffmpeg -i a.mp4 -i b.mp4 -filter_complex \
 "[0:v]fps=24,settb=1/24,setpts=PTS-STARTPTS[a];[1:v]fps=24,settb=1/24,setpts=PTS-STARTPTS[b];\
  [a][b]xfade=transition=fade:duration=0.1667:offset=$((DUR_A))-0.1667" join.mp4
```

---

## 5. The morph corridor — the one AI-native shot

One composition, camera and subject locked, and then let the **style** run through: the same corridor
becomes jungle, motel corridor, vault, art deco, chessboard floor. No physical production can do that, and
for us it's cheaper than an ordinary shot because you reuse one setup.

Recipe:
1. Generate **one** keyframe of the corridor with the subject at the vanishing point.
2. Use that frame as the reference anchor (`consistency.md`) and generate N style variants — **same frame,
   same subject position, same focal length**, only material/light/set different. 5–7 variants over 2.5 s is
   the right tempo (≈0.4 s per style).
3. Morph between them. Order of preference: (a) i2v with the variants as start/end frame per pair; (b) if the
   model doesn't hold the composition: `xfade=transition=dissolve` of 0.4 s per pair over the stills, *with*
   a slight gblur peak in the middle of each transition so the dissolve doesn't read as a slideshow.
4. **Quality gate**: the subject must not jump. Put the first frames of all variants side by side
   (`magick +append`) and check that the silhouette sits on the same pixels. If not: regenerate with a
   tighter anchor, not "it's fine".

Watch the trap the reference itself didn't clear: the further into the series you get, the more nonsense
detail the model adds (doors with a handle on both sides). For us that's a rejection point, unless §2 rule 5
applies and the tone carries it.

---

## 6. Text — generating is forbidden, compositing is the norm

The reference already does this well and it's the single most important lesson: **all hero text was put on
in post**, all background text was generated and is therefore nonsense (`ADMINOIIIG`, `NEW GOD` with a
dropped S, illegible mush on the top edge of a divider card).

Method:
1. Generate the surface blank (§3).
2. Render the text with **pango-view** to PNG (the canonical lettering toolchain, `tooling.md`) in the
   brand fonts, weight 700–900.
3. Place it in the surface with a corner-pin/perspective warp so it sits *in* the surface rather than
   stuck on top:
   ```bash
   magick text.png -matte -virtual-pixel transparent \
     -distort Perspective '0,0 X1,Y1  W,0 X2,Y2  W,H X3,Y3  0,H X4,Y4' warped.png
   ```
4. **Let the surface's texture come back** over the text — a billboard is weathered, a doormat is rough.
   Without this step the text reads as a sticker:
   ```bash
   # weather the text with the surface's texture (multiply at ~20-30%)
   magick warped.png \( surface_crop.png -colorspace gray -blur 0x1 \) \
     -compose multiply -define compose:args=25 -composite text_weathered.png
   ```
5. Overlay it on the shot in ffmpeg. If the camera moves, the text has to move with it — so generate the
   shot with a **tracking marker** (e.g. a coloured patch) or keep the text reveal in the static part of the
   shot.

> **Title layer (plates, cards, kinetic typography over the edit) → `titles-hyperframes.md`.** Pango remains
> the route for text *in* the world (perspective warp onto a surface), and the fallback for the title layer.

> **Gotcha (verified on Apple Silicon, Homebrew ffmpeg 8.1.2):** this build has **no `drawtext`** (no
> libfreetype) and **no `subtitles`/`ass` filter** (no libass). All text — subtitles and karaoke included —
> therefore goes through pango/magick to PNG and then `overlay`. Don't count on an ASS karaoke file. If you
> render on a second machine or server, it must match this toolchain.

---

## 7. Overlays that cost nothing and bind everything

Three layers that turn the separate shots into one film. All three are PNG overlays:

1. **The fourth-wall annotation.** A handwritten line plus arrow, aimed at something outside the film (in
   the reference: *DO NOT SKIP! ↓*, with the arrow exactly where the streaming player's skip button sits).
   In the reference it runs 0–7 s, i.e. only while the viewer can still click away. For a brand, the variant
   is a line that addresses the viewer about the context they're watching in (a LinkedIn scroll, an email,
   a landing page).
2. **Karaoke subtitles.** The theme is sung, the line sits at the bottom, one word at a time lights up in
   the accent colour. Build this as one PNG per word state and overlay them on the beats:
   ```bash
   # one PNG per word state; line identical, only the span colour differs
   pango-view -q --font="Inter Bold 44" --markup \
     -t 'but he <span foreground="#e11">fails</span> to save the universe.' -o w03.png
   ```
   Take the timing from the music, not from a guess — see §8.
3. **The brand bug.** A small logo bottom right, through the whole sequence. This is the brand-ownership
   requirement from `commercial-craft.md` §0 rule 1 in its cheapest form.

---

## 8. Audio — this is where the form stands or falls

The masks (§4) only work if the rhythm justifies them. Without music this is a series of incomprehensible
shots.

- **Build on one theme of 20–35 s** with a clear rise and one landing on the title card. Via
  `audio-studio`; instrumental beds are allowed (AI music that imitates real pop songs is not).
- **The joins sit on the beat.** Set the BPM grid before the edit and lay the shot durations on it; it's
  easier to trim a shot by 0.2 s than to shift the music.
- **J/L cuts** over the masks: let shot B's sound start just before its picture. A whoosh over a whip blur
  and a low impact on the push-through do more than any extra generation.
- **Loudness**: master at **−14 LUFS** (YouTube/web) or −16 (social). The reference upload sits at **−4.6
  LUFS integrated** — a brickwalled promo master. Don't copy that; it's distribution aggression, not craft.
- **Reusable per brand**: one theme, a different arrangement variant per use. The reference had Danny
  Elfman write ten variants for ten episodes — that principle (one theme, N colours) is exactly what a brand
  leader needs so it doesn't get stale.

---

## 9. Economics

For a ~33 s sequence in 13 shots, with Veo 3 Fast (4 s, $0.10/s without audio) and nano-banana Pro:

| Item | Count | Cost |
|---|---|---|
| Keyframes (stills) | 13 + variants | ~$2 |
| i2v clips | 13 × 4 s | ~$5.20 |
| Re-rolls (realistically 2–3× on the hero shots) | 4–6 extra clips | ~$2 |
| Music | 1 theme | via audio-studio |
| **Total** | | **~€10–20** |

What *drives cost down* in this form, and therefore belongs explicitly in the storyboard:
- **occluder shots with N texts** (§4b) — one generation, several beats;
- **the morph corridor** (§5) — one setup, 5–7 variants, yields 2.5 s;
- **static text carriers** — no motion in the scene means fewer re-rolls.

The money is in the i2v generation, not in the edit or the lettering. Report it honestly to whoever
pays: more shots = linearly more expensive, more text versions per shot = free.

---

## 10. QA gate (on top of `commercial-craft.md` §7)

```bash
# 1. how many visible cuts? Expected: 1 (the landing on the title/credits)
ffmpeg -v error -i leader.mp4 -vf "select='gt(scene,0.0)',metadata=print:file=-" -f null - 2>/dev/null \
  | paste - - | sed 's/.*pts_time:\([0-9.]*\).*scene_score=\([0-9.]*\)/\1 \2/' | sort -k2 -gr | head

# 2. luminance arc — deliberate, not accidental
ffmpeg -v error -i leader.mp4 -vf "scale=64:36,signalstats,metadata=print:file=-" -f null - 2>/dev/null \
  | grep YAVG

# 3. dense frame strip: every text fully legible at least once
ffmpeg -v error -i leader.mp4 -vf "fps=2,scale=400:-1,tile=4x6" -q:v 3 qa-%d.jpg
```

Checklist:
- [ ] **≤1 scene score above 0.40**, and that one is deliberate (the landing).
- [ ] **Every hero text holds still and fully in frame for ≥1.2 s** (a sentence ≥2.5 s) — read them off the strip.
- [ ] **No generated text in frame.** Zoom in on every background surface with letters. Nonsense text =
      reject or direct it away (defocus, out of frame, paste over).
- [ ] **First vs. last frame per i2v clip**: only the intended move, no rotation/tilt/drift.
- [ ] **Occluder joins really fall behind the object** — check A's out-frame next to B's in-frame
      (`commercial-craft.md` §7).
- [ ] **Brand bracket complete**: bug present, brand fonts, brand grade, landing on the brand.
- [ ] **Loudness measured** (`ebur128`), −14/−16 LUFS.
- [ ] **9:16 variant** is its own render, not a crop (`vertical-916.md`). Note: symmetrical one-point
      compositions crop more easily than average — an advantage of this form — but the text carriers have
      to be repositioned.

---

## 11. Teardown — Stuart Fails to Save the Universe, ep. 1 (evidence)

Measured on the HBO Max YouTube upload (1 Aug 2026), 1920×1080, 23.976 fps.
**33.0 s sequence** (+13 s subscribe outro), **13 shots**, average 2.5 s, **1 visible cut** (32.28 s,
scene score 0.44; all other joins ≤0.22). Integrated loudness −4.6 LUFS, LRA 7.1.

| t | Shot | Text in frame | Technique |
|---|---|---|---|
| 0.0 | protagonist frontal, push-in | overlay *DO NOT SKIP! ↓* | §3 |
| 1.5 | push through darkness | | mask 1 |
| 2.0 | lecture hall, backs/silhouettes | screen: *"And shit is about to get weirder."* | §3 |
| 4.0 | giant legs crush a small town | karaoke line | §3 |
| 5.5 | whip blur forward | | mask 2 |
| 6.5 | billboard above the clouds | *"Don't even think about clicking the skip titles button."* | §3 |
| **9.0** | **police helicopter crosses the frame** | → text swapped afterwards | **mask 3 + §4b** |
| 9.5 | same billboard, different text | *"Well, sure you can think it, but fair warning…"* | §4b |
| 12.5 | desert ruin, cast, explosions | | §3 |
| 14.5 | darkness | | mask 1 |
| 15.0 | fortune cookie | *"…that's a Danny Elfman theme song."* | §3 |
| 18.0 | comic-book bins, push-in | *"AND HOW ABOUT THESE GRAPHICS?"* | §3 |
| **20.0** | **comic book flies through the frame** | → *"NOT BAD CONSIDERING WE HAD LIKE ZERO MONEY IN THE BUDGET"* | mask 3 + §4b |
| 22.0 | POV, shoes on a doormat | *"Anyway, that's our opening title sequence."* | §3 |
| 23.5 | door with a sign | *"WE'RE HOPING IT'LL GET BETTER WITH EACH EPISODE…"* | §3 |
| 25.0 | hand pushes the door open, camera goes through | | mask 4 |
| 25.5 | **morph corridor**, 5–7 styles in 2.5 s | | §5 |
| 28.5 | title card out of an explosion | + spoiler line | landing |
| 32.3 | camera through the letter V | → black, credits | mask 4 + the one cut |

**What they couldn't hide** (verified in the frames ourselves, not taken from the press):
generated background text is nonsense (`ADMINOIIIG`, `NEW GOD`); the doors in the morph corridor have a
handle on both sides; the giant legs have no contact shadow. The hero text, by contrast, is perfectly
kerned, sits *in* the surface and has realistic wear — so it was put on in post. That contrast *is* the
lesson (§6).

**What saves the form**: the copy comments on itself (*"we had like zero money in the budget"*). That tone
grants licence for the artifacts. Without that licence you have to be photoreal and you lose on every
artifact — hence §2 rule 5.

---

## Prior art
- `scroll-video.md` §4 — portal chaining, occluder joins, luminance arc (same foundation, different
  control of time).
- `commercial-craft.md` §0 rule 1 (brand bracket) and rule 5 (Ken Burns ban; §2 rule 2 here explains the
  boundary), §1 (transitions), §2 (titles), §7 (pre-delivery inspection).
- `consistency.md` — anchor reference for the morph corridor.
- `vertical-916.md` — 9:16 is its own render.
- Reference: *Stuart Fails to Save the Universe*, ep. 1 opening credits, HBO Max, 2026.
