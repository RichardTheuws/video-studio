# Directing, rhythm & dynamics — video-studio

`commercial-craft.md` says what makes a film feel *expensive*. This document says what makes it
feel **directed**: shot grammar before generation, and speed in the edit.
It's the layer where most AI videos break down — technically correct shots lined up like a
slideshow.

> **Where this comes from.** Measured on a comedy teaser: 12 shots, nearly all eye-level
> medium/wide with a slow push-in, every clip used 1:1 at full Veo length in the edit.
> Result: 57 s at one tempo, not a single joke landing, and a key shot in which the requested
> action never happened. Every rule below addresses one of those four failure modes.

---

## 1. Shot grammar — lock this before you generate a single keyframe

A shot list isn't finished with "what happens". Every row has **four** columns:

| column | why |
|--------|-----|
| **size** | XCU / CU / MS / WS — your most important dramatic lever, and it's free |
| **camera height** | low = power, eye level = reality, high = the subject is small/waiting |
| **the one action** | literally one verb. Two actions in one shot = the model picks one |
| **cut length** | what survives in the edit (§3) — not the generation length |

Three hard rules:

- **Size contrast on every meaningful moment.** Never two shots of the same size next to
  each other within the same location. A joke, a shock or a turn lands on the *difference*
  between shots, not on the content of one shot. Chaos = wide, the punchline = XCU.
- **One action per shot.** "He lands in front of the tractor *and* stops it with one hand *and*
  doesn't spill his coffee" is three actions; i2v then delivers zero. Split into three shots (or
  bake the other two into the keyframe, §2).
- **Camera height varies deliberately and meaningfully.** If you can't explain why a shot is
  low, it's at eye level. Everything at eye level = no direction.

With two characters: keep the **eyeline** consistent (who looks left, who looks right) and
state that direction explicitly in the prompt. An i2v model has no 180° rule; you do.

## 2. The action belongs in the KEYFRAME, not the video prompt

The leverage is upstream (`lessons.md`: three measurements all pointed at the keyframe, not at
prompt ceremony around the video model). In practice:

- **Generate the keyframe mid-motion**, not before it. Not "a pan on the stove" but "butter
  half-melted and sizzling, foam bubbling at the edge". Not "he's ready to push off" but "his
  knees bend, dust blows away under his boots".
- A still that already moves (splashes, smoke, motion blur, something halfway through the air)
  demonstrably animates stronger than a tidy pose — the model doesn't have to invent the motion,
  only continue it.
- If the action doesn't work in the keyframe, it certainly won't work in the video. **Redraw the
  keyframe; don't start fiddling with the video prompt.**
- **Measured**: an empty-ceiling shot with "the drop falls" gave motion energy **0.08**; a more
  explicit motion prompt on the same keyframe gave **0.10**; replacing the keyframe with a
  splash-with-ripples gave **8.36**. So stop after one failed prompt attempt — the second is
  wasted money. See `lessons.md`.

**Find dead cuts before delivery:**
```bash
for f in work/*.mp4; do printf '%-14s ' "$(basename $f .mp4)"; ffmpeg -v error -i "$f" \
  -vf "scale=160:90,tblend=all_mode=difference,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-" \
  -f null - 2>/dev/null | awk -F= '/YAVG/{s+=$2;n++} END{printf "%.2f\n", s/n}'; done | sort -k2 -n
```
Below ~0.5 a shot is effectively a still. One dead cut in an otherwise tight edit reads
as a stutter.

## 3. Generate long, cut short — this is where the speed is

**The rule: never use an i2v clip at full length.** Veo delivers 4/6/8 s because that's the
enum, not because the shot needs to last that long.

Target lengths in the edit:

| function of the shot | cut length |
|----------------------|-----------|
| punchline / reaction / insert (XCU) | **1.2 – 2.0 s** |
| ordinary beat, one action | **2.0 – 3.0 s** |
| establishing / the final image | **3.0 – 4.0 s** |
| two-shot where something is exchanged | **3.5 – 4.5 s** |

And more important than any number: **variance**. A film where every shot lasts 4 s averages
4 s and feels dead; 1.5 / 3 / 2 / 4 / 1.8 feels directed. Put the cut length in the shot list
and *edit to it*, even when the clip is prettier than its place in the rhythm.

## 4. Pick the right window — `scripts/pick-window.sh`

i2v clips have a **dead run-up** (the keyframe barely moves for the first half to full second)
and often a **decay** at the end (drift, morphing hands). Finding the window by hand is
guesswork; measure it.

```bash
scripts/pick-window.sh clips/01-crisis.mp4 2.5
# ss=3.42 (motion 2.677, clip 6.00s, window 2.5s)

scripts/pick-window.sh clips/01-crisis.mp4 2.5 --cut work/01-crisis.mp4
```

The script measures motion energy per frame (difference image → mean luma) and returns the
start time of the window with the most motion; the first 0.4 s count half so the static
run-up doesn't win.

> Measured on the teaser clips: the strongest window of `01-crisis` only starts at **3.42 s**.
> That clip was used 1:1 in the film, so the first 3.4 seconds were dead time in the
> opening shot. This is exactly where "slow" comes from.

**The output is a proposal, not a verdict.** Look at the window; sometimes you want the calm
(a waiting gag), and then you deliberately pick a low-motion window. But then it's a choice.

## 5. Dynamics in the edit

- **Cut on action.** Cut in the middle of a motion, not after it. Two shots that both come to
  rest before the cut = two dead ends.
- **Sound leads picture.** Let an SFX or music accent start 2-4 frames before the cut;
  the cut then feels intended instead of accidental.
- **Rhythm block around a punchline**: build up with shortening cuts (3.0 → 2.2 → 1.5) and then
  let the punchline *hold*. Accelerate-then-stop is the cheapest comedy timing there is.
- **You're allowed to make speed.** A clip that moves too sluggishly can be picked up in ffmpeg —
  `setpts=0.8*PTS` (25% faster) is usually invisible and rescues a limp animation.
  Above ~1.4× it gets visibly jerky at 24 fps.
- **Hard cut is the default for deadpan comedy**, but put at least one **real transition** in
  the film where the camera keeps moving (Kling `tail_image_url`, `models.md`) — that's the
  difference between a string of shots and a film. Pick the place where the world changes: two
  shots that jump from location A to location B anyway become one motion together.
- **Do NOT trim a tail-frame transition.** By definition it starts on its start frame and
  lands on its end frame; cutting a window out of it destroys exactly what you paid for.
  This is the only exception to "generate long, cut short" (§3) — explicitly exclude it from
  `pick-window.sh` in your edit list. Such a shot is usually also your longest, and that's
  good: it raises the spread and it's your signature move (measured on a series episode:
  spread 0.61 → 0.90 s from this one shot).
- **Always consider one shot without motion.** Rhythm exists by virtue of contrast; if
  *everything* moves, nothing moves.

## 6. QA — measurable, before delivery

```bash
# mean shot length + spread from your edit list
awk '{s+=$1; a[NR]=$1} END{m=s/NR; for(i in a) v+=(a[i]-m)^2;
      printf "shots %d  mean %.2fs  spread %.2fs\n", NR, m, sqrt(v/NR)}' cutlengths.txt
```

- **Mean shot length < 3.0 s** for a teaser/comedy. Above that → you used clips 1:1.
- **Spread > 0.6 s.** Low spread = metronome = no direction.
- **At least 3 different shot sizes** in the film, and no two equal sizes in a row
  within one location.
- **Every requested action is actually visible.** Walk the shot list against the picture; a
  shot in which the action didn't happen is a *re-render*, not "good enough".
