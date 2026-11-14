# Lessons — index of lessons and measurements (video-studio)

**This is an index with measurements; the rules live in the thematic documents.** New lesson: first the rule in the
thematic document (`montage-ffmpeg`, `models`, `consistency`, `directing`, `series-production` "Pitfalls in the capture
rig", `tooling`, `commercial-craft` §9, `brand-intake` §7, …), then **one** index line here: date · measurement/number ·
pointer. Consolidated 2026-11-08 from ~250 lines of prose / ~195 lessons; grouped by theme, chronological within a theme.
Dates are the day it went wrong (or was measured), so a rule can be traced to its evidence.

---

## ffmpeg / montage → `montage-ffmpeg.md` "Pitfalls from the log"
- 2026-06-23 (inherited from an earlier trailer pipeline) — decoupled muxing, `amix=normalize=0`, synth SFX > AI SFX, `${var}[label]`, FX on black + `blend=screen`.
- 2026-06-24 — PNG without `-loop 1` = one frame: a temporal fade is invisible; position expressions do work on a still.
- 2026-06-24 — commas in filter expressions break the inline graph; concat lists with absolute paths.
- 2026-06-24 — Homebrew ffmpeg without `drawtext` → all text as PNG via ImageMagick + overlay.
- 2026-06-25 — phone video `1920x1080` + `rotation=-90` displays 1080×1920; `scale=1920:1080` stretches people wide. Blurred-fill recipe → `landscape-from-vertical.md` §5.
- 2026-06-26 — HDR tags (`yuv420p10le`, `bt2020nc`, `smpte2084`) leak into the output: a muted blue goes electric with the hex correct (#627CB6). Tonemap via zscale (`ffmpeg-full`), `setparams` at the end, `format=yuv420p` after every xfade, verify three tags.
- 2026-07-01 — `crop=…:eval=frame` missing; `-filter_complex_script` for commas.
- 2026-07-08 — `-i title.png` without `-loop 1`: title layer gone without a sound.
- 2026-07-08 — grade/vignette/grain turns a white end card grey: xfade the end card in after the graded chain.
- 2026-07-08 — `-loop 1` without `-framerate`: 25 fps input, clip 3.07 s instead of 6 s, chain shifts, `-ss` past the end "Output file is empty".
- 2026-07-10 — leader/outro with 96 kHz audio: timebase 1/24 ≠ 1/12288 → `fps=24,setsar=1,settb=1/24,setpts=PTS-STARTPTS` on every input.
- 2026-07-12 — `zoompan` on a looping still: 3 s×25 fps×d=72 → 5400 frames = 207 s. xfade demands equal fps *and* timebase (`1/12288 ≠ 1/12800`, `24 ≠ 25`, exit −22).
- 2026-07-16 — `-loop 1` watermark without an end bound: a 9:16 preview became 2888 s / 48 min. Self-QA on duration and resolution per deliverable (headless runner gate 8–120 s).
- 2026-07-19 — `blend=all_mode=screen` on yuv420p = magenta cast; via `gbrp`.
- 2026-07-20 — reading a frame sequence faster (63 → 30 fps) drops every second frame at 2.1× = judder; re-render, `-count_frames` must match.
- 2026-07-20 — stable-audio-25 cap 190 s (`le: 190`); two generations + `acrossfade=d=8`.
- 2026-07-20 — social: CRF 19 at 1080×1920 = 27 MB for 11 s; CRF 26/25 → 2.4–2.9 MB resp. 17 MB. Messenger limit ≤ 16 MB.
- 2026-07-29 — no `fade=t=in` on frame 0 of an embed (black thumbnail).
- 2026-08-13 — a `#` comment *inside* `filter_complex` silently breaks the graph (title below the frame); a PNG sequence as an extra input wrecks the `enable` timing of other overlays → bake the second layer into the sequence; `gblur` has no per-frame `sigma`.
- 2026-08-20 — loudness within a series: ep2 −19.6 LUFS against ep1 −15.4; `volume=0.85` = −1.4 dB to trace back. Bed variants measured: bossa 2524 Hz / 4.36 onsets/s / 43.6 %, pop punk 2493 / 4.04 / 45.2 %, ska punk 2931 / 5.06 / 54.3 %, surf punk 2792 / 4.68 / 50.3 % (`montage-ffmpeg.md` "Music bed").
- 2026-08-21 — copy-concat + xfade truncates the film (26 s where 58 s was due); `tile=` with more frames than tiles wants `-frames:v 1`.
- 2026-08-21 — VO lines of 11 s and 5.5 s did not fit beats of 8 and 4 s: measure VO before the shot list.
- 2026-09-22 (II) — a bed at `loudnorm=I=-20` mixed unchanged = film −20.7 LUFS; normalise at film level.
- 2026-09-22 (III) — Playwright webm + `overlay=shortest=0`: segments 33.4× too long (218 s instead of 6.5 s; 387 instead of 11.6), final duration correct, grain ~0.3–0.5 s on the seams. `+genpts`, `shortest=1`, output `-t`, segment guard.
- 2026-09-22 (IV) — a card↔screen-recording dissolve hisses (~0.45 s, six times); five explanations fell (segment length, 32 re-encodes, `tv/bt470bg` vs `unknown`, 8/10/16 bit, `-ss` placement). `fadeblack` and a cut are clean.
- 2026-11-08 — encoder measured: VideoToolbox 1.8 s / SSIM 0.9988 against libx264 veryfast 1.3 s / 0.99994 → hardware encode KILL (`montage-ffmpeg.md` "Encoder").

## i2v models → `models.md` "Measured behaviour of i2v models"
- 2026-06-23 — the Kling queue ran past 4000 (hours); cancel via the API, `pkill` doesn't stop the job.
- 2026-07-07 — calm Veo clips: 8 s + "minimal, very slow, camera locked, background perfectly still".
- 2026-07-13 — Veo turned "swirl into one warm glowing form" into a heart; name the shape.
- 2026-07-14 — locked-off prefix: 12/12 garden photos camera-locked. i2v on a letterbox strip expands and hallucinates (a portrait on the wall) → UI/strips/collages = static hold.
- 2026-07-16 — Veo 3 Fast: `4s/6s/8s`, 720p, 48–75 s/clip, $0.10/s; 2.39:1 + `auto` → 16:9 1280×720; prompt through a content checker (`422`): "small child silhouette … corner" blocked, "child-height shadow" not; blocked = no cost.
- 2026-07-29 — Veo reinterprets a 3D cartoon character (dust coat → blazer, hi-vis → dress shirt, tape measure gone, reframing) despite a negative; $1.60 wasted. Alternative ffmpeg push-in (1.5× upscale, z 1.0→1.055, `noise=alls=4:allf=t+u`). Baked-in sign text survives.
- 2026-08-09 — Veo lets textile loose on a pull-out; a push-in holds ("stays taut, fixed and firmly hung"). A composited print survived 14/14 clips; carrier 85 mm instead of 50 mm.
- 2026-08-10 — Kling has `tail_image_url`, Veo doesn't: the only real transition between two stills; `xfade` between separate shots is a dissolve, rejected.
- 2026-08-19 — `negative_prompt` inert on Kling v2.5 (n=4/arm, 14 renders ~$5): anti-sheen U=9/16 (8 chance), median difference +0.003 at a spread of 0.04–0.10; positive control "forbid all colour" → saturation 0.4164 vs A-range 0.4158–0.4264; positive channel U=3/16, −0.020. Skin texture is not promptable.
- 2026-08-19 — style first does nothing for i2v (6 seeds × 2 arms, ~$11): U=13/36, medians 1.041 vs 1.035; drift median 7 % (1.05 on a scale R=1.58), max 15 %. Veo `seed` 777 identical → difference 22.78 vs 24.02 for other seeds: not honoured.
- 2026-08-19 — role labelling of references (nano-banana pro, n=8/arm, ~$2): 16/16 no leakage; yellow U=44/64 (32 chance, p≈0.10) = framing: area U=52/64 (+32 %), hue 43.0° vs 40.8° U=40/64; background U=30/64. Thread through the three measurements: the lever is in the keyframe.
- 2026-08-20 — drop shot: prompt v1 0.08, v2 0.10, another keyframe (splash) 8.36. See `directing.md` §2.
- 2026-08-21 — Kling start+end with small angle steps = a near-full orbit in 5 s, logos float (at 2.6 s a different glyph than the real one); transition ≤ 1.2 s or sped up (0.3× PTS); a flip top→inside does work. Take the last window (~1.4 s), not 0.28× PTS ("the front twice"). No product tour with Kling (a second visor, visible only at full resolution) → a tour from ≥6 real angles. Generated fans get band shirts → "plain shirt" (IP).
- 2026-10-14 — model migration (~$7): Gemini Omni Flash KILL (2/3 shots a new camera position, one shot a different face; ~40 s, 720p); Kling v3 Pro PASS (face + framing tightest, the end-frame transition drove the ascent where v2.5 ran off low, 9:16 native 1080×1920). Delivers 1928×1072; end-frame jobs ~16 min, plain ~2 min; fields `start_image_url`/`end_image_url`.
- 2026-10-14 (II) — first headless production with Kling v3: 7 shots/format, 9:16 in 9.5 min, 16:9 in 4 min; $3.58 generation + $0.34–0.59 orchestration per format.
- 2026-10-16 (II) — late intruder: a hand from 2.6 s under "nothing else moves". A wipe in the title layer covers the seam only at a band width ≥ 1.6×W (~0.1 s fully covered).
- 2026-10-22 — walk-to-camera out of frame after ~5.8 s → keyframe at 75 %, lower, headroom. Loop with start = end: seam 0.77 vs frame step 0.14, with a 1 s crossfade (N−24 frames) 0.34. Rising from the dark: end frame at 22 % dimmed as the start frame; nano-banana refused "same face from afar" (0 images). Projection membrane: `o = 0.15 + 0.15·(L−Lref) + (D>0 ? 2.3·D : 1.35·D)`, L = gauss σ130 @1080p, flat screen 0.149, vignette superellipse p 2.4, edge exactly 0.
- 2026-11-01 — Kling turned "abstract shapes" in a shop window into a heart (see 2026-07-13).
- 2026-11-08 — Seedance 1.5 Pro test bench II: identity equal to Kling v3, native 1920×1080, ≈ $0.35/6 s vs $0.84; the end-frame transition loses (`models.md`).
- 2026-11-09 — three Kling v3 end-frame transitions that share each other's end frame (K1→K2, K2→K3, K3→light field) cut together into one continuous shot (scene score max 0.03); pace via speed ramps per segment. The xfade to the landing card must fall on the *white* part of the last clip (YAVG > 210), or the logo slides over visible image.
- 2026-11-12 — a Kling v3 start + end frame transition in **9:16** drifted from ~2.2 s into a young, dark-haired stock hero (identity drift toward a protected archetype); the same transition in 16:9 held. Seen frame by frame at 5 fps, not on a 1 fps strip. Fix without a re-render: cut on the take-off (first ~1.3 s of the transition becomes a separate shot).
- 2026-11-14 — fal retired Seedance 1.5 Pro on 2026-11-11, three days after it became the default; Kling v3 Pro is the default again. A retirement date lives in `api.fal.ai/v1/models?endpoint_id=…` (`retires_at`, `replacement`), **not** in the pricing API, which keeps listing the endpoint — check it whenever you pick a model.

## nano-banana / keyframes / keying → `consistency.md` §6–7
- 2026-11-09 — Gemini API 402 `RESOURCE_EXHAUSTED` (prepaid credit used up) stops nano-banana; the same model runs on fal: `fal-ai/nano-banana-pro` (+ `/edit` with `image_urls` as the anchor), $0.15/image, `resolution:"2K"` gives 2752×1536.
- 2026-11-12 — references copied from an earlier production can be **Git-LFS pointers** (132 bytes of ASCII) if they were never checked out; nano-banana only says `400 Unable to process input image` and the whole board fails. Run `file <ref> | grep -v 'image data'` before each generation; restore with `git lfs checkout <path>`.
- 2026-06-24 — 9 characters consistent across 6 comic pages via the cover as the `-r` anchor; generate text-free, keep text-free masters.
- 2026-07-10 — a real pet → a 3D anchor from 3–4 photos; likeness held across 6 Veo shots (`consistency.md` §1).
- 2026-07-12 — keyframe storyboard as a gate: stills ~€0.06, a board of 10 ~€0.60, i2v ~€5; break-even ~2 % conversion at ~€1/board and ~€45 margin (`storyboard-keyframes.md`).
- 2026-08-01 — a green key ate an anthracite coat: torso alpha 50–55 %, spots 11 %; magenta `#FF00FF`, despill `-channel RB -fx "u - 0.75*max(0,((u.r+u.b)/2)-u.g)"`, torso ≥ 98 %.
- 2026-08-01 — sprite sheet (6 poses): registration top within 1 px, height within 0.8 %; `connected-components` `area-threshold=150000`; no `-trim`; `qtrle`, 12 fps.
- 2026-08-10 — negatives don't remove a real outdoor brand's logo → depth of field; 2.39 bars unless "full frame edge to edge"; "deep black cotton" came back mid-grey; an opaque layer wrecks alpha (`CopyOpacity`); cutting out from white → erode the mask 2 px; PIL `convert("RGB")` drops alpha.
- 2026-08-11 — morph corridor: the reference scores DSSIM 0.38–0.43 between style plateaus, 0.37 first↔last (edge map 256×144); phone green screen: clean until 1.9 s, glasses in the band from 2.2 s, cloth `#2DBB51`, similarity 0.10 (0.14+ eats skin, 0.28 person gone); grade RGBA without touching alpha (`-modulate`/`-colorize` after `+clone -alpha extract` = a semi-transparent shirt).
- 2026-08-20 — a costume sheet without a face ref = a stranger + an emblem drifting to the protected shape (`consistency.md` §3.5).
- 2026-08-21 — a 120 cm ottoman became a small block next to a person: name scale + a human yardstick.
- 2026-10-14 (II) — 16:9 from 9:16 *with* the location anchor as a second ref: 5/8 frames the establishing wide again; without the anchor + "only widen to 16:9" works, ~$0.20/frame.
- 2026-10-22 — nano-banana on "pure black": a dark-blue panel + a pool of light; clean up, then `curves=all='0/0 0.075/0 0.14/0.05 …'` → RGB exactly 0.
- 2026-11-01 — nano-banana Pro 9:16 rotated 90° twice; "Upright portrait orientation … sky at the top, road at the bottom" + "lower fifth / upper fifth" works.

## Typography and titles → `commercial-craft.md` §2, `tooling.md`, `titles-hyperframes.md`
- 2026-11-12 — an ImageMagick end-card vignette step inherited `-geometry` from the previous composite → always reset with `-geometry +0+0` before a full-frame multiply.
- 2026-11-14 — three productions shipped their titles via HyperFrames → pango is no longer the title-layer fallback; it stays for text in the world and stills.
- 2026-06-24 — a mono logo variant flattens an emblem into a disc → full colour on a glass panel (rgba ~0.62 + a gold hairline) (`brand-intake.md` §7).
- 2026-07-07 — InterDisplay Black as a Druk Wide substitute; `label:` before `-border`; bake lower-thirds per beat clip (no retime across the xfade chain).
- 2026-07-10 — a title bar on a hero that already shows the site headline = double text: drop it.
- 2026-07-13 / 07-19 — `magick pango:` fails (bottle without the pango delegate, `PANGO* PANGO ---`); `pango-view` → PNG → composite; never silently to `label:`/`caption:`.
- 2026-07-16 — fonts per project (the preflight families are the legacy of one explainer; another brand → Spectral after a specimen board) (`brand-intake.md` §7).
- 2026-07-20 — a pango helper with one fixed tmp file: N× the last text, titles gone; AI chip before the wipe peak (wipe 0.35–1.60 s, chip 0.45 s, full 0.75 s ≈ 30 %; at 1.9 s ~0.5 s of AI imagery stood unlabelled).
- 2026-08-09 — `-crop` doesn't enlarge a canvas: `-set option:distort:viewport 2752x1536+0+0` before `-distort Perspective` (`title-sequence.md` §12).
- 2026-08-09 — ffmpeg 8.1.2 without `drawtext`/`subtitles`/`ass`: karaoke = one PNG per word state.
- 2026-08-13 — title-card anatomy of a personal brand leader: three sizes, a narrow heavy letter, extrusion light brass → dark bronze, a gold bevel carrying it, generate the material but take the letterforms from pango.
- 2026-10-14 (II) — `pango-view --width` in points: 820 "px" @96 dpi = 1093 px; title plates in a dissolve double up; a cumulative list without fades.
- 2026-10-14 (III) — HyperFrames PoC: GPU 948/980 frames identical (up to 4/255 on edge pixels), `--no-browser-gpu` 980/980; an old `node` v18 ahead of v26 in PATH on the render machine; the template ships in the skill (the render machine has no repo); GSAP overwrites `transform` and doesn't interpolate `var()`; `cp -RL`; a ProRes frame via `-pix_fmt rgba` + `-flatten`; `snapshot`/`--describe` sends frames to an external model → `HYPERFRAMES_NO_TELEMETRY=1`.
- 2026-11-01 — the template treats every unknown `kind` as a card → a production layer (own entry folder + `prod.js`/`prod.css`), `render-titles.sh` accepts it (`titles-hyperframes.md`).
- 2026-11-08 — HyperFrames 0.9.23 vs 0.8.99: 0/96 frames bit-identical, difference = anti-aliasing in motion (max 495 px, rest frames 0) → the pin stays (`tooling.md`).

## Capture / Playwright → `series-production.md` "Pitfalls in the capture rig"
- 2026-07-07 — `recordVideo` with a cursor dot via `page.evaluate` per `mouse.move`; speed-ramp static stretches (`setpts=PTS/1.8`, beat 9 s → 5 s); gate via `addCookies`.
- 2026-07-09 / 07-10 / 07-15 — Playwright MCP in Docker: screenshots not on the host; Chrome headless locally (`--window-size=1920,7200`, crop sections); npx Playwright without a browser → `{ channel: 'chrome' }`; capture format = output format (540 CSS px ×2 for 9:16; 390×844 dsf 3; 1920×1080 dsf 2).
- 2026-07-10 — a cookie banner (`position:fixed`) sits only at the bottom of a full-page render: crop the hero from it.
- 2026-07-11 — WebGL: `recordVideo` black, headless blank → headed + screenshot sequence (~220 frames/ratio); "tour" buttons were instruction modals; €0.
- 2026-07-15 — `omitBackground` opaque through a base CSS background (`srgba`, check alpha mean < 1); a feed scroll >10k px in 4 s = smear → cap ~2.5 viewports in ±5 s; widget root via grep → `addStyleTag`; signature move "painting → platform" (match-dissolve landscape→UI).
- 2026-07-31 — a device in 16:9 at 90–94 % height = ~450 px wide, text ~16 px → 1.35×/1.55× frame height, factor ~1.7; a fixed-width app: 390×693 dsf 3 → 1170×2079 → 1080×1920.
- 2026-08-26 — init script with a rAF loop instead of `evaluate` after `goto` (text visible 1.5–3 s; a 250 ms interval misses the first paint, the header flashed 2 frames); caught by a re-check at 10 fps.
- 2026-08-26 (II) — four white beats with "ok": guard on 0 events; `next dev` 500 `vendor-chunks` = a corrupt `.next`, `pkill -f next-server`, `start_new_session=True`, captures sequential.
- 2026-08-26 (III) — an SSR flash ~0.3 s: four failed attempts (innerText kept main hidden for 49 s; `<p>` instead of a heading; rAF lost the race; `innerText` empty under `visibility:hidden`) → hide preventively + `textContent`.
- 2026-08-26 (IV) — own worktree + port 3001; `NEXT_PUBLIC_API_URL` on 3000 cost three runs.
- 2026-08-26 (V) — `readdirSync(dir)[0]` promoted old webm files; `rmSync` per take, newest mtime.
- 2026-09-14 — staging: `networkidle` times out after 60 s → `domcontentloaded` + 6 s; mint the token in the stack with a `DATABASE_URL` guard and `trap`; mask real names; a probe per beat found four storyboard deviations.
- 2026-09-22 — `document.head` null in an init script; a mask before hydration breaks React (#418/#423/#425) → after `load` + start captures 2 s later; the 0-events guard rejected scroll beats → 'silent'; logged out = 401 blocks in frame; a sandboxed iframe isn't in `innerText`; `scrollIntoViewIfNeeded` on a late table times out.
- 2026-09-22 (II) — UI motion: 7/14 beats "still" during 41 actions → longest still interval (YAVG < 0.15) against ~3.5 s; every beat ended 3.5–5.0 s still → `active_end()`/`fit_dur()`.
- 2026-10-16 — CDP screencast (jpeg q95, viewport 1440×810 @ dsf 4/3) sharper than recordVideo; ffconcat `duration` rounds < 1/25 s up (7.8 s → 10.2 s) → 30 fps CFR yourself; run the closing hold through; svg cursor.
- 2026-10-16 (II) — the screencast delivers CSS pixels (1440×810, 390×693) → `--force-device-scale-factor` (1920×1080; 3840×2160 at dsf 8/3) + a width guard; an SVG logo clipped (viewBox 600 at ~626).
- 2026-11-01 — terminal via PTY asciicast + xterm.js frame stepping (30 fps), xterm height = rows × cell height; phone recording: track an anchor (green tick) per frame, a window with a static layout, key automatically on link pixels in the bottom band; a messenger shifts the button row twice.
- 2026-11-01 (II) — the smallest element with the text (sort by `textContent.length`) + visible in the viewport; blur via MutationObserver; read the whole page for names; 1280×720 @1.5 for 16:9, CU 960×540 @2; a number card 13.8 → 8.9 s by moving a VO line to the capture.
- 2026-11-03 — Wayback calendar (bare HTML 2009–2010), `if_` URLs, `body.style.zoom`; archive.org refuses parallel; recordVideo ignores dsf (again); archive footage via the YouTube channel (`yt-dlp --flat-playlist`, 403 = `brew upgrade yt-dlp`).

## Audio and voice → `montage-ffmpeg.md` "Audio and voice", `models.md` Audio
- 2026-06-24 — stable-audio = royalty-free, no mute on TikTok/Reels; generate two variants in parallel and choose.
- 2026-07-07 — the model can't audit a bed → caveat; ElevenLabs `speed` ~0.85; fal-side ElevenLabs SFX failed → direct or synth.
- 2026-07-07 — brand fit: an electronic bed was rejected where the brand's canon was orchestral; reuse the approved bed.
- 2026-11-03 — local TTS ~25 s/take: first a third of the take grid, measure, top up; saves over an hour.

## API / fal → `models.md` "fal API gotchas", `scripts/lib/fal.sh`
- 2026-06-23 — call schema-aware; result URL on the base-model path; Flux Dev sometimes without `status`.
- 2026-07-09 — reuse existing fal wrappers instead of rebuilding the queue.
- 2026-07-14 — Veo demanded a public `image_url` → a public keyframe host (since 2026-11-08 forbidden, see below).
- 2026-07-15 / 08-21 — a data URI via argv: "Argument list too long", a request without a body, five Kling jobs "successful" with `NO URL` (3 min, no cost); macOS ARG_MAX ~1 MB < two 2K JPEGs. Body via file, `--data-binary`; keyframes 1280×720/q88.
- 2026-08-11 — fal's fetcher gave `file_download_error` on a self-hosted URL that returned 200 → upload to fal-cdn.
- 2026-10-14 (II) — test the runner's API key first (`/v1/models` → 200; a non-workspace key 400).
- 2026-11-08 — audit: 103 client photos / 48 MB public for four months on a "temporary" keyframe host; 41 polling loops and 22 audio helpers across productions, the ARG_MAX bug logged twice; 40 scripts read the key from an unrelated project's `.env`. Now `scripts/lib/fal.sh` (upload to fal-cdn, resolver `~/.config/video-studio/.env`, cost log).
- 2026-11-08 — fal keeps request input/output for 90 days and cdn files public up to the account default → `X-Fal-Store-IO: 0` + a lifecycle header in `fal.sh`; `fal.sh delete` tested (200 → 404).
- 2026-11-08 — a cost line that could not be estimated (price per token) made `fal_run` fail on the last `&&` → the helper always ends with `return 0`; clips were generated but not downloaded.

## Shell / zsh / tools → `tooling.md` "Build gaps and shell pitfalls"
- 2026-06-24 — an ImageMagick install broke ffmpeg (`libx265.215.dylib`); `caption:` empty → `label expected` (an array shifted).
- 2026-06-24 / 08-13 / 11-08 — zsh doesn't split `$var` (`set -- $line`, `for f in $files`), arrays 1-indexed; two fal jobs with an empty `image_url`.
- 2026-07-01 — `-linecap` doesn't exist.
- 2026-07-09 / 07-20 / 08-10 — `magick montage` demands a font, even without labels; grids with `+append`/`-append`.
- 2026-07-13 — `fc-list | grep -q` under pipefail = SIGPIPE 141 → a false "not found" in preflight.
- 2026-08-09 — zsh expands `64*12` and globs → quote; `-v error` hides `metadata=print` → `file=-`.
- 2026-08-10 — `read a b < <(identify …)` kills `set -e`.
- 2026-08-21 — `local a="$1" b="$V/$a"`; APFS case-insensitive (`t4.png` = `T4.png`, card gone with rc=0); `| tail -1` hid three un-rebuilt `tour.mp4` rounds (mtime 20:00).
- 2026-11-08 — `board/*.jpeg` references were Git-LFS pointers (ASCII): all `ssim_end` measurements of both test benches were empty. `file` on your reference before you measure; `git lfs pull` first.
- 2026-11-08 — preflight reports peer drift and the ffmpeg version (local 8.1.2 ≠ peer 9.0.2); after aligning both on 9.0.2 the core recipes (xfade+settb, ProRes overlay, signalstats, ebur128, pango chain) were unchanged.

## QA and measuring → `commercial-craft.md` §7 and §9, `directing.md` §6–7
- 2026-11-12 — custom PIL beat renderer: a segment mixed in by a crossfade before its first cut got a negative local time; a flash formula `1 - t/0.14` went above 1 and `astype(np.uint8)` without a clip produced a rainbow-noise frame (visible only on a frame strip at the segment boundary, not at 1 fps). Rule: `np.clip(…, 0, 255)` before every `astype(np.uint8)`, local time < 0 = first frame without effect, and an automatic check on all segment boundaries.
- 2026-06-26 — a first cut approved on ~10 thumbnails, the client saw bad cuts: strip ≤ 0.7 s, out/in frame per cut, hold per card; cards ~28 % (max ~25 %); a speaker talking silently for 3 s; uniform 0.3 s dissolves = mud; 3 language versions before the core cut was right; a CTA assumption untested.
- 2026-07-10 — resized strips hide aspect/framing (an empty letterboxed leader, a clashing hero); a native frame per segment, check SAR.
- 2026-07-20 — 3D walkthrough: a plan hold with micro-drift reads as a still (10–12 s identical); explode layers 3400/4300/5200 cm with the camera at 2000, easing `t^2.1`; 9:16 from a 3D rig FOV 55 → 78 (117° would distort), end points −(look − pos).
- 2026-08-10 — don't judge a print on the last frame (`MET` legible for 1.3 s, the boot = occluder). Print on product: SSIM 0.26 → 0.63 → 0.92; a virtual try-on model replaced a head with a garment.
- 2026-08-19 — measurement lessons: a positive control is mandatory; validate the tracker (NCC ≥ 0.70, a brown door through the skin mask); sensitivity (σ=0.5 → −0.09); content-matched ground truth (flatness cel 0.635 vs photo 0.395 but billboard 0.749; uniformity 0.239 vs 0.158; mid/edge 3.13 vs 5.39; 720p +14 % vs 1080p +72 %, recalibrated +58 %); area measures framing, hue measures compliance.
- 2026-08-20 — a teaser: 12 shots, 11 at eye level, every clip 1-to-1 (57 s in one tempo); `pick-window.sh`: best window of the opener at 3.42 s, another at 5.46 s, another at 3.46 s; three actions in one shot = none; spread 0.61 → 0.90 s through the tail-frame shot (ep2).
- 2026-08-26 — a film without voice: holds ≥ 4 s; a 4.0 s card with fades = 2.6 s.
- 2026-09-22 (IV) — read frames with `-i f -ss t`; test a transition at several points.
- 2026-10-14 — a 6-frame strip missed the jump that comes in the last ~0.7 s; 8 frames × 3 draws always saw it.
- 2026-11-01 (II) — thumbnail from the outro source frame (1280×720) instead of a multiply/divide composite (a fringe three times).
- 2026-11-08 — a delivered client teaser fails `qa-check.sh`: colour tags `unknown/unknown/bt709`, 9:16 at 19.7 MB, −15.9 LUFS against a social target of −14. A rule in a document is not a gate.

## Second render machine / parity → `tooling.md`, `preflight.sh` (`VIDEO_STUDIO_PEER`)
- 2026-07-15 — the production machine produced a blurred-fill 9:16 because `vertical-916.md` and commercial-craft §0.5 had not been synced since provisioning.
- 2026-10-14 (III) — an old node v18 ahead of v26 on the production machine; put the newer node first in PATH; the HyperFrames template must ship in the skill.
- 2026-11-08 — 3 files of drift at the audit; ffmpeg 8.1.2 (dev) ≠ 9.0.2 (production); the public release 9 changes behind.

## Workflow → `brand-intake.md` §7, `commercial-craft.md` §0, `SKILL.md` §0
- 2026-06-24 — ImageMagick "skipped" without asking → the iron preflight rule (A/B/C).
- 2026-06-24 — consume the brand canon and EDL (style guide + tokens + an existing render pipeline); a hero tier above a "not loud" canon.
- 2026-06-28 — copy-first with 6/167 clips gave generic b-roll: footage-first, one proof shot per line, show the shot↔line map.
- 2026-07-07 — join the brand's existing pipeline (leader/outro bracket, dark heavy-type cards, an orchestral bed, real-time recordings); finals in a fixed place (`<name>-16x9.mp4`); Ken Burns rejected for the second time (the #2 repeat mistake after "real shop photos").
- 2026-07-07 / 07-14 — hard rule: no Ken Burns, motion = a real element coming to life (`commercial-craft.md` §0.5); 13 campaign videos rebuilt zoompan → i2v/static.
- 2026-07-10 — a v1 leader without i2v cost from a nano-banana style frame (~$0).
- 2026-07-12 — an insight from one client job (the storyboard gate) enriches the skill for every project.
- 2026-07-16 — self-QA per deliverable (duration, resolution) in the headless delivery contract.
- 2026-08-21 — every build step with its own `rc`, mtime of intermediates, QA frames from the delivered file at the timecode the client named.
- 2026-11-08 — audit: without a shared library every bug repeats; a "temporary" public host becomes permanent; client imagery leaves the machine only toward the API that needs it. A rule in a document is not a gate → `scripts/qa-check.sh`. Every video with AI imagery carries the label (EU AI Act art. 50) — visible on the end card and in the metadata.
