# Consistent image production — video-studio

The hardest requirement in AI imaging is keeping subject/style identical across *all* shots. Proven techniques:

## 1. Anchor reference (the core)
First generate one strong **anchor image** (cover/hero/key frame) where the subject + style are definitively locked. Then use that anchor as a **reference (`-r`)** for every subsequent image → designs and style stay consistent.
- Proven in production: using a comic's cover page as the `-r` anchor kept 9 characters + the style consistent across 6 pages.
- nano-banana: `nano-banana "PROMPT, SAME style/characters as reference" -r anchor.jpeg [-r focus-char.jpeg] -o page -s 2K --model pro`. Reference order matters: 1st = primary style/content; extra refs = secondary; a final blank image = exact dims.

## 2. Keyframe-first for video
Never animate blindly with text-to-video. For each shot, generate a **start frame** (with subject + environment already correct, passing the anchor reference), then animate *that* frame with image-to-video (Veo). Characters are then consistent between shots by definition.

## 3. Text does NOT belong in the generation
Image-gen renders text unreliably (gibberish). So: **generate text-free** (prompt: "ABSOLUTELY NO text/words/letters, leave clean bands for captions") and add text **separately** with ImageMagick.
- Caption-box recipe (classic comic narration): yellow field + black frame + auto-wrap:
  ```bash
  magick -background "#F2C230" -fill "#141414" -font "/System/Library/Fonts/Supplemental/Arial Bold.ttf" \
    -pointsize 54 -size 1150x caption:"TEXT" -bordercolor "#F2C230" -border 22 -bordercolor "#141414" -border 6 cap.png
  magick page.jpeg cap_top.png -gravity North -geometry +0+44 -composite \
    cap_bot.png -gravity South -geometry +0+44 -composite -quality 92 final.jpeg
  ```
- Keep the **text-free masters** separately → change captions without regenerating.
- An ImageMagick caption with an empty string gives `label expected` → never pass an empty string; map captions explicitly (case/dict), not via an array index that can shift.

## 4. Train your own character LoRA (for a recurring face/character)
When one specific person or character must recur across shots, train a small LoRA:
- Endpoint `fal-ai/flux-lora`; provide your own image dataset and pick a distinctive **trigger word** (an uncommon token that won't collide with normal vocabulary).
- Use it via `loras:[{path:URL, scale:1.0}]`, and put the trigger word at the front of every prompt: `"<TRIGGER>, <description of person>, <scene>"`. Roughly ~$0.03/image.
- Weight URLs can expire → keep a `.safetensors` backup and re-host if needed. Never hard-code personal identifiers into the skill; the trigger word and dataset stay project-local.

## 5. Flux biases (anti-patterns) — strong positive cues > negatives
- **Kawaii/chibi pull** on cute-coded subjects → use 2× more **positive** style cues (medium, line quality, proportions) than negatives; describe "uncute, spiky, ragged, weathered".
- **Anti-blur**: prefix `crisp sharp focus high detail` + negative `NOT blurry NOT soft focus` on pose text.
- **`profile side-view facing right`** >> `side-view` for a real side profile (and it dampens kawaii).
- **Value collapse to black** on "mystical/saffron/watercolor" → lead with `luminous bright pastel`, force `predominantly blue and cream values`, `NOT dark NOT black NOT night`.
- **`NO characters` fails** in cave/landscape scenes (lone-wanderer bias) → stack 6× negatives + fill the space with a dominant non-human subject.
- **Tile/texture strips**: aspect 2:1 + rider-prefix up front + strip "psychedelic/scene" style tags.
- **BiRefNet only for one clear subject** (sprite/prop), not for landscape parallax (it strips all or nothing) → use color-key / `globalCompositeOperation`.
