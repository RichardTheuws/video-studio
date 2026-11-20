#!/usr/bin/env python3
"""Loanword check before recording: every loanword or brand name from reference/lang/<lang>/loanwords.json that appears in
the intended text must be covered — either in reference/lang/<lang>/pronunciation.json, or replaced in that line's speech
text by a spelling of your own. Otherwise the voice says it the way it is written (or the way it guesses), and the voice
gate doesn't notice: whisper writes the word correctly anyway. Measured on a Dutch voice: "websajt" came out as "websat".

  VO_LANG=nl loanwords.py <workdir|lines.json>      exit 0 = covered, 1 = words without a pronunciation (listed on stdout)
Also: no spelling in pronunciation.json with 'aj' before a consonant (Dutch: 'aj' there is heard as 'a'; write 'ai').
A language without a loanword list passes."""
from __future__ import annotations
import json, os, pathlib, re, sys

REF = pathlib.Path(__file__).resolve().parents[2] / "reference" / "lang"


def lists(lang: str | None = None):
    d = REF / (lang or os.environ.get("VO_LANG", "en"))
    lw = {w.lower() for w in json.loads((d / "loanwords.json").read_text())["words"]} if (d / "loanwords.json").exists() else set()
    u = json.loads((d / "pronunciation.json").read_text()) if (d / "pronunciation.json").exists() else {}
    return lw, {k.lower(): v for k, v in u.get("words", {}).items()}, {k.lower() for k in u.get("suffixes", {})}


def tokens(t: str) -> list[str]:
    return [w.lower() for w in re.findall(r"[A-Za-zÀ-ÿ][\wÀ-ÿ'-]*", t or "")]


def uncovered(lines: list[dict], lang: str | None = None) -> list[tuple[str, str]]:
    lw, pron, tails = lists(lang)
    missing = []
    for l in lines:
        speech = set(tokens(l.get("speech", "")))
        for w in dict.fromkeys(tokens(l["text"])):
            parts = [w] + [p for p in w.split("-") if p != w]
            for d in parts:
                if d not in lw or d in pron or any(d.endswith(s) for s in tails):
                    continue
                if d not in speech:      # this line speaks the word in a spelling of its own
                    continue
                missing.append((l["id"], d))
    return missing


def bad_spelling(lang: str | None = None) -> list[tuple[str, str]]:
    lang = lang or os.environ.get("VO_LANG", "en")
    if lang != "nl":
        return []
    _, pron, _ = lists(lang)
    return [(k, v) for k, v in pron.items() if re.search(r"aj(?=[bcdfghjklmnpqrstvwxz])", v)]


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__); return 2
    p = pathlib.Path(sys.argv[1]); p = p / "lines.json" if p.is_dir() else p
    missing, bad = uncovered(json.loads(p.read_text())), bad_spelling()
    for i, w in missing:
        print(f"  FAIL  line {i}: '{w}' is a loanword without a pronunciation (add it to pronunciation.json or spell it in 'speech')")
    for k, v in bad:
        print(f"  FAIL  pronunciation.json: {k} → {v} ('aj' before a consonant is heard as 'a'; write 'ai')")
    print("LOANWORDS:", "PASS" if not (missing or bad) else "FAIL")
    return 1 if (missing or bad) else 0


if __name__ == "__main__":
    sys.exit(main())
