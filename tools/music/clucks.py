"""Slice the chicken recordings into individual cluck samples.

Sources, both by JarredGibb on Freesound, CC0:
  233093 "Chicken - Buck - 96kHz.wav"   https://freesound.org/people/JarredGibb/sounds/233093/
  233097 "Chicken - Buck 2 - 96kHz.wav" https://freesound.org/people/JarredGibb/sounds/233097/
"""
import os
import sys
import warnings

import numpy as np
from scipy.io import wavfile
from scipy.signal import resample_poly

SR = 48000

# Freesound ID -> [(name, start ms, end ms)], picked from each recording's loudness envelope.
SLICES = {
    "233093": [
        ("buck_1", 312, 395),
        ("buck_2", 552, 635),
        ("buck_3", 832, 900),
        ("buck_4", 1165, 1240),
    ],
    "233097": [
        ("bok_soft", 400, 495),
        ("bawk_long", 545, 1100),
        ("bok", 1140, 1280),
        ("bok_sharp", 1375, 1485),
    ],
}


def sound_id(path):
    return os.path.basename(path).split("__")[0]


def load(path):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        sr, x = wavfile.read(path)
    x = x.astype(np.float64)
    x = resample_poly(x, SR, sr)
    return x / np.abs(x).max()


def fundamental(x):
    """Rough pitch in Hz from autocorrelation of the loudest 60 ms."""
    n = int(SR * 0.06)
    i = int(np.argmax(np.convolve(x**2, np.ones(n), "valid")))
    w = x[i:i + n] * np.hanning(n)
    ac = np.correlate(w, w, "full")[n - 1:]
    lo, hi = SR // 1200, SR // 150
    return SR / (lo + int(np.argmax(ac[lo:hi])))


def slice_clucks(x, sid):
    out = {}
    for name, a, b in SLICES[sid]:
        s = x[int(a * SR / 1000):int(b * SR / 1000)].copy()
        fi, fo = int(SR * 0.004), min(int(SR * 0.03), len(s) // 3)
        s[:fi] *= np.linspace(0, 1, fi)
        s[-fo:] *= np.linspace(1, 0, fo)
        out[name] = s / np.abs(s).max()
    return out


if __name__ == "__main__":
    clucks = slice_clucks(load(sys.argv[1]), sound_id(sys.argv[1]))
    for name, s in clucks.items():
        print(f"{name:10s} {len(s) / SR * 1000:5.0f} ms  ~{fundamental(s):4.0f} Hz")
        if len(sys.argv) > 2:
            wavfile.write(f"{sys.argv[2]}/{name}.wav", SR, (s * 32767).astype(np.int16))
