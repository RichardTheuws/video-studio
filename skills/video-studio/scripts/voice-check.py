#!/usr/bin/env python3
"""voice-check.py — the voice gate. Origin: an automated run picked a voice by itself (a multilingual TTS model with an
English-speaking stock voice for a Dutch script); the result sounded "heavily put-on, with an English accent", and whisper
heard a studio's house number one digit off.

  <VS_VO_PY> -I voice-check.py <vo.json | dir with vo*.json> [--lang en] [--voices voices.json] [--master <mp4>]...

  1. list      the voice is listed in reference/voices.json for the language: engine matches AND the reference audio is
               byte-identical (sha256). No manifest or no reference = FAIL. This is the real accent gate: language ID does
               NOT hear an accent. Real (human, consenting) voice instead of AI: a manifest with engine "real" and a voice_id
               from `real_voices`; PASS only when the manifest sits in a folder listed in that entry's `only_for`.
  2. language  whisper language ID per clip: probability of the language ≥ 0.90 (catches a wrong language or babble, not an accent)
  3. words     word error rate (WER) against the speech text ≤ 0.20 per clip and ≤ 0.10 on average (numbers normalised)
  4. numbers   every number from the script is heard exactly like that (47 ≠ 48: a brand name or digit that sounds wrong is
               a fault even when the WER is low)
  6. clean     per clip: no unvoiced tail after the sentence (TTS noise, breath, thud), no hard edge (click), dynamics not
               > 6 dB below the raw take (pumping normalisation), 48 kHz (scripts/vo/clean.py)
  5. metadata  (per --master) the comment names the AI voice ("voice"/"stem") and the `metadata_core` from voices.json
               (e.g. the reference voice's name): EU AI Act art. 50 covers synthetic audio too.
Thresholds measured with large-v3-turbo on Dutch: a stock-voice multilingual TTS scored nl 0.976–0.998 despite a heavy
accent, a cloned Chatterbox voice 0.994–0.999. Exit 0 PASS · 1 FAIL · 2 usage error.
Manifest shapes: (a) vo.json {engine, anchor, voice_id?, lines:[{file, text, speech?, take?}]} (scripts/vo/pick.py);
(b) a folder with vo<N>.json + vo<N>.mp3 per clip ({text, model_id, voice_id?}, ElevenLabs shape).
"""
import subprocess
import difflib, glob, hashlib, json, os, re, sys, unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "vo"))
from lang import parse_number, DOT  # noqa: E402

WHISPER = "mlx-community/whisper-large-v3-turbo"
MIN_LANG, MAX_WER_CLIP, MAX_WER_AVG = 0.90, 0.20, 0.10


def tokens(s, lang="en"):
    s = unicodedata.normalize("NFKC", s.lower()).replace("’", "'")
    # English keeps hyphens long enough to read "thirty-six"; other words are split on them again below
    raw = re.findall(r"[0-9]+[a-z]?|[a-zà-ÿ']+" + ("(?:-[a-zà-ÿ']+)*" if lang == "en" else ""), s)
    out = []
    for w in raw:
        g = parse_number(w, lang) if not re.match(r"[0-9]", w) else None
        prev = out[-1] if out and isinstance(out[-1], int) else None
        if g is not None and prev is not None and g in (100, 1000) and prev < g:
            out[-1] = prev * g                       # "two hundred" → 200
        elif g is not None and prev is not None and prev >= 100 and prev % 100 == 0 and g < prev % 1000 + 1000:
            out[-1] += g                             # "tweeduizend zevenentwintig" / "two thousand twenty" → 2027 / 2020
        elif g is not None and prev is not None and lang == "en" and prev % 10 == 0 and prev % 100 >= 20 and g < 10:
            out[-1] += g                             # "thirty six" → 36
        elif g is not None:
            out.append(g)
        elif re.fullmatch(r"[0-9]+[a-z]?", w):
            m = re.match(r"([0-9]+)([a-z]?)", w)
            out.append(int(m.group(1)))
            if m.group(2):
                out.append(m.group(2))
        else:
            out.extend(p for p in w.split("-") if p)
    # "47" + "b" (from "forty-seven b" or "47b") → one brand token
    res = []
    for t in out:
        if isinstance(t, str) and len(t) == 1 and res and isinstance(res[-1], int):
            res[-1] = f"{res[-1]}{t}"
        else:
            res.append(t)
    return [str(t) for t in res]


def same(a, b):
    """Same word as whisper spells it: exact, or (words only, not numbers) nearly equal. Whisper spells brand names its own
    way while the voice says them right; numbers stay exact (47b ≠ 48b), the number check catches those too."""
    if a == b:
        return True
    if re.search(r"[0-9]", a + b) or min(len(a), len(b)) < 4:
        return False
    return difflib.SequenceMatcher(None, a, b).ratio() >= 0.8


def wer(ref, hyp, lang="en"):
    dot = DOT.get(lang, "dot")                      # the spoken "." of a domain
    r, h = [t for t in tokens(ref, lang) if t != dot], [t for t in tokens(hyp, lang) if t != dot]
    d = list(range(len(h) + 1))
    for i in range(1, len(r) + 1):
        prev, d[0] = d[0], i
        for j in range(1, len(h) + 1):
            cur = min(d[j] + 1, d[j - 1] + 1, prev + (not same(r[i - 1], h[j - 1])))
            prev, d[j] = d[j], cur
    return d[len(h)] / max(len(r), 1)


def numbers(s, lang="en"):
    return [t for t in tokens(s, lang) if re.match(r"^[0-9]", t)]


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def read(path):
    """→ (engine, anchor_path|None, voice_id|None, [(audio, speech text, text)])"""
    if os.path.isdir(path) and os.path.isfile(os.path.join(path, "vo.json")):
        path = os.path.join(path, "vo.json")
    if os.path.isfile(path):
        d = json.load(open(path)); base = os.path.dirname(path)
        clips = [(os.path.join(base, r["file"]), r.get("speech") or r["text"], r.get("text") or r.get("speech"))
                 for r in d.get("lines", [])]
        anchor = d.get("anchor")
        if anchor and not os.path.isabs(anchor):     # relative to the manifest, a folder above it, or the skill
            cand = [os.path.normpath(os.path.join(base, *[".."] * k, anchor)) for k in range(4)]
            cand.append(os.path.normpath(os.path.join(HERE, "..", anchor)))
            anchor = next((c for c in cand if os.path.isfile(c)), cand[0])
        return d.get("engine", ""), anchor, d.get("voice_id"), clips
    clips, engine, voice = [], "", None
    for j in sorted(glob.glob(os.path.join(path, "vo*.json")), key=lambda x: int(re.sub(r"\D", "", os.path.basename(x)) or 0)):
        d = json.load(open(j)); a = None
        for ext in (".mp3", ".wav", ".m4a"):
            if os.path.isfile(j[:-5] + ext):
                a = j[:-5] + ext; break
        engine = engine or ("elevenlabs " + d.get("model_id", "")).strip()
        voice = voice or d.get("voice_id")
        clips.append((a, d.get("text", ""), d.get("text", "")))
    return engine, None, voice, clips


def list_match(data, lang, engine, anchor, voice_id, path):
    """→ (voice entry|None, reason). AI voice: engine + reference sha (or voice_id) in data[lang]. Real voice (engine 'real'):
    voice_id in data['real_voices'] for this language AND the manifest sits in a folder from `only_for`."""
    if re.match(r"(?i)^real", engine or ""):
        p = os.path.realpath(path).replace(os.sep, "/")
        for s in data.get("real_voices", []):
            if s.get("id") != voice_id or s.get("lang", lang) != lang:
                continue
            if any(f"/{m.strip('/')}/" in p + "/" for m in s.get("only_for", [])):
                return s, f"real voice, exception: {s.get('source', '')[:60]}"
            return None, f"real voice {voice_id} is only allowed in {', '.join(s.get('only_for', []))}, not in {path}"
        return None, f"real voice {voice_id or 'without voice_id'} is not in voices.json[real_voices]"
    allowed = data.get(lang, [])
    if anchor and os.path.isfile(anchor):
        h = sha(anchor)
        match = next((s for s in allowed if s.get("anchor_sha256") == h and re.search(s.get("engine_match", "$^"), engine)), None)
        return match, f"engine {engine[:50]!r}, reference {os.path.basename(anchor)} sha {h[:12]}"
    why = f"engine {engine[:50]!r}, voice id {voice_id or 'unknown'}, reference {'missing' if not anchor else 'not found: ' + anchor}"
    match = next((s for s in allowed if voice_id and s.get("voice_id") == voice_id and re.search(s.get("engine_match", "$^"), engine)), None)
    return match, why


def metadata_comment(mp):
    try:
        out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format_tags=comment", "-of", "default=nw=1:nk=1", mp],
                             capture_output=True, text=True, timeout=30)
        return out.stdout.strip() if out.returncode == 0 else None
    except Exception:
        return None


def main(argv):
    if not argv or argv[0].startswith("-"):
        print(__doc__); return 2
    path, lang, vlist = argv[0], os.environ.get("VO_LANG", "en"), os.path.join(HERE, "..", "reference", "voices.json")
    masters, check_clean = [], True
    i = 1
    while i < len(argv):
        if argv[i] == "--lang": lang = argv[i + 1]; i += 2
        elif argv[i] == "--voices": vlist = argv[i + 1]; i += 2
        elif argv[i] == "--master": masters.append(argv[i + 1]); i += 2
        elif argv[i] == "--no-clean": check_clean = False; i += 1     # only for old manifests in a regression test
        else: print(__doc__); return 2
    if not os.path.exists(path):
        print(f"ERROR: {path} does not exist", file=sys.stderr); return 2
    engine, anchor, voice_id, clips = read(path)
    fails = []
    print(f"── voice-check ({lang}): {path}")
    # 1. list
    match, why = list_match(json.load(open(vlist)), lang, engine, anchor, voice_id, path)
    if match:
        print(f"  PASS  list       {match['id']} ({why})")
    else:
        fails.append("list"); print(f"  FAIL  list       voice not in voices.json[{lang}] — {why}")
    if not clips or any(not a or not os.path.isfile(a) for a, _, _ in clips):
        fails.append("clips"); print("  FAIL  clips      no or missing audio clips in the manifest")
        print("──\nVOICE: FAIL"); return 1
    # 2–4. whisper
    try:
        import mlx_whisper
        from mlx_whisper import audio as A, decoding as D, load_models as L, tokenizer as T
    except Exception as e:
        print(f"  FAIL  whisper    mlx-whisper not available ({e}) — run with the VO venv (VS_VO_PY)"); return 1
    m = L.load_model(WHISPER)
    tok = T.get_tokenizer(m.is_multilingual, num_languages=m.num_languages, language=None, task="transcribe")
    wers = []
    from clean import judge as judge_clean
    takes = {}
    man = path if not os.path.isdir(path) else os.path.join(path, "vo.json")
    if os.path.isfile(man) and man.endswith(".json"):
        md = json.load(open(man)); base = os.path.dirname(man)
        for rg in md.get("lines", []):
            t = os.path.join(base, "takes", rg.get("take", "")) if rg.get("take") else None
            takes[os.path.join(base, rg["file"])] = t if t and os.path.isfile(t) else None
    for a, speech, text in clips:
        mel = A.log_mel_spectrogram(A.pad_or_trim(A.load_audio(a)), n_mels=m.dims.n_mels)
        _, probs = D.detect_language(m, mel[None], tok)
        p = probs[0].get(lang, 0.0)
        hyp = mlx_whisper.transcribe(a, path_or_hf_repo=WHISPER, language=lang, temperature=0.0)["text"].strip()
        w = min(wer(speech, hyp, lang), wer(text, hyp, lang))
        wers.append(w)
        want, got = numbers(text, lang), numbers(hyp, lang)
        miss = [g for g in want if g not in got]
        r = []
        if p < MIN_LANG: r.append(f"language {lang} {p:.3f} < {MIN_LANG}")
        if w > MAX_WER_CLIP: r.append(f"WER {w:.2f} > {MAX_WER_CLIP}")
        if miss: r.append(f"number/brand heard as {got} instead of {want}")
        if check_clean:
            r += judge_clean(a, takes.get(a))
        name = os.path.basename(a)
        if r:
            fails.append(name); print(f"  FAIL  {name:<10} {'; '.join(r)} — heard: {hyp[:70]!r}")
        else:
            print(f"  PASS  {name:<10} language {p:.3f} · WER {w:.2f}{' · numbers ' + ','.join(want) if want else ''}")
    avg = sum(wers) / len(wers)
    if avg > MAX_WER_AVG:
        fails.append("wer-avg"); print(f"  FAIL  average    WER {avg:.2f} > {MAX_WER_AVG}")
    else:
        print(f"  PASS  average    WER {avg:.2f}")
    # 5. metadata: the AI voice is named in the comment of every master, with the core of the credit
    core = match.get("metadata_core") if match else None
    for mp in masters:
        cm = metadata_comment(mp)
        if cm is None:
            fails.append("metadata"); print(f"  FAIL  metadata   {os.path.basename(mp)}: unreadable"); continue
        missing = [w for w, ok in (("voice", re.search(r"(?i)\b(voice|stem)\b", cm)), (core, core and core.lower() in cm.lower())) if w and not ok]
        if missing:
            fails.append("metadata")
            print(f"  FAIL  metadata   {os.path.basename(mp)}: comment doesn't name {' and '.join(missing)} — {cm[:80]!r}"
                  f" → -metadata comment=\"AI-generated imagery and voice — <brand> ({match.get('credit') if match else 'credit'}), EU AI Act art. 50\"")
        else:
            print(f"  PASS  metadata   {os.path.basename(mp)}: {cm[:70]}")
    print("──")
    print("VOICE: PASS" if not fails else f"VOICE: FAIL ({', '.join(fails[:6])})")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
