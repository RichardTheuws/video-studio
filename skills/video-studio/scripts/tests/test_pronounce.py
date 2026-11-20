"""Pronunciation list, Dutch locale (reference/lang/nl/pronunciation.json): 'Cube' and 'site' came out as Dutch words."""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "vo"))
from pronounce import apply

nl = lambda t: apply(t, lang="nl")
assert nl("Maak kennis met de Cube.") == "Maak kennis met de kjoeb."
assert nl("Kijk op onze site, of app ons.") == "Kijk op onze saait, of ep ons."
assert nl("Kijk op example.nl of WhatsApp ons.") == "Kijk op example.nl of wotsep ons."
assert nl("Een website en een webshop.") == "Een websait en een websjop."
assert nl("Cubes en parasite blijven.") == "Cubes en parasite blijven."      # whole words only
assert nl("e-mail of mail") == "iemeel of meel"
assert nl("geen Engels hier") == "geen Engels hier"
assert nl("Een grote gaspan op een stevig frame.") == "Een grote gaspan op een stevig freem."
assert nl("Zo werkt de watertank.") == "Zo werkt de watertenk."               # suffix in a compound
assert nl("De water-tank werkt op rvs.") == "De water-tenk werkt op rvs."
assert nl("De tank weekt het vet los.") == "De tenk weekt het vet los."
assert nl("Even tanken bij de pomp.") == "Even tanken bij de pomp."           # 'tanken' stays
assert apply("Visit our website.", lang="en") == "Visit our website."          # no English list: unchanged
print("pronounce: 13 PASS")
