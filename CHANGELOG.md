# Changelog — Video Studio skill

Format: [SemVer](https://semver.org). Newest on top.

## 1.2.0 — 2026-10-14
Three months of production, distilled. The biggest changes:

- **Model migration: Kling v3 Pro is the primary image-to-video model** (`models.md`). fal retires Veo 3 / 3.1 Fast on
  2026-10-25 — if you pinned Veo, move now. Measured on a test bench: Kling v3 Pro holds face + framing tightest and
  renders 9:16 natively. Note its 1928×1072 output (always scale + crop) and late action (use `pick-window.sh`).
- **New title layer: HyperFrames** (`titles-hyperframes.md`, `templates/titles/`, `scripts/render-titles.sh`). One HTML
  composition renders titles for 9:16 *and* 16:9 as a single transparent ProRes 4444 overlay — words that build, a
  typewriter card, an accent word that glows on the beat, a font-size ladder for long copy. Brand colours and fonts come
  in through the spec. Renders are frame-identical across machines (`--no-browser-gpu`). Pango/ImageMagick stays as
  fallback and for text *in* the world. Requires Node ≥ 22; `doctor.sh` and `preflight.sh` check it.
- **Directing & rhythm** (`directing.md` + `scripts/pick-window.sh`): shot grammar fixed before generation, cut lengths
  with variance as a requirement, measurable QA (mean shot length, spread, number of shot sizes), and a motion-energy
  tool that finds the strongest window in a clip.
- **New playbooks:** `title-sequence.md` (a brand leader with one visible cut), `storyboard-keyframes.md` +
  `scripts/storyboard.sh` (a visual keyframe board as the cheap gate before i2v), `vertical-916.md` (a real 9:16 master),
  `scroll-video.md` (a film played by the scrollbar), `print-on-product.md` (a print that reads as real, measured).
- **Craft bar:** no Ken Burns on stills — art-directed i2v with a locked camera, or a static hold (`commercial-craft.md`).
  Music bed measured, not judged by ear (`montage-ffmpeg.md`). Naming a style in two layers (`brand-intake.md`). A cast
  register for recurring characters (`consistency.md`).
- **`lessons.md` roughly tripled**, including measured negative results (e.g. `negative_prompt` is inert on Kling i2v;
  style-first prompts don't matter when the keyframe carries the style; Veo ignores `seed`).
- Bundled fonts (OFL) and GSAP are listed in `THIRD_PARTY_NOTICES.md`.

## 1.1.0 — 2026-07-10
- **New capability layer: series / campaign production** (`reference/series-production.md` + SKILL §0.6 + Files
  list). Scales the single-film flow to a set of related deliverables without lowering the bar. Five steps:
  (1) storyboard the whole series with one sign-off — the long-form embeds the teasers, a fixed beat structure
  per episode; (2) PoC gate — prove the hardest/signature move once before fan-out; (3) deterministic capture
  rig — reproducible "real footage" from a live product (Playwright + mock data, target-format viewports,
  `settle()`); (4) one idempotent template → parallel fan-out (variable swap per episode/language as tracked
  background tasks); (5) fan-out discipline (validate before you multiply, pre-delivery per output, source
  hygiene per language, cost scales too).

## 1.0.0 — 2026-07-09
First public release. A Claude Code skill for end-to-end video production & editing, driven from chat.

- **Two modes**: existing footage (subject auto-select via frame inspection) + full-AI (keyframe-first image-to-video).
- **Intake gate**: brief → brand adopt/create → leader/outro bracket → lines-you-never-cross → storyboard sign-off → keyframe plan, before anything is produced.
- **Premium quality bar** (`commercial-craft.md`): crafted transitions (no hard-cut-by-default), heavy readable titles with backing, one consistent grade + grain, pacing, pre-delivery inspection. Below the bar → rebuild, don't ship.
- **Machine doctor** (`scripts/doctor.sh`): friendly onboarding check — what you have, what's missing, which mode you can run, with install commands.
- **Per-job preflight** (`scripts/preflight.sh`): never silently degrade; stop and ask when a required capability is missing.
- **Reference playbooks**: tooling, models (image + image-to-video + audio, with costs), consistency (anchor reference, text-less + lettering, custom LoRA, Flux biases), montage + ffmpeg gotchas, existing-footage auto-select, reframe 9:16 ↔ 16:9, and a running lessons log.
- **Self-maintaining**: records new lessons, model/price changes, and tooling updates after every job.
