"""Level 4 (Gate Areas) music: the cluck groove's instruments at 132 BPM
in A minor, for "high energy, survival tension".

  bars 1-8   Am - F - G - E7: four-on-the-floor kicks, a pumping octave
             bass in eighths, sixteenth hats, clucks on the off-beats
  bars 9-16  the cluck melody on top, a fill turning back to bar 1

Seamless like arrivals.py. Placeholder until the commissioned soundtrack.

Usage (from the repo root): python3 tools/music/gates.py
Writes game/assets/audio/music/gates.wav (32 kHz, 16-bit mono).
"""
import os

import numpy as np
from scipy.io import wavfile

import groove

groove.BPM = 132
groove.BEAT = 60 / groove.BPM

from arrivals import snes_loop  # noqa: E402  (after the tempo change)
from groove import ROLES, add, at, bass, hat, kick, organ, pitched, snare  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(REPO, "game", "assets", "audio", "music", "gates.wav")
BARS = 16
BEATS = BARS * 4

CHORDS = [[57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 56, 59, 62]] * 4
ROOTS = [33, 29, 31, 28] * 4

MELODY = [
    (32, 69), (32.5, 72), (33, 76), (34, 74), (34.5, 72), (35, 71),
    (36, 69), (36.5, 72), (37, 77), (38, 76), (38.5, 74), (39, 72),
    (40, 67), (40.5, 71), (41, 74), (42, 76), (42.5, 74), (43, 71),
    (44, 68), (44.5, 71), (45, 74), (46, 76), (47, 80),
    (48, 81), (48.5, 79), (49, 76), (50, 72), (50.5, 76), (51, 79),
    (52, 77), (52.5, 76), (53, 72), (54, 69), (54.5, 72), (55, 77),
    (56, 79), (56.5, 76), (57, 74), (58, 71), (58.5, 74), (59, 79),
    (60, 76), (60.5, 74), (61, 71), (61.5, 68), (62, 64), (63, 69),
]
MELODY_START = 32


def render():
    c = groove.load_clucks()
    n = at(BEATS) // 3 * 3
    mix = np.zeros(n + at(8))
    for bar in range(BARS):
        b0 = bar * 4
        add(mix, organ(CHORDS[bar], 4), b0, 0.14)
        for eighth in range(8):
            note = ROOTS[bar] + (12 if eighth % 2 else 0)
            add(mix, bass(note, 0.5), b0 + eighth / 2, 0.4)
        for beat in range(4):
            add(mix, kick(), b0 + beat, 0.65)
        for beat in (1, 3):
            add(mix, snare(), b0 + beat, 0.38)
        for step in range(16):
            add(mix, hat(), b0 + step / 4, 0.12 if step % 2 == 0 else 0.07)
        soft = 0.6 if b0 >= MELODY_START else 1.0
        add(mix, c[ROLES["offbeat"][0]], b0 + 1.5, 0.5 * soft)
        add(mix, c[ROLES["offbeat"][1]], b0 + 3.5, 0.4 * soft)
        if bar % 4 == 3 and b0 + 4 != MELODY_START:
            add(mix, c[ROLES["fill"]], b0 + 3.75, 0.5)
    for offset, name in ROLES["intro"]:
        add(mix, c[name], MELODY_START + offset, 0.55)
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
