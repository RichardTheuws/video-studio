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

## 1. Which mode?

| Question | Mode |
|------|-------|
| Does the footage already exist (local files or URLs)? | **A — Existing footage** → `reference/existing-footage.md` |
| Must the imagery be generated (no usable footage)? | **B — Full-AI** → `reference/models.md` + `reference/consistency.md` |
| Both (AI shots between real clips)? | Combine; montage always via `reference/montage-ffmpeg.md` |

When unsure whether usable footage exists: **inventory first** (mode A, "auto-select" step), then propose what AI should fill in.

## 1.5 Concept round → storyboard sign-off (STANDARD)
This is intake step 5. For any video with a creative/narrative layer (titles, treatment, montage tone, storyboard): do **not** start with one chosen direction. First give the user **3 concrete concept suggestions** — story/title/treatment directions, recommended first, with the copy/arc per concept. The user picks before the full build. This prevents "beautifully made, wrong story".
- Titles/story must tell a **rising arc** (setup → tension → payoff → identity), not loose labels. Deliver the exact lines per concept, not just a theme.
- Then layer up: **GOOD → EXTREME** (a coherent version first, then push to per-letter kinetics, beat-sync, light-leaks). Show intermediate steps.
- **For a narrative/multi-shot video this is a sign-off gate**: the chosen concept becomes a **shot-by-shot storyboard** (beat, on-screen copy, shot-type, source: real footage / AI keyframe) the user **approves before production**. Nothing is produced until the storyboard stands.

## 2. Mode A — Existing footage (auto-select by subject)
**IRON RULE — screen captures always at the TARGET format.** Make/render a screen capture in the same aspect ratio as the output: 16:9 video → capture at desktop width; **9:16 video → render the page at MOBILE width (native vertical layout) and capture 9:16**. Never reuse/reframe a 16:9 desktop grab for a 9:16 video (or vice versa). Stretching or "pasting on a background" is not a native capture.

Short: inventory → (download) → **extract frames and visually inspect to select by subject** → trim/concat/grade → montage. Auto-select leans on your own multimodal read: pull thumbnails with ffmpeg, **read them**, pick the matching segments. Full recipe + commands: **`reference/existing-footage.md`**.

## 3. Mode B — Full-AI (consistent image production → video)
Short: **keyframe-first**. Generate a start-frame per shot where subject + environment are already correct (nano-banana/Flux, with a reference anchor for consistency), then animate *that* frame with image-to-video (fal.ai Veo>Kling). Never blind text-to-video. Models/costs/params: **`reference/models.md`**. Consistency techniques (anchor reference, text-less + separate lettering, custom LoRA): **`reference/consistency.md`**.

## 4. Montage & audio (both modes)
ffmpeg montage with proven gotchas (decoupled muxing, synth SFX, `font=Impact`, FX on black + `blend=screen`): **`reference/montage-ffmpeg.md`**. Run long fal jobs as **tracked background tasks**; never assume "looks done" — inspect frames.

## 5. Quality bar — commercial/premium (REQUIRED)
Read **`reference/commercial-craft.md`** before every commercial video. That's the bar that makes work feel paid-for. **The bottom line** (§0 there): every video clears the reference standard — brand ownership (leader+outro+brand wrap), external material as element-in-your-context, enough text to explain the story (including over embedded pieces), and an arc that lands on the message. Below that → rebuild, don't ship. The three default mistakes you NEVER make:
1. **No hard-cut-by-default** — premium leans on crafted transitions (cross-dissolves, dip-to-white/black, speed-ramps, J/L-cuts). Hard cut only deliberately on the beat. (ffmpeg `xfade`.)
2. **No thin/unreadable titles** — text is always **heavy (700–900), large, with backing** (scrim/glass-plate/bar) and holds long enough to read. One type system. (Text via ImageMagick PNG → overlay.)
3. **No flat/jumping grade** — one consistent, rich grade across all shots + grain/dither.
Plus: **hero breathes**, **cut on beat/motion**, **hook in the first 1.5s**, audio loudnorm+duck. Never end on "technically works" — test against the premium bar and the QA checklist in `commercial-craft.md`.

**REQUIRED before delivery — Pre-delivery inspection (`commercial-craft.md`):** a moving medium is NEVER judged on stray thumbnails. View a dense frame-strip (≤0.7s), the out-frame of A next to the in-frame of B per cut, hold/legibility of cards, and source hygiene (subs/watermark/grade). And validate one cut before fanning out to languages/variants. Skipping this was the #1 failure source.

- **Consistency above all**: character/style identical across all shots (anchor reference; keyframe-first).
- **Always really inspect**: pull frames and look; never trust "completed" alone.
- **No placeholder as final**: canvas/generated, no emoji.
- **Cost-aware**: report estimated/actual cost of paid generation briefly and factually.

## 6. Self-maintenance (continuously — required)
This skill must grow. On **every** run:
1. **Before**: run preflight (§0). A new capability gap → ask + (after approval) install.
2. **During/after**: the moment you learn something — a working workaround, a broken/new model, a price change, a tool that breaks another tool, a better prompt technique — **record it immediately**:
   - New lesson/gotcha → append in **`reference/lessons.md`** (with a 1-line why).
   - Changed model/price/endpoint → update **`reference/models.md`**.
   - New/changed tool or install step → update **`reference/tooling.md`** + `scripts/preflight.sh` + `scripts/doctor.sh`.
   - Bump **`CHANGELOG.md`** (date + 1 line).
3. **In doubt whether the skill is still correct** (last review > ~1 month ago, or a model/price feels stale): say so and propose a quick verification (1 test call) before building on the old assumption.

## Files
- `scripts/doctor.sh` — friendly one-time "is my machine ready?" onboarding check.
- `scripts/preflight.sh` — per-job tooling/keys check, mode-aware, exit≠0 if something required is missing.
- `reference/brand-intake.md` — **the intake gate**: brand adopt-or-create, leader/outro, lines-you-never-cross, storyboard format + sign-off, keyframe plan.
- `reference/tooling.md` — every tool + install/check commands + keys.
- `reference/models.md` — model registry (image + image-to-video + audio) with costs/params/when.
- `reference/consistency.md` — consistent image production (anchor reference, text-less + lettering, custom LoRA, Flux biases).
- `reference/montage-ffmpeg.md` — montage recipes + ffmpeg gotchas.
- `reference/commercial-craft.md` — **the premium bar**: transitions, readable heavy titles with backing, pacing, grade finish, QA checklist.
- `reference/landscape-from-vertical.md` — **16:9 from a 9:16 source** without stretching: the reframe toolkit.
- `reference/existing-footage.md` — existing video: probe, download, subject auto-select, trim/concat/grade.
- `reference/lessons.md` — running log of production lessons (append-only).
- `CHANGELOG.md` — maintenance history of this skill.
