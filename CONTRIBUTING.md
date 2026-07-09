# Contributing to Video Studio

Thanks for wanting to make the studio better. This skill is designed to grow — new recipes, model updates, platform ports and sharper prompts are all welcome.

## Ways to contribute

- **New montage recipes / ffmpeg gotchas** → add them to `reference/montage-ffmpeg.md` or `reference/lessons.md` (with a one-line *why*).
- **Model or price updates** → `reference/models.md`.
- **New/changed tooling** → update `reference/tooling.md`, `scripts/preflight.sh` **and** `scripts/doctor.sh` together.
- **Platform ports** (Linux/Windows) → especially the `scripts/` — keep the macOS path working.
- **Docs & clarity** → the README and `SKILL.md` are the front door; improvements welcome.

## Ground rules

- **Keep it client-free.** No personal paths, keys, names, or client/brand identifiers — this is a public, reusable skill.
- **One quality bar.** Recipes should hold the standard in `reference/commercial-craft.md` (crafted transitions, readable heavy titles, one grade). No "technically works".
- **Keep commands real.** Prefer concrete, tested `ffmpeg`/`ImageMagick`/`fal.ai` commands over hand-waving.
- **Small, focused PRs.** One idea per PR. Update the `CHANGELOG.md`.

## Local check

```bash
bash scripts/doctor.sh          # is your machine ready?
bash scripts/preflight.sh all   # per-job gate
```

By contributing you agree your work is released under the repo's [MIT license](LICENSE).
