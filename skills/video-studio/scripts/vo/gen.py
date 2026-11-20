#!/usr/bin/env python3
"""Voice-over takes with Chatterbox multilingual (MIT), zero-shot cloned on a reference voice (reference/extended.md §3).

  gen.py <workdir> [--seeds 3] [--loanwords-ok]        run with the VO venv (VS_VO_PY, see extended.md §5b)

Reads <workdir>/lines.json: [{"id": "01", "text": intended text (= the subtitle), "speech": speech text}].
The speech text first goes through scripts/vo/pronounce.py (reference/lang/<VO_LANG>/pronunciation.json).
Writes <workdir>/takes/<id>-s<seed>.wav (existing takes are skipped, so it can be resumed).
Reference voice: env VO_ANCHOR, otherwise assets/voice/anchor.wav in the skill. No voice ships with the skill — bring a
reference you have the rights to (extended.md §3). Language: env VO_LANG (default en).
Note: --seeds N makes take sN for EVERY line in lines.json; to redo one line, use a workdir with only that line."""
import os, sys, json, pathlib, warnings
warnings.filterwarnings("ignore")

SKILL = pathlib.Path(__file__).resolve().parents[2]
ANCHOR = os.environ.get("VO_ANCHOR", str(SKILL / "assets" / "voice" / "anchor.wav"))
LANG = os.environ.get("VO_LANG", "en")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    w = pathlib.Path(sys.argv[1]).resolve()
    seeds = int(sys.argv[sys.argv.index("--seeds") + 1]) if "--seeds" in sys.argv else 3
    lines = json.loads((w / "lines.json").read_text())
    if not os.path.isfile(ANCHOR):
        sys.exit(f"gen.py: no reference voice at {ANCHOR} — set VO_ANCHOR=<your reference.wav> (reference/extended.md §3)")
    # Loanwords first: a word without a pronunciation gets spoken wrong and the voice gate doesn't notice.
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    from loanwords import uncovered, bad_spelling
    missing, bad = uncovered(lines, LANG), bad_spelling(LANG)
    if (missing or bad) and "--loanwords-ok" not in sys.argv:
        for i, x in missing: print(f"loanword without a pronunciation: line {i} '{x}'")
        for k, v in bad: print(f"pronunciation.json: {k} → {v} ('aj' before a consonant; write 'ai')")
        sys.exit("gen.py: sort out the pronunciation first (reference/lang/<lang>/pronunciation.json or 'speech'), or deliberately --loanwords-ok")
    from pronounce import apply  # common loanwords the way a native speaker says them
    jobs = [(l["id"], apply(l.get("speech") or l["text"], lang=LANG), s) for l in lines for s in range(1, seeds + 1)]
    todo = [j for j in jobs if not (w / "takes" / f"{j[0]}-s{j[2]}.wav").exists()]
    if not todo:
        print("all takes exist already"); return
    import torch, torchaudio
    import perth
    if getattr(perth, "PerthImplicitWatermarker", None) is None:   # some builds ship without the watermarker
        class _NoWM:
            def apply_watermark(self, wav, sample_rate=None, **kw): return wav
        perth.PerthImplicitWatermarker = _NoWM
    from chatterbox.mtl_tts import ChatterboxMultilingualTTS as TTS
    dev = "mps" if torch.backends.mps.is_available() else ("cuda" if torch.cuda.is_available() else "cpu")
    model = TTS.from_pretrained(device=dev)
    (w / "takes").mkdir(parents=True, exist_ok=True)
    for i, text, seed in todo:
        dest = w / "takes" / f"{i}-s{seed}.wav"
        torch.manual_seed(seed)
        wav = model.generate(text, language_id=LANG, audio_prompt_path=ANCHOR,
                             exaggeration=0.45, cfg_weight=0.5, temperature=0.7)
        torchaudio.save(str(dest), wav if wav.dim() == 2 else wav.unsqueeze(0), model.sr)
        print("ok", dest.name, flush=True)


if __name__ == "__main__":
    main()
