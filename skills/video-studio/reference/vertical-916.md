# A 9:16 master from a 16:9 production — the recipe

**Goal**: a real, premium **9:16 (1080×1920)** version alongside the 16:9 master — not a lazy flat scale or blurred-fill. Proven on a full brand explainer; use it whenever a video ships in both formats.

> **NEVER Ken Burns** (`commercial-craft.md` §0.5) applies in full. Motion comes from image-to-video element animation or a static hold — in 9:16 too.

## The five-step recipe

1. **Crop the source to 9:16 (subject-preserving); don't upscale the 16:9 clip.** For real photos: crop the **high-res source photo** to 9:16 and generate **9:16-native i2v** (sharp). Never cut a vertical out of a low-res 16:9 i2v clip (soft).
   ```bash
   # center crop to 9:16 + a clean 1080x1920 (works for most garden/scene shots)
   magick src/photo.jpg -resize 1080x1920^ -gravity center -extent 1080x1920 -quality 92 src916/photo.jpg
   ```
   - **Subject off-center?** Shift the crop (`-gravity west/east` or an explicit `-extent WxH+X+Y`), or use an **editorial frame** (vertical column + brand field). Wide establishing shots that won't crop → regenerate 9:16-native, or go editorial.
   - Check the crops (contact sheet) before generating: never crop the subject in half.

2. **9:16-native i2v** (the primary model in `models.md`). Feed the 9:16 crop as the start image → the aspect follows from the keyframe (Kling has no `aspect_ratio` field). Measured on Kling v3 Pro: a 1080×1920 keyframe → a **1080×1920** clip (Veo gave 720×1280), with first frame = last frame framing, so the locked-off prompt is honoured. Use the same **locked-off camera** prompt prefix as the 16:9 (forbid zoom/pan/push-in). Curate first vs last frame. Host the source keyframes somewhere the i2v API can fetch them.

3. **Titles/lower-thirds at 1080×1920 inside the SAFE BAND** (real pango). Platform chrome: keep the top ~10% and the **bottom ~15% clear**; put the lower-third in the band just above that (bottom margin ~330px). A portrait scrim for legibility:
   ```bash
   magick -size 1080x760 gradient:'rgba(10,22,21,0)-rgba(10,22,21,0.82)' scrim.png   # transparent -> dark at the bottom
   # number on top, heading below, left x=80, heading width ~900 (not against the edge)
   ```
   Number bigger (Fraunces Black ~128), heading ~54 (the 16:9 used 44/96 → scale with the narrower column).

4. **Recompose leader/endcard/triad cards in portrait** (1080×1920). Brand cards are usually 16:9 stills; recompose them with the **logo + brand color + pango text** in portrait (logo centered; endcard = logo on top + CTA + URL). Sample the background color from the 16:9 card (`magick card.png -format '%[pixel:p{40,40}]' info:`). Build a `leader_9x16`/`outro_9x16` pair once per brand and reuse it.

5. **`montage-916.sh`** = a mirror of `montage.sh` with `scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920` instead of 1920×1080, i2v input `clips/i2v916-*.mp4`, the 9:16 titles/cards, and the **same xfade offsets + audio bed**. Output `<name>-9x16.mp4`.

## QA (on top of `commercial-craft.md` §7)
- A dense frame strip on the 9:16 too (portrait frames side by side).
- **Safe-zone check**: titles/CTA inside the safe band (not under platform UI).
- **Subject preservation**: the key element never falls out of the crop.
- Grade + rhythm identical to the 16:9 master (same film, different frame).

## Economics
9:16 i2v costs about the same as 16:9 (~€0.50/clip on Veo 3 Fast) and is **reusable across every video for that brand** (asset library). Titles/cards are script work (near €0). For **real-asset builds** the 9:16 is therefore cheap; only full-AI hero shots carry real extra generation cost.

## See also
`landscape-from-vertical.md` — the reframe toolkit for the opposite direction (9:16 source → 16:9). A 608×1080 → 1080×1920 crop-and-scale is the same idea inverted.
