#!/usr/bin/env python3
"""Per-language helpers for the voice-over chain and the voice gate: number words (both directions), the spoken word for
"." in a domain and for "%", and the forms of address the story gate checks. Two locales are worked out: `nl` (the one
the chain was built and measured on) and `en`. Add a language by adding an entry to each table below; everything else
in scripts/vo and scripts/voice-check.py reads from here.

The pronunciation list and the loanword list live next to it as data, per language:
reference/lang/<lang>/pronunciation.json and reference/lang/<lang>/loanwords.json (both optional)."""
from __future__ import annotations
import re

# ── number words ───────────────────────────────────────────────────────────────
_NL_ONES = "nul een twee drie vier vijf zes zeven acht negen tien elf twaalf dertien veertien vijftien zestien zeventien achttien negentien".split()
_NL_TENS = {2: "twintig", 3: "dertig", 4: "veertig", 5: "vijftig", 6: "zestig", 7: "zeventig", 8: "tachtig", 9: "negentig"}
_EN_ONES = ("zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen "
            "eighteen nineteen").split()
_EN_TENS = {2: "twenty", 3: "thirty", 4: "forty", 5: "fifty", 6: "sixty", 7: "seventy", 8: "eighty", 9: "ninety"}


def _nl_words(n: int) -> str:
    if n < 20: return _NL_ONES[n]
    if n < 100:
        t, e = divmod(n, 10)
        return _NL_TENS[t] if e == 0 else _NL_ONES[e] + ("en" if _NL_ONES[e][-1] != "e" else "ën") + _NL_TENS[t]
    if n < 1000:
        h, r = divmod(n, 100); return ("honderd" if h == 1 else _NL_ONES[h] + "honderd") + (_nl_words(r) if r else "")
    return str(n)


def _en_words(n: int) -> str:
    if n < 20: return _EN_ONES[n]
    if n < 100:
        t, e = divmod(n, 10); return _EN_TENS[t] + ("" if e == 0 else " " + _EN_ONES[e])
    if n < 1000:
        h, r = divmod(n, 100); return _EN_ONES[h] + " hundred" + (" " + _en_words(r) if r else "")
    return str(n)


def number_words(n: int, lang: str) -> str:
    """12 → 'twaalf' / 'twelve'. Unknown language: the digits stay."""
    return {"nl": _nl_words, "en": _en_words}.get(lang, str)(n)


# words → number (voice gate: "zesendertig" → 36). "een"/"one" is almost always the article, so it is not a number.
_NL_UNITS = {"nul": 0, "één": 1, "twee": 2, "drie": 3, "vier": 4, "vijf": 5, "zes": 6, "zeven": 7, "acht": 8, "negen": 9,
             "tien": 10, "elf": 11, "twaalf": 12, "dertien": 13, "veertien": 14, "vijftien": 15, "zestien": 16,
             "zeventien": 17, "achttien": 18, "negentien": 19}
_NL_TENS_W = {v: k * 10 for k, v in _NL_TENS.items()}
_EN_UNITS = {w: i for i, w in enumerate(_EN_ONES) if w != "one"}
_EN_TENS_W = {v: k * 10 for k, v in _EN_TENS.items()}


def _nl_parse(w: str):
    """'zesendertig' → 36, 'tweeduizend' → 2000, 'honderdtwaalf' → 112; otherwise None."""
    w = w.replace("ë", "e")
    if not w or not re.fullmatch(r"[a-z]+", w):
        return None
    for mult, val in (("duizend", 1000), ("honderd", 100)):
        if mult in w:
            before, _, after = w.partition(mult)
            v = 1 if not before else _nl_parse(before)
            n = 0 if not after else _nl_parse(after)
            return None if v is None or n is None else v * val + n
    if w in _NL_UNITS: return _NL_UNITS[w]
    if w in _NL_TENS_W: return _NL_TENS_W[w]
    for t, tv in _NL_TENS_W.items():
        if w.endswith(t):
            head = w[: -len(t)]
            head = head[:-2] if head.endswith("en") else head[:-3] if head.endswith("ën") else None
            if head and head in _NL_UNITS and _NL_UNITS[head] < 10:
                return tv + _NL_UNITS[head]
    return None


def _en_parse(w: str):
    """English writes numbers as separate words ('thirty six'); one token at a time: 'thirty' → 30, 'six' → 6,
    'thirty-six' → 36, 'hundred' → 100, 'thousand' → 1000. The tokenizer adds them up."""
    if w in _EN_UNITS: return _EN_UNITS[w]
    if w in _EN_TENS_W: return _EN_TENS_W[w]
    if w in ("hundred", "thousand"): return {"hundred": 100, "thousand": 1000}[w]
    m = re.fullmatch(r"([a-z]+)-([a-z]+)", w)
    if m and m.group(1) in _EN_TENS_W and m.group(2) in _EN_UNITS and _EN_UNITS[m.group(2)] < 10:
        return _EN_TENS_W[m.group(1)] + _EN_UNITS[m.group(2)]
    return None


def parse_number(w: str, lang: str):
    return {"nl": _nl_parse, "en": _en_parse}.get(lang, lambda _w: None)(w)


# ── spoken symbols ─────────────────────────────────────────────────────────────
DOT = {"nl": "punt", "en": "dot"}            # example.com → "example punt com" / "example dot com"
PERCENT = {"nl": "procent", "en": "percent"}
SLASH = {"nl": "slash", "en": "slash"}

# ── forms of address (story gate D1: never mix them) ───────────────────────────
# English "you" has no informal/formal/plural split, so the check is a no-op there.
ADDRESS = {
    "nl": {"jij": {"jij", "je", "jou", "jouw", "jezelf"}, "jullie": {"jullie"}, "u": {"u", "uw", "uzelf"}},
    "en": {},
}
