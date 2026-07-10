# Changelog — Video Studio skill

Format: [SemVer](https://semver.org). Newest on top.

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
