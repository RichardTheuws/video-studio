# Tooling — video-studio

What the skill uses, how to check for it, and how to install it (after approval). `scripts/preflight.sh` automates this check in a mode-aware way; `scripts/doctor.sh` is the friendly first-time version. **If something required is missing → stop and ask, never install silently.**

## Core (always)
| Tool | Check | Install | Role |
|------|-------|---------|------|
| ffmpeg / ffprobe | `ffmpeg -version` | `brew install ffmpeg` | montage, transcode, frame extraction, scene detection, audio |
| jq | `jq --version` | `brew install jq` | parse fal API JSON |
| curl | `curl --version` | system | fal API calls, downloads, FTP deploy |
| `scripts/lib/fal.sh` | `scripts/lib/fal.sh price fal-ai/stable-audio-25/text-to-audio` | ships with the skill | **the one fal layer**: key resolver, upload to fal-cdn, submit, wait, result, cancel, cost log (`costs.jsonl`) |
| `scripts/qa-check.sh` | `scripts/qa-check.sh film.mp4 --expect 20` | ships with the skill | measurable QA gate before delivery (format, SAR, bt709 tags, duration, size, loudness, rhythm, dead cuts, AI label); exit ≠ 0 = don't deliver |

## Title layer — HyperFrames (canonical; recipe: `titles-hyperframes.md`)
| Tool | Check | Install | Role |
|------|-------|---------|------|
| Node ≥ 22 | `node -v` | `brew install node` | HyperFrames CLI. If an older node (e.g. v18 in `/usr/local/bin`) comes first in PATH, put the newer one ahead of it — on every machine that renders. |
| HyperFrames 0.8.99 | `npx --yes hyperframes@0.8.99 --version` | none: `npx` fetches the pinned version (cached in `~/.npm/_npx`) | renders the transparent title MOV; always via `scripts/render-titles.sh`. **The pin stays** (measured 2026-11-08 against 0.9.23: 0/96 frames bit-identical, but the difference is only anti-aliasing on frames with motion — max 495 px out of 2 M, rest frames identical). Upgrade when a feature needs it, on every render machine at once, then re-run the bit-identity test between machines. |
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
| FAL_AI_KEY | `scripts/lib/fal.sh key` | `FAL_AI_KEY=...` in `~/.config/video-studio/.env` | image-to-video (Seedance / Kling), Flux/Recraft image, stable-audio |
| ELEVENLABS_API_KEY | env or `.env` | optional | voices/SFX |
| SUNO_API_KEY | env or `.env` | optional | music (often produced in-browser; supply prompts) |

## Existing-footage mode
| Tool | Check | Install | Role |
|------|-------|---------|------|
| yt-dlp | `which yt-dlp` | `brew install yt-dlp` | **only** needed to download from a URL (YouTube etc.); not for local files |
| ffmpeg | (see core) | — | scene detection (`select='gt(scene,0.4)'`), thumbnails, trim, concat |

## Keys & paths
- **One key resolver: `scripts/lib/fal.sh key`.** Search order: `$FAL_AI_KEY` → `./.env` → `../.env` → `$VIDEO_STUDIO_ENV` (an extra file, e.g. on a headless runner) → **`~/.config/video-studio/.env`** (the canonical location, `chmod 600`). Preflight and doctor check exactly these locations. Never hard-code a path to an `.env` in a production script: in one audit, 40 scripts read the key from an unrelated project's `.env`. **Never commit, never echo.**
- The same file holds `ELEVENLABS_API_KEY`, `SUNO_API_KEY`, `SUNO_API_URL`.
- The Gemini key for nano-banana lives in its own `.env` (separate from fal), set during the nano-banana skill's `/init`.
- If your project already has a fal.ai wrapper for images (sprites/backgrounds/logos/og-images/remove-bg), reuse it rather than rebuilding one.

## Known tool interactions
- **`brew install imagemagick` can break ffmpeg's x265 link** (`libx265.<v>.dylib not found`). Fix: `brew reinstall ffmpeg`. Check after every ImageMagick install whether ffmpeg/ffprobe still run; if not, restore immediately. (See `lessons.md`.)

> If anything here changes (new tool, different install, new key) → update this file, `scripts/preflight.sh` and `scripts/doctor.sh`, and bump `CHANGELOG.md`.

## Build gaps and shell pitfalls (consolidated from the log, 2026-11-08)
### What these builds cannot do
- **Homebrew ffmpeg (8.1.2, verified 2026-08-09) has no `drawtext`, no `subtitles`/`ass`** (no libfreetype, no libass), no `zscale` (→ `ffmpeg-full`), and `crop` without `eval=frame`. All text — subtitles and karaoke included — goes through pango/magick to PNG and then `overlay`; karaoke = one PNG per word state. The same bottle risk applies to any second render machine: check parity before a text recipe goes to a runner.
- **Homebrew ImageMagick has no pango delegate** (`magick -list format` shows `PANGO* PANGO ---`; 2026-07-13, 07-19), **no default font** (`-font <path>` is mandatory, also for `montage -label`; name lookup fails — 2026-07-09, 08-10), **no `-linecap`** (use `-strokelinecap`; 2026-07-01), and `caption:`/`label:` with an empty string gives `label expected` (2026-06-24). `label:` must come before `-border` (2026-07-07).
- **`brew install imagemagick` can break ffmpeg's x265 dylib** → `brew reinstall ffmpeg`; check ffmpeg after every media-tool install (2026-06-24).
- **An outdated `yt-dlp` gives 403** on YouTube: `brew upgrade yt-dlp` (a pip update doesn't touch the brew install; 2026-11-03). archive.org refuses parallel requests (`ERR_CONNECTION_REFUSED` on every tab) while another job hammers the archive: go serial, with pauses.
- **PIL `convert("RGB")` throws the alpha channel away** — load artwork that carries its ink mask with `convert("RGBA")`, otherwise the output is byte-identical to the version without the mask (2026-08-10).

### Shell (the Bash tool runs zsh on macOS)
- **zsh does not word-split `$var`**: `set -- $line`, `for f in $files` and `set -- $p` give empty fields — two fal jobs went out with an empty `image_url` (2026-06-24, 08-13, 11-08). Use `while IFS=' ' read -r a b`, `${=line}`, `read -rA`, or run under `bash -c`. zsh arrays are 1-indexed. Quote globs and `*` in filter arguments (`mpdecimate=hi=64*12`, `trans/precise*`; 2026-08-09). `"[0:v]$GRADE[v]"` → `${GRADE}[v]`.
- **`fc-list | grep -q` fails under `pipefail`** (SIGPIPE, exit 141): capture first, then match without a pipe (2026-07-13).
- **`read a b < <(identify …)` kills a `set -e` script** (no trailing newline → exit 1 although the values are set): `WH=$(identify -format '%w %h' f); W=${WH% *}` (2026-08-10).
- **`local a="$1" b="$V/$a"` expands `$a` before it is assigned** → with `set -u` the script dies; split the `local` lines (2026-08-21).
- **`-v error` also suppresses `showinfo`/`metadata=print`**: use `metadata=print:file=-` with `2>/dev/null` (2026-08-09).
- **APFS is case-insensitive**: `t4.png` and `T4.png` are the same file; an intermediate overwrote the card with `rc=0` (2026-08-21). Give intermediates their own prefix, verify with `ls -la`.
- **`bash build.sh | tail -1` hides a failing step** (exit 0 through the pipe): three "fix rounds" assembled the same stale intermediate (2026-08-21). Every build step gets its own `rc=$?`, and compare the **mtime of the intermediate** against the export; take QA frames from the file you deliver.
- **ARG_MAX (~1 MB on macOS) is smaller than two base64 JPEGs**: a data URI via `jq --arg` or argv sends a request without a body (`{"detail":[{"type":"missing","loc":["body"]}]}`, "Argument list too long"; 2026-07-15, 08-21). Body via file + `curl --data-binary @req.json`; `scripts/lib/fal.sh` does this — and uploads imagery to fal-cdn instead of embedding it.
- **`pango-view --width` is in points**: at `--dpi=96`, 820 "px" becomes 1093 px (2026-10-14); `width_pt = px*72/dpi`. A pango helper that writes to one fixed tmp file gives N× the last text in a multi-layer composite (2026-07-20): a unique name per call.
- **Reference images can be Git-LFS pointers** (ASCII text, not JPEG): every SSIM measurement against them silently came back empty (2026-11-08). Run `file` on your reference before you measure; `git lfs pull` first.
- Keys: see "Keys & paths" — never an `.env` path in a production script (2026-11-08).
