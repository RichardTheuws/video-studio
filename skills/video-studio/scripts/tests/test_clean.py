"""Clean voice clip (scripts/vo/clean.py + the cut in pick.py): tail noise after the sentence, hard edge, pumping
normalisation, sample rate, clicks in a music bed. Self-contained: the 'take' is synthesised here (a voiced harmonic
signal with syllable envelopes, then an unvoiced noise tail, at 24 kHz like a raw Chatterbox take), so no voice ships.
Run with the VO venv (numpy, librosa, scipy) and ffmpeg in PATH."""
import pathlib, subprocess, sys, tempfile, wave
import numpy as np
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "vo"))
from clean import judge, voice_bounds, clicks_per_min, MAX_CLICKS
from pick import clean as cut_and_normalise

SR = 24000


def write(path, x, sr=SR):
    y = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(y.tobytes())


def take():
    """0.05–3.30 s 'speech' (f0 120–170 Hz, 6 harmonics, ~4 syllables/s, short pauses between words), 0.25 s gap, 0.9 s breathy noise, 0.3 s silence."""
    rng = np.random.default_rng(7)
    t = np.arange(int(3.25 * SR)) / SR
    f0 = 145 + 25 * np.sin(2 * np.pi * 0.7 * t)
    ph = 2 * np.pi * np.cumsum(f0) / SR
    v = sum(np.sin(k * ph) / k for k in range(1, 7))
    env = 0.55 + 0.45 * np.sin(2 * np.pi * 4.0 * t) ** 2
    env *= np.minimum(1, np.minimum(t / 0.03, (t[-1] - t) / 0.03))
    for g in (0.45, 0.95, 1.40, 1.95, 2.45, 2.90):                 # short pauses between 'words' (< 150 ms: still one burst)
        env *= 1 - 0.995 * np.exp(-0.5 * ((t - g) / 0.025) ** 2)
    voice = 0.25 * v * env + 0.002 * rng.standard_normal(len(t))
    noise = rng.standard_normal(int(0.9 * SR))
    noise = np.convolve(noise, np.ones(8) / 8, "same") * 0.12
    noise *= np.minimum(1, np.minimum(np.arange(len(noise)) / 800, (len(noise) - np.arange(len(noise))) / 800))
    pad = lambda s: np.zeros(int(s * SR))
    return np.concatenate([pad(0.05), voice, pad(0.25), noise, pad(0.3)])


with tempfile.TemporaryDirectory() as d:
    d = pathlib.Path(d)
    tk, clip = d / "take.wav", d / "clip.wav"
    write(tk, take())
    r = judge(tk)
    assert any("unvoiced tail" in x for x in r), r                              # 1. raw take: noise after the sentence
    assert any("sample rate" in x for x in r), r                                # 2. raw take is 24 kHz
    a, b = voice_bounds(tk); assert 0 <= a < 0.1 and 3.2 < b < 3.5, (a, b)      # 3. cut right after the voice, before the noise
    cut_and_normalise(tk, clip)                                                 # pick.py: cut + adeclick + fades + linear loudnorm
    assert judge(clip, tk) == [], judge(clip, tk)                               # 4. the cut, linearly normalised clip is clean
    run = lambda *x: subprocess.run(["ffmpeg", "-v", "error", "-y", *map(str, x)], check=True)
    run("-i", clip, "-af", "atrim=0:1.0", "-ar", "48000", d / "edge.wav")                       # 5. cut off mid-word
    assert any("hard edge" in x for x in judge(d / "edge.wav")), judge(d / "edge.wav")
    run("-i", clip, "-af", "loudnorm=I=-16:TP=-2:LRA=7", d / "pump.wav")                        # 6. old single pass: 192 kHz
    assert any("sample rate" in x for x in judge(d / "pump.wav", tk))
    run("-i", clip, "-af", "acompressor=threshold=-50dB:ratio=20:attack=1:release=50:makeup=24,alimiter=limit=0.9", "-ar", "48000", d / "flat.wav")
    assert any("dynamics" in x for x in judge(d / "flat.wav", tk)), judge(d / "flat.wav", tk)   # 7. lifted silences
    # 8–9. music bed: a tone bed with sharp clicks fails, after adeclick + lowpass it passes (qa-check.sh --bed)
    run("-f", "lavfi", "-i", "sine=f=220:d=20,volume=0.3", "-f", "lavfi", "-i", "anoisesrc=d=20:c=white:a=0.9,"
        "aeval='val(0)*lt(mod(t\\,0.05)\\,0.0004)':c=same", "-filter_complex", "[0][1]amix=inputs=2:normalize=0", "-ar", "48000", d / "tick.wav")
    run("-i", d / "tick.wav", "-af", "adeclick=w=55:o=75,lowpass=f=4500:p=2,lowpass=f=4500:p=2", d / "tick-clean.wav")
    t1, t2 = clicks_per_min(d / "tick.wav"), clicks_per_min(d / "tick-clean.wav")
    assert t1 > MAX_CLICKS, t1
    assert t2 <= MAX_CLICKS, t2
print("clean: 9 PASS")
