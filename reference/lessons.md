# Lessons — video-studio

Generic, reusable technical lessons distilled from real production. Each entry: the lesson + why it matters. Grouped by topic. When you learn a new one, append it under the right heading.

## Build & tooling gaps (macOS / brew)

- **A brew media-tool install can break another's dylibs.** `brew install imagemagick` bumped x265; ffmpeg then looked for a `libx265.<v>.dylib` that was gone and `ffprobe` failed. Fix: `brew reinstall ffmpeg`. *Why*: check after every brew install of a media tool that ffmpeg/ffprobe still run, and restore immediately — tools silently clobber each other's shared libraries.
- **brew-ffmpeg often lacks `drawtext` (no libfreetype).** Check `ffmpeg -filters | grep drawtext`. If missing (`drawbox` is usually still present), render ALL text (captions, end-card, lower-thirds) with **ImageMagick** as a transparent PNG (real fonts + manual shadow: black-offset annotate + main annotate) and **overlay with ffmpeg** (`-loop 1 -framerate 30 -i caption.png`, `format=rgba,fade=...:alpha=1`). *Why*: higher quality (real typography/kerning) and no drawtext escaping hell. Alternative: an ffmpeg build with libfreetype.
- **The regular brew-ffmpeg lacks `zscale`/zimg/libplacebo.** The `tonemap` filter needs zscale to linearize, and the `colorspace` filter does not support `itrc=smpte2084`. Fix on macOS: `brew install ffmpeg-full` (keg-only, doesn't clash) → binary at `/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg`, which has zscale. *Why*: use that binary for footage builds with HDR sources; add `ffmpeg -filters | grep zscale` to preflight for footage mode.
- **`crop=...:eval=frame` does not work in every ffmpeg build** ("Option 'eval' to filter 'crop': not found"). For a per-frame animating reveal/crop, use an **overlay with an animated y/x expression** (`overlay=y='36*pow(1-clip((t-T)/D,0,1),2)'`) or an alpha `fade` — both widely supported. *Why*: don't assume a filter option exists; feature-probe.
- **ImageMagick may lack the `pango:` delegate** ("no decode delegate for `<span...>`"). For weighted/italic/color-span text, render fragments with `-font <ttf> -fill <color> label:` and `+append`/composite. Also: `-linecap` is not a top-level option (use `-strokelinecap` or omit).
- **`magick montage` can fail on the default font** ("unable to read font" / `RenderFreetype` error), even without labels. Fix: pass `-font <path>` explicitly, or build contact sheets with `magick a.png b.png -append` / `ffmpeg ...tile=WxH` instead of `montage`.

## ffmpeg filtergraph & shell

- **The default macOS shell is zsh, which does NOT word-split unquoted `$var`.** `set -- $line` or a `while IFS='|' read` loop behaves differently than in bash → fields shift or empty out and segments fail silently. Fix: `set -- ${=line}` (zsh split flag), `read -rA arr`, or run the script explicitly under `bash -c`. *Why*: EDL/batch loops break invisibly otherwise.
- **zsh reads `$VAR[label]` as an array subscript** ("No such filter ''"). Write `${VAR}[label]` in filtergraph strings.
- **Commas inside ffmpeg expressions** (`min(a,b)`, `if(...)`, `clip(a,b,c)`) break the filtergraph parser. Escape as `\,`, avoid them, or put the whole graph in a file and run with **`-filter_complex_script`** (commas inside quotes then stay intact).
- **`ffmpeg concat` lists should use absolute paths** — relative paths resolve against the list file's location, not the cwd.
- **Mux audio and video decoupled.** A combined `filter_complex` with video grade + `amix` mysteriously swallows SFX. Render video separately, audio separately, then `-c:a copy`. Use `amix=normalize=0`; no `weights=` with spaces.
- **Synth SFX beat AI SFX for sharp hits** (AI produces broad "whoosh" blobs). Build impacts from `sine` + `anoisesrc` + `lowpass` + `aecho` with attack at t=0, and place them on the visual hit via `adelay`.
- **FX overlays generated on pure black** composite cleanly with `blend=all_mode=screen` (black→transparent) or `lumakey`.

## Still-image inputs (the recurring silent failure)

- **A `-i image.png` input without `-loop 1` is a single-frame stream at t=0.** Any time-based `fade=alpha=1` (or other temporal animation) then evaluates only at t=0, so the layer stays permanently at its t=0 value (typically fully transparent) and **vanishes silently** from the render — the rest of the render "works" perfectly. Fix: `-loop 1 -t <end+0.5> -i image.png`; fades on absolute times; overlay with an enable window. *Why*: this silently costs a full render; a frame-strip inspection catches it. Note: position expressions (`y=f(t)`) *do* work on a still (overlay evaluates per main frame); only filter animations on the still input do not.
- **Always set `-framerate` before every `-loop 1` image input.** Without it the input defaults to 25fps; a `zoompan` with `fps=30` counts output frames per input frame (d=1), so the clip ends up shorter than intended. In an xfade chain that shifts everything after it forward, and the video stream ends before the audio/container duration — symptom: `ffprobe format=duration` looks right, but `-ss` past the real video end gives "Output file is empty". Fix: `-framerate <target>` before each `-loop 1` image input, and when debugging a chain always check `-select_streams v -show_entries stream=duration` per building block.

## Color / HDR

- **HDR source leaks HDR tags → wrong colors in SDR players.** 4K phone footage is often HDR (`pix_fmt=yuv420p10le`, `color_space=bt2020nc`, `color_transfer=smpte2084` (PQ)). ffmpeg drags those tags into the output without converting → the output is mis-tagged as HDR while the pixels are SDR range → players show everything oversaturated (classic symptom: blue goes electric/royal). *Why*: the hex can be exactly right and still look wrong.
  - **Detect (mandatory in source hygiene)**: `ffprobe -select_streams v:0 -show_entries stream=color_space,color_transfer,color_primaries,pix_fmt`. `bt2020` / `smpte2084` / `arib-std-b67` (HLG) / `*10le` = HDR. Treat `is_hdr` as `color_transfer ∈ {smpte2084, arib-std-b67}` and tonemap only HDR sources (running an SDR source through the tonemap chain washes it out).
  - **Fix**: tonemap HDR→SDR bt709 and tag the output explicitly: `zscale=t=linear:npl=100,tonemap=hable,zscale=t=bt709:m=bt709:p=bt709:r=tv,format=yuv420p`, encode with `-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv`.
  - **CLI flags alone don't force the tags**: libx264 output often keeps `smpte2084`/`bt2020`, and `xfade` silently upcasts to `yuv444p`. Set frame metadata with the **`setparams` filter** at the end of each graph (`setparams=colorspace=bt709:color_primaries=bt709:color_trc=bt709:range=tv`) + `format=yuv420p` after every `xfade`. **Always verify the output tags** (`ffprobe`) — all three (space/transfer/primaries) must read bt709.

## Source orientation & aspect

- **Check source orientation before choosing an aspect.** Phone video is often shot vertical but stored as a landscape stream + rotation tag (`stream=1920x1080` + `rotation=-90` → displays as 1080x1920). `scale=1920:1080` on such material stretches it flat (people go wide). Check first: `ffprobe -select_streams v:0 -show_entries stream_side_data=rotation` (and decode one frame for the real display dims). *Why*: if 9:16 looks native-perfect but 16:9 looks stretched, your source is vertical — vertical is then the master and landscape is a compromised derivative (see `landscape-from-vertical.md`).

## Consistency & lettering

- **Hold subject/style constant across shots via an anchor reference.** Generating each image with the first strong image as an `-r` anchor kept many characters + one style consistent across many pages/shots. Generate text-free and add captions separately; keep the text-free masters for re-lettering. *Why*: image-gen renders text unreliably, and without an anchor the model drifts.
- **Never pass an empty caption string to ImageMagick** (`caption:`/`label:` → `label expected`). A bash array with an accidental empty element shifts every caption by one. Map captions explicitly per item (case/dict), not via a fragile array index. Also: with `magick`, `label:` must come *before* `-border`, otherwise "no images for -border".

## Mono logos & branded lockups

- **A mono (single-color) logo variant flattens a detailed emblem into a meaningless silhouette.** Use the full-color logo with a glass panel (a brand-color `rgba` ~0.62 + a thin gold hairline) on busy/dark shots. Mono is only for genuinely simple wordmarks. *Why*: a detailed round emblem (icons, ornament) becomes an unreadable disc when reduced to one color.
- **Build branded lockups as a designed PNG** (ImageMagick: rounded panel + hairline + full-color emblem) rather than a flat ffmpeg `drawbox`.

## AI music & audio honesty

- **fal.ai stable-audio gives social-safe original music** (`stable-audio-25/text-to-audio`, param `seconds_total`) → no copyright mute on TikTok/Reels, which matters for mobile-first delivery. Generate two variants in parallel and choose by ear. Keep it instrumental (underscore/bed), never a synthetic "song" imitating real pop.
- **You cannot audit audio by looking.** When you can't actually hear the result, deliver it with an explicit "not heard / replaceable" caveat and note that cuts aren't frame-accurate on the beat — never sell it as finished.

## Inspection & process (the #1 failure source)

- **A time-based medium is judged densely, not on a handful of stills.** Declaring a cut "good" from ~10 tiled thumbnails misses bad cuts and dead time. Before "done": (a) dense frame strip ≤0.7s across the whole clip; (b) per cut, view the OUT-frame of A next to the IN-frame of B — a cut exists by virtue of those two frames; (c) check each card's hold/legibility on its real duration. See `commercial-craft.md` §7.
- **Pick cut points on frames, not arithmetic.** Determine in/out by viewing the actual boundary frames, not `frame k ≈ k/12·duration`. Cut on a clean/stable frame, on motion or beat — never mid motion-blur or on a dark handheld frame.
- **Text-card budget ≤ ~25% of runtime.** Footage carries the story; cards punctuate. A near-static opener/CTA of several seconds reads cheap/slow.
- **Never mute a testimonial to silent lip-movement** — a talking head without their voice is uncanny. Use their audio (ducked under the music) or don't make it a long shot.
- **Uniform dissolves are as bad as uniform hard cuts.** The same 0.3s `xfade` everywhere is mud; between two dark handheld shots it becomes soup. Choose the transition per boundary based on the (viewed) motion; dissolve only between compatible shots.
- **Do a source-hygiene pass before montage**, per source: detect watermark / burned-in subs / already-present titles / already-graded look / letterbox. Don't double-grade; don't blindly mix watermarked with non-watermarked material.
- **Validate ONE cut before fan-out.** Rendering multiple language versions/variants before the core cut is right is wasted work. Get one core segment/cut right and approved, then produce variants/languages.
- **A capability gap is never silently skipped.** If a required tool is missing, stop and ask (install / alternative route / cancel), install after approval. *Why*: a missing tool is a user decision, not something to work around silently.

## Motion & "MovieMaker" register (hard rules)

- **Never Ken Burns / zoompan on stills.** Auto pan/zoom over a flat photo reads low-grade — it's the MovieMaker signature. Motion comes from crafted transitions (luxe cross-dissolves, dip-to-black), strong kinetic typography, and one rich grade + subtle film grain. Static premium stills + luxe dissolves = high-end. *Why*: fake camera movement over a flat image reads cheap and makes the frame restless.
- **If a still must move, a REAL element in it must come to life** via art-directed image-to-video (fal Veo/Kling): a crowd subtly moving, a glass raised, flickering light, hair/smoke moving. Direct the element explicitly + negative-prompt against camera drift/zoom/pan; render multiple takes and **curate**. Never "animate this" blindly → the model spins the subject on its axis.
- **Live screen recording beats stills + Ken Burns for instructional video.** Record the real flow (e.g. Playwright `recordVideo`, or local headless Chrome) with real UI motion: cursor, typing, clicks, page transitions. Speed-ramp static stretches (form filling) rather than panning; trim the lead-in; record calmly (long holds) and edit real-time so steps stay legible. *Why*: Ken Burns on UI screens is dull and speeding up makes steps unreadable — record calm, edit real-time.

## Capture format & environment

- **Capture format = output format.** Don't reuse 16:9 desktop grabs for a 9:16 cutdown by pasting them as cards on a background — that isn't native capture. For 9:16, render the responsive page at mobile width so the native mobile layout appears, then crop 9:16 full-bleed. Headless recipe: `--force-device-scale-factor=2 --window-size=540,<tall>` (540 CSS-px → mobile breakpoint; ×2 DPI → 1080px bitmap) → full-page PNG → `magick -crop 1080x1920+0+<y>`.
- **For real page-capture footage, render locally, not via a containerized browser.** A Playwright-MCP that runs in Docker writes its screenshots inside the container, not on your local FS — you see them inline but can't feed them to ffmpeg/magick. Render locally with headless Chrome instead: `--headless=new --hide-scrollbars --window-size=1600,<tall> --screenshot=out.png "file://.../page.html"` → one full-page PNG → crop sections with `magick -crop 1600x900+0+<y>`.

## Reuse over rebuild

- **Reuse existing fal helpers instead of rebuilding the queue.** Reproducible wrappers for Veo-3-Fast i2v (keyframe→mp4) and stable-audio beds already handle correct `response_url` polling. A reuse audit pays off — don't rebuild queue polling. Art-direct i2v motion with a negative against camera drift ("camera pan/zoom/push/dolly") so elements move while the camera stays locked.
- **When adding to an existing brand's video pipeline, find and reuse it first.** A second video in a brand portfolio should adopt the existing branded leader→content→outro bracket, card style, music bed and delivery conventions — not spin up a parallel scratch track. Store finished films in one fixed, consistent deliverable location with fixed naming (e.g. `<brand>/<character>/<name>-16x9.mp4` + `-9x16.mp4`), not a new place each time.
