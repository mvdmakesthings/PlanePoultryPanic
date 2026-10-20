"""Level 1 (Arrivals) music: a 16-bar loop built from the cluck test groove.

Same instruments and sound as groove.py (organ, walking bass, drums, cluck
percussion, a melody on a repitched cluck, through the SNES-style output
stage), arranged as a full loop for the level:

  bars 1-8   Em - C - Am - B7, twice: the groove, with clucks answering the
             snare and a cluck drum fill every four bars, then the chicken
             "crash" into
  bars 9-16  the cluck melody: the groove's phrase, then an answering phrase
             that comes home, and a cluck fill that turns back to bar 1.

The loop is seamless: anything that rings past the end (and the echo) wraps
around onto the start. Placeholder until the commissioned soundtrack.

Usage (from the repo root): python3 tools/music/arrivals.py
Writes game/assets/audio/music/arrivals.wav (32 kHz, 16-bit mono).
"""
import os

import numpy as np
from scipy.io import wavfile

import groove
from groove import ROLES, add, at, bass, hat, kick, organ, pitched, snare, snesify

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(REPO, "game", "assets", "audio", "music", "arrivals.wav")
BARS = 16
BEATS = BARS * 4

# E minor, spooky surf: Em - C - Am - B7, four times.
CHORDS = [[52, 55, 59], [48, 52, 55], [45, 48, 52], [47, 51, 54, 57]] * 4
WALK = [[40, 43, 47, 43], [36, 40, 43, 40], [33, 36, 40, 36], [35, 39, 42, 39]] * 4

# (beat, MIDI note) for the cluck melody. Bars 9-12 are the groove's phrase;
# bars 13-16 answer it and land back on E for the loop.
MELODY = [
    (32.5, 64), (33, 67), (33.5, 71), (34.5, 69), (35, 67),
    (36.5, 64), (37, 67), (37.5, 72), (38.5, 71), (39, 67),
    (40.5, 69), (41, 72), (41.5, 76), (42.5, 74), (43, 72),
    (44.5, 71), (45, 75), (45.5, 78), (46.5, 76), (47, 71), (47.5, 64),
    (48.5, 64), (49, 67), (49.5, 71), (50.5, 72), (51, 71),
    (52.5, 67), (53, 64), (53.5, 67), (54.5, 72), (55, 76),
    (56.5, 72), (57, 69), (57.5, 72), (58.5, 76), (59, 74),
    (60.5, 75), (61, 71), (61.5, 66), (62, 63), (62.5, 59), (63, 64),
]
MELODY_START = 32


def render():
    c = groove.load_clucks()
    # Loop length in 48 kHz samples, rounded to a multiple of 3 so it maps to
    # a whole number of 32 kHz samples.
    n = at(BEATS) // 3 * 3
    mix = np.zeros(n + at(8))

    for bar in range(BARS):
        b0 = bar * 4
        add(mix, organ(CHORDS[bar], 4), b0, 0.18)
        for i, note in enumerate(WALK[bar]):
            add(mix, bass(note, 1), b0 + i, 0.45)
        for beat in (0, 2):
            add(mix, kick(), b0 + beat, 0.7)
        for beat in (1, 3):
            add(mix, snare(), b0 + beat, 0.35)
        for eighth in range(8):
            add(mix, hat(), b0 + eighth / 2, 0.12)
        # Clucks answer the snare on the off-beats, softer under the melody.
        soft = 0.6 if b0 >= MELODY_START else 1.0
        add(mix, c[ROLES["offbeat"][0]], b0 + 1.5, 0.5 * soft)
        add(mix, c[ROLES["offbeat"][1]], b0 + 3.5, 0.4 * soft)
        # A cluck fill at the end of every fourth bar (but not into the crash).
        if bar % 4 == 3 and b0 + 4 != MELODY_START:
            add(mix, c[ROLES["fill"]], b0 + 3.75, 0.5)

    # The chicken "crash" going into the melody.
    for offset, name in ROLES["intro"]:
        add(mix, c[name], MELODY_START + offset, 0.55)

    for beat, note in MELODY:
        add(mix, pitched(c[ROLES["melody"][0]], ROLES["melody"][1], note), beat, 0.45)

    # Wrap the tail (notes ringing past the end) onto the start.
    loop = mix[:n].copy()
    tail = mix[n:]
    loop[:len(tail)] += tail
    return loop


def snes_loop(loop):
    """The SNES output stage, applied so the echo and filters wrap around:
    run three copies back to back and keep the middle one."""
    sr, y = snesify(np.tile(loop, 3))
    length = len(loop) * 2 // 3  # 48 kHz -> 32 kHz
    return sr, y[length:2 * length]


def main():
    sr, y = snes_loop(render())
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    wavfile.write(OUT, sr, y)
    print(f"wrote {os.path.relpath(OUT, REPO)} ({len(y) / sr:.1f}s loop at {sr} Hz)")


if __name__ == "__main__":
    main()
