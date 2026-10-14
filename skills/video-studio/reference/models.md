# Model registry — video-studio

Which model for what, with cost/params and pitfalls. **Verify prices/endpoints with a test call if a line feels stale** — record any drift (self-maintenance).

## Image-to-video (fal.ai) — the core of Full-AI
| Model | Endpoint | When | Cost / params |
|-------|----------|------|---------------|
| **Kling v3 Pro** (primary since 2026-10-14) | `fal-ai/kling-video/v3/pro/image-to-video` | default for every shot and for transitions: holds the keyframe's face + framing the tightest (test bench 2026-10-14, see `lessons.md`) | $0.112/s without audio, $0.168 with. Fields: **`start_image_url`** (not `image_url`), **`end_image_url`** (start + end frame → a real unbroken transition), `duration` as a **string** `"3"`…`"15"` (any whole second), `generate_audio`, `elements` (character references, `@Element1` in the prompt), `multi_prompt`. **Delivers 1928×1072** → in the montage always `scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080`. **Output follows the keyframe's aspect ratio**: 1920×1080 → 1928×1072, 1080×1920 → 1080×1920, but 1536×2752 (nano-banana 2K 9:16) → 1072×1928. Wait time for a normal shot ~2–3.5 min; with an end frame measured 2.5–16 min (heavily queue-dependent) → always a background task. The requested main action often lands in the **last quarter** of the clip → always pick the window with `pick-window.sh`. No `seed`, no `aspect_ratio` (it comes from the keyframe). |
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
