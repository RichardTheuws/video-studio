# Model registry — video-studio

Which model for what, with cost/params and pitfalls. **Verify prices/endpoints with a test call if a line feels stale** — record any drift (self-maintenance).

## Image-to-video (fal.ai) — the core of Full-AI
| Model | Endpoint | When | Cost / params |
|-------|----------|------|---------------|
| **Veo 3 Fast** (primary) | `fal-ai/veo3/fast/image-to-video` | default: reliable, direct, **native audio** | ~$0.15/s with audio, $0.10 without; duration enum `4s/6s/8s` |
| Kling i2v | `fal-ai/kling-video/...` | only when there is no time pressure | global queue has climbed past 4000 (hours). **Has no `aspect_ratio`** (it comes from the keyframe) → passing it = `input_value_error`. Cancel via `PUT .../requests/<id>/cancel`; `pkill` on the poller does NOT stop the fal job. |

**Principle**: always **image-to-video from your own keyframe**, never text-to-video. The keyframe (nano-banana/Flux) locks subject + environment → characters are consistent by definition. See `consistency.md`.

## Stills / keyframes
| Tool/Model | Strong at | Note |
|-----------|-----------|------|
| **nano-banana** (Gemini 3 Flash/Pro) | fast iteration, style/character transfer via refs, exact dims, green-screen (`-t`) | Pro for cover/hero quality; ~$0.13/1K (Pro), ~$0.067 (Flash). Reference order matters: 1st = primary style, last = dims (blank-image trick). |
| fal.ai **Flux Dev** (`fal-ai/flux/dev`) | sprites/pixel-art, character frames | strong kawaii bias + value collapse; see `consistency.md` for anti-biases |
| fal.ai **Flux Pro v1.1** (`fal-ai/flux-pro/v1.1`) | backgrounds, watercolor, parallax layers | weak warm/cool enforcement → force the value distribution explicitly |
| fal.ai **Recraft V3** (`fal-ai/recraft-v3`) | flat brand logos, icons | clean/vector; for painterly title art prefer Flux Dev sprite-style |
| **Custom character LoRA** | a recurring face/character across shots | `fal-ai/flux-lora`, your own trigger word, `loras:[{path:URL, scale:1.0}]`. Train on your own dataset; see `consistency.md`. |
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
