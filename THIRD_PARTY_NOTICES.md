# Third-party notices

The skill itself is MIT-licensed (see `LICENSE`). The title template bundles a few third-party files so that renders
work offline and stay frame-identical across machines. They keep their own licenses:

| File(s) | Project | License |
|---|---|---|
| `skills/video-studio/templates/titles/shared/fonts/Fraunces.ttf` | [Fraunces](https://github.com/undercasetype/Fraunces) | SIL Open Font License 1.1 — `fonts/OFL-Fraunces.txt` |
| `skills/video-studio/templates/titles/shared/fonts/InterDisplay-*.otf` | [Inter](https://github.com/rsms/inter) | SIL Open Font License 1.1 — `fonts/OFL-InterDisplay.txt` |
| `skills/video-studio/templates/titles/shared/fonts/JetBrainsMono.ttf` | [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) | SIL Open Font License 1.1 — `fonts/OFL-JetBrainsMono.txt` |
| `skills/video-studio/templates/titles/shared/vendor/gsap.min.js` | [GSAP](https://gsap.com) 3.14.2 | GSAP Standard "No Charge" License — <https://gsap.com/standard-license/> |

[HyperFrames](https://github.com/heygen-com/hyperframes) (Apache 2.0) is not bundled; `render-titles.sh` runs a pinned
version through `npx`.
