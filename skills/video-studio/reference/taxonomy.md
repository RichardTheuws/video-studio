# Taxonomy v1 — tags per production (fixed)

The writer puts this block in the front matter of `brief.md`, **before** production. The tags record the *intent*, so
the learning loop can see afterwards which choice gave which result (`scenario.md` §0). If a value is missing, pick the
closest one and write it in `note`; a new value only comes via a version change (v2) with a line in the skill CHANGELOG.
Never tag retroactively to explain a number.

```yaml
taxonomy: v1
video_id: <brand>-<slug>-<9x16|16x9>      # unique; equal to the file name without extension
brand: <brand-slug>                       # account on which it is measured
type: teaser | promo | social-proof | explainer | tips | spotlight | walkthrough | leader | series | brand-film | personal
hook: peak-first | question | character-action | reveal | text-claim | sound | brand-first
structure: peak-rewind | chronological | five-act | list | loop
brand_first_s: 1.5                        # seconds to the first brand cue, of any kind
brand_cue: logo | colour | product | character | sound | none      # the FIRST cue
emotion: joy | warmth | surprise | humour | awe | nostalgia | tension   # the dominant one, one value
sound: music | voice-over | dialogue | sfx-only
ending: resolve | cliffhanger | loop | cta | sting
length_s: 20
lessons: [S-A01, S-A04, S-PR03]           # the lessons you applied deliberately
# only when applicable:
series: {id: <series-slug>, episode: 2, recap: none | overlay | spoken, open_question: question | peril | reveal}
sting: <brand>-sting-v2                   # version of leader/outro
test_slot: {tag: ending, variant: B, pair: <pair-id>}   # at most one; the other half of the pair has the same pair-id
note: ""
```

## Rules

- **One `test_slot` per brief.** Two changes at once = you don't know what caused the effect; the board run rejects it.
- **Cheap tests first**: `ending`, placement of the `sting`, `sound`, `brand_first_s`, recap. They only cost editing.
  A test on `hook` or `structure` usually needs new keyframes or i2v.
- **Client videos** get the same tags (they enrich the library), but are only measured if the client shares numbers.
- **Personal film**: `type: personal`, otherwise only `emotion`, `sound`, `structure`. Never measured.
- **Which metric judges which tag**: hook and `brand_first_s` → skip rate / 3-s hold; `structure`, `emotion`,
  `sound` → average watch % and the watch curve; `ending` and `series` → watch-to-end and watch-through to the next episode.
