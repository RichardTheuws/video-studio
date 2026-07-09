# Intake / brief — establish the assignment + the brand (video-studio §0.5)

Preflight checks the tooling; this gate checks the **assignment** and the **brand canon**. Always walk it explicitly and report what you found — a wrong assumption here (no brand canon, no storyboard, blindly generating all shots) is the most expensive mistake in the pipeline. Output: a mini-brief + adopted/created brand canon + storyboard decision + keyframe plan. Only then proceed to mode selection.

## 1. Brief (always, 6 fields)
| Field | Example |
|-------|---------|
| Goal | teach (instruction) · launch (feature/story) · reach (promo/social) |
| Format + aspect | 16:9 · 9:16 · both (hero + cutdown) |
| Length | 15–30s promo · 30–90s instruction · 60–75s launch |
| Channel | in-app · hero · social · help centre |
| Languages | e.g. primary + EN + DE — on-screen copy = exact product strings |
| "What must land?" | one sentence — the core the viewer remembers |

## 2. Brand style guide — ALWAYS check first (adopt or create)
**Never build a video on an unconfirmed brand canon.** Search first, then decide.

**Does a guide already exist? → ADOPT.** Search order:
1. `brand-kits/<brand>/` in the project repo (canonical if present).
2. Existing site / design guide / `style.css` / `console.css` of the brand (extract tokens).
3. Logo files (SVG/PNG), existing videos (reverse-engineer leader/outro).

Pull at minimum and record:
- **Colors** — primary/secondary/accent as hex, plus text/background.
- **Typography** — fonts + weights (heading vs body), and the type system for titles (heavy 700–900, with a backing — see `commercial-craft.md`).
- **Logo canon** — variants (color/mono/white), safe area, and **squash rules** (never squash/stretch a mono logo — a known trap).
- **Tone** — warm/corporate/raw; what the brand *never* does.

**No guide exists? → CREATE (after approval).** Propose a minimal guide (colors + type + logo usage + tone), present it in the A/B/C form for real choices, and save it as `brand-kits/<brand>/brand.md` + assets. Don't build production on a guessed brand identity.

## 3. Leader + outro (per brand, reusable)
Each brand gets one **branded bracket**: a leader (intro) and outro that recur on *every* video — no per-video improvisation.
- Build once per `commercial-craft.md` (heavy titles with backing, brand grade, brand music tone).
- Save the renderable source + a short spec in `brand-kits/<brand>/` (duration, colors, logo placement, music bed).
- Reuse afterwards; only change it when the brand canon changes.

## 4. Lines we never cross (per brand)
Record the hard, brand-specific rules — they apply to *every* video of that brand. Common examples:
- **Real people only** (faces = real photos/footage; AI imagery only for non-human: posters, backgrounds, title cards).
- **Music**: strictest brand variant = licensed tracks only. See below for the general floor.

**Music — the general rule (applies everywhere, unless a brand is stricter):** instrumental **muzak / neutral beds are always fine** — including AI-generated (e.g. fal stable-audio underscore). **Forbidden is only AI "fake music" that imitates real pop songs**: vocals, hooks, recognizable song structure that imitates a real track. So prompt for *underscore/bed/ambient/score*, never for a "song". Always audibly verify it reads as a **bed**, not a song. (One way to phrase the brand rule: "a real licensed track *or neutral background muzak* — never a synthetic AI song".)

Ask about these limits explicitly for each new brand and note them in `brand-kits/<brand>/`.

## 5. Storyboard — needed? (the first of two sign-offs)
- **Narrative / multi-shot** (launch, promo, cinematic) → **yes**: shot-by-shot storyboard, **sign-off before production**. Nothing is produced until it's approved.
- **Single-shot / mechanical** (short instruction capture) → light: only the concept round (SKILL §1.5).
- **When in doubt: storyboard.**

**Storyboard format** (one row per beat):
| # | Beat (arc) | On-screen copy | Shot type / camera | Source | Duration |
|---|-----------|----------------|--------------------|--------|----------|
| 01 | Passion — "what you love" | "You love what you do." | close, warm | real footage | 0–3s |
| 03 | Offer | "Available as a speaker" | UI capture (real screen) | live capture | 3–12s |
| 08 | Trust — payoff + CTA | "Shared passion builds trust." | endcard over faces | real footage | 34–54s |

The arc builds up (setup → tension → payoff → identity), not loose labels. On-screen copy = exact product strings for UI video (matches the app per language).

## 6. Keyframe plan (only with AI imagery)
- Decide per shot: does it need a **generated start frame**, and with which **anchor** (`consistency.md` §1 — keyframe-first + anchor reference for cross-shot consistency)?
- Generate text-free; lettering separately (`consistency.md` §3).
- **Validate one keyframe / one cut before fan-out** to all shots/languages/variants (SKILL §5 pre-delivery). Never blindly generate the whole set — this was the #1 failure source.

## Gate output (checklist)
- [ ] Mini-brief (6 fields) filled in
- [ ] Brand canon: **adopted** (source cited) or **created** (proposed + approved) → in `brand-kits/<brand>/`
- [ ] Leader/outro: exists / built once
- [ ] Lines-we-never-cross noted
- [ ] Storyboard: needed? if so → made + **sign-off** before production
- [ ] Keyframe plan (for AI): anchor chosen, one cut validated before fan-out

> New lesson about intake/brand canon → append in `lessons.md` + bump `CHANGELOG.md`.
