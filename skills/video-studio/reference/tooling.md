# Tooling — video-studio

What the skill uses, how to check for it, and how to install it (after approval). `scripts/preflight.sh` automates this check in a mode-aware way. **If something required is missing → stop and ask, never install silently.**

## Core (always)
| Tool | Check | Install | Role |
|------|-------|---------|------|
| ffmpeg / ffprobe | `ffmpeg -version` | `brew install ffmpeg` | montage, transcode, frame extraction, scene detection, audio |
| jq | `jq --version` | `brew install jq` | parse fal API JSON |
| curl | `curl --version` | system | fal API calls, downloads, FTP deploy |

## Full-AI mode
| Tool/Key | Check | Install/set | Role |
|----------|-------|-------------|------|
| nano-banana | `which nano-banana` | `nano-banana` skill → `/init` (Bun + Gemini key) | stills/keyframes (Gemini 3 Flash/Pro), reference anchor, green-screen |
| ImageMagick (`magick`) | `magick -version` | `brew install imagemagick` | lettering, caption boxes, compositing, exact dimensions |
| FAL_AI_KEY | env or `.env` | `FAL_AI_KEY=...` in project `.env` | image-to-video (Veo/Kling), Flux/Recraft image, stable-audio |
| ELEVENLABS_API_KEY | env or `.env` | optional | voices/SFX |
| SUNO_API_KEY | env or `.env` | optional | music (often produced in-browser; supply prompts) |

## Existing-footage mode
| Tool | Check | Install | Role |
|------|-------|---------|------|
| yt-dlp | `which yt-dlp` | `brew install yt-dlp` | **only** needed to download from a URL (YouTube etc.); not for local files |
| ffmpeg | (see core) | — | scene detection (`select='gt(scene,0.4)'`), thumbnails, trim, concat |

## Keys & paths
- The project `.env` (in the project root, or `~/.config/video-studio/.env`) holds keys such as `FAL_AI_KEY`, `ELEVENLABS_API_KEY`, `SUNO_API_KEY`, `SUNO_API_URL`. **Never commit, never echo.**
- The Gemini key for nano-banana lives in its own `.env` (separate from fal), set during the nano-banana skill's `/init`.
- If your project already has a fal.ai wrapper for images (sprites/backgrounds/logos/og-images/remove-bg), reuse it rather than rebuilding one.

## Known tool interactions
- **`brew install imagemagick` can break ffmpeg's x265 link** (`libx265.<v>.dylib not found`). Fix: `brew reinstall ffmpeg`. Check after every ImageMagick install whether ffmpeg/ffprobe still run; if not, restore immediately. (See `lessons.md`.)

> If anything here changes (new tool, different install, new key) → update this file and `scripts/preflight.sh`, and bump `CHANGELOG.md`.
