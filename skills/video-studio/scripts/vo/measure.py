#!/usr/bin/env python3
"""Voice gate per take (reference/extended.md §3): Whisper large-v3 (language VO_LANG, brand names as initial_prompt) →
WER against the intended text; f0 median (pyin) and MFCC c1–c19 relative to the reference voice; tempo, tail, noise floor.
Each take is also transcribed WITHOUT the vocab hint, by large-v3 and by turbo, for the name check (names.py).

  measure.py <workdir>        run with the VO venv (VS_VO_PY)
Reads <workdir>/lines.json and <workdir>/takes/*.wav, writes <workdir>/measure.jsonl (lines already there are skipped).
Vocab: <workdir>/vocab.txt (one line with brand names/domains), otherwise env VO_PROMPT."""
import os, sys, json, re, pathlib, subprocess

SKILL = pathlib.Path(__file__).resolve().parents[2]
ANCHOR = os.environ.get("VO_ANCHOR", str(SKILL / "assets" / "voice" / "anchor.wav"))
LANG = os.environ.get("VO_LANG", "en")
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from lang import number_words, DOT, PERCENT, SLASH  # noqa: E402
from names import names_ok  # noqa: E402

# per-language spelling variants whisper uses for the same word (after normalisation)
JOIN = {"nl": [("chat gpt", "chatgpt"), ("a i", "ai"), ("ee aai", "ai")], "en": [("chat gpt", "chatgpt"), ("a i", "ai")]}


def norm(s: str, lang: str = LANG) -> str:
    """Comparable form: numbers written out, domains with the spoken dot, letters/digits only."""
    s = s.lower().replace("’", "'")
    s = re.sub(r"(\d+)\s*%", lambda m: m.group(1) + " " + PERCENT.get(lang, "%"), s)
    s = re.sub(r"\d+", lambda m: number_words(int(m.group()), lang), s)
    s = re.sub(r"(?<=\w)\.(?=\w)", " " + DOT.get(lang, ".") + " ", s).replace("/", " " + SLASH.get(lang, "/") + " ")
    s = s.replace("ë", "e").replace("é", "e")
    s = re.sub(r"[^a-z0-9à-ÿ ]", " ", s)
    s = " ".join(s.split())
    for a, b in JOIN.get(lang, []):
        s = re.sub(r"\b" + a + r"\b", b, s)
    return s


def compound(a: list, b: list) -> list:
    """Compound words (Dutch, German): whisper often writes "verdergaat" as "verder gaat" (and the other way round). Two
    consecutive words in b that together form exactly one word of a count as that word."""
    ra, out, j = set(a), [], 0
    while j < len(b):
        if j + 1 < len(b) and b[j] not in ra and b[j] + b[j + 1] in ra: out.append(b[j] + b[j + 1]); j += 2
        else: out.append(b[j]); j += 1
    return out


def wer(ref: str, hyp: str) -> float:
    a, b = ref.split(), hyp.split(); b = compound(a, b); d = list(range(len(b) + 1))
    for i, x in enumerate(a, 1):
        prev, d[0] = d[0], i
        for j, y in enumerate(b, 1):
            prev, d[j] = d[j], min(d[j] + 1, d[j - 1] + 1, prev + (x != y))
    return d[-1] / max(1, len(a))


def load(p, sr=16000):
    import numpy as np
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(p), "-ac", "1", "-ar", str(sr), "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).copy()


def timbre(x):
    import numpy as np, librosa
    x = x / (np.sqrt(np.mean(x ** 2)) + 1e-9) * 0.05
    m = librosa.feature.mfcc(y=x, sr=16000, n_mfcc=20); a = librosa.feature.rms(y=x)[0] > 0.02
    return m[1:, a[: m.shape[1]]].mean(1)


def f0med(x):
    import numpy as np, librosa
    f0, v, _ = librosa.pyin(x, fmin=60, fmax=450, sr=16000, frame_length=1024); f0 = f0[v]
    return float(np.median(f0)) if len(f0) else 0.0


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    import numpy as np
    import mlx_whisper
    w = pathlib.Path(sys.argv[1]).resolve()
    if not os.path.isfile(ANCHOR):
        sys.exit(f"measure.py: no reference voice at {ANCHOR} — set VO_ANCHOR (reference/extended.md §3)")
    # Two references per line: the subtitle ("Acme") and the speech text (a phonetic spelling). Whisper writes what it
    # hears, so a phonetic brand name counts as right if it matches either one (lowest WER).
    lines = json.loads((w / "lines.json").read_text())
    ref = {l["id"]: l["text"] for l in lines}
    speech = {l["id"]: l.get("speech") or l["text"] for l in lines}
    vocab = (w / "vocab.txt").read_text().strip() if (w / "vocab.txt").exists() else os.environ.get("VO_PROMPT") or None
    out = w / "measure.jsonl"
    done = {json.loads(x)["f"] for x in out.read_text().splitlines() if x.strip()} if out.exists() else set()
    ax = load(ANCHOR); at, af = timbre(ax), f0med(ax)
    tx = lambda p, model, **kw: mlx_whisper.transcribe(str(p), path_or_hf_repo=model, language=LANG, temperature=0.0,
                                                       condition_on_previous_text=False, **kw)["text"].strip()
    with out.open("a") as fh:
        for p in sorted((w / "takes").glob("*.wav")):
            if p.name in done: continue
            key = re.sub(r"-s\d+$", "", p.stem)
            if key not in ref: continue
            x = load(p)
            rms = np.sqrt(np.convolve(x ** 2, np.ones(1280) / 1280, "valid")[::640] + 1e-12); db = 20 * np.log10(rms)
            act = np.nonzero(db > -35)[0]
            span = (act[-1] - act[0]) * 640 / 16000 + 0.08 if len(act) else 0
            tail = len(x) / 16000 - (act[-1] * 640 + 1280) / 16000 if len(act) else 0
            hyp = tx(p, "mlx-community/whisper-large-v3-mlx", initial_prompt=vocab)
            # Second listen WITHOUT the vocab hint: with the hint whisper writes the brand name even when it isn't said.
            hyp_free = tx(p, "mlx-community/whisper-large-v3-mlx")
            # ...and with the turbo model (the one the final QA uses): a name only counts when BOTH models hear it
            # (measured: large heard one wrong variant, turbo another — 12 of 14 takes dropped the first consonant).
            hyp_turbo = tx(p, "mlx-community/whisper-large-v3-turbo")
            ok1, mis1 = names_ok(ref[key], speech[key], vocab or "", hyp_free)
            ok2, mis2 = names_ok(ref[key], speech[key], vocab or "", hyp_turbo)
            f0 = f0med(x); nwords = len(norm(ref[key]).split())
            fh.write(json.dumps({"f": p.name, "key": key, "dur": round(len(x) / 16000, 2), "span": round(span, 2), "tail": round(tail, 2),
                "floor_db": round(float(np.percentile(db, 5)), 1), "wps": round(nwords / max(span, 0.1), 2), "f0": round(f0),
                "f0_dev": round(f0 / af - 1, 3) if af else 0.0, "mfcc": round(float(np.linalg.norm(timbre(x) - at)), 1),
                "wer": round(min(wer(norm(ref[key]), norm(hyp)), wer(norm(speech[key]), norm(hyp))), 3), "hyp": hyp,
                "hyp_free": hyp_free, "hyp_turbo": hyp_turbo, "names_ok": ok1 and ok2,
                "names_missing": sorted(set(mis1) | set(mis2))}, ensure_ascii=False) + "\n")
            fh.flush()
            print("measured", p.name, flush=True)


if __name__ == "__main__":
    main()
