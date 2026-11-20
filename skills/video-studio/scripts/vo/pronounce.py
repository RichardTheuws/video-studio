#!/usr/bin/env python3
"""Apply the pronunciation list to a speech text (reference/lang/<lang>/pronunciation.json). Whole words, case-insensitive;
suffixes (compound words) first. A language without a list returns the text unchanged.

  VO_LANG=nl pronounce.py "Kijk op onze site, of app ons."   →  Kijk op onze saait, of ep ons.
"""
from __future__ import annotations
import json, os, pathlib, re, sys

_REF = pathlib.Path(__file__).resolve().parents[2] / "reference" / "lang"


def _path(lang: str | None = None) -> pathlib.Path:
    return _REF / (lang or os.environ.get("VO_LANG", "en")) / "pronunciation.json"


def _load(lang: str | None = None) -> dict:
    p = _path(lang)
    return json.loads(p.read_text()) if p.exists() else {}


def words(lang: str | None = None) -> dict:
    return {k.lower(): v for k, v in _load(lang).get("words", {}).items() if k != v}


def suffixes(lang: str | None = None) -> dict:
    return {k.lower(): v for k, v in _load(lang).get("suffixes", {}).items()}


def apply(text: str, table: dict | None = None, tails: dict | None = None, lang: str | None = None) -> str:
    table = words(lang) if table is None else table
    tails = suffixes(lang) if tails is None else tails
    if tails:  # compounds: "watertank" -> "watertenk", "water-tank" -> "water-tenk"
        sp = re.compile(r"(?<=\w)(-?)(" + "|".join(re.escape(k) for k in sorted(tails, key=len, reverse=True)) + r")(?![\w-])",
                        re.IGNORECASE)
        text = sp.sub(lambda m: m.group(1) + tails[m.group(2).lower()], text)
    if not table:
        return text
    pattern = re.compile(r"(?<![\w-])(" + "|".join(re.escape(k) for k in sorted(table, key=len, reverse=True)) + r")(?![\w-])",
                         re.IGNORECASE)
    return pattern.sub(lambda m: table[m.group(1).lower()], text)


if __name__ == "__main__":
    print(apply(" ".join(sys.argv[1:])))
