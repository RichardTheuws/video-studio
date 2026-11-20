#!/usr/bin/env python3
"""Clean voice clip. Measured cause of "a strange extra sound effect" in an explainer: Chatterbox often adds 0.4–1.4 s of
noise, breath or a low thud after the sentence (9 of 17 lines, up to −16 dB, as loud as the voice), and the old single-pass
`loudnorm` pulled the silences and that tail up by as much as +19 dB on short lines (and wrote 192 kHz). pick.py cuts and
normalises with these functions; voice-check.py judges every clip with them.

  clean.py <clip.wav> [<raw take.wav>]     → PASS/FAIL lines, exit 1 on a FAIL
  clean.py --bed <bed.wav>                 → clicks per minute in the music bed (qa-check.sh --bed)
"""
from __future__ import annotations
import subprocess, sys
import numpy as np

MAX_PUMP_DB = 6.0      # the clip's dynamics (voice − floor) may be at most this much smaller than the raw take's
MAX_EDGE = 0.02        # first/last sample: louder = a click in the mix


def _bursts(y, hop=160):
    import librosa
    db = 20 * np.log10(librosa.feature.rms(y=y, frame_length=400, hop_length=hop)[0] + 1e-9)
    act = db > db.max() - 35
    bursts, i, n = [], 0, len(act)
    while i < n:
        if act[i]:
            j = i
            while j < n and (act[j] or act[j:j + 15].any()):
                j += 1
            bursts.append([i, j]); i = j
        else:
            i += 1
    return bursts


def _unvoiced_tail(v, d) -> bool:
    # an unvoiced tail; a short spoken sentence still reaches a voiced probability ≥ 0.09 over > 1 s
    return (v < 0.05 and d < 1.5) or (v < 0.10 and d < 0.6)


def voice_bounds(src) -> tuple[float, float]:
    """Start and end of the voice. Silence trimming at −45 dB leaves a TTS tail in place because it isn't silence. Method:
    split the take into bursts above (peak − 35 dB) with gaps ≥ 150 ms; a last burst without voice (pyin voiced probability
    < 0.05 and shorter than 1.5 s, or < 0.10 and shorter than 0.6 s) is tail noise and goes, repeatedly. Start = start of the
    first burst − 30 ms (not the first vowel: then an initial consonant drops away — a brand name lost its first letter)."""
    import librosa
    y, sr = librosa.load(str(src), sr=16000, mono=True)
    hop = 160
    bursts = _bursts(y, hop)
    if not bursts:
        return 0.0, len(y) / sr
    _, _, vp = librosa.pyin(y, fmin=65, fmax=450, sr=sr, frame_length=1024, hop_length=hop)
    while len(bursts) > 1:
        a, b = bursts[-1]
        if _unvoiced_tail(np.nanmean(vp[a:b]), (b - a) * hop / sr):
            bursts.pop()
        else:
            break
    return max(0.0, bursts[0][0] * hop / sr - 0.03), min(len(y) / sr, bursts[-1][1] * hop / sr + 0.06)


def bursts_and_tail(src):
    """→ (number of bursts, [(from, to, voiced probability, duration)] of unvoiced bursts at the end)."""
    import librosa
    y, sr = librosa.load(str(src), sr=16000, mono=True)
    hop = 160
    bursts = _bursts(y, hop)
    _, _, vp = librosa.pyin(y, fmin=65, fmax=450, sr=sr, frame_length=1024, hop_length=hop)
    tail = []
    for a, b in reversed(bursts[1:]):
        v, d = float(np.nanmean(vp[a:b])), (b - a) * hop / sr
        if _unvoiced_tail(v, d):
            tail.append((round(a * hop / sr, 2), round(b * hop / sr, 2), round(v, 3), round(d, 2)))
        else:
            break
    return len(bursts), tail


def load(p, sr=48000):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(p), "-ac", "1", "-ar", str(sr), "-f", "f32le", "-"], capture_output=True).stdout
    return np.frombuffer(raw, np.float32)


def dynamics_db(x, sr=48000):
    """Distance voice (p95) to noise floor (p10) in 20-ms frames. A linear gain doesn't change it; a pumping normalisation
    (which lifts the silences) makes it smaller. So compare dynamics, not the floor itself (the raw take has digital silence
    before and after the sentence, which the cut removes)."""
    h = int(sr * 0.02); m = len(x) // h
    f = 20 * np.log10(np.sqrt((x[:m * h].reshape(m, h) ** 2).mean(1)) + 1e-9)
    return float(np.percentile(f, 95) - np.percentile(f, 10))


def judge(clip, take=None) -> list[str]:
    """List of reasons (empty = clean)."""
    r = []
    sr = int(subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=sample_rate",
                                      "-of", "csv=p=0", str(clip)]).strip())
    if sr != 48000:
        r.append(f"sample rate {sr} (expected 48000; 192 kHz = dynamic loudnorm)")
    _, st = bursts_and_tail(clip)
    if st:
        r.append("unvoiced tail " + ", ".join(f"{a}–{b} s (voiced {v})" for a, b, v, _ in st))
    x = load(clip)
    if len(x) and max(abs(float(x[0])), abs(float(x[-1]))) > MAX_EDGE:
        r.append(f"hard edge {max(abs(float(x[0])), abs(float(x[-1]))):.3f} (a click going in or out)")
    if take:
        a, b = voice_bounds(take); t = load(take)[int(a * 48000):int(b * 48000)]
        dv = dynamics_db(t) - dynamics_db(x)
        if dv > MAX_PUMP_DB:
            r.append(f"dynamics {dv:.1f} dB smaller than the raw take (a pumping normalisation lifts the silences)")
    return r


MAX_CLICKS = 200       # per minute, music bed after treatment (a raw stable-audio bed measured 2012; after declick+lowpass 37)


def clicks_per_min(p, sr=48000) -> float:
    """Audible clicks in a music bed: 2-ms frames where the energy above 10 kHz jumps ≥ 20 dB above its own median and is
    no more than 45 dB below the total. A stable-audio bed had ~2000 per minute (sharp broadband clicks up to 22 kHz) plus a
    whistle around 5 kHz; adeclick + lowpass 4.5 kHz brought it to 37."""
    import scipy.signal as ss
    x = load(p, sr)
    b, a = ss.butter(4, 10000 / (sr / 2), "high"); h = ss.lfilter(b, a, x); w = 96; m = len(h) // w
    e = 20 * np.log10(np.sqrt((h[:m * w].reshape(m, w) ** 2).mean(1)) + 1e-9)
    tot = 20 * np.log10(np.sqrt((x[:m * w].reshape(m, w) ** 2).mean(1)) + 1e-9)
    audible = ((e - ss.medfilt(e, 51)) > 20) & (e > tot - 45)
    return float(audible.sum() / (len(x) / sr / 60))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    if sys.argv[1] == "--bed":      # clean.py --bed <music bed as it goes into the mix>
        t = clicks_per_min(sys.argv[2])
        print(f"BED: {'PASS' if t <= MAX_CLICKS else 'FAIL'} — {t:.0f} clicks per minute (max {MAX_CLICKS})")
        sys.exit(0 if t <= MAX_CLICKS else 1)
    rs = judge(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
    print("CLEAN:", "PASS" if not rs else "FAIL — " + "; ".join(rs))
    sys.exit(1 if rs else 0)
