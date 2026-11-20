"""Name check: with the vocab hint whisper writes the brand name even when the voice drops a sound."""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "vo"))
from names import names_ok, names_in

V = "Ravelo, Ravelotank, ravelo.nl, Rav, reuzenpan"       # a fictional brand
assert names_in("Drie tips voor je Ravelo reuzenpan.", V) == ["ravelo", "reuzenpan"]
assert names_ok("Drie tips voor je Ravelo reuzenpan.", "Drie tips voor je Ravelo reuzenpan.", V,
                "Drie tips voor je Havelo heuzenpan.") == (False, ["ravelo", "reuzenpan"])
assert names_ok("Drie tips voor je Ravelo reuzenpan.", "Drie tips voor je Raveelo reuzenpan.", V,
                "Drie tips voor je Raveelo reuzenpan.") == (True, [])            # phonetic spelling counts
assert names_ok("Kijk op ravelo.nl of app Rav.", "Kijk op ravelo punt en el of ep Rav.", V,
                "Kijk op ravelo.nl of app Rav.")[0] is True
assert names_ok("Kijk op ravelo.nl of app Rav.", "Kijk op ravelo punt en el of ep Rav.", V,
                "Kijk op havelo.nl of app Hav.")[0] is False
assert names_ok("Geen namen hier.", "Geen namen hier.", V, "Geen name hier.") == (True, [])
assert names_ok("Eigen ontwerp van Ravelo.", "Eigen ontwerp van Raveelo.", V, "Eigen ontwerp van Havelo.")[0] is False
assert names_ok("Eigen ontwerp van Ravelo.", "Eigen ontwerp van Raveelo.", V, "Eigen ontwerp van Raveelo.")[0] is True
# a split compound and a sound-alike spelling count as heard, another name doesn't
R = "Ravenkaart Claude Anthropic"
assert names_ok("Ravenkaart laat het zien.", "Raavenkaart laat het zien.", R, "Raven Kaart laat het zien.")[0] is True
assert names_ok("Claude, een AI van Anthropic.", "Kload, een ee-aai van Antroppik.", R, "Claude, een AI van Antropic.")[0] is True
assert names_ok("Claude, een AI van Anthropic.", "Kload, een ee-aai van Antroppik.", R, "Kloot, een AI van Intopic.") == (False, ["claude", "anthropic"])
assert names_ok("Ravenkaart laat het zien.", "Raavenkaart laat het zien.", R, "Kravenkaart laat het zien.")[0] is False
# measure.py: WER counts a split compound as one word, but not a stray error
import importlib.util
sp = importlib.util.spec_from_file_location("measure", pathlib.Path(__file__).resolve().parents[1] / "vo" / "measure.py")
m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
assert m.wer("met wie ze verdergaat", "met wie ze verder gaat") == 0.0
assert m.wer("a b c", "a bc") > 0
assert m.norm("9 van de 96, op example.nl", "nl") == "negen van de zesennegentig op example punt nl"
assert m.norm("9 of the 96, on example.com", "en") == "nine of the ninety six on example dot com"
print("names: 16 PASS")
