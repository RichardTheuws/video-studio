# Mode A — Existing footage (auto-select by subject)

Working with existing material: inventory it, select by subject, and edit. Core idea for auto-select: **ffmpeg pulls frames, you view them yourself (Read tool) and pick the matching segments** — no external classification model needed.

## 1. Inventory
```bash
# all video files + duration/codec/resolution
for f in **/*.{mp4,mov,mkv,webm}; do
  printf "%s  " "$f"; ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height,codec_name:format=duration \
    -of csv=p=0 "$f"
done
```
Source is a URL (YouTube etc.)? Download first (requires `yt-dlp` — preflight checks this):
```bash
yt-dlp -f "bv*+ba/b" -o "%(title)s.%(ext)s" "<url>"
```

## 2. Subject auto-select (the smart step)
1. **Detect scene cuts** and mark them as candidate segments:
   ```bash
   ffmpeg -i in.mp4 -filter:v "select='gt(scene,0.4)',showinfo" -f null - 2>scenes.txt
   # pts_time values in scenes.txt = scene boundaries
   ```
2. **Pull thumbnails** (per scene or every N sec):
   ```bash
   ffmpeg -i in.mp4 -vf "fps=1/3,scale=480:-1" -q:v 4 /tmp/ff/thumb_%04d.jpg
   ```
3. **Inspect visually**: read the thumbnails with the Read tool and decide which show the requested subject (person, location, action, mood). Note the time ranges of the matching scenes.
4. **Cut** on those ranges (see montage `trim`), then `concat`.

> This way the pipeline "understands" the subject without an extra API: your multimodal eye does the classification on the pulled frames. Briefly report which clips/ranges you chose and why.

## 3. Footage-first, not copy-first
Don't write copy and then hunt for images from too thin a pool — that produces generic b-roll that doesn't *prove* the message. Instead:
- **Inventory the strongest real moments in the whole pool first**; let those drive the story and the exact words. The message may/should **move** toward what the footage proves.
- **One proof shot per line**: every claim ties to a shot that visibly makes it true. If a claim can't be proven with footage → cut or rewrite the claim, not the other way around.
- **Use the whole pool**: a handful of clips out of a large library = repetitive, interchangeable shots. Inventory broadly before you pick the 5–8 hero shots.
- **Show the shot↔line map**: when in doubt, make the mapping (line → exact clip → why it proves it) explicit and get it approved before render — that's exactly what the client judges.

## 4. Normalize before montage
Different sources → uniform fps/resolution/codec before concat (otherwise `-c copy` breaks):
```bash
ffmpeg -i src.mov -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=30" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac norm.mp4
```

## 5. Enrich (optional, bridge to Full-AI)
Missing shots? Fill in with AI keyframes → i2v (mode B), and edit them between the existing clips. Grade everything to one look (curve/LUT) so AI and real shots match.

## 6. Finish
Montage + audio via `montage-ffmpeg.md`. Deliver in the right aspect for the destination + a poster frame.
