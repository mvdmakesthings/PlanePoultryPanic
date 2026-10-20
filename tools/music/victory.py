"""The ending's victory music: the cluck groove's instruments at 100 BPM
in C major, "triumphant relief with a travel motif". A 16-bar loop: the
groove brightened to C - G - Am - F, then the cluck melody, which opens
with the airport chime's two notes (G, then C) as its travel motif.

Seamless like arrivals.py. Placeholder until the commissioned soundtrack.

Usage (from the repo root): python3 tools/music/victory.py
Writes game/assets/audio/music/victory.wav (32 kHz, 16-bit mono).
"""
import os

import numpy as np
from scipy.io import wavfile

import groove

groove.BPM = 100
groove.BEAT = 60 / groove.BPM

from arrivals import snes_loop  # noqa: E402  (after the tempo change)
from groove import ROLES, add, at, bass, hat, kick, organ, pitched, snare  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(REPO, "game", "assets", "audio", "music", "victory.wav")
BARS = 16
BEATS = BARS * 4

CHORDS = [[48, 52, 55], [47, 50, 55], [45, 48, 52], [45, 48, 53]] * 4
WALK = [[36, 40, 43, 40], [31, 35, 38, 35], [33, 36, 40, 36], [29, 33, 36, 33]] * 4

MELODY = [
    (16, 67), (17, 72), (18, 76), (19, 74), (19.5, 72),
    (20, 71), (21, 74), (22, 79), (23, 77),
    (24, 76), (25, 72), (26, 69), (27, 72), (27.5, 76),
    (28, 77), (29, 76), (30, 74), (31, 72),
    (48, 67), (49, 72), (50, 76), (51, 79), (51.5, 81),
    (52, 79), (53, 77), (54, 74), (55, 71),
    (56, 72), (57, 76), (58, 81), (59, 79),
    (60, 77), (60.5, 76), (61, 74), (62, 72),
]


def render():
    c = groove.load_clucks()
    n = at(BEATS) // 3 * 3
    mix = np.zeros(n + at(8))
    for bar in range(BARS):
        b0 = bar * 4
        add(mix, organ(CHORDS[bar], 4), b0, 0.17)
        for i, note in enumerate(WALK[bar]):
            add(mix, bass(note, 1), b0 + i, 0.4)
        for beat in (0, 2):
            add(mix, kick(), b0 + beat, 0.6)
        for beat in (1, 3):
            add(mix, snare(), b0 + beat, 0.3)
        for eighth in range(8):
            add(mix, hat(), b0 + eighth / 2, 0.1)
        add(mix, c[ROLES["offbeat"][0]], b0 + 1.5, 0.35)
    for start in (16, 48):
        for offset, name in ROLES["intro"]:
            add(mix, c[name], start + offset, 0.45)
    for beat, note in MELODY:
        add(mix, pitched(c[ROLES["melody"][0]], ROLES["melody"][1], note), beat, 0.42)
    loop = mix[:n].copy()
    tail = mix[n:]
    loop[:len(tail)] += tail
    return loop


def main():
    sr, y = snes_loop(render())
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    wavfile.write(OUT, sr, y)
    print(f"wrote {os.path.relpath(OUT, REPO)} ({len(y) / sr:.1f}s loop at {sr} Hz)")


if __name__ == "__main__":
    main()
