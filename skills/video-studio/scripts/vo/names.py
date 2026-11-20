#!/usr/bin/env python3
"""Name check for a take: the brand and product names from vocab.txt must be heard in a transcription WITHOUT the vocab
hint. With the hint, whisper writes the brand name even when the voice drops a sound (measured: a brand starting with R
came out as "H…" four times across one client's videos, and the gate never saw it). A phonetic spelling taken from the
speech text counts as heard too."""
from __future__ import annotations
import re, unicodedata


def norm(w: str) -> str:
    return re.sub(r"[^a-z0-9]", "", unicodedata.normalize("NFKD", w.lower()).encode("ascii", "ignore").decode())


def sound(w: str) -> str:
    """Sound-alike form of a (brand) name as Dutch/English ears write it: th→t, ph→f, ck/c→k, qu→kw, double consonants single."""
    w = w.replace("th", "t").replace("ph", "f").replace("ck", "k").replace("qu", "kw").replace("c", "k")
    return re.sub(r"([b-df-hj-np-tv-z])\1", r"\1", w)


def words(t: str) -> list[str]:
    return [n for n in (norm(x) for x in re.split(r"[\s,;:!?()\"„“”]+", t or "")) if n]


def names_in(text: str, vocab: str) -> list[str]:
    """The vocab names (≥ 3 characters) that occur in this line."""
    v = {n for n in words(vocab) if len(n) >= 3}
    return [n for n in dict.fromkeys(words(text)) if n in v]


def names_ok(text: str, speech: str, vocab: str, hyp_free: str) -> tuple[bool, list[str]]:
    """(all heard?, missing names). Allowed per name: the name itself, or a word from the speech text that is not in the
    subtitle (the phonetic spelling)."""
    # Sound-alike counts as heard: "Antropic" is how a Dutch ear writes a correctly spoken "Anthropic".
    # Compounds: whisper sometimes splits one name into two words ("Raven Kaart"); two neighbours together count too.
    ww = words(hyp_free)
    heard = set(ww) | {a + b for a, b in zip(ww, ww[1:])}; heard |= {sound(g) for g in heard}
    phonetic = set(words(speech)) - set(words(text))
    # A phonetic spelling only counts for the name it resembles (same first two letters), not for every name in the line.
    missing = [n for n in names_in(text, vocab)
               if n not in heard and sound(n) not in heard and not any(f in heard and f[:2] == n[:2] for f in phonetic)]
    return (not missing, missing)
