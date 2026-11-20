"""Loanword check, Dutch locale ('websajt' came out as 'websat')."""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "vo"))
from loanwords import uncovered, bad_spelling

L = lambda i, t, s=None: {"id": i, "text": t, "speech": s if s is not None else t}
u = lambda lines: uncovered(lines, "nl")
assert u([L("01", "Kijk op onze website.")]) == []                          # in pronunciation.json
assert u([L("01", "Lees het op LinkedIn.")]) == [("01", "linkedin")]        # brand without a pronunciation
assert u([L("01", "Lees het op LinkedIn.", "Lees het op Linkt-in.")]) == []   # own spelling in speech
assert u([L("01", "Claude leest mee.", "Kload leest mee.")]) == []
assert u([L("01", "Plan een meeting.")]) == [("01", "meeting")]
assert u([L("01", "Geen leenwoord hier, alleen een route.")]) == []
assert u([L("01", "Een follow-up per mail.")]) == [("01", "follow-up")]    # mail is listed, follow-up isn't
assert bad_spelling("nl") == [], bad_spelling("nl")                          # no 'aj' before a consonant
assert uncovered([L("01", "Plan a meeting.")], "en") == []                   # no English list: passes
print("loanwords: 9 PASS")
