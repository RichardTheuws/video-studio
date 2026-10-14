---
name: video-studio
description: Produce and edit video end-to-end — cut existing footage (auto-selecting clips by subject) or full-AI (consistent image generation → image-to-video → montage with audio). Use for trailers, cinematics, promos, social clips, montages, "make/edit a video or trailer", image-to-video, or any video-production/-editing task. Runs a tooling preflight first and maintains its own playbook.
---

# Video Studio

End-to-end video production and editing, plus consistent image generation. Two modes (combinable), one quality bar. Treat this as **professional work**, not a gimmick.

## 0. ALWAYS FIRST: preflight (non-negotiable)

Before every job, run the tooling check and pick the mode.

```bash
bash scripts/preflight.sh <ai|footage|all>
```

**The iron rule — never silently degrade.** If a tool/key the chosen mode needs is missing (ffmpeg, nano-banana, FAL_AI_KEY, ImageMagick for lettering, yt-dlp for URL sources…): **STOP and ask** in A/B/C form — *install / different approach / cancel* — and act on the answer. Only install after approval. **Never** "skip" a step or take a lesser route without saying so. A missing capability is the user's decision, not a silent assumption.
> Why this rule exists: ImageMagick was once "skipped" without asking, while the user would gladly have allowed the install. Making capability gaps visible is the core of this skill.

> First-time setup? Point the user at `scripts/doctor.sh` — a friendly "is my machine ready?" check with install commands per mode.

## 0.5 Intake / brief — define the job (REQUIRED, before mode)
Preflight checks the *tooling*; intake checks the *job*. Never skip it — a wrong assumption here (no brand canon, no storyboard) forces an expensive rebuild. Walk this gate explicitly and report what you found. Full procedure: **`reference/brand-intake.md`**.

1. **Brief** — goal (teach/launch/reach), format(s) + aspect (16:9 / 9:16), length, channel, languages, deadline. One line: "what has to land?".
2. **Brand style guide — does one already exist? (ALWAYS check)**
   - **Yes → adopt**: pull colours (hex), typography (fonts + weights), logo canon (variants + do-not rules), tone. Search the project (`brand/`, an existing site, logo files, a design guide). Never guess when a canon exists.
   - **No → create** (after approval): propose a minimal brand guide (colours, type, logo usage, tone) and save it. Don't build on an invented brand identity without proposing it.
3. **Leader + outro** — is there a branded intro/outro bracket for this brand? If not: build it once (per `commercial-craft.md`) and reuse it per film. Part of the brand canon, not per-video improvisation.
4. **Lines you never cross** — record the brand-specific hard rules (e.g. "only real music, only real people"). They apply to every film of that brand.
5. **Storyboard — needed?** Narrative or multi-shot video (launch/promo/cinematic) → **yes, shot-by-shot storyboard with sign-off before production** (this is the first of two sign-offs; the second is final approval). Single-shot/mechanical (short screen capture) → light: concept round only (§1.5). When in doubt: storyboard.
6. **Keyframe plan (for AI imagery)** — decide per shot which need a generated start-frame, with which anchor (`consistency.md`). **Validate one keyframe / one cut before fanning out** to all shots/languages/variants (§5 pre-delivery). Never generate the whole set blind.

> Gate output: a mini-brief + (adopted/created) brand canon + storyboard decision + keyframe plan. Only then proceed to mode selection.

## 0.6 One video or a series? (sets the order of work)
Do you have to deliver **more than one** related deliverable — a feature series, a campaign with social cutdowns, a long-form film with embedded teasers, or the same video in N languages? Then switch to **series mode**. The quality bar doesn't change; the *order* does: **storyboard the whole set first → prove the hardest move with one PoC → produce the rest in parallel from one proven, idempotent template.** This scales "one video in a few hours" to "five videos + a long-form, three languages, in one session" without lowering the bar. A single standalone video → stay in the normal flow. Full recipe (series storyboard + sign-off, PoC gate, deterministic capture rig, parallel fan-out, fan-out discipline): **`reference/series-production.md`**.

## 1. Which mode?

| Question | Mode |
|------|-------|
| Does the footage already exist (local files or URLs)? | **A — Existing footage** → `reference/existing-footage.md` |
| Must the imagery be generated (no usable footage)? | **B — Full-AI** → `reference/models.md` + `reference/consistency.md` |
| Both (AI shots between real clips)? | Combine; montage always via `reference/montage-ffmpeg.md` |
| Is the film **played by the scrollbar** (web hero, brand manifesto)? | **C — Scroll video** → `reference/scroll-video.md` (all-intra encode, scrubber, portal-chaining; an explicit exception to "locked-off camera") |

When unsure whether usable footage exists: **inventory first** (mode A, "auto-select" step), then propose what AI should fill in.

## 1.5 Concept round → storyboard sign-off (STANDARD)
This is intake step 5. For any video with a creative/narrative layer (titles, treatment, montage tone, storyboard): do **not** start with one chosen direction. First give the user **3 concrete concept suggestions** — story/title/treatment directions, recommended first, with the copy/arc per concept. The user picks before the full build. This prevents "beautifully made, wrong story".
- Titles/story must tell a **rising arc** (setup → tension → payoff → identity), not loose labels. Deliver the exact lines per concept, not just a theme.
- Then layer up: **GOOD → EXTREME** (a coherent version first, then push to per-letter kinetics, beat-sync, light-leaks). Show intermediate steps.
- **For a narrative/multi-shot video this is a sign-off gate**: the chosen concept becomes a **shot-by-shot storyboard** (beat, on-screen copy, shot-type, source: real footage / AI keyframe) the user **approves before production**. Nothing is produced until the storyboard stands. (See `reference/brand-intake.md` for the storyboard format.)
- **A visual keyframe storyboard is the cheap gate before i2v.** For AI imagery, render the storyboard as a board of **real keyframes (stills)** before you run a single second of image-to-video — stills cost cents (~€0.60 for 10), i2v costs ~€5. That de-risks the spend and gives the client direction on something tangible. Generate at **delivery quality** (the board is the personalised floor, not a shop window). Recipe + script: **`reference/storyboard-keyframes.md`** (`scripts/storyboard.sh`).

## 2. Mode A — Existing footage (auto-select by subject)
**IRON RULE — screen captures always at the TARGET format.** Make/render a screen capture in the same aspect ratio as the output: 16:9 video → capture at desktop width; **9:16 video → render the page at MOBILE width (native vertical layout) and capture 9:16**. Never reuse/reframe a 16:9 desktop grab for a 9:16 video (or vice versa). Render a responsive page headless at the right width (see `lessons.md` 2026-07-09). Stretching or "pasting on a background" is not a native capture.

Short: inventory → (download) → **extract frames and visually inspect to select by subject** → trim/concat/grade → montage. Auto-select leans on your own multimodal read: pull thumbnails with ffmpeg, **read them**, pick the matching segments. Full recipe + commands: **`reference/existing-footage.md`**.

## 3. Mode B — Full-AI (consistent image production → video)
Short: **keyframe-first**. Generate a start-frame per shot where subject + environment are already correct (nano-banana/Flux, with a reference anchor for consistency), then animate *that* frame with image-to-video (fal.ai Kling v3 Pro; Veo is shut down on 2026-10-25). Never blind text-to-video. Models/costs/params: **`reference/models.md`**. Consistency techniques (anchor reference, text-less + separate lettering, custom LoRA): **`reference/consistency.md`**.

**Is the deliverable a leader / title sequence / brand intro (20–35s)?** There is a worked-out form that reads premium and is cheap: **`reference/title-sequence.md`** — text-in-the-world + a straight camera move, four maskings so the whole sequence has **one** visible cut, and the occluder trick that turns one generation into several beats.

## 3.5 Directing & rhythm (REQUIRED for every multi-shot video)
A string of technically correct shots is not yet a film. **Before you generate a single keyframe**, each shot has a fixed **size** (XCU/CU/MS/WS), **camera height**, **the one action** and the **cut length**. Three hard rules: size contrast at every meaningful moment (never two equal sizes in a row in the same location), one action per shot, and the action already sits *in the keyframe* — not in the video prompt (the lever is upstream, `lessons.md` 2026-08-19).

**And: NEVER use an i2v clip at full length.** 4/6/8 s is the model's enum, not your shot length. Cut to 1.2–2.0 s (punchline/insert), 2.0–3.0 s (ordinary beat), 3.0–4.0 s (establishing/closer) — with real variance; a film where every shot lasts the same feels dead. Pick the strongest window by measurement, not by feel: `scripts/pick-window.sh <clip> <sec> [--cut out.mp4]`. Full: **`reference/directing.md`**.

## 4. Montage & audio (both modes)
ffmpeg montage with proven gotchas (decoupled muxing, synth SFX, `font=Impact`, the zsh `${var}[label]` trap, FX on black + `blend=screen`): **`reference/montage-ffmpeg.md`**. Run long fal jobs as **tracked background tasks**; never assume "looks done" — inspect frames.

## 5. Quality bar — commercial/premium (REQUIRED)
Read **`reference/commercial-craft.md`** before every commercial video. That's the bar that makes work feel paid-for. **The bottom line** (§0 there): every video clears the reference standard — brand ownership (leader+outro+brand wrap), external material as element-in-your-context, enough text to explain the story (including over embedded pieces), and an arc that lands on the message. Below that → rebuild, don't ship. The default mistakes you NEVER make:
1. **No hard-cut-by-default** — premium leans on crafted transitions (cross-dissolves, dip-to-white/black, speed-ramps, J/L-cuts). Hard cut only deliberately on the beat. (ffmpeg `xfade`.)
2. **No thin/unreadable titles** — text is always **heavy (700–900), large, with backing** (scrim/glass-plate/bar) and holds long enough to read. One type system. Never a thin line of text on a busy picture. (Title layer via HyperFrames, `reference/titles-hyperframes.md`; pango PNG is the fallback.)
3. **No flat/jumping grade** — one consistent, rich grade across all shots + grain/dither.
4. **No slideshow** — clips placed 1-to-1 at full i2v length is the most common failure mode. Check before delivery: **average shot length < 3.0 s** for teaser/comedy, **spread > 0.6 s**, at least 3 different shot sizes, and every requested action actually visible (`reference/directing.md` §6).
Plus: **hero breathes**, **cut on beat/motion**, **hook in the first 1.5s**, audio loudnorm+duck. Never end on "technically works" — test against the premium bar and the QA checklist in `commercial-craft.md`.

**REQUIRED before delivery — Pre-delivery inspection (`commercial-craft.md` §7):** a moving medium is NEVER judged on stray thumbnails. View a dense frame-strip (≤0.7s), the out-frame of A next to the in-frame of B per cut, hold/legibility of cards, and source hygiene (subs/watermark/grade). And validate one cut before fanning out to languages/variants. Skipping this was the #1 failure source.

- **Consistency above all**: character/style identical across all shots (anchor reference; keyframe-first).
- **Always really inspect**: pull frames and look; never trust "completed" alone.
- **No placeholder as final**: canvas/generated, no emoji.
- **Cost-aware**: report estimated/actual cost of paid generation briefly and factually — and say where the money went (it sits in i2v generation, not in montage or captures).

## 6. Self-maintenance (continuously — required)
This skill must grow. On **every** run:
1. **Before**: run preflight (§0). A new capability gap → ask + (after approval) install.
2. **During/after**: the moment you learn something — a working workaround, a broken/new model, a price change, a tool that breaks another tool, a better prompt technique — **record it immediately**:
   - New lesson/gotcha → append in **`reference/lessons.md`** (with date + a 1-line why).
   - Changed model/price/endpoint → update **`reference/models.md`**.
   - New/changed tool or install step → update **`reference/tooling.md`** + `scripts/preflight.sh` + `scripts/doctor.sh`.
   - Bump **`CHANGELOG.md`** (date + 1 line).
3. **In doubt whether the skill is still correct** (last review > ~1 month ago, or a model/price feels stale): say so and propose a quick verification (1 test call) before building on the old assumption.

## Files
- `scripts/doctor.sh` — friendly one-time "is my machine ready?" onboarding check.
- `scripts/preflight.sh` — per-job tooling/keys check, mode-aware, exit≠0 if something required is missing.
- `scripts/storyboard.sh` — generates a **visual keyframe storyboard** (stills, 3/5/2) as the cheap gate before i2v; auto-anchor for consistency, labelled board + cost line.
- `scripts/pick-window.sh` — measures the strongest window in an i2v clip (`<clip> <sec> [--cut out.mp4]`).
- `scripts/render-titles.sh` — renders the HyperFrames title layer as a transparent ProRes 4444 MOV, with a QA gate on alpha + duration.
- `templates/titles/` — the title-layer composition (one source for 9:16 + 16:9, fonts + GSAP bundled, brand via `spec.brand`).
- `reference/storyboard-keyframes.md` — **the storyboard gate** (§1.5): why (i2v economics + de-risking), the honesty/floor rule, beats→prompts→board recipe, edge cases.
- `reference/brand-intake.md` — **the intake gate** (§0.5): brand adopt-or-create, leader/outro, lines-you-never-cross, storyboard format + sign-off, keyframe plan.
- `reference/series-production.md` — **series / campaign mode** (§0.6): series storyboard + sign-off for the whole set, PoC gate before fan-out, deterministic capture rig, one template → parallel fan-out, fan-out discipline.
- `reference/tooling.md` — every tool + install/check commands + keys.
- `reference/models.md` — model registry (image + image-to-video + audio) with costs/params/when.
- `reference/consistency.md` — consistent image production (anchor reference, text-less + lettering, custom LoRA, Flux biases).
- `reference/directing.md` — **directing, rhythm & dynamics** (§3.5): shot grammar (size/height/one action/cut length) before generation, the action in the keyframe, "generate long, cut short" with target lengths, the measured window (`scripts/pick-window.sh`), cut-on-action + speed-ramps, and the measurable QA thresholds.
- `reference/montage-ffmpeg.md` — montage recipes + ffmpeg gotchas.
- `reference/commercial-craft.md` — **the premium bar**: transitions (no hard-cut default), readable heavy titles with backing, pacing, grade finish, QA checklist.
- `reference/landscape-from-vertical.md` — **16:9 from a 9:16 source** without stretching: the reframe toolkit (animated pan/tilt — crop x/y is per-frame!, static crop, split/multi-panel, editorial frame, blurred-fill fallback, seamless overflow). Always check the source orientation first.
- `reference/vertical-916.md` — **a 9:16 master from a 16:9 production** (REQUIRED for every 9:16 deliverable): the 5-step recipe (crop the high-res source → 9:16-native i2v → titles in the safe band → portrait cards with logo → 9:16 montage). **Never a flat scale, letterbox or blurred fill of the 16:9** — that is not a 9:16 master.
- `reference/titles-hyperframes.md` — **the title layer**: template in `templates/titles/` (brand via `spec.brand`), a spec with times from the measured montage offsets, `scripts/render-titles.sh` → transparent MOV → one overlay. Bit-identical across machines.
- `reference/title-sequence.md` — **the brand leader / title sequence** (a form within mode B): the joke or promise is written *in the world* and the camera drives toward it. Four maskings to join N shots with **one** visible cut, the occluder as a free second shot (one generation, N texts), the morph walk, and the hard rule **never generate hero text — always composite it**. ~€10–20 for 33 s.
- `reference/scroll-video.md` — **scroll-driven film** (mode C): all-intra encode (every frame a keyframe) + verification, blob preload, damping/dead-zone scrubber, and the camera method (portal-chaining, occluder joins, luminance arc, a reserved text zone). Contains the only allowed exception to **NEVER Ken Burns / locked-off camera**.
- `reference/existing-footage.md` — existing video: probe, download, subject auto-select, trim/concat/grade.
- `reference/print-on-product.md` — **putting a real print/logo on a product** (merchandise, textiles, promo): the albedo × light model, the measured method (log domain, robust polynomial fit, alpha from deviation: SSIM 0.26 → 0.92 against ground truth), the cross-validation setup, and why virtual-try-on models collapse on film footage. Read this before any video where a printed item is the hero.
- `reference/lessons.md` — running log of production lessons (append-only).
- `CHANGELOG.md` (repo root) — maintenance history of this skill.
