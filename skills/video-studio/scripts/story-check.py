#!/usr/bin/env python3
"""story-check.py — the storyline gate. Origin: a season's greeting that a client rejected while every technical gate was
green. The copy read as a product list instead of a greeting, switched from informal "you" to plural "you", and the brief
asked for the holidays while the pictures stayed a dark studio.

Runs TWICE: at the storyboard (before the expensive generation: brief + script + keyframe prompts) and on the final result
(+ a frame strip, so the verdict on the pictures is about what is really on screen).

  python3 -I story-check.py --brief brief.md --phase storyboard|final [--titles spec.json] [--vo vo.json|dir]
                            [--script text.txt] [--prompts prompts.txt] [--frames strip.jpg] [--lang en] [--no-llm] [--json out.json]

Deterministic (always):
  D1 address     one form of address across plates + voice (Dutch: jij/je/jouw OR jullie OR u/uw, never mixed;
                 languages without that split, like English, pass)
  D2 length      voice ≤ 12 words per breath group (up to . ! ? : ; , or –); plate ≤ 8 words (one thought)
  D3 repetition  no plate twice; no content word on ≥ 3 plates
  D4 season      if the brief asks for a season (Christmas, year end, New Year, holidays, winter …), seasonal motifs appear
                 in ≥ half of the beats (keyframe prompts; in the final phase the rubric also judges the strip)
Rubric (LLM, fixed criteria, each PASS/FAIL with a reason):
  hook · line (every line follows from the previous one) · one_thought · closer (fits the goal of the brief) ·
  picture_fits (the pictures fit the brief) · voice_and_plate (they reinforce each other, don't repeat or clash)
The rubric runs a headless LLM command: env STORY_CHECK_LLM (default "claude -p"; any command that takes the prompt as its
last argument and prints the answer works). Final verdict: FAIL if one criterion fails. LLM not reachable = FAIL (never
skipped silently); --no-llm = only the deterministic half, verdict INCOMPLETE (exit 3), never PASS.
Exit 0 PASS · 1 FAIL · 2 usage error · 3 incomplete.
"""
import json, os, re, shlex, subprocess, sys, glob, shutil

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "vo"))
from lang import ADDRESS  # noqa: E402

SEASON = {
    "holidays": ["snow", "sneeuw", "snowflake", "christmas", "kerst", "fairy light", "string light", "twinkl", "bokeh",
                 "fireworks", "vuurwerk", "sparkl", "glitter", "festive", "ornament", "bauble", "garland", "candle", "kaars",
                 "winter", "frost", "pine", "fir", "dennen", "champagne", "confetti", "lichtjes", "gold leaf", "goudglans"],
}
SEASON_TRIGGER = {"holidays": ["kerst", "eindejaar", "nieuwjaar", "feestdagen", "jaarwisseling", "oud en nieuw", "winter",
                               "christmas", "xmas", "year-end", "year end", "new year", "holiday", "festive season"]}
STOP = set("""de het een en van in op te dat die is zijn met voor aan als bij om tot uit naar ook maar dan nog niet wel
of door over je jij jullie u we wij ons onze mijn ik zo wat wie hoe waar dit deze er al meer heel
the a an and of in on to that is are with for at as by from into also but then not or over you your we our my it this
these there more very what who how where""".split())


def words(s):
    return [w for w in re.findall(r"[\wÀ-ÿ'’-]+", (s or "").replace("*", "").lower()) if re.search(r"[a-zà-ÿ]", w)]


def read_titles(p):
    if not p:
        return []
    out = []
    for it in json.load(open(p)).get("items", []):
        if it.get("kind") in ("plate", "pair", "card", "figure"):
            t = " ".join(str(it.get(k)) for k in ("kicker", "head", "text", "typed", "knew", "label") if it.get(k))
            out.append((float(it.get("in", 0)), t.replace("*", "").replace("\n", " ").strip()))
    return out


def read_vo(p):
    if not p:
        return []
    if os.path.isdir(p):
        man = os.path.join(p, "vo.json")
        if os.path.isfile(man):
            p = man
        else:
            lines = []
            for f in sorted(glob.glob(os.path.join(p, "vo*.json")), key=lambda x: int(re.sub(r"\D", "", os.path.basename(x)) or 0)):
                lines.append(json.load(open(f)).get("text", ""))
            return [r for r in lines if r]
    d = json.load(open(p))
    if isinstance(d, dict) and "lines" in d:
        return [r.get("text") or r.get("speech") or "" for r in d["lines"]]
    if isinstance(d, list):
        return [x if isinstance(x, str) else (x.get("text") or "") for x in d]
    return []


def read_prompts(p):
    if not p:
        return []
    beats = []
    for ln in open(p, encoding="utf-8"):
        ln = ln.strip()
        if not ln or ln.startswith("#"):
            continue
        parts = ln.split("|")
        beats.append({"role": parts[0] if len(parts) > 2 else "", "name": parts[1] if len(parts) > 2 else "", "prompt": parts[-1]})
    return beats


def deterministic(brief, plates, voice, beats, lang="en"):
    res = {}
    allw = words(" ".join(t for _, t in plates) + " " + " ".join(voice))
    forms = ADDRESS.get(lang, {})
    groups = {g: sorted(set(allw) & ws) for g, ws in forms.items() if set(allw) & ws}
    if not forms:
        res["D1_address"] = ("PASS", f"no address split in '{lang}'")
    else:
        res["D1_address"] = ("PASS", f"one form: {list(groups) or ['none']}") if len(groups) <= 1 else \
            ("FAIL", "mixed forms of address: " + ", ".join(f"{g} ({'/'.join(w)})" for g, w in groups.items()))
    long = []
    for r in voice:
        for z in re.split(r"(?<=[.!?:;,–—])\s+", r):    # breath group: read aloud, a comma is a pause
            if len(words(z)) > 12:
                long.append(f"voice {len(words(z))} w: {z[:50]!r}")
    for _, t in plates:
        if len(words(t)) > 8:
            long.append(f"plate {len(words(t))} w: {t[:50]!r}")
    res["D2_length"] = ("PASS", "voice ≤ 12, plate ≤ 8 words") if not long else ("FAIL", "; ".join(long[:4]))
    texts = [t.lower() for _, t in plates]
    dup = sorted({t for t in texts if texts.count(t) > 1})
    count = {}
    for t in texts:
        for w in set(words(t)):
            if len(w) >= 5 and w not in STOP:
                count[w] = count.get(w, 0) + 1
    often = sorted(w for w, n in count.items() if n >= 3)
    res["D3_repetition"] = ("PASS", "no repetition") if not (dup or often) else \
        ("FAIL", "; ".join(([f"plate 2×: {d!r}" for d in dup]) + ([f"'{w}' on ≥ 3 plates" for w in often])))
    bl = brief.lower()
    for season, trig in SEASON_TRIGGER.items():
        if any(x in bl for x in trig):
            if not beats:
                res["D4_season"] = ("FAIL", f"the brief asks for {season}, but there are no keyframe prompts to check (--prompts)")
            else:
                hit = [b["name"] or str(i + 1) for i, b in enumerate(beats) if any(re.search(r"\b" + re.escape(m), b["prompt"].lower()) and not re.search(r"\b" + re.escape(m) + r"ed\b", b["prompt"].lower()) for m in SEASON[season])]
                ok = len(hit) * 2 >= len(beats)
                res["D4_season"] = ("PASS" if ok else "FAIL",
                                    f"seasonal motifs in {len(hit)}/{len(beats)} beats ({', '.join(hit) or 'none'}); needs ≥ {(len(beats) + 1) // 2}")
            break
    return res


CRITERIA = {
    "hook": "Do the first 2 seconds (first plate/voice line/beat) grab the viewer, in line with the goal of the brief?",
    "line": "Does every line follow logically from the previous one, without a jump or a list that breaks the story? Does it read as one story with a beginning, middle and end?",
    "one_thought": "Does every plate carry exactly one thought (not two, not a loose list of facts)?",
    "closer": "Does the closer fit the goal of the brief (e.g. a greeting ends on the wish, a sales video on the call to action)?",
    "picture_fits": "Do the pictures (keyframe prompts and, if there is a strip, the real frames) fit the brief? For a seasonal brief: are seasonal motifs clearly visible in at least half of the beats?",
    "voice_and_plate": "Do voice and plates reinforce each other (no clashing content, no other form of address, the plate doesn't repeat the voice word for word unless deliberately)?",
}


def rubric(brief, plates, voice, beats, phase, frames):
    cmd0 = shlex.split(os.environ.get("STORY_CHECK_LLM", "claude -p"))
    if not cmd0 or not shutil.which(cmd0[0]):
        return None, f"LLM command not found ({' '.join(cmd0) or 'empty'}; set STORY_CHECK_LLM)"
    tl = "\n".join(f"  {t:5.1f}s  PLATE: {x}" for t, x in plates) or "  (no plates)"
    vo = "\n".join(f"  {i+1}. VOICE: {x}" for i, x in enumerate(voice)) or "  (no voice)"
    kf = "\n".join(f"  {i+1}. [{b['role']}|{b['name']}] {b['prompt']}" for i, b in enumerate(beats)) or "  (no keyframe prompts)"
    crit = "\n".join(f'- "{k}": {v}' for k, v in CRITERIA.items())
    strip = (f"\nAlso read the frame strip of the final result with your Read tool: {os.path.abspath(frames)} — judge "
             f"'picture_fits' on what is REALLY visible there, not on the prompts.\n") if frames else ""
    prompt = f"""You are the story editor of a video studio. Judge this short business video ({phase} phase) strictly, like an
experienced final editor: a video that is technically correct but doesn't run as a story is a FAIL.

BRIEF:
{brief.strip()[:4000]}

PLATES (time, text on screen):
{tl}

VOICE (voice-over, in order):
{vo}

PICTURES (keyframe prompts per beat):
{kf}
{strip}
Criteria (each PASS or FAIL, with a concrete one-sentence reason that names the line or the picture):
{crit}

Answer with ONLY this JSON object, without explanation before or after:
{{"hook": {{"verdict": "PASS|FAIL", "reason": "…"}}, "line": {{…}}, "one_thought": {{…}}, "closer": {{…}}, "picture_fits": {{…}}, "voice_and_plate": {{…}}}}"""
    cmd = cmd0 + [prompt]
    if frames and os.path.basename(cmd0[0]) == "claude":
        cmd = cmd0 + ["--allowedTools", "Read", prompt]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=420)
    except subprocess.TimeoutExpired:
        return None, "LLM timeout"
    out = r.stdout
    m = re.search(r"\{.*\}", out, re.S)
    if not m:
        return None, f"no JSON from the LLM (exit {r.returncode}): {out[:200]!r}"
    try:
        d = json.loads(m.group(0))
    except Exception as e:
        return None, f"unreadable JSON: {e}"
    res = {}
    for k in CRITERIA:
        v = d.get(k) or {}
        o = str(v.get("verdict", "")).upper()
        res["R_" + k] = ("PASS" if o == "PASS" else "FAIL", v.get("reason", "no verdict given"))
    return res, None


def main(argv):
    a = {"--brief": None, "--phase": "final", "--titles": None, "--vo": None, "--script": None, "--prompts": None,
         "--frames": None, "--json": None, "--lang": os.environ.get("VO_LANG", "en")}
    llm = True
    i = 0
    while i < len(argv):
        if argv[i] == "--no-llm":
            llm = False; i += 1
        elif argv[i] in a and i + 1 < len(argv):
            a[argv[i]] = argv[i + 1]; i += 2
        else:
            print(__doc__); return 2
    if not a["--brief"] or a["--phase"] not in ("storyboard", "final"):
        print(__doc__); return 2
    brief = open(a["--brief"], encoding="utf-8").read()
    plates = read_titles(a["--titles"])
    voice = read_vo(a["--vo"])
    if a["--script"]:
        voice += [l.strip() for l in open(a["--script"], encoding="utf-8") if l.strip()]
    beats = read_prompts(a["--prompts"])
    if not plates and not voice:
        print("ERROR: no plates (--titles) and no voice (--vo/--script): nothing to judge", file=sys.stderr); return 2
    res = deterministic(brief, plates, voice, beats, a["--lang"])
    if llm:
        r, err = rubric(brief, plates, voice, beats, a["--phase"], a["--frames"])
        if r:
            res.update(r)
        else:
            res["R_rubric"] = ("FAIL", f"rubric not judged: {err}")
    print(f"── story-check ({a['--phase']}): {len(plates)} plates, {len(voice)} voice lines, {len(beats)} beats")
    for k, (o, reason) in res.items():
        print(f"  {o:4}  {k:<18} {reason}")
    fails = [k for k, (o, _) in res.items() if o != "PASS"]
    if a["--json"]:
        json.dump({k: {"verdict": o, "reason": r} for k, (o, r) in res.items()}, open(a["--json"], "w"), ensure_ascii=False, indent=1)
    print("──")
    if fails:
        print(f"STORY: FAIL ({', '.join(fails)})"); return 1
    if not llm:
        print("STORY: INCOMPLETE — only the deterministic half; the rubric was not judged"); return 3
    print("STORY: PASS"); return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
