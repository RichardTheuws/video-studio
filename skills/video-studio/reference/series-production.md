# Series / campaign production — one storyboard, a PoC, parallel fan-out (video-studio §0.6)

The core flow (§0.5 intake → montage → §5 bar) is written for **one** film. The moment you have to deliver a
**set of related videos** — a feature series, a campaign, or the same video in N languages — the quality bar
doesn't change, only the *order of work* does: you storyboard the whole series first, prove the hardest move
once, and produce the rest **in parallel** from one proven template. This is the layer that scales "one video
in a few hours" to "five videos + a long-form, three languages, in one session" — without lowering the bar.

> **When is this mode?** More than one deliverable sharing a look/brand/arc: a feature series (e.g. one teaser
> per product feature), a launch with social cutdowns, a long-form film with embedded teasers, or multi-language.
> A single standalone video → stay in the normal §0.5 flow.

---

## 1. Storyboard the series, not the film (one sign-off for the whole set)

Before anything is built: one **series storyboard** that treats the whole set as a single arc.

- **The set + the through-line** — which episodes (features/subjects), and the shared frame that binds them
  (same leader/outro bracket, same grade, same music tone, same loudness target — e.g. −14 LUFS). Every episode
  must read as part of **one series**, not feel loose.
- **The long-form embeds the teasers** — plan the long video as the narrative whole the short teasers are cut
  from (or vice versa: the teasers are the export moments out of the long-form). So one storyboard delivers
  both the series *and* the long film, with shared beats.
- **A fixed beat structure per episode** — lock one skeleton every episode fills in, so fan-out becomes
  mechanical. Example (a 16s teaser): `leader 3s → hook → detail → subtitle → outro 4s`, cuts masked with a
  shared sting. Only the copy + capture choreography differ per episode.
- **One row per episode** in the storyboard (same format as `brand-intake.md` §5), plus a header table that
  records the shared constants (bracket, grade, music, loudness, aspect ratios, languages).

**Sign off the series storyboard before production** — the same gate as §0.5 step 5, but once for the whole set.
Nothing is produced until it stands. A mistake here multiplies by N episodes × M languages.

## 2. Prove the hardest move once (PoC gate before fan-out)

Before committing to the full set: generate **one proof-of-concept** of the hardest, most series-defining
element — the signature move that recurs everywhere. If the PoC holds → scale. If it fails → you've spent one
video, not N×M.

- Build the PoC in **both aspect ratios** if the series ships both, so it proves the technique end-to-end
  before a single episode is built.
- This is the series-scale version of the existing rule "validate one cut before fan-out" (SKILL §5 /
  `brand-intake.md` §6): for a series you validate not one cut but the **whole mini-pipeline of one episode** —
  bracket, grade, music and both ratios included — as proof the template is correct.

## 3. Deterministic capture rig (reproducible "real footage" from a live product)

For UI / product videos the source footage isn't a one-off recording but a **repeatable rig**. This is what
makes fan-out reliable: every run yields identical frames, so you can regenerate languages/variants without
drift.

- **A Playwright rig against the local dev server with mock data** (e.g. a `USE_MOCKS` flag) — no auth wall, no
  live API, so feed posts / map pins / list items are stable between runs.
- **Capture at the TARGET format** (iron rule, SKILL §2): render mobile at the **real app-webview viewport**
  (e.g. 390×844, `deviceScaleFactor 3` = 1-to-1 with what the app shows) for 9:16, and desktop (e.g. 1440×900,
  `dsf 2`) for 16:9. Never reframe a desktop grab for 9:16.
- **`settle()` before every shot** — wait for `networkidle` + a short extra pause (longer for maps/animations)
  so tiles/motion have finished rendering. Determinism is the entire value of the rig.
- **Parametrise via env** (locale, routes-only, viewports-only, proof-recording) so one rig covers all
  screens × languages × viewports. A new screen = one line in the routes array.

No live product to record? Then "the rig" is your keyframe set (§0.5 step 6 / `consistency.md`): generate the
anchor reference once, reuse it deterministically across every episode.

## 4. One template → parallel fan-out (idempotent build per episode)

Build the first episode fully as a **template**; the rest is a variable swap.

- **Build episode 1 end-to-end and fully scripted** (`prepare-<x>.sh` = generate source assets,
  `build-<x>.sh` = assemble both ratios). It becomes the template — swap a language variable and, for another
  feature, the copy + capture choreography.
- **Idempotent builds** — each `build-*.sh` overwrites its outputs identically. This is what makes running in
  parallel safe: no run pollutes another, and a re-run after a copy fix is free.
- **Fan-out = parallel tracked tasks** — produce the remaining episodes (+ languages) concurrently as
  background tasks (each an agent/job filling the same template with different copy). Never assume "looks done":
  inspect each output separately at pre-delivery (§5).
- **Shared constants stay identical across the set** — bracket, grade, music, loudness, aspect-ratio pair. If
  one episode deviates it no longer reads as a series. The template enforces this; change the constants only in
  the template and re-run.

## 5. Fan-out discipline (the traps that multiply with N)

- **Validate before you multiply** — the series storyboard (§1) and the PoC (§2) stand before episode 2 begins.
  The most expensive mistake is producing a wrong assumption N×M times.
- **Pre-delivery per output, not per series** — a moving medium is never judged on one thumbnail (SKILL §5 /
  `commercial-craft.md`). For a series: a dense frame-strip per episode, in both ratios, in every language.
  Fan-out means more inspections, not fewer.
- **Source hygiene per language** — on-screen copy = the exact product strings per language (matches the app).
  The rig delivers this when you set the locale correctly; verify it per language, never guess.
- **Cost scales too** — paid generation (i2v, stills) × N episodes × M languages. Report the total
  estimated/actual cost briefly and factually before the full fan-out (SKILL §5).

## Series-gate output (checklist)
- [ ] Series storyboard: the set + through-line + fixed beat structure + long-form embedding → **sign-off** before production
- [ ] Shared constants recorded (bracket, grade, music, loudness, aspect-ratio pair, languages)
- [ ] PoC of the signature move built + approved before fan-out
- [ ] Capture rig deterministic (mock data, target-format viewports, `settle()`) — or keyframe anchor recorded
- [ ] Episode 1 built as an idempotent template; the rest = variable swap
- [ ] Fan-out run in parallel as tracked tasks; every output inspected separately at pre-delivery
- [ ] Total cost reported before the full fan-out

> New lesson about series production / fan-out → append in `lessons.md` + bump `CHANGELOG.md`.
