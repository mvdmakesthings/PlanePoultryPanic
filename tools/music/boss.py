"""Level 5 (the Final Departure Gate) boss music: the cluck groove's
instruments at 144 BPM in E Phrygian, for "intense, with chicken-themed
musical jokes". Plays from the boss fight through the escape.

  bars 1-8   E - F - E - Dm/G: a galloping bass, kicks on every beat,
             snares on 2 and 4, sixteenth hats, the long "bawk" answering
             the end of every second bar like a horn stab
  bars 9-16  the cluck melody, and a rapid-fire cluck roll (the chickens
             doing a drum solo) to turn back to bar 1

Seamless like arrivals.py. Placeholder until the commissioned soundtrack.

Usage (from the repo root): python3 tools/music/boss.py
Writes game/assets/audio/music/boss.wav (32 kHz, 16-bit mono).
"""
import os

import numpy as np
from scipy.io import wavfile

import groove

groove.BPM = 144
groove.BEAT = 60 / groove.BPM

from arrivals import snes_loop  # noqa: E402  (after the tempo change)
from groove import ROLES, add, at, bass, hat, kick, organ, pitched, snare  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(REPO, "game", "assets", "audio", "music", "boss.wav")
BARS = 16
BEATS = BARS * 4

CHORDS = [[52, 56, 59], [53, 57, 60], [52, 56, 59], [50, 53, 57]] * 4
ROOTS = [28, 29, 28, 31] * 4

MELODY = [
    (32, 64), (32.5, 65), (33, 64), (33.5, 71), (34.5, 69), (35, 68),
    (36, 65), (36.5, 64), (37, 65), (37.5, 72), (38.5, 71), (39, 69),
    (40, 68), (40.5, 69), (41, 71), (42, 76), (42.5, 74), (43, 72),
    (44, 71), (44.5, 69), (45, 67), (46, 65), (47, 64),
    (48, 76), (48.5, 77), (49, 76), (49.5, 72), (50.5, 71), (51, 68),
    (52, 77), (52.5, 76), (53, 74), (53.5, 72), (54.5, 71), (55, 69),
    (56, 68), (56.5, 71), (57, 76), (58, 77), (58.5, 76), (59, 74),
    (60, 72), (60.5, 71), (61, 68), (61.5, 65), (62, 64),
]
MELODY_START = 32


def render():
    c = groove.load_clucks()
    n = at(BEATS) // 3 * 3
    mix = np.zeros(n + at(8))
    for bar in range(BARS):
        b0 = bar * 4
        add(mix, organ(CHORDS[bar], 4), b0, 0.13)
        # Galloping bass: long-short-short on every beat.
        for beat in range(4):
            for offset, length in ((0.0, 0.5), (0.5, 0.25), (0.75, 0.25)):
                add(mix, bass(ROOTS[bar] + (12 if offset == 0.75 else 0), length), b0 + beat + offset, 0.38)
            add(mix, kick(), b0 + beat, 0.65)
        for beat in (1, 3):
            add(mix, snare(), b0 + beat, 0.4)
        for step in range(16):
            add(mix, hat(), b0 + step / 4, 0.11 if step % 2 == 0 else 0.06)
        soft = 0.6 if b0 >= MELODY_START else 1.0
        add(mix, c[ROLES["offbeat"][0]], b0 + 1.5, 0.45 * soft)
        # The long bawk answers every second bar, like a horn stab.
        if bar % 2 == 1 and b0 < MELODY_START:
            add(mix, c["bawk_long"], b0 + 3, 0.5)
    for offset, name in ROLES["intro"]:
        add(mix, c[name], MELODY_START + offset, 0.55)
    for beat, note in MELODY:
        add(mix, pitched(c[ROLES["melody"][0]], ROLES["melody"][1], note), beat, 0.42)
    # Cluck drum solo: a roll of clucks rising in pitch to turn the loop.
    for k in range(8):
        add(mix, pitched(c["buck_3"], ROLES["melody"][1], 60 + k * 2), BEATS - 2 + k * 0.25, 0.35)
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
