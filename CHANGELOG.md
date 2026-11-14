# Changelog — Video Studio skill

Format: [SemVer](https://semver.org). Newest on top.

## 1.4.0 — 2026-11-14
- **A story layer: `reference/scenario.md` + `reference/taxonomy.md`.** Telling order (open on the peak, then show how) and ±85 lessons across 11 video types (teaser, promo, social proof, explainer, tips, spotlight, walkthrough, leader, series, brand film, personal film). Every lesson carries a status (`external-strong` / `external` → `signal` → `house-rule`), its evidence and the metric that would confirm it; conflicts between lessons are resolved explicitly. A fixed tag vocabulary goes in the front matter of `brief.md` so a learning loop can link choices to results.
- `qa-check.sh --titles spec.json`: reading-time gate per title from the HyperFrames spec, ≥ max(1.5 s; characters ÷ 15).
- `SKILL.md` §1.5, `commercial-craft.md` §0.4 and `storyboard-keyframes.md` (draw the peak keyframe first) point to it.

## 1.3.4 — 2026-11-14
- **Kling v3 Pro is the default for every shot again.** fal retired Seedance 1.5 Pro on 2026-11-11; `models.md` marks it as retired, README/doctor/tooling no longer name it. New lesson: a retirement date is in the models API (`retires_at`), not in the pricing API.
- **Pango is no longer the title-layer fallback** (the three-production condition for HyperFrames is met); it stays for text in the world and stills.
- Lessons: an end-frame chain cut as one continuous shot, Kling 9:16 transition identity drift, Gemini 402 → nano-banana-pro on fal, LFS pointers as references, ImageMagick `-geometry` leak, uint8 overflow in a custom renderer.
- Plugin manifests were still on 1.3.2; now in step with the changelog.

## 1.3.3 — 2026-11-09
- `fal.sh` cost log: image endpoints (unit `images`, e.g. `fal-ai/nano-banana-pro`) are now estimated as price × `num_images`. Before, they logged `null` and a run with `num_images: 2` was easy to undercount by half in a cost report.

## 1.3.2 — 2026-11-08
- **EU AI label in the title template.** The official European Commission icons (AI / AI GENERATED / AI MODIFIED, white and black) ship in `templates/titles/shared/eu-ai-label/`; a new `ailabel` spec item places them inside the safe band (9:16 bottom-left, 16:9 bottom-right) with a plain-language text such as "Made with AI". Required by `commercial-craft.md` §0 rule 6 (EU AI Act Art. 50).

## 1.3.1 — 2026-11-08
Review fixes on 1.3.0 (none of these changes the recipes):
- `fal.sh key` no longer reads `./.env` / `../.env` (the result depended on the caller's cwd); `preflight.sh` and `doctor.sh` use the same order. A project file is passed explicitly via `$VIDEO_STUDIO_ENV`.
- `fal.sh`: `.env` values with a trailing `# comment` are parsed correctly; `fal_wait` fails fast on an error body (`{"detail":…}`) instead of polling until the timeout.
- `qa-check.sh`: the AI-label check matches the real marker (`AI-generated`, `Made with AI`, `AI Act`) instead of any `AI` substring; empty `--cuts` file is a FAIL; `--lufs` is honoured regardless of `--social` order; missing option values exit 2 with a message; true-peak gate is −1.0 dBTP as documented.

## 1.3.0 — 2026-11-08
An audit release: the lessons of three months turned into gates and one library, not more prose.

- **`scripts/lib/fal.sh` — the one fal.ai layer.** Key resolver (`env → $VIDEO_STUDIO_ENV → ~/.config/video-studio/.env`; deliberately no cwd-relative `.env`),
  upload to fal's own storage (never a public host of your own — the request body goes via a file, so no more ARG_MAX
  requests without a body), `submit`/`wait`/`result`/`run`/`cancel`/`delete`, a price lookup and a cost log per production
  (`costs.jsonl`, `fal.sh costs` sums it). Privacy defaults: no request history at fal (`X-Fal-Store-IO: 0`), uploads expire
  after 24 h, outputs after 7 days. Why: dozens of productions each had their own polling loop and the same bug was logged twice.
- **`scripts/qa-check.sh` — the measurable QA gate.** Format, SAR, pix_fmt, bt709 colour tags, duration, file size, loudness /
  true peak, shot length and spread, dead cuts, and the AI label in the metadata — each as PASS/FAIL with the rule it comes
  from; exit ≠ 0 = don't deliver. Why: three rules that had stood in the docs for months were all failed by one delivered video.
- **AI label is a rule** (`commercial-craft.md` §0 rule 6): "Made with AI" on the end card and
  `-metadata comment="AI-generated imagery — <brand>, EU AI Act art. 50"` on the master. Law in the EU since August 2026, honest everywhere.
- **Seedance 1.5 Pro is the default for single shots** (`models.md`); Kling v3 Pro stays for start+end-frame transitions
  (measured: Seedance holds identity equally well at native 1920×1080 and roughly 40 % of the price, but its end-frame
  transition runs and then switches hard). Kling v3 Pro is now $0.14/s.
- **Encoder measured** (`montage-ffmpeg.md`): hardware encoding (VideoToolbox) is slower *and* worse than
  `libx264 -preset veryfast` — KILL. Masters `-preset slow -crf 18`, previews `-preset veryfast -crf 20`.
- **Lessons consolidated into the playbooks.** `lessons.md` is now an index (date · measurement · pointer); the rules moved
  into thematic sections: `montage-ffmpeg` "Pitfalls from the log", `tooling` "Build gaps and shell pitfalls", `models`
  "Measured behaviour of i2v models", `consistency` §6–7 (keyframe pitfalls, keying and alpha), `directing` §7,
  `series-production` "Pitfalls in the capture rig", `brand-intake` §7, `commercial-craft` §9 "Measurement discipline",
  `title-sequence` §12, `existing-footage` §7–8, `print-on-product` §8, `vertical-916` additions.
- **Preflight**: same key search order as `fal.sh`; set `VIDEO_STUDIO_PEER=<ssh-host>` and it also reports skill drift,
  ffmpeg version and node on a second render machine (warns, never blocks). `doctor.sh` checks the same key locations.
- HyperFrames stays pinned at 0.8.99 (measured against 0.9.23: only anti-aliasing differs on motion frames; the pin is
  re-tested across machines before any upgrade).

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
