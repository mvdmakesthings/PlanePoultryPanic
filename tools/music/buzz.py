"""Energy-drink music: the cluck groove's instruments, sped up to 176 BPM
and bright, for the 10 seconds Amanda is buzzing. The level's own music
comes back when she crashes.

  bars 1-4   A - E - F#m - D: a four-on-the-floor kick, sixteenth hats,
             an octave-jumping bass on every eighth, and clucks on the
             offbeats like a sugar-rushed hi-hat
  bars 5-8   the cluck melody racing up and down in sixteenths, and a
             rising cluck roll to turn back to bar 1

About 11 seconds, seamless like arrivals.py. Placeholder until the
commissioned soundtrack.

Usage (from the repo root): python3 tools/music/buzz.py
Writes game/assets/audio/music/buzz.wav (32 kHz, 16-bit mono).
"""
import os

import numpy as np
from scipy.io import wavfile

import groove

groove.BPM = 176
groove.BEAT = 60 / groove.BPM

from arrivals import snes_loop  # noqa: E402  (after the tempo change)
from groove import ROLES, add, at, bass, hat, kick, organ, pitched, snare  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(REPO, "game", "assets", "audio", "music", "buzz.wav")
BARS = 8
BEATS = BARS * 4

# A major, the happiest pop progression there is: A - E - F#m - D, twice.
CHORDS = [[57, 61, 64], [56, 59, 64], [54, 57, 61], [57, 62, 66]] * 2
ROOTS = [33, 28, 30, 26] * 2

# Bars 5-8: sixteenth-note runs up and down each chord, landing on A.
RUNS = [
    [69, 73, 76, 81, 76, 73, 69, 73, 76, 81, 85, 81, 76, 73, 76, 81],
    [68, 71, 76, 80, 76, 71, 68, 71, 76, 80, 83, 80, 76, 71, 76, 80],
    [66, 69, 73, 78, 73, 69, 66, 69, 73, 78, 81, 78, 73, 69, 73, 78],
    [66, 69, 74, 78, 81, 78, 74, 69, 74, 78, 81, 86, 81, 78, 74, 69],
]
MELODY_START = 16


def render():
    c = groove.load_clucks()
    n = at(BEATS) // 3 * 3
    mix = np.zeros(n + at(8))
    for bar in range(BARS):
        b0 = bar * 4
        add(mix, organ(CHORDS[bar], 4), b0, 0.11)
        for eighth in range(8):
            add(mix, bass(ROOTS[bar] + (12 if eighth % 2 else 0), 0.5), b0 + eighth / 2, 0.36)
        for beat in range(4):
            add(mix, kick(), b0 + beat, 0.65)
            # Clucks on every offbeat, alternating the two short bucks.
            add(mix, c[ROLES["offbeat"][beat % 2]], b0 + beat + 0.5, 0.3 if b0 >= MELODY_START else 0.42)
        for beat in (1, 3):
            add(mix, snare(), b0 + beat, 0.42)
        for step in range(16):
            add(mix, hat(), b0 + step / 4, 0.12 if step % 2 == 0 else 0.07)
    for offset, name in ROLES["intro"]:
        add(mix, c[name], MELODY_START + offset, 0.5)
    for bar, run in enumerate(RUNS):
        for step, note in enumerate(run):
            beat = MELODY_START + bar * 4 + step / 4
            add(mix, pitched(c[ROLES["melody"][0]], ROLES["melody"][1], note), beat, 0.36)
    # A rising cluck roll in the last beat turns the loop.
    for k in range(4):
        add(mix, pitched(c["buck_3"], ROLES["melody"][1], 69 + k * 4), BEATS - 1 + k * 0.25, 0.35)
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
