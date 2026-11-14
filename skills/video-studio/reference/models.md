# Model registry — video-studio

Which model for what, with cost/params and pitfalls. **Verify prices/endpoints with a test call if a line feels stale** — record any drift (self-maintenance).

## Image-to-video (fal.ai) — the core of Full-AI
| Model | Endpoint | When | Cost / params |
|-------|----------|------|---------------|
| **Kling v3 Pro** (default for every shot and every end-frame transition; default for single shots again since 2026-11-14, Seedance 1.5 Pro is retired) | `fal-ai/kling-video/v3/pro/image-to-video` | every transition with a start + end frame, and any shot where identity must hold the tightest (test bench 2026-10-14, see `lessons.md`) | **$0.14/s** without audio (fal pricing API 2026-10-16; was $0.112), more with audio — check `api.fal.ai/v1/models/pricing?endpoint_id=…` or `scripts/lib/fal.sh price <endpoint>`. Fields: **`start_image_url`** (not `image_url`), **`end_image_url`** (start + end frame → a real unbroken transition), `duration` as a **string** `"3"`…`"15"` (any whole second), `generate_audio`, `elements` (character references, `@Element1` in the prompt), `multi_prompt`. **Delivers 1928×1072** → in the montage always `scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080`. **Output follows the keyframe's aspect ratio**: 1920×1080 → 1928×1072, 1080×1920 → 1080×1920, but 1536×2752 (nano-banana 2K 9:16) → 1072×1928. Wait time for a normal shot ~2–3.5 min; with an end frame measured 2.5–16 min (heavily queue-dependent) → always a background task. The requested main action often lands in the **last quarter** of the clip → always pick the window with `pick-window.sh`. No `seed`, no `aspect_ratio` (it comes from the keyframe). |
| ~~Seedance 1.5 Pro~~ | `fal-ai/bytedance/seedance/v1.5/pro/image-to-video` | **do not use**: fal retired the model on **2026-11-11** (`api.fal.ai/v1/models?endpoint_id=…` → `retires_at`, suggested replacement `minimax/h3-max/image-to-video`, untested) | was the single-shot default 2026-11-08 → 11-11; test bench II below stays as a record. |
| Kling v2.5 (start + end frame) | `fal-ai/kling-video/v2.5-turbo/pro/image-to-video` | fallback for transitions if v3 is down | `image_url` + `tail_image_url`, `duration:"5"`; 1924×1076, ~60–110 s. On the same transition (2026-10-14) the figure ran off low where v3 rode the requested rise. |
| ~~Veo 3 / 3.1 Fast~~ | `fal-ai/veo3/fast/…`, `fal-ai/veo3.1/fast/…` | **do not use** — fal shuts both down on **2026-10-25** (3.1 first-last-frame on 2026-11-17) | was primary until 2026-10-14. `seed` was accepted but not honoured (2026-08-19). |
| ~~Gemini Omni Flash~~ | `fal-ai/gemini-omni-flash/image-to-video` | **KILL** (2026-10-14): changes camera position and face relative to the keyframe | fast (~40 s) and ~$0.13/s, but max 720p, no end frame, no seed — breaks the keyframe-first principle |

Kling in general: the global queue once climbed past 4000 (hours). Cancel via `PUT .../requests/<id>/cancel`; `pkill` on the poller does NOT stop the fal job. Don't send `aspect_ratio` (`input_value_error`).

**`negative_prompt` does nothing** (measured 2026-08-19, including a positive control): on
`kling-video/v2.5-turbo/pro/image-to-video` even a negative prompt that forbids *all* colour leaves the
saturation unchanged. Send the field if you like, but don't count on it — see `lessons.md` 2026-08-19.
That endpoint also has **no `seed`**, so A/B comparisons need several draws per arm.

**Migrating off Veo — what the test bench showed (2026-10-14):** same keyframes + prompts as an earlier Veo production (the baseline), Kling v3 Pro against Gemini Omni Flash, plus an end-frame transition and one 9:16 shot (~$7 total). Omni Flash picked a new camera position in 2 of 3 shots and gave the hero a different face → KILL. Kling v3 Pro held face + framing, the end-frame transition rode the requested move, and 9:16 came back native 1080×1920 with a fixed camera → PASS. One measurement trap: on a 6-frame strip Kling v3 seemed never to perform the jump in one shot; three draws sampled at 8 frames showed it always comes — in the **last ~0.7 s**. Judge "action missing" only on a strip that samples the last quarter densely.

**Principle**: always **image-to-video from your own keyframe**, never text-to-video. The keyframe (nano-banana/Flux) locks subject + environment → characters are consistent by definition. See `consistency.md`.

## Stills / keyframes
| Tool/Model | Strong at | Note |
|-----------|-----------|------|
| **nano-banana** (Gemini 3 Flash/Pro) | fast iteration, style/character transfer via refs, exact dims, green-screen (`-t`) | Pro for cover/hero quality; ~$0.13/1K (Pro), ~$0.067 (Flash). Reference order matters: 1st = primary style, last = dims (blank-image trick). |
| fal.ai **Flux Dev** (`fal-ai/flux/dev`) | sprites/pixel-art, character frames | strong kawaii bias + value collapse; see `consistency.md` for anti-biases |
| fal.ai **Flux Pro v1.1** (`fal-ai/flux-pro/v1.1`) | backgrounds, watercolor, parallax layers | weak warm/cool enforcement → force the value distribution explicitly |
| fal.ai **Recraft V3** (`fal-ai/recraft-v3`) | flat brand logos, icons | clean/vector; for painterly title art prefer Flux Dev sprite-style |
| **Custom character LoRA** | a recurring face/character across shots | `fal-ai/flux-lora`, your own trigger word, `loras:[{path:URL, scale:1.0}]`. Weights URLs can expire — keep a `.safetensors` backup. Train on your own dataset; see `consistency.md`. |
| Real-ESRGAN (`fal-ai/esrgan`) | upscaling | — |

## Audio
| Model | Endpoint | Role | Note |
|-------|----------|------|------|
| stable-audio-25 | `fal-ai/stable-audio-25/text-to-audio` | music bed | param `seconds_total`. **Fine as instrumental muzak/underscore/bed** (this is allowed, not "fake music"). Prompt for *underscore/ambient/score, no vocals* — NEVER for a song that imitates a real pop track. Audibly verify it reads as a bed, not a song. |
| Suno | (in-browser or SUNO_API_KEY) | per-stage themes | supply prompts |
| ElevenLabs | API key | voices, SFX stingers, announcer | **fal-side ElevenLabs SFX failed** ("Sound effect generation failed") → generate SFX directly at ElevenLabs, or build **synth SFX in ffmpeg** (see montage). |

## fal API gotchas (general)
- **Use `scripts/lib/fal.sh`** (`fal_upload` · `fal_submit` · `fal_wait` · `fal_result` · `fal_run` · `fal_cancel` · `fal_price` · `fal_delete`), not a curl loop of your own per production. Everything below is built into it, plus a cost line per call in `costs.jsonl`. Privacy defaults: `X-Fal-Store-IO: 0` (no request history at fal), uploads expire after 24 h, outputs after 7 days.
- **Imagery for i2v goes through fal's own storage** (`fal.sh upload photo.jpg` → a `fal.media` URL), **never through a public host of your own**. A "temporary" public keyframe host becomes permanent (client photos sat public for months in one audit) and fal's fetcher gave `file_download_error` on it anyway (2026-08-11).
- **Call schema-aware**: each model has its own params. Pull the in-schema: `https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=<ep>` and send only supported keys.
- **Result URL** lives on the **base-model path** (e.g. `queue.fal.run/fal-ai/kling-video/requests/<id>`), not the sub-tier path. Poll the `status_url`/`response_url` from the submit response; **do not reconstruct it yourself**. Retry the result fetch (short 400/425 right after COMPLETED).
- Flux Dev queue sometimes returns `{images:[...]}` **without** `status` → fallback: extract `images[0].url` directly, otherwise the poll hangs forever.
- **Parallel batch**: several `run_in_background` Bash calls in one message; the fal queue handles parallelism fine (8 assets < 60s).
- Long jobs = **tracked background tasks**; don't live-poll (the queue is erratic).

## Virtual try-on (a real garment on a person) — tested, of limited use
| Model | Endpoint | Finding |
|-------|----------|---------|
| FASHN v1.6 | `fal-ai/fashn/tryon/v1.6` | `model_image` + `garment_image` (+ `category`, `garment_photo_type`, `mode`). ~5 s. **Does not work on cinematic footage** — see below. |
| Kling Kolors VTON | `fal-ai/kling/v1-5/kolors-virtual-try-on` | `human_image_url` + `garment_image_url` |
| others | `fal-ai/flux-pro/v1/vto`, `fal-ai/leffa/virtual-tryon`, `fal-ai/cat-vton` | same category |

**Verified 2026-08-10**: FASHN v1.6 on a dark concert photo (a fan with raised arms, a crowd, a blown-out
spotlight) replaced the head with a garment and floated the shirt grotesquely in frame. These models are
trained on e-commerce imagery (one person, frontal, standing, even light) and their person segmentation
fails outside that. Usable for e-commerce-like frames; for film footage use `print-on-product.md`. One
~5 s call settles it — test per case instead of assuming.

## Measured behaviour of i2v models (rules from the log, consolidated 2026-11-08)
Everything below was measured on real clips; dates point to `lessons.md`.

**What the keyframe decides (the lever is upstream)**
- The keyframe carries the style: 12 Veo clips from a cel-shaded keyframe drifted a median 7 % (max 15 %) toward photorealism, whether the style sentence came first or last (U=13/36; 2026-08-19). Prompt order buys nothing in i2v.
- Motion comes from the keyframe: an empty ceiling + "the drop falls" gave motion energy 0.08, a more explicit prompt 0.10, a keyframe *with* the splash 8.36 (2026-08-20). Stop after one failed prompt attempt.
- `negative_prompt` is inert on Kling (positive control: a prompt forbidding all colour left saturation at 0.4164 against an A-range of 0.4158–0.4264; anti-sheen U=9/16; 2026-08-19). Skin texture is not promptable: keyframe or grade.
- Role-labelling references adds nothing with two references (no leakage in 16/16; the U=44/64 "more yellow" was framing: coat area U=52/64, hue 43.0° vs 40.8° U=40/64; 2026-08-19).
- Vague "merge/coalesce" prompts become an icon: Veo turned "swirl into one warm form" into a heart, and Kling did the same with "abstract shapes" in a shop window (2026-07-13, 11-01). Name the geometry ("vertical column of light", "soft vertical bars").
- A figure "walking toward the camera" walks out of frame after ~5.8 s in Kling v3: place the keyframe at 75 % and lower (headroom) + "stops, head fully inside the frame with headroom" (2026-10-22).

**What i2v cannot do (use something else)**
- Stylised 3D cartoon characters with fixed character DNA: Veo turned a dust coat into a blazer, a hi-vis collar into a dress shirt, dropped the tape measure and reframed, despite a locked-off prompt and a negative (2026-07-29). Alternative: an ffmpeg push-in on the approved keyframe (1.5× upscale, z 1.0→~1.055, `noise=alls=4:allf=t+u`), or a sprite-sheet walk cycle in one generation (`consistency.md` §7). Baked-in text does survive Veo.
- UI screens, text strips and letterbox collages: Veo pushes through the bands and hallucinates outside the crop (2026-07-14) → static hold. Curate first vs last frame: expanded = KILL.
- Product turntables: a Kling start + end frame fills 5 s with a (near) full orbit, lets small logos float (2026-08-21) and, on an ambiguous object (a cap), hallucinates a second visor somewhere — also in the "clean" last window, visible only frame by frame at full resolution. Build tours from ≥6 real angles (poses 1.2–1.5 s, 4 % push, 0.25 s dissolve). Keep Kling for the journey (product → in use), where a hallucination is masked. From an orbit you do use, take the **last window** (~1.4 s arriving at the end pose), not the whole clip at 0.28× PTS — or you see the front twice.
- Hanging textile on a pull-out: Veo lets a banner sag and fold; on a push-in it holds. Always drive toward hero text on textile + "the banner stays taut, fixed and firmly hung" (2026-08-09). A pre-composited print survived 14/14 clips with "the printed lettering must stay exactly as it is"; frame the carrier large enough from the start (85 mm instead of 50 mm).

**Kling v3 — tricks that work**
- Loop: `start_image_url` = `end_image_url` gives a near-seamless loop (seam 0.77 against a median frame step of 0.14); a 1 s crossfade end→start (output N−24 frames) → 0.34 (2026-10-22).
- Rising out of the dark: end frame (close-up) from nano-banana, start frame deterministic with ImageMagick (end frame at 22 %, dimmed, soft ellipse mask, on black) → start + end; identity exactly equal (2026-10-22).
- A plate can get a late intruder (a hand from 2.6 s, prompt said "nothing else moves"; 2026-10-16): pick the window before it, strip the last quarter densely.
- A 9:16 keyframe 1080×1920 → a 1080×1920 clip with a fixed camera (Veo gave 720×1280); 12/12 garden photos came back camera-locked on the prefix "Locked-off static tripod camera, no camera movement of any kind, no zoom, no pan, no push-in, the frame stays completely fixed. Only [element] moves…" (2026-07-14).

**Seedance 1.5 Pro vs Kling v3 Pro (test bench II, 2026-11-08)**: same keyframes, same prompts. Identity and framing equal to Kling v3, native 1920×1080, roughly $0.35 against $0.84 for 6 s. The start + end frame transition loses: Seedance runs first and then switches hard where Kling drives the move. Hence the split: Seedance for single shots, Kling v3 for end-frame transitions — until fal retired Seedance 1.5 Pro on 2026-11-11; Kling v3 Pro is the default for everything again. Note: `board/*.jpeg` references turned out to be Git-LFS pointers locally, so every `ssim_end` column of both benches was empty until `git lfs pull` — run `file` on your references before you measure.

**Veo 3 Fast (historical, until 2026-10-25)**: `duration` enum `4s/6s/8s`, 720p, ~48–75 s/clip, $0.10/s; a 2.39:1 keyframe with `aspect_ratio:auto` came back as 16:9 (1280×720) — letterbox in the edit. **The prompt goes through a content checker** (`422 content_policy_violation`): "small child silhouette … corner" blocked, "child-height shadow in the foreground" on the same image not; blocked = no cost (2026-07-16). `seed` accepted but not honoured: an identical seed differed 22.78 against 24.02 for different seeds (2026-08-19).
