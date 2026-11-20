#!/usr/bin/env python3
"""Subtitles from the script, timed by the measured VO (reference/extended.md §4): text = lines.json (intended text), time per
cue = the first word of the cue via monotone alignment on the whisper words in vo.json. Rules: ≤ 2 lines, ≤ 42 characters
per line, ≥ 1.0 s, ≤ 17 characters/s.

  subs.py <vo.json> <starts.json> <out-prefix>
starts.json: {"<line id>": <absolute start time of that VO line in the film, s>}
Writes <out-prefix>.subs.json (items {"kind":"sub","in","out","text"} for the title layer) and <out-prefix>.srt.
Plain python3 (no venv needed)."""
import json, re, sys, unicodedata
from pathlib import Path

MAXL, MAXCPS, MINDUR = 42, 17.0, 1.0
norm = lambda w: re.sub(r"[^a-z0-9]", "", unicodedata.normalize("NFKD", w.lower()).encode("ascii", "ignore").decode())


def wrap(t: str, maxl: int = MAXL) -> str:
    if len(t) <= maxl:
        return t
    ws = t.split(); best = None
    for i in range(1, len(ws)):
        a, b = " ".join(ws[:i]), " ".join(ws[i:])
        if len(a) <= maxl and len(b) <= maxl:
            sc = abs(len(a) - len(b)) - (8 if a[-1] in ",:;?." else 0)
            if best is None or sc < best[0]:
                best = (sc, a + "\n" + b)
    if not best:
        raise ValueError(f"cue too long for 2×{maxl}: {t}")
    return best[1]


def cues_for_line(r: dict, start: float) -> list[dict]:
    sw, hw = r["text"].split(), r["words"]
    pos, h = {}, 0
    for j, w in enumerate(sw):
        n = norm(w)
        for q in range(h, min(h + 4, len(hw))):
            if n and (hw[q]["n"] == n or (len(n) >= 4 and hw[q]["n"][:4] == n[:4])):
                pos[j] = hw[q]["s"]; h = q + 1; break
    known = sorted(pos)

    def tj(j):
        if j in pos: return pos[j]
        lo = max([k for k in known if k < j], default=None); hi = min([k for k in known if k > j], default=None)
        if lo is None: return 0.0
        if hi is None: return pos[lo]
        return pos[lo] + (pos[hi] - pos[lo]) * (j - lo) / (hi - lo)

    parts, cur = [], []
    for j, w in enumerate(sw):
        cur.append(j)
        if re.search(r"[.?:,!]$", w): parts.append(cur); cur = []
    if cur: parts.append(cur)
    groups, cur = [], []
    for d in parts:
        text = " ".join(sw[k] for k in cur + d)
        if cur and (len(text) > 66 or re.search(r"[.?:!]$", sw[cur[-1]])): groups.append(cur); cur = list(d)
        else: cur = cur + d
    if cur: groups.append(cur)
    out = [{"in": round(start + tj(c[0]) - 0.06, 3), "line": r["id"], "text": wrap(" ".join(sw[k] for k in c))} for c in groups]
    out[-1]["end"] = round(start + r["duration_s"] + 0.2, 3)
    return out


def build(vo: dict, starts: dict) -> list[dict]:
    subs = []
    for r in vo["lines"]:
        if r["id"] in starts:
            subs += cues_for_line(r, float(starts[r["id"]]))
    subs.sort(key=lambda s: s["in"])
    i = 0
    while i < len(subs) - 1:   # too short or too fast → merge with the next cue of the same line if it fits
        a, b = subs[i], subs[i + 1]
        too_fast = len(a["text"].replace("\n", " ")) / max(b["in"] - a["in"], 0.01) > MAXCPS
        if a["line"] == b["line"] and (b["in"] - a["in"] < MINDUR or too_fast):
            try:
                a["text"] = wrap(a["text"].replace("\n", " ") + " " + b["text"].replace("\n", " "))
            except ValueError:
                i += 1; continue
            if "end" in b: a["end"] = b["end"]
            del subs[i + 1]; continue
        i += 1
    for i, s in enumerate(subs):
        nxt = subs[i + 1]["in"] if i + 1 < len(subs) else 1e9
        end = s.pop("end", None) or nxt
        s["out"] = round(min(end, nxt), 3)
        if s["out"] - s["in"] < MINDUR: s["out"] = round(min(s["in"] + MINDUR, nxt), 3)
    return [{"kind": "sub", "in": s["in"], "out": s["out"], "text": s["text"]} for s in subs]


def ts(x: float) -> str:
    h = int(x // 3600); m = int(x % 3600 // 60); s = x % 60
    return f"{h:02d}:{m:02d}:{int(s):02d},{int(round((s - int(s)) * 1000)) % 1000:03d}"


def srt(subs: list[dict]) -> str:
    return "\n".join(f"{i + 1}\n{ts(s['in'])} --> {ts(s['out'])}\n{s['text']}\n" for i, s in enumerate(subs))


def main() -> None:
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    vo = json.loads(Path(sys.argv[1]).read_text()); starts = json.loads(Path(sys.argv[2]).read_text())
    subs = build(vo, starts)
    pre = Path(sys.argv[3])
    pre.parent.mkdir(parents=True, exist_ok=True)
    Path(f"{pre}.subs.json").write_text(json.dumps(subs, ensure_ascii=False, indent=1))
    Path(f"{pre}.srt").write_text(srt(subs), encoding="utf-8")
    print(f"{len(subs)} cues → {pre}.srt")


if __name__ == "__main__":
    main()
