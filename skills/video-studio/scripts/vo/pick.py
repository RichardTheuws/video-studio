#!/usr/bin/env python3
"""Pick the best take per line (reference/extended.md §3): gate = WER 0 with the vocab, every brand name also heard without
the vocab hint, tail < 0.6 s, f0 within ±15% of the reference voice; within that, the lowest MFCC distance. Cuts on the
voice bounds (pyin), removes clicks, normalises linearly (−16 LUFS, two passes), and writes word times (mlx-whisper turbo,
TIMES only; the text comes from lines.json) to <workdir>/vo.json.

  pick.py <workdir> [03=03-s1.wav ...] [--anyway]      run with the VO venv (VS_VO_PY)
Writes <workdir>/vo/<id>.wav and <workdir>/vo.json. Exit 3 if a line fails the gate (then: gen.py --seeds 6 and measure
again), unless --anyway (the best take goes in and gate: FAIL is recorded in vo.json). `03=03-s1.wav` pins an approved take.
Commit vo.json after approval and compare after every run: new takes in measure.jsonl can silently change a pick."""
import json, os, pathlib, re, subprocess, sys, unicodedata
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from clean import voice_bounds  # noqa: E402  (same source as the check in voice-check.py)

LANG = os.environ.get("VO_LANG", "en")
ENGINE = os.environ.get("VO_ENGINE", "Chatterbox multilingual (MIT), zero-shot clone")
norm = lambda w: re.sub(r"[^a-z0-9]", "", unicodedata.normalize("NFKD", w.lower()).encode("ascii", "ignore").decode())


def clean(src, dst) -> None:
    """Take → line: cut on the voice bounds (no tail), remove clicks (adeclick), short fades, and LINEAR normalisation to
    −16 LUFS in two passes. A single-pass `loudnorm` works dynamically: on a short line it lifted the silences and the tail
    noise by up to +19 dB and wrote 192 kHz."""
    a, b = voice_bounds(src)
    pre = f"atrim={a:.3f}:{b:.3f},asetpts=PTS-STARTPTS,aresample=48000,adeclick=w=55:o=75,afade=t=in:d=0.012,afade=t=out:st={max(0, b - a - 0.08):.3f}:d=0.08"
    m = subprocess.run(["ffmpeg", "-v", "info", "-hide_banner", "-i", str(src), "-af", pre + ",loudnorm=I=-16:TP=-2:LRA=11:print_format=json",
                        "-f", "null", "-"], capture_output=True, text=True).stderr
    j = json.loads(m[m.rindex("{"):m.rindex("}") + 1])
    ln = (f"loudnorm=I=-16:TP=-2:LRA=11:linear=true:measured_I={j['input_i']}:measured_TP={j['input_tp']}:"
          f"measured_LRA={j['input_lra']}:measured_thresh={j['input_thresh']}:offset={j['target_offset']}")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-af", pre + "," + ln + ",aresample=48000", "-ac", "1",
                    "-ar", "48000", str(dst)], check=True)


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    import mlx_whisper
    w = pathlib.Path(sys.argv[1]).resolve()
    pinned = dict(a.split("=", 1) for a in sys.argv[2:] if "=" in a)
    lines = {l["id"]: l for l in json.loads((w / "lines.json").read_text())}
    meas = [json.loads(x) for x in (w / "measure.jsonl").read_text().splitlines() if x.strip()]
    out = {"anchor": os.environ.get("VO_ANCHOR", "assets/voice/anchor.wav"), "engine": ENGINE, "lines": []}
    if os.environ.get("VO_VOICE_ID"):
        out["voice_id"] = os.environ["VO_VOICE_ID"]
    (w / "vo").mkdir(exist_ok=True)
    fails = []
    for i in sorted(lines):
        c = [m for m in meas if m["key"] == i]
        if not c:
            sys.exit(f"no measured takes for line {i}")
        if i in pinned:
            c = [m for m in c if m["f"] == pinned[i]] or c
        ok = [m for m in c if m["wer"] == 0 and m["tail"] < 0.6 and abs(m["f0_dev"]) <= 0.15 and m.get("names_ok", True)]
        best = sorted(ok or c, key=lambda m: (m["wer"], m["mfcc"]))[0]
        if not ok:
            fails.append(i)
        src, dst = w / "takes" / best["f"], w / "vo" / f"{i}.wav"
        clean(src, dst)
        d = float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(dst)]))
        r = mlx_whisper.transcribe(str(dst), path_or_hf_repo="mlx-community/whisper-large-v3-turbo", language=LANG,
                                   word_timestamps=True, temperature=0.0)
        ws = [{"w": x["word"].strip(), "n": norm(x["word"]), "s": round(x["start"], 3), "e": round(x["end"], 3)}
              for s in r["segments"] for x in s.get("words", [])]
        out["lines"].append({"id": i, "file": f"vo/{i}.wav", "text": lines[i]["text"], "speech": lines[i].get("speech") or lines[i]["text"],
            "take": best["f"], "gate": "PASS" if ok else "FAIL", "wer": best["wer"], "f0_dev": best["f0_dev"],
            "duration_s": round(d, 3), "words": ws, "whisper": r["text"].strip()})
        print(i, best["f"], "PASS" if ok else "FAIL", round(d, 2), "|", r["text"].strip(), flush=True)
    (w / "vo.json").write_text(json.dumps(out, ensure_ascii=False, indent=1))
    total = sum(r["duration_s"] for r in out["lines"])
    print(f"VO total {total:.1f} s over {len(out['lines'])} lines; gate FAIL: {fails or 'none'}")
    if fails and "--anyway" not in sys.argv:
        sys.exit(3)


if __name__ == "__main__":
    main()
