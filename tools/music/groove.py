"""8-bar test groove: cluck percussion (bars 1-4), then a pitched-cluck melody (bars 5-8).

Instruments are simple synth stand-ins; the point is to hear the clucks in a mix.
Usage: python groove.py <out_dir>
"""
import os
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter, resample_poly

from clucks import SR, load, slice_clucks, sound_id

BPM = 112
BEAT = 60 / BPM
BARS = 8
rng = np.random.default_rng(7)

SAMPLES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "samples")

# Which cluck plays which part. Short clucks come from 233093, the long bawk from 233097.
# "intro" leads into bar 5 (beat offsets from beat 16); "melody" is (sample, rough pitch in Hz).
ROLES = {
    "offbeat": ("buck_1", "buck_4"),
    "fill": "buck_3",
    "intro": [(-1, "buck_1"), (-0.75, "buck_2"), (-0.5, "buck_3"), (-0.25, "buck_4"), (0, "bawk_long")],
    "melody": ("buck_2", 310),
}


def hz(note):
    """MIDI note number to Hz."""
    return 440 * 2 ** ((note - 69) / 12)


def at(beat):
    return int(beat * BEAT * SR)


def env(n, attack=0.005, release=0.05):
    e = np.ones(n)
    a, r = min(int(SR * attack), n), min(int(SR * release), n)
    e[:a] = np.linspace(0, 1, a)
    e[n - r:] *= np.linspace(1, 0, r)
    return e


def add(mix, sig, beat, gain):
    i = at(beat)
    sig = sig[:len(mix) - i]
    mix[i:i + len(sig)] += sig * gain


def lowpass(x, cutoff, order=2):
    b, a = butter(order, cutoff / (SR / 2))
    return lfilter(b, a, x)


def bass(note, beats):
    n = at(beats * 0.9)
    t = np.arange(n) / SR
    f = hz(note)
    saw = 2 * ((t * f) % 1) - 1
    sig = lowpass(0.6 * np.sin(2 * np.pi * f * t) + 0.4 * saw, 900)
    return sig * np.exp(-t * 3) * env(n)


def organ(notes, beats):
    """Drawbar-ish organ with a little vibrato: the B-movie horror sound."""
    n = at(beats)
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t)
    sig = np.zeros(n)
    for note in notes:
        f = hz(note) * vib
        ph = 2 * np.pi * np.cumsum(f) / SR
        sig += np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.3 * np.sin(4 * ph)
    return sig / len(notes) * env(n, 0.02, 0.1)


def kick():
    n = int(SR * 0.18)
    t = np.arange(n) / SR
    f = 50 + 90 * np.exp(-t * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 18)


def snare():
    n = int(SR * 0.15)
    t = np.arange(n) / SR
    noise = lowpass(rng.uniform(-1, 1, n), 6000)
    return (0.7 * noise + 0.3 * np.sin(2 * np.pi * 190 * t)) * np.exp(-t * 25)


def hat():
    n = int(SR * 0.04)
    noise = rng.uniform(-1, 1, n)
    noise -= lowpass(noise, 7000)
    return noise * np.exp(-np.arange(n) / SR * 90)


def pitched(sample, base_hz, note):
    """Repitch by changing playback speed, the way the SNES sampler does it."""
    ratio = hz(note) / base_hz
    up, down = int(round(1000 / ratio)), 1000
    return resample_poly(sample, up, down)


def snesify(x):
    """Approximate the SNES output stage: 32 kHz, soft top end, filtered echo, 16-bit."""
    x = lowpass(x, 9000, order=4)
    x = resample_poly(x, 32000, SR)
    sr = 32000
    d = int(sr * 0.24)  # echo delay
    dry = np.concatenate([x, np.zeros(d * 4)])
    echo = np.zeros_like(dry)
    b, a = butter(1, 3000 / (sr / 2))
    for i in range(d, len(dry), d):
        tap = lfilter(b, a, dry[i - d:i] + echo[i - d:i]) * 0.35
        echo[i:i + d] += tap[:len(echo[i:i + d])]
    y = dry + 0.4 * echo
    y = y / np.abs(y).max() * 0.9
    return sr, np.round(y * 32767).astype(np.int16)


def load_clucks():
    clucks = {}
    for name in sorted(os.listdir(SAMPLES)):
        if name.endswith(".wav"):
            path = os.path.join(SAMPLES, name)
            clucks.update(slice_clucks(load(path), sound_id(path)))
    return clucks


def main(out_dir):
    c = load_clucks()
    intro_starts = 16 + min(offset for offset, _ in ROLES["intro"])
    mix = np.zeros(at(BARS * 4) + SR)

    # E minor, spooky surf: Em - C - Am - B7, twice.
    chords = [[52, 55, 59], [48, 52, 55], [45, 48, 52], [47, 51, 54, 57]] * 2
    walk = [[40, 43, 47, 43], [36, 40, 43, 40], [33, 36, 40, 36], [35, 39, 42, 39]] * 2

    for bar in range(BARS):
        b0 = bar * 4
        add(mix, organ(chords[bar], 4), b0, 0.18)
        for i, note in enumerate(walk[bar]):
            add(mix, bass(note, 1), b0 + i, 0.45)
        for beat in (0, 2):
            add(mix, kick(), b0 + beat, 0.7)
        for beat in (1, 3):
            add(mix, snare(), b0 + beat, 0.35)
        for eighth in range(8):
            add(mix, hat(), b0 + eighth / 2, 0.12)
        # Cluck percussion: answers the snare on the off-beats.
        add(mix, c[ROLES["offbeat"][0]], b0 + 1.5, 0.5)
        add(mix, c[ROLES["offbeat"][1]], b0 + 3.5, 0.4)
        if bar % 4 == 3 and b0 + 3.75 < intro_starts:
            add(mix, c[ROLES["fill"]], b0 + 3.75, 0.5)

    # A chicken "crash" going into the melody section.
    for offset, name in ROLES["intro"]:
        add(mix, c[name], 16 + offset, 0.55)

    # Bars 5-8: melody played on a single repitched cluck.
    melody = [  # (beat, MIDI note)
        (16.5, 64), (17, 67), (17.5, 71), (18.5, 69), (19, 67),
        (20.5, 64), (21, 67), (21.5, 72), (22.5, 71), (23, 67),
        (24.5, 69), (25, 72), (25.5, 76), (26.5, 74), (27, 72),
        (28.5, 71), (29, 75), (29.5, 78), (30.5, 76), (31, 71), (31.5, 64),
    ]
    for beat, note in melody:
        add(mix, pitched(c[ROLES["melody"][0]], ROLES["melody"][1], note), beat, 0.45)

    sr, y = snesify(mix)
    os.makedirs(out_dir, exist_ok=True)
    wavfile.write(os.path.join(out_dir, "cluck_groove_test.wav"), sr, y)
    for name, s in c.items():
        wavfile.write(os.path.join(out_dir, f"{name}.wav"), SR, (s * 32767).astype(np.int16))


if __name__ == "__main__":
    main(sys.argv[1])
