# Tooling — video-studio

What the skill uses, how to check for it, and how to install it (after approval). `scripts/preflight.sh` automates this check in a mode-aware way; `scripts/doctor.sh` is the friendly first-time version. **If something required is missing → stop and ask, never install silently.**

## Core (always)
| Tool | Check | Install | Role |
|------|-------|---------|------|
| ffmpeg / ffprobe | `ffmpeg -version` | `brew install ffmpeg` | montage, transcode, frame extraction, scene detection, audio |
| jq | `jq --version` | `brew install jq` | parse fal API JSON |
| curl | `curl --version` | system | fal API calls, downloads, FTP deploy |

## Title layer — HyperFrames (canonical; recipe: `titles-hyperframes.md`)
| Tool | Check | Install | Role |
|------|-------|---------|------|
| Node ≥ 22 | `node -v` | `brew install node` | HyperFrames CLI. If an older node (e.g. v18 in `/usr/local/bin`) comes first in PATH, put the newer one ahead of it — on every machine that renders. |
| HyperFrames 0.8.99 | `npx --yes hyperframes@0.8.99 --version` | none: `npx` fetches the pinned version (cached in `~/.npm/_npx`) | renders the transparent title MOV; always via `scripts/render-titles.sh` |
| Chrome | (HyperFrames finds/fetches its own headless Chrome) | — | frame capture; always `--no-browser-gpu` for cross-machine parity |
| title template | `ls templates/titles/shared/fonts` | ships with the skill | fonts + GSAP live inside the composition, so no system-font dependency; brand via `spec.brand` |

## Lettering / title cards — pango (fallback for the title layer; stays for text-in-the-world)
Canonical text render: **real pango rendering via `pango-view` → transparent PNG → composite with ImageMagick.**
| Tool | Check | Install | Role |
|------|-------|---------|------|
| ImageMagick (`magick`) | `magick -version` | `brew install imagemagick` | compositing text PNGs onto a canvas, exact dimensions, grades |
| pango-view | `which pango-view` | `brew install pango` | the TEXT itself: markup, variable-font weights, `letter_spacing`, `line_height`, wrap |
| brand fonts | `fc-list \| grep -i Fraunces` | font files in `~/Library/Fonts` (fontconfig) | e.g. Fraunces/Inter/Outfit (the default house style) — pango finds them by family name via fontconfig |

- **Why pango-view and not `magick pango:`** — Homebrew's ImageMagick bottle is built **without** the pango/fontconfig delegate (`magick -version` lists only `freetype`); `pango:` fails with "no decode delegate". `label:`/`caption:` (freetype) works but lacks variable-font axes, real `letter_spacing` and rich markup → weaker typography. **Never silently degrade to `label:`** — install pango; a dependency that makes the output better is always welcome. An ImageMagick source rebuild with pango is fragile (breaks on `brew upgrade`); `pango-view` is the robust, upgrade-safe route and gives identical output.
- **Recipe**: `pango-view --no-display -q --background=transparent --dpi=140 --align=left --markup -t "<span font='Fraunces Bold 66' foreground='#F5F2EC'>…<span style='italic' foreground='#B6A78F'>…</span></span>" -o t.png` → then `magick canvas.png t.png -gravity … -geometry … -composite out.png`.
- **PARITY (hard)**: if you render on a second machine or server (e.g. one that runs the skill headless), it needs exactly these tools + fonts — otherwise its output drifts from what you approved locally. Preflight enforces the tools.

## Full-AI mode
| Tool/Key | Check | Install/set | Role |
|----------|-------|-------------|------|
| nano-banana | `which nano-banana` | `nano-banana` skill → `/init` (Bun + Gemini key) | stills/keyframes (Gemini 3 Flash/Pro), reference anchor, green-screen |
| ImageMagick (`magick`) | `magick -version` | `brew install imagemagick` | lettering, caption boxes, compositing, exact dimensions |
| FAL_AI_KEY | env or `.env` | `FAL_AI_KEY=...` in `~/.config/video-studio/.env` | image-to-video (Kling), Flux/Recraft image, stable-audio |
| ELEVENLABS_API_KEY | env or `.env` | optional | voices/SFX |
| SUNO_API_KEY | env or `.env` | optional | music (often produced in-browser; supply prompts) |

## Existing-footage mode
| Tool | Check | Install | Role |
|------|-------|---------|------|
| yt-dlp | `which yt-dlp` | `brew install yt-dlp` | **only** needed to download from a URL (YouTube etc.); not for local files |
| ffmpeg | (see core) | — | scene detection (`select='gt(scene,0.4)'`), thumbnails, trim, concat |

## Keys & paths
- Keys live in `~/.config/video-studio/.env` (or a project `.env` in the current or parent directory): `FAL_AI_KEY`, `ELEVENLABS_API_KEY`, `SUNO_API_KEY`, `SUNO_API_URL`. Preflight and doctor check exactly these three locations. **Never commit, never echo.**
- The Gemini key for nano-banana lives in its own `.env` (separate from fal), set during the nano-banana skill's `/init`.
- If your project already has a fal.ai wrapper for images (sprites/backgrounds/logos/og-images/remove-bg), reuse it rather than rebuilding one.

## Known tool interactions
- **`brew install imagemagick` can break ffmpeg's x265 link** (`libx265.<v>.dylib not found`). Fix: `brew reinstall ffmpeg`. Check after every ImageMagick install whether ffmpeg/ffprobe still run; if not, restore immediately. (See `lessons.md`.)

> If anything here changes (new tool, different install, new key) → update this file, `scripts/preflight.sh` and `scripts/doctor.sh`, and bump `CHANGELOG.md`.
