"""voice-check.py without whisper: the list (AI voice by reference sha, real-voice exception scoped to folders) and the
number tokens per language. Self-contained: the voice list here is an in-memory example, not reference/voices.json."""
import hashlib, importlib.util, json, pathlib, tempfile
H = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("voicecheck", H / "voice-check.py"); vc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vc)
n = 0
def ok(c):
    global n
    assert c; n += 1

with tempfile.TemporaryDirectory() as d:
    ref = pathlib.Path(d) / "anchor.wav"; ref.write_bytes(b"RIFF-not-really-audio")
    other = pathlib.Path(d) / "other.wav"; other.write_bytes(b"another reference")
    sha = hashlib.sha256(ref.read_bytes()).hexdigest()
    D = {"en": [{"id": "house-a", "engine_match": "(?i)chatterbox", "anchor_sha256": sha, "metadata_core": "RefVoice"}],
         "nl": [],
         "real_voices": [{"id": "speaker-a", "lang": "en", "engine_match": "(?i)^real", "only_for": ["productions/campaign-a"],
                          "source": "consent for campaign A only", "metadata_core": "real recording"}]}
    m, _ = vc.list_match(D, "en", "Chatterbox multilingual (MIT)", str(ref), None, "/x/vo.json"); ok(m and m["id"] == "house-a")
    m, _ = vc.list_match(D, "en", "Chatterbox multilingual (MIT)", str(other), None, "/x/vo.json"); ok(m is None)   # other reference
    m, _ = vc.list_match(D, "en", "elevenlabs eleven_multilingual_v2", str(ref), None, "/x/vo.json"); ok(m is None)  # other engine
    m, _ = vc.list_match(D, "nl", "Chatterbox", str(ref), None, "/x/vo.json"); ok(m is None)                       # not approved for nl
    m, why = vc.list_match(D, "en", "Chatterbox", None, None, "/x/vo.json"); ok(m is None and "missing" in why)     # no reference
    A = "/x/studio/productions/campaign-a/audio/vo.json"
    m, _ = vc.list_match(D, "en", "real", None, "speaker-a", A); ok(m and m["id"] == "speaker-a")                 # allowed there
    m, why = vc.list_match(D, "en", "real", None, "speaker-a", "/x/studio/productions/campaign-b/vo.json"); ok(m is None and "only allowed" in why)
    m, _ = vc.list_match(D, "en", "real", None, "speaker-a", "/x/studio/productions/campaign-a-copy/vo.json"); ok(m is None)  # no prefix leak
    m, _ = vc.list_match(D, "en", "real", None, "someone-else", A); ok(m is None)
    m, _ = vc.list_match(D, "nl", "real", None, "speaker-a", A); ok(m is None)                                     # only in its language
    m, _ = vc.list_match(D, "en", "elevenlabs eleven_multilingual_v2", None, "speaker-a", A); ok(m is None)        # an AI engine is not 'real'
# the shipped list is empty on purpose (no voice ships with the skill)
V = json.load(open(H.parent / "reference" / "voices.json")); ok(V["en"] == [] and V["nl"] == [] and V["real_voices"] == [])
# numbers per language: a wrong digit is a fault even at low WER
ok(vc.numbers("Kamer 47b op de kaart", "nl") == ["47b"])
ok(vc.numbers("kamer zevenenveertig b op de kaart", "nl") == ["47b"])
ok(vc.numbers("in tweeduizend zevenentwintig", "nl") == ["2027"])
ok(vc.numbers("nine of the ninety-six answers", "en") == ["9", "96"])
ok(vc.numbers("nine of the ninety six answers", "en") == ["9", "96"])
ok(vc.numbers("two hundred twelve", "en") == ["212"])
ok(vc.wer("Visit example.com today", "visit example dot com today", "en") == 0.0)
ok(vc.wer("Kijk op example.nl", "kijk op example punt nl", "nl") == 0.0)
print(f"voice-check: {n} PASS")
