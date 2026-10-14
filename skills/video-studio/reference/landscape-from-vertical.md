# Landscape from vertical material — the reframe toolkit

**Problem**: the source is 9:16 (vertical), you want a nice 16:9. **Never** flat `scale` (it stretches). Blurred-fill is the lazy fallback. This is the premium approach: **reframe per shot** with a toolkit, and let compositions **flow seamlessly into each other**. 9:16 stays the native master; 16:9 is a *composed reframing*.

**Key insight (ffmpeg)**: in `crop`, **x/y are per-frame animatable** (only w/h are not). So you can **pan/tilt within the vertical image** and thus make a true full-frame 16:9 that follows the subject. This is the most important technique.

## Per-shot decision tree
| Shot content | Technique |
|-------------|-----------|
| Tall/vertical subject filling the frame (hair, full figure) | **Animated reframe** (pan/tilt along the subject) |
| Action in a horizontal band (face, hands, detail, product, wide context) | **Static 16:9 crop** |
| Comparison / montage / energy | **Split / multi-panel** (verticals side by side) |
| Hero / brand moment | **Editorial frame** (vertical as a column + brand field + title in the free space) |
| Nothing fits | **Blurred-fill** (last resort) |

## 1. Animated reframe (pan/tilt) — the default for vertical subjects
Crop a 16:9 window from the vertical image and **animate the y** over the shot duration (root→tip along the hair, or upward). Full-frame, no fill, dynamic.
```
# source shows 1080x1920; window 1080x608 (=16:9), tilt from top to bottom over D sec
crop=1080:608:0:'(ih-608)*min(t/D\,1)',scale=1920:1080,setsar=1
```
Variants: tilt up → `(ih-608)*(1-min(t/D,1))`; subtle "rest" pan → smaller motion range; horizontal pan the same on x.

## 2. Static 16:9 crop
For shots where the action sits in a horizontal band:
```
crop=1080:608:0:Y,scale=1920:1080   # Y = fixed vertical position of the band
```

## 3. Split / multi-panel (verticals across the width)
Fill the width with 2–3 vertical clips → energetic montage or before/after. Triptych ≈ fills 1920:
```
[0:v]crop=640:1080:220:420,setsar=1[p1];[1:v]crop=640:1080:220:420[p2];[2:v]crop=640:1080:220:420[p3];
[p1][p2][p3]hstack=inputs=3
# or diptych: two 960-wide crops + hstack=2
```
Tip: a thin gold divider between panels (`drawbox`), or a soft feather seam.

## 4. Editorial frame (vertical as a design element)
Vertical clip in a column, the free space for a brand field + title. Premium hero/brand look.
```
# bg: brand color field (optionally a faint blurred copy of the clip); fg: vertical sharp in a column right
-f lavfi -i color=c=0x2D1F2B:s=1920x1080:d=<dur>
[0:v]crop=1080:1350:0:300,scale=-2:1000[fg];
[1:v][fg]overlay=x=1150:y=40[tmp];
[tmp]drawbox=x=1130:y=40:w=4:h=1000:color=0xC9A962@0.8:t=fill[v]
# the left keeps space for title/logo/tagline
```
(note: lavfi `color` needs a `:d=<dur>` or `-t`; don't leave empty filter tokens in the graph.)

## 5. Blurred-fill (fallback)
Only when nothing else fits:
```
[0:v]split[bg][fg];[bg]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=40,eq=saturation=0.6[bg2];[fg]scale=-2:1080[fg2];[bg2][fg2]overlay=(W-w)/2:0
```

## Seamless flow between compositions
Switch between reframe modes with **slide/wipe/feather** so it becomes one moving landscape film, not loose boxes:
- panel slides in from the right while the previous exits to the left (overlay x-animation or `xfade=slideleft`);
- split-screen that "opens" (two panels sliding apart from the center);
- soft gradient seam between panels (feather with an alpha-gradient mask).

## Workflow for a whole edit
1. Walk the EDL; assign a technique per shot (decision tree).
2. Render each shot separately as a 16:9 segment (reframe), keeping the same in/out + beat timing as the 9:16 master.
3. Concat with the same crafted transitions (`commercial-craft.md`).
4. Titles/overlays on landscape-safe zones; in editorial frames, use the free space.

> Result: a 16:9 that feels *composed* (panning reframes, split moments, editorial frames flowing into each other) instead of a stretched or boxed vertical clip. The 9:16 stays the master; the 16:9 is its own, deliberate reframing.

**The opposite direction** (a 16:9 production that also needs a real 9:16 master): see `vertical-916.md`.
