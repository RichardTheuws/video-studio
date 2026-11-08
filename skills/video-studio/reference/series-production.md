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
  mechanical. Example (a 16s teaser): `leader 3s → hook 3.8s → detail 3.2s → subtitle 2s → outro 4s`, cuts masked with a
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

### Pitfalls in the capture rig (consolidated from the log, 2026-11-08)
**Where the frames land and what you record with**
- A Playwright MCP running in Docker keeps screenshots inside the container, not on the host, so ffmpeg can't use them (2026-07-09, 07-10, 07-15). Host-side Playwright with `{ channel: 'chrome' }` (bypasses the bundled-chromium mismatch) or Chrome headless (`--headless=new --hide-scrollbars --force-device-scale-factor=2 --window-size=540,<tall> --screenshot`).
- **`recordVideo` gives black frames on WebGL** (compositor; 2026-07-11) → headed Chromium + a `page.screenshot` sequence (~220 frames per ratio). **`recordVideo` ignores `deviceScaleFactor`** (1280×720@1.5 gave 1280×720 top-left in a grey 1920×1080 frame; 2026-10-16, again 2026-11-03): record at the target resolution and zoom the page.
- **CDP `Page.startScreencast`** (jpeg q95) is sharper than recordVideo and only sends frames on change, with timestamps — but delivers **CSS pixels**, even with a dsf in the context (1440×810 instead of 1920×1080): start Chromium with `--force-device-scale-factor=<dsf>` and guard the frame width (2026-10-16). Do NOT assemble via an ffconcat list with a `duration` per frame (< 1/25 s is rounded up: 7.8 s → 10.2 s); resample to 30 fps CFR yourself (last frame received per output frame, a symlink series) and let the last frame run to the wall-clock end, otherwise the closing hold disappears. Cursor = your own fixed svg element with rAF easing.
- **A "live" terminal without screen-recording permissions**: log the command in a PTY with timestamps (asciicast v2), play it in xterm.js, step through time frame by frame (`advance(t)` + screenshot, 30 fps); its own column width per target format. Height of the xterm element = `rows × cell height`, otherwise half a row at the top (2026-11-01).
- **Format**: 16:9 at 1920×1080@1x gives text that is too small — take 1280×720@1.5 (same bitmap, 1.5× larger text); a CU at 960×540@2 gives real size contrast without zoompan (check the layout doesn't jump to mobile; 2026-11-01). 9:16 = 390×844 dsf 3, or 390×693 for a fixed-width app (`vertical-916.md`). Cap feed scrolls at ~2.5 viewport heights in ±5 s, never full page (white smear; 2026-07-15).

**Init scripts, masks and hydration**
- DOM patches and chrome hiding via `context.addInitScript` with a rAF loop until `<body>`/`<head>` exist (they can be null before the first paint; 2026-09-22), plus a MutationObserver. A `page.evaluate` after `goto` leaves the unpatched text up for 1.5–3 s; a 250 ms interval misses the first paint (2026-08-26).
- **An SSR error flash** ("ACCESS REQUIRED" ~0.3 s) is hidden preventively before the first paint (`main{visibility:hidden}` from document start) and released on a visible-text-node check with **`textContent`** — `innerText` is empty under `visibility:hidden` and gave two white beats (2026-08-26). Debug in isolation with a 100 ms DOM dump, not another blind capture.
- **Masking text before hydration breaks React** (#418/#423/#425): a name mask starts after `load`; cut the first seconds with the real name out in the build by starting every capture 2 s later (2026-09-22). Blur dynamic content in a MutationObserver too (skip already-blurred spans, or it wraps endlessly; 2026-11-01).
- **Read the whole page for names and numbers** before recording: a fixed list of competitor names missed one domain and figures not in the script (2026-11-01). Staging carries real names (admin accounts, confidential contacts, e-mail in the console; 2026-09-14).
- **Selectors**: pick the **smallest** element containing the text (sort by `textContent.length`), filtered on visible in the viewport (`getBoundingClientRect`, `height>0`); otherwise you scroll to the card header or highlight an invisible duplicate (2026-11-01). Filter out the site's own widgets (mascot) via `addStyleTag` (2026-07-15). A cookie banner (`position:fixed`) sits only at the bottom of a full-page render — crop the hero from that (2026-07-10).

**"Ok" is not proof**
- A beat that reports "ok" may have filmed a white page (dev server 500, invalid session; four such beats in one edit; 2026-08-26). Guard: 0 logged events for a non-silent beat → reject the take, exit ≠ 0. But mark scroll/cursor beats explicitly as 'silent' and don't reject on app errors (hydration, 401) — that's for the QA eye (2026-09-22).
- Empty `recordVideo.dir` (`rmSync(dir,{recursive:true,force:true})`) before every take and pick the **newest** file: `readdirSync(dir)[0]` promoted old broken takes and masked three diagnoses (2026-08-26). A raw folder with >1 webm = a symptom.
- `next dev` with 500 on every route (`Cannot find module './vendor-chunks/…'`) = a corrupt `.next`; `rm -rf .next` only helps once the old server is dead (`pkill -f next-server`) and the new one starts in its own session (`start_new_session=True`). Captures sequential, one owner of the server (2026-08-26).
- **Isolate the recording server in its own worktree** (`git worktree add --detach`, symlink node_modules, own port). Trap that cost three runs: `NEXT_PUBLIC_API_URL` still pointed at port 3000 → every logged-in beat "not found" while SSR and curl gave 200; set *all* `NEXT_PUBLIC_*` URLs and restart with a clean `.next` (2026-08-26). Diagnosis: API with token on both ports → equal → it's the client → grep env.
- **Staging**: logged-in pages never reach `networkidle` (polling) → `domcontentloaded` + a fixed settle (6 s). Mint tokens *inside* the staging stack (`docker run --rm --network <net> --env-file .env node:20-alpine npx tsx …`) with a guard that `DATABASE_URL` really is staging and a `trap` that removes the script (2026-09-14). A probe pass per beat with `expect` texts before sign-off found four deviations from the storyboard.
- What you film logged out shows auth errors ("Could not load …", 401): film in the intended role and report the error (2026-09-22). A mail preview in a sandboxed iframe isn't in `body.innerText` — wait for the empty state to disappear. `scrollIntoViewIfNeeded` on a table that arrives with the second data round times out: scroll to the bottom and wait for a cell.
- Verify the flow live before recording (bugs may have been fixed) and in-app "tour" buttons may be instruction modals (2026-07-07, 07-11). After rendering, measure the duration of your **segments**, not only the final film (`montage-ffmpeg.md`, 2026-09-22).

> New lesson about series production / fan-out → the rule here, one index line in `lessons.md`, bump `CHANGELOG.md`.
