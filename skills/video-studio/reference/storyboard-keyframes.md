# Visual keyframe storyboard — the cheap gate before i2v (video-studio)

This is the **visual** counterpart of the text storyboard in `brand-intake.md` §5. Where that one is a table for internal sign-off, this is a board of **real generated keyframes** (stills) you show the client/stakeholder before a single second of image-to-video is rendered. It augments the text storyboard, it doesn't replace it: the text storyboard sets the beats, this board makes them visible.

## Why it exists (the economics)
The money in an AI video sits in **image-to-video**, not in image generation. Keyframes are stills → ~€0.06 each. A board of 10 (3 leader + 5 content + 2 outro) costs **~€0.60** (Flash 1K). The i2v render after it costs ~€5. So:

- **De-risk your own spend**: no i2v money goes out until the client has approved a direction.
- **Direction without friction**: the client reacts to something tangible ("this board, but beat 2 different") instead of writing a brief up front. Pointing takes 10 seconds; describing is work.
- **Reassurance = showing the floor**: generate at **delivery quality**, not prettier. Then the board is a promise the final video meets by definition.
- **Break-even**: at ~€1 per board and ~€45 margin on a €50 job, it pays for itself at **~2% incremental conversion**. Any plausible direction effect clears that easily.

## The iron honesty rule
Keyframes are the **peak** — i2v can hold them or degrade them, never improve them. Show a nicer board than you deliver and you set a bar the video won't reach = disappointment. **So generate at exactly the tier/size you will deliver.** The board is the personalised floor, not a shop window.

## Recipe

### 1. Beats → prompts (Claude writes this)
Turn the text storyboard into one prompts file, one beat per line: `SECTION|LABEL|prompt`.
- Default split **3 / 5 / 2** (leader / content / outro) — adjust freely per brief.
- **Generate text-free** (lettering comes separately, `consistency.md` §3) — put "no text" in every prompt.
- Adopt the brand canon (color hex, tone) from the brand's kit — never guess (`brand-intake.md` §2).
- Every content beat is a **proof shot** for its line (`existing-footage.md` §3, `lessons.md`).

```
# prompts.txt — example (16:9, brand periwinkle #627CB6)
LEADER|Logo reveal|dark studio, soft periwinkle rim light, negative space, cinematic, no text
LEADER|Brand mood|abstract periwinkle gradient sweep, premium, no text
LEADER|Subject intro|founder at desk, warm key light, shallow depth, no text
CONTENT|Problem|cluttered paper invoices on desk, cool light, no text
CONTENT|Product hero|clean SaaS dashboard on laptop, periwinkle accents, no text
CONTENT|In use|hand scrolling the app, close-up, warm, no text
CONTENT|Result|relaxed founder, coffee, soft morning light, no text
CONTENT|Proof|abstract rising graph motif, periwinkle, no text
OUTRO|CTA card|empty branded end-card, periwinkle gradient, center-safe, no text
OUTRO|Logo lockup|clean logo space on dark, no text
```

### 2. Generate (the script does the rest)
```bash
bash scripts/storyboard.sh \
  -p prompts.txt -o out/storyboard -t "Storyboard — <brand>" \
  -m flash -s 1K -a 16:9
```
(Run from the skill directory, or use the path where the skill is installed.)
- **Consistency**: the first keyframe automatically becomes the **anchor** (`-r`) for all following ones (keyframe-first, `consistency.md` §1). Pass your own anchor with `-r anchor.png` to hold an existing character/hero frame.
- Output: `out/storyboard/kf-NN-*.png` per beat + `board.png` (a labelled 5-wide grid) + a cost line.
- **9:16?** `-a 9:16` and the board tiles the same way — respect the target format (SKILL §2: never reuse a 16:9 grab for 9:16).

### 3. Show it → collect direction
Send `board.png` as the gate. The client sets the direction by reacting to it. Only after approval do you move on to keyframe validation + i2v (SKILL §3, `models.md`). **Still validate one cut before fan-out** — the board doesn't replace the pre-delivery inspection.

## Edge cases
- **No brand canon** → do `brand-intake.md` §2 first (adopt, or create after approval). Don't build a board on a guessed identity.
- **A URL instead of a brand kit**: scrape the brand tokens (colors/logo/tone) → write the prompts → run the script. If the scrape fails → fall back to a brand-kit template, or ask.
- **nano-banana / magick missing** → the script stops with the A/B/C question (never skip silently, SKILL §0).
- **Need Pro?** Only if the *delivery* is Pro (hero/cover quality). Otherwise Flash — the board shows the floor, not the ceiling.

## Self-maintenance
New lesson about storyboards / the keyframe gate → append to `lessons.md` + bump `CHANGELOG.md`. A nano-banana price/flag change → update `models.md` + the cost table in `scripts/storyboard.sh`.
