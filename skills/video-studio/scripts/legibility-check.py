#!/usr/bin/env python3
"""legibility-check.py — legibility gate for the title layer (deterministic). Origin: a season's greeting a client
rejected ("the text doesn't flow well everywhere"; plates still half typed out when the picture changed).

  python3 -I legibility-check.py <spec.json> <video.mp4> [--cuts segments.txt --xfade s]

Per reading-text item (plate, pair, card, figure, credit; not: sub — qa-check.sh --srt judges that — and ailabel):
  1. reading time  fully visible AFTER typing out ≥ 0.6 s + words ÷ 3 s (typing and fades recomputed from titles.js)
  2. transition    a picture transition never falls inside the text's build-up (text half typed at a cut/xfade)
  3. size          letter height ≥ 4.5 % of the frame height (16:9) / ≥ 5.0 % of the frame width (9:16)
  4. lines         ≤ 2 lines (estimated with the real plate width from titles.css; a written \\n counts)
  5. contrast      ≥ 4.5:1, MEASURED on the real frame under the plate (text pixels p97 against background p30, WCAG luminance)
  6. overlap       no overlap with a subtitle, AI label or credit on screen at the same time (bbox from titles.css)
--cuts = SEGMENT DURATIONS including the dissolve overlap (t += duration − xfade), not the cut distances qa-check.sh reads;
the check fails by itself if the segments don't fill the film. A film of mostly hard cuts: --xfade 0.
Exit 0 = all PASS, 1 = at least one FAIL, 2 = usage error. Output per item: PASS/FAIL with the measurement.
Limitation (honest): the bbox is estimated from titles.css, not from the render; a logo inside the picture itself is not
seen by this check (that is the frame strip, commercial-craft §7). If you change titles.css, update GEO below.
"""
import json, math, re, subprocess, sys, tempfile, os

# Geometry from templates/titles/shared/titles.css (2026-11-17). px in the master.
GEO = {
    "landscape": {"W": 1920, "H": 1080, "plate_x": 90, "plate_w": 820, "pad_x": 62, "pad_y": 52,
                  "fs": 58, "fs_small": 50, "lh": 1.08, "onder_bottom": 56, "onder_maxw": 1500,
                  "sub": (60, 1080 - 120 - 80, 1920 - 60, 1080 - 120),          # x0,y0,x1,y1 (2 lines ≈ 80 px per line → generous)
                  "ailabel": (1920 - 72 - 360, 1080 - 56 - 48, 1920 - 72, 1080 - 56),
                  "credit": (72, 1080 - 50 - 110, 72 + 900, 1080 - 50)},
    "portrait": {"W": 1080, "H": 1920, "plate_x": 70, "plate_w": 940, "pad_x": 62, "pad_y": 52,
                 "fs": 68, "fs_small": 60, "lh": 1.08, "top": 250, "onder_bottom": 400,
                 "sub": (60, 1920 - 420 - 130, 1080 - 60, 1920 - 420),
                 "ailabel": (70, 1920 - 330 - 56, 70 + 420, 1920 - 330),
                 "credit": (70, 260, 1010, 260 + 130)},
}
GLYPH = 0.52            # mean glyph width ÷ font size for headings (bold display sans, measured on 6 plates)
MIN_VIS_BASE, WPS = 0.6, 3.0
MIN_FS = {"landscape": ("H", 0.045), "portrait": ("W", 0.050)}
MIN_CONTRAST = 4.5
TEXT_KINDS = {"plate", "pair", "card", "figure", "credit"}


def words_of(s):
    return [w for w in re.split(r"\s+", (s or "").replace("*", "").replace("\n", " ")) if re.search(r"\w", w)]


def item_text(it):
    parts = [it.get(k) for k in ("kicker", "head", "text", "typed", "knew", "num", "noemer", "label")]
    for k in ("foot", "lines"):
        v = it.get(k) or []
        parts += v if isinstance(v, list) else [v]
    return "\n".join(str(p) for p in parts if p)


def reveal_end(it):
    """Moment the text is fully there, recomputed from titles.js (plate: words rise in with a stagger)."""
    f = float(it.get("fade", 0.25 if it.get("kind") in ("plate", "pair") else 0.3))
    t0 = float(it["in"])
    if it.get("static"):
        return t0
    if it.get("kind") in ("plate", "pair"):
        n = max(len(words_of(item_text(it))), 1)
        stagger = min(0.035, 0.9 / n)
        return max(t0 + f, t0 + 0.05 + (n - 1) * stagger + 0.3)
    if it.get("kind") == "card" and it.get("typewriter"):
        return t0 + float(it["typewriter"])
    return t0 + f + 0.5


def est_lines(it, g):
    fs = g["fs_small"] if it.get("small") else g["fs"]
    if it.get("pos") == "onder" and "onder_maxw" in g:      # 16:9: a bottom plate is wider (fit-content, max 1500)
        avail = g["onder_maxw"] - 2 * g["pad_x"]
    else:
        avail = g["plate_w"] - 2 * g["pad_x"]
    per = max(int(avail / (fs * GLYPH)), 1)
    lines = 0
    for ln in (it.get("text") or item_text(it)).replace("*", "").split("\n"):
        lines += max(1, math.ceil(len(ln.strip()) / per))
    return lines, fs, per


def plate_bbox(it, g, lines, fs):
    h = lines * fs * g["lh"] + 2 * g["pad_y"] + (40 if it.get("bron") else 0)
    if g is GEO["landscape"]:
        if it.get("pos") == "onder":
            longest = max(len(l) for l in (it.get("text") or "").replace("*", "").split("\n") or [""])
            w = min(g["onder_maxw"], longest * fs * GLYPH + 2 * g["pad_x"])
            x0 = (g["W"] - w) / 2
            return (x0, g["H"] - g["onder_bottom"] - h, x0 + w, g["H"] - g["onder_bottom"])
        y0 = (g["H"] - 60 - h) / 2
        return (g["plate_x"], y0, g["plate_x"] + g["plate_w"], y0 + h)
    if it.get("pos") == "onder":
        return (g["plate_x"], g["H"] - g["onder_bottom"] - h, g["plate_x"] + g["plate_w"], g["H"] - g["onder_bottom"])
    return (g["plate_x"], g["top"], g["plate_x"] + g["plate_w"], g["top"] + h)


def lum(rgb):
    def c(v):
        v = v / 255.0
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, gg, b = rgb
    return 0.2126 * c(r) + 0.7152 * c(gg) + 0.0722 * c(b)


def measure_contrast(video, t, box, W, H):
    x0, y0, x1, y1 = [int(round(v)) for v in box]
    x0, y0 = max(x0 + 10, 0), max(y0 + 10, 0)
    x1, y1 = min(x1 - 10, W), min(y1 - 10, H)
    if x1 - x0 < 20 or y1 - y0 < 20:
        return None
    cmd = ["ffmpeg", "-v", "error", "-ss", f"{t:.3f}", "-i", video, "-frames:v", "1",
           "-vf", f"crop={x1-x0}:{y1-y0}:{x0}:{y0},scale=iw/2:ih/2", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    raw = subprocess.run(cmd, capture_output=True).stdout
    if not raw:
        return None
    L = sorted(lum(raw[i:i + 3]) for i in range(0, len(raw) - 2, 3 * 3))   # every third pixel is enough
    lt, lb = L[int(len(L) * 0.97)], L[int(len(L) * 0.30)]
    return (max(lt, lb) + 0.05) / (min(lt, lb) + 0.05)


def overlap(a, b):
    return not (a[2] <= b[0] or b[2] <= a[0] or a[3] <= b[1] or b[3] <= a[1])


def main(argv):
    if len(argv) < 2:
        print(__doc__); return 2
    spec_p, video = argv[0], argv[1]
    cuts_p, xfade = None, 0.0
    i = 2
    while i < len(argv):
        if argv[i] == "--cuts": cuts_p = argv[i + 1]; i += 2
        elif argv[i] == "--xfade": xfade = float(argv[i + 1]); i += 2
        else: print(f"unknown option {argv[i]}", file=sys.stderr); return 2
    spec = json.load(open(spec_p))
    W, H = [int(x) for x in subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
            "stream=width,height", "-of", "csv=p=0", video], capture_output=True, text=True).stdout.strip().split(",")[:2]]
    fmt = "landscape" if W > H else "portrait"
    g = dict(GEO[fmt]); scale = W / g["W"]
    for k in ("W", "H"): g[k] = W if k == "W" else H
    GEO[fmt] = g   # plate_bbox compares by identity
    # transitions: [start, end] of every cut/xfade
    trans = []
    if cuts_p:
        lens = [float(l) for l in open(cuts_p) if l.strip()]
        # --cuts = SEGMENT DURATIONS including the dissolve overlap (t += duration − xfade). A file of cut distances
        # (what qa-check.sh --cuts counts) shifts every transition by k × xfade and silently makes the transition test
        # unreliable (measured 2026-11-19). Check: together the segments must fill the film.
        vdur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", video],
                                    capture_output=True, text=True).stdout.strip() or 0)
        som = sum(lens) - xfade * max(0, len(lens) - 1)
        if xfade and vdur and abs(som - vdur) > max(0.5, xfade * 2):
            print(f"  FAIL  cuts       segments fill {som:.2f} s, the film runs {vdur:.2f} s: pass segment durations including "
                  f"the dissolve overlap (not the cut distances of qa-check.sh), or --xfade 0 for hard cuts")
            print("──\nLEGIBILITY: FAIL (cuts file doesn't match the film)"); return 1
        t = 0.0
        for k, l in enumerate(lens[:-1]):
            t += l - (xfade if k > 0 else 0)
            trans.append((t - xfade, t) if xfade else (t - 0.04, t + 0.04))
    items = spec.get("items", [])
    others = [(it, k) for k, it in enumerate(items) if it.get("kind") in ("sub", "ailabel", "credit")]
    fails = 0; n = 0
    print(f"── legibility-check: {os.path.basename(video)} ({W}×{H}, {fmt})")
    for k, it in enumerate(items):
        kind = it.get("kind")
        if kind not in TEXT_KINDS or "in" not in it or "out" not in it:
            continue
        n += 1
        txt = item_text(it)
        nw = len(words_of(txt))
        f = float(it.get("fade", 0.25 if kind in ("plate", "pair") else 0.3))
        rv = reveal_end(it)
        vis = (float(it["out"]) - f) - rv
        need = MIN_VIS_BASE + nw / WPS
        reasons = []
        if vis + 1e-6 < need:
            reasons.append(f"reading time {vis:.2f}s fully visible, needs {need:.2f}s ({nw} words)")
        for a, b in trans:
            if a < rv - 0.02 and b > float(it["in"]) + 0.02:   # 20 ms margin: a plate starting exactly at the end of the transition is fine
                reasons.append(f"transition {a:.2f}–{b:.2f}s falls in the build-up ({float(it['in']):.2f}–{rv:.2f}s): text half done at a cut")
                break
        if kind in ("plate", "pair"):
            lines, fs, per = est_lines(it, g)
            fs_px = fs * scale
            ref, minr = MIN_FS[fmt]
            base = W if ref == "W" else H
            if fs_px / base + 1e-9 < minr:
                reasons.append(f"letter {fs_px:.0f}px = {100*fs_px/base:.1f}% of the {'width' if ref=='W' else 'height'} < {100*minr:.1f}%")
            if lines > 2:
                reasons.append(f"~{lines} lines (≤ 2; ~{per} characters fit per line)")
            box = plate_bbox(it, g, lines, fs)
            mid = rv + max(vis, 0.1) / 2
            cr = measure_contrast(video, mid, box, W, H)
            if cr is None:
                reasons.append("contrast not measurable (frame/bbox)")
            elif cr + 1e-6 < MIN_CONTRAST:
                reasons.append(f"contrast {cr:.1f}:1 < {MIN_CONTRAST}:1 on the real frame ({mid:.1f}s)")
            for o, ko in others:
                if float(o["in"]) < float(it["out"]) and float(o["out"]) > float(it["in"]):
                    ob = g.get(o["kind"])
                    if ob and overlap(box, ob):
                        reasons.append(f"overlaps {o['kind']} #{ko} ({float(o['in']):.1f}–{float(o['out']):.1f}s)")
            meta = f"vis {vis:.2f}s/needs {need:.2f}s · {lines} l · contrast {cr:.1f}:1" if cr else f"vis {vis:.2f}s/needs {need:.2f}s"
        else:
            meta = f"vis {vis:.2f}s/needs {need:.2f}s"
        label = txt.replace("\n", " ").replace("*", "")[:38]
        if reasons:
            fails += 1
            print(f"  FAIL  #{k:<2} {kind:<6} {label!r}: " + "; ".join(reasons))
        else:
            print(f"  PASS  #{k:<2} {kind:<6} {label!r}: {meta}")
    print("──")
    if not n:
        print("LEGIBILITY: no reading-text items found"); return 0
    print(f"LEGIBILITY: {'PASS' if not fails else 'FAIL'} ({n - fails}/{n} items)")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
