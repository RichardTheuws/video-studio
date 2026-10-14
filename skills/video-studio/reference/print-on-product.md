# Putting a real print on a product — measured, not estimated

**Why this exists**: for brands that *print* things (merchandise, textiles, promo items) the product is the hero, and a print that reads as a sticker isn't a cosmetic problem but a substantive error. Two consecutive brand leaders were rejected on exactly this: *"it's far too obvious that it isn't real"*. This document is the method that fixes it, including the measurement setup, so it stays a measurement and not a matter of taste.

The method has two operations: **extract** (pull the artwork and its ink mask out of a product photo) and **apply** (put it on a target frame, relit for that frame). The sections below describe what each must do.

---

## 1. The model in one line

**observation = albedo × light.** A print that reads fake carries the light of the *source photo* and ignores that of the target. So you have to work in two directions: take the source light out, put the target light in.

## 2. The three things that make the difference

Measured with cross-validation against ground truth (see §4). Blank fabric = SSIM 0.007 as the floor.

| Approach | SSIM | RMSE |
|---|---|---|
| naive paste (warp + multiply by a blurred grey value) | 0.259 | 0.272 |
| + relight with the target's light field | 0.625 | 0.226 |
| + source weave out, target weave in | 0.719 | 0.194 |
| **log domain + robust polynomial fit + alpha-from-deviation** | **0.919** | **0.092** |

1. **Work in the LOG domain.** `log I = log R + log S` turns shadow separation into a subtraction. Dividing linearly by a light field of ~0.05 blows the artwork up 20× — that's the washed-out look you see.
2. **Estimate the light field with a robust polynomial fit over ONLY the fabric pixels** (order **1**, iteratively reweighted, Cauchy). Blur + diffusion gets dragged along by the studio halo and by the artwork itself — measured fabric level 0.171 where it should be 0.05. And **order 2 or 3 is measurably worse** (0.846 → 0.811 → 0.72): a higher order starts absorbing the artwork itself instead of the light.
3. **Alpha from DEVIATION, not from luminance.** The question isn't *"how light is this pixel"* but *"how far does it deviate from what the fabric should be here"*. On unprinted fabric that deviation is zero, so alpha is zero there — automatically, without a threshold. A luminance key leaves the surrounding black in place, and *that* is the visible rectangle.

## 3. Five rules that follow

1. **Transfer the level with one measured gain**, not with absolute light fields. The light field travels **centered** (mean 0 in log) — only the variation — and the level via `gain = target fabric level / source fabric level`. Normalize both sides separately to mean 1 and you import the brightness of the studio photo.
2. **Determine the ink mask before relighting.** Afterwards the fabric black has been lifted to mid-grey and no longer keys out.
3. **Strip the weave of the source photo and add that of the target.** Weave at the wrong scale and orientation is a giveaway. Measured gain: 0.625 → 0.719.
4. **The garment tone must match.** A print from a black shirt on a much lighter garment will never look real — that's an error in the *target frame*, not in the compositing. Measure it and stop at a >2.5× difference. **Measure the fabric level in a ring around the print area**: garment detection is built for product photos on white and fails on a dark scene (there you measure 0.55 where it's 0.15).
5. **Ink doesn't cover fully.** The measured optimal knee is generous (≈0.4): the fabric reads through the ink. Screen print isn't foil, and this is exactly what makes a composite read as integrated.

## 4. The measurement setup — this keeps it a measurement

**Cross-validation against ground truth.** Find the same artwork on **two different products** in the product photo library (e.g. one band design on a men's tee, a women's tee and a hoodie). Extract the artwork from photo A, apply it with the method to the product in photo B, and compare with what B actually looks like. One number, no taste.

```
extract  A.jpg                          → art.png (artwork + ink mask in alpha)
apply    B.jpg  art.png  quad(x1,y1 … x4,y4) → recon.jpg
compare  recon.jpg  B.jpg  box(x1,y1,x2,y2)  → RMSE + SSIM inside the print box
```

Two traps in the *measuring* itself, both walked into:

- **Band ratios (mid/high-frequency energy inside vs. outside the print) don't measure what you think.** They mostly measure the detail of the artwork itself, and the ratio isn't comparable between photos with different weave sharpness. Use cross-validation.
- **SSIM rewards blur.** Always report a detail ratio alongside it: `std(highpass(result)) / std(highpass(real))`, which should sit around 1.0. At the measured optimal setting it is 1.20 — slightly sharper than real, not blurrier.

## 5. Virtual try-on: tested and rejected for cinematic frames

fal has a whole category of try-on models (`fal-ai/fashn/tryon/v1.6`, `fal-ai/kling/v1-5/kolors-virtual-try-on`, `fal-ai/flux-pro/v1/vto`, `leffa`, `cat-vton`). They take a real garment photo plus a person and handle draping and lighting themselves — on paper exactly what you want.

**In practice they collapse on cinematic imagery.** FASHN v1.6 on a dark concert photo (fan with raised arms, crowd, a blown-out spot behind) replaced the man's head with a garment and put the shirt in frame grotesquely enlarged and floating. Cause: these models are trained on e-commerce imagery — one person, frontal, standing, studio-like — and their person segmentation fails outside that.

**Rule**: try-on is usable for e-commerce-like frames (frontal, calm, one person, even light). For cinematic frames use the method from §1–3. Test it per case with one call (it's cheap and done in ~5s) instead of assuming — in both directions.

## 6. More important than the method: the target frame

In every attempt that went wrong, the **frame** turned out to be the fault, not the compositing:

- a print in a shadowed area doesn't read, and no amount of ink boosting in post fixes that — **the print area must be lit**;
- a spectacle shot (silhouette, backlight, a diagonal cloth full of folds) is a bad print surface: a print on a silhouette reads as a light spot. Generate **flat, frontal, evenly lit** carriers for text/print and let the spectacle shots carry nothing (see `title-sequence.md` §3);
- the tone of the carrier must match the source (§3 rule 4).

So: approve the frame on print-area light first, then composite. The other way round costs you an afternoon.

## 7. References

- `title-sequence.md` §6 — never generate hero text (this document is the image counterpart of that rule).
- `commercial-craft.md` §7 — pre-delivery inspection; never judge a print on a single frame.
- `lessons.md` — the individual technical traps (ImageMagick without a default font, `read`+`identify`, alpha loss under an opaque texture layer, PIL dropping alpha, cut-out color bleed).
