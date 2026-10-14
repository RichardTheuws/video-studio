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

## 2.5 Naming a style: two layers (a name for the client, technique for the model)

Taken from a teardown of the Okay Spielberg tool. This is a **practice choice**, not measured model
behaviour — the three claims from that teardown that *could* be measured were tested the same day and
didn't hold (`lessons.md`). This one stands on its own grounds.

**The rule: a brand name, studio name, film title or artist name never goes into the prompt.**
Talk to the client in names ("the look of a 90s anime"), but send the model a **technique
description**. Two layers, then, and the translation happens before generation.

Why:
- **Liability.** A client delivery whose production prompt says "in the style of <studio>" is a
  document you don't want to show anyone. The technique description is neutral and defensible.
- **Providers block or water down names** — and they fail silently: you don't get a refusal, you
  get a generic look. If you don't know that failure mode, you'll look for the cause in the wrong place.
- **Reproducible and steerable.** A name is a black box that means something different per model; a
  technique description can be tuned, reused and recorded in the brand canon.

**How to build such a description** — cover every one of these explicitly, or the model falls back
to generic: drawing/render technique (cel, digital paint, 3D, photographic), line quality (heavy
outline, no outline, brush stroke), palette **with real colors** ("rust, muted cyan, warm ochre with a
neon accent"), lighting approach (flat cel, noir contrast, soft diffuse), proportions and facial
stylisation, background technique and level of detail, texture (grain, watercolor bleed, halftone) and
the feel of motion (on twos, fluid).

**Hard gate: never fall back to the bare style name.** If your technique description is too thin
(rule of thumb: less than one dense paragraph), stop — don't generate with the name as an emergency
measure. That's exactly the degradation you can't see in the output but can in the quality. Okay
Spielberg throws a hard error here; that's the right reflex.

**With imagery of real people: keep sensitive props out of the *style* description.** No smoking,
alcohol or weapons in the style text — that text also gets applied to photos of real people (possibly
minors) and has to pass the image generator's safety check. Carry the look entirely through render
technique, grade, light, composition and texture. The same mechanism once got a Veo prompt blocked on
the word "child" (`lessons.md`): the **prompt** is screened separately, even when the image is harmless.

**Same rule for music.** Replace a composer's name in a music prompt with 2–3 sentences about
instrumentation, harmonic language, rhythm and emotional register. That fits the existing floor
(`models.md`, Audio): an instrumental bed/underscore is fine, something that reads as a real pop song is not.

**Record it**: a brand's technique description belongs in `brand-kits/<brand>/brand.md`, next to colors
and type. It's part of the canon, not something you reinvent per video.

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
