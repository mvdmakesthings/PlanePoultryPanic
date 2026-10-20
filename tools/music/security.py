"""Level 2 (Security) music: a 16-bar loop from the cluck groove's
instruments, in D minor and a notch more urgent than Arrivals.

  bars 1-4   Dm - Bb - Gm - A7, held back: organ, bass on the roots, a
             kick on each downbeat and ticking hats, clucks on the off-beats
  bars 5-8   the full groove with a walking bass and a cluck fill
  bars 9-16  the cluck melody, with a repeated-note "scanner beep" figure,
             over sixteenth-note hats; a fill turns back to bar 1

Seamless like arrivals.py. Placeholder until the commissioned soundtrack.

Usage (from the repo root): python3 tools/music/security.py
Writes game/assets/audio/music/security.wav (32 kHz, 16-bit mono).
"""
import os

import numpy as np
from scipy.io import wavfile

import groove
from arrivals import snes_loop
from groove import ROLES, add, at, bass, hat, kick, organ, pitched, snare

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(REPO, "game", "assets", "audio", "music", "security.wav")
BARS = 16
BEATS = BARS * 4

CHORDS = [[50, 53, 57], [46, 50, 53], [43, 46, 50], [45, 49, 52, 55]] * 4
WALK = [[38, 41, 45, 41], [34, 38, 41, 38], [31, 34, 38, 34], [33, 37, 40, 37]] * 4

MELODY = [
    (32.5, 69), (33, 69), (33.5, 74), (34.5, 72), (35, 69),
    (36.5, 70), (37, 74), (37.5, 77), (38.5, 74), (39, 70),
    (40.5, 67), (41, 70), (41.5, 74), (42.5, 72), (43, 70),
    (44.5, 69), (45, 73), (45.5, 76), (46.5, 73), (47, 69),
    (48.5, 74), (49, 74), (49.5, 77), (50.5, 76), (51, 74),
    (52.5, 70), (53, 72), (53.5, 74), (54.5, 77), (55, 74),
    (56.5, 79), (57, 77), (57.5, 74), (58.5, 70), (59, 67),
    (60.5, 69), (61, 73), (61.5, 76), (62, 73), (62.5, 69), (63, 62),
]
MELODY_START = 32


def render():
    c = groove.load_clucks()
    n = at(BEATS) // 3 * 3
    mix = np.zeros(n + at(8))
    for bar in range(BARS):
        b0 = bar * 4
        held = bar < 4
        add(mix, organ(CHORDS[bar], 4), b0, 0.16)
        if held:
            add(mix, bass(WALK[bar][0], 2), b0, 0.45)
            add(mix, bass(WALK[bar][0], 2), b0 + 2, 0.4)
            add(mix, kick(), b0, 0.7)
        else:
            for i, note in enumerate(WALK[bar]):
                add(mix, bass(note, 1), b0 + i, 0.45)
            for beat in (0, 2):
                add(mix, kick(), b0 + beat, 0.7)
            for beat in (1, 3):
                add(mix, snare(), b0 + beat, 0.35)
        # Hats tick in eighths, then sixteenths under the melody.
        steps = 16 if b0 >= MELODY_START else 8
        for step in range(steps):
            add(mix, hat(), b0 + step * 4 / steps, 0.12 if step % 2 == 0 or steps == 8 else 0.07)
        soft = 0.6 if b0 >= MELODY_START else 1.0
        add(mix, c[ROLES["offbeat"][0]], b0 + 1.5, 0.5 * soft)
        add(mix, c[ROLES["offbeat"][1]], b0 + 3.5, 0.4 * soft)
        if bar % 4 == 3 and bar != 3 and b0 + 4 != MELODY_START:
            add(mix, c[ROLES["fill"]], b0 + 3.75, 0.5)
    for offset, name in ROLES["intro"]:
        add(mix, c[name], MELODY_START + offset, 0.55)
    # The fill at the very end turns back to bar 1.
    add(mix, c[ROLES["fill"]], BEATS - 0.25, 0.5)
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
