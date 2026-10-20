"""Generate the game's sound effects and placeholder music.

Usage (from the repo root, needs only Python 3):
    python3 tools/audio/build.py            # sound effects
    python3 tools/audio/build.py --music    # also the placeholder music

Writes 16-bit mono WAV files to game/assets/audio/sfx/ (and, with
--music, game/assets/audio/music/). Every sound is synthesized "sfxr style": a
simple wave (square, saw, triangle, sine or noise) shaped by a volume
envelope, with optional pitch slides, vibrato, an arpeggio jump and a
low-pass filter. Each sound is a short recipe in SOUNDS below, so a sound
can be tuned by editing numbers and rebuilding. The output is the same
every run (random noise uses fixed seeds).

The music is a placeholder until the commissioned tracks arrive: short
chiptune loops written as note lists in music.py. The game plays no music
for now, so it's only built when asked for.
"""
import argparse
import math
import random
import struct
import wave
from pathlib import Path

import music

RATE = 22050
REPO = Path(__file__).resolve().parents[2]
SFX_DIR = REPO / "game" / "assets" / "audio" / "sfx"
MUSIC_DIR = REPO / "game" / "assets" / "audio" / "music"


# ---------- synthesis ----------

def tone(wave="square", freq=440.0, slide=0.0, slide_accel=0.0, duty=0.5,
         attack=0.005, sustain=0.1, decay=0.1, punch=0.0,
         vibrato_depth=0.0, vibrato_speed=0.0, arp_time=0.0, arp_mult=1.0,
         lowpass=1.0, volume=0.5, seed=1):
    """One sfxr-style voice. Times are in seconds, freq in Hz.

    slide: pitch change in octaves per second (negative falls).
    slide_accel: how fast the slide itself changes, octaves/s^2.
    punch: extra volume at the start of the sustain, 0-1.
    arp_time / arp_mult: after arp_time seconds, multiply the pitch (a jump).
    lowpass: 1.0 is open; lower values muffle the sound.
    """
    rnd = random.Random(seed)
    length = attack + sustain + decay
    n = int(length * RATE)
    out = []
    phase = 0.0
    noise = rnd.uniform(-1, 1)
    last_cycle = 0
    filtered = 0.0
    for i in range(n):
        t = i / RATE
        octaves = slide * t + 0.5 * slide_accel * t * t
        f = freq * (2.0 ** octaves)
        if arp_time and t >= arp_time:
            f *= arp_mult
        if vibrato_depth:
            f *= 1.0 + vibrato_depth * math.sin(math.tau * vibrato_speed * t)
        f = max(f, 1.0)
        phase += f / RATE
        cycle = int(phase)
        p = phase - cycle
        if wave == "square":
            s = 1.0 if p < duty else -1.0
        elif wave == "saw":
            s = 2.0 * p - 1.0
        elif wave == "triangle":
            s = 4.0 * abs(p - 0.5) - 1.0
        elif wave == "sine":
            s = math.sin(math.tau * p)
        else:  # noise: a new random level twice per cycle, like sfxr
            half = int(phase * 2)
            if half != last_cycle:
                last_cycle = half
                noise = rnd.uniform(-1, 1)
            s = noise
        # Envelope: attack ramp, sustain (with punch), linear decay.
        if t < attack:
            env = t / attack
        elif t < attack + sustain:
            env = 1.0 + punch * (1.0 - (t - attack) / max(sustain, 1e-6))
        else:
            env = max(0.0, 1.0 - (t - attack - sustain) / max(decay, 1e-6))
        filtered += (s - filtered) * lowpass
        out.append(filtered * env * volume)
    return out


def mix(*voices, gaps=None):
    """Adds voices together; gaps[i] delays voice i by that many seconds."""
    gaps = gaps or [0.0] * len(voices)
    length = max(int(g * RATE) + len(v) for v, g in zip(voices, gaps))
    out = [0.0] * length
    for v, g in zip(voices, gaps):
        start = int(g * RATE)
        for i, s in enumerate(v):
            out[start + i] += s
    return out


def write_wav(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 1.0 if peak <= 0.95 else 0.95 / peak
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples))


# ---------- the sounds ----------

def cluck(seed, pitch=1.0):
    """A chicken's "bok": a short nasal square chirp that drops, twice."""
    a = tone("square", 520 * pitch, slide=-3.0, duty=0.3, attack=0.002, sustain=0.03,
             decay=0.05, lowpass=0.5, volume=0.35, seed=seed)
    b = tone("square", 700 * pitch, slide=-4.0, duty=0.25, attack=0.002, sustain=0.04,
             decay=0.08, vibrato_depth=0.08, vibrato_speed=30, lowpass=0.5, volume=0.4, seed=seed)
    return mix(a, b, gaps=[0.0, 0.07])


SOUNDS = {
    # Player
    "step": lambda: tone("noise", 900, slide=-2.0, attack=0.001, sustain=0.01, decay=0.04,
                         lowpass=0.25, volume=0.35, seed=2),
    "pickup": lambda: tone("square", 660, duty=0.5, attack=0.001, sustain=0.04, decay=0.12,
                           arp_time=0.05, arp_mult=1.5, volume=0.3),
    "throw": lambda: tone("noise", 2400, slide=-3.5, attack=0.01, sustain=0.05, decay=0.12,
                          lowpass=0.35, volume=0.4, seed=3),
    "eat": lambda: mix(*[tone("noise", 1800, attack=0.002, sustain=0.02, decay=0.05,
                              lowpass=0.5, volume=0.4, seed=10 + k) for k in range(3)],
                       tone("square", 330, slide=1.5, duty=0.5, attack=0.01, sustain=0.05,
                            decay=0.15, volume=0.2),
                       gaps=[0.0, 0.11, 0.22, 0.3]),
    "hurt": lambda: mix(tone("square", 300, slide=-4.0, duty=0.5, attack=0.001, sustain=0.06,
                             decay=0.12, punch=0.5, volume=0.4),
                        tone("noise", 1500, attack=0.001, sustain=0.03, decay=0.06,
                             lowpass=0.6, volume=0.35, seed=4)),
    "peck": lambda: tone("noise", 3000, slide=-2.0, attack=0.001, sustain=0.01, decay=0.04,
                         lowpass=0.8, volume=0.4, seed=5),
    "death": lambda: mix(*[tone("square", 392 / (1.26 ** k), duty=0.5, attack=0.005,
                                sustain=0.12, decay=0.1 + 0.3 * (k == 3), volume=0.3)
                           for k in range(4)], gaps=[0.0, 0.18, 0.36, 0.54]),
    # Items and objects
    "key": lambda: mix(*[tone("square", f, duty=0.25, attack=0.002, sustain=0.06, decay=0.12,
                              volume=0.3) for f in (523, 659, 784, 1047)],
                       gaps=[0.0, 0.08, 0.16, 0.24]),
    "spray": lambda: tone("noise", 5000, attack=0.03, sustain=0.25, decay=0.2, lowpass=0.7,
                          vibrato_depth=0.2, vibrato_speed=14, volume=0.3, seed=6),
    "splat": lambda: mix(tone("noise", 700, slide=-2.5, attack=0.001, sustain=0.03, decay=0.15,
                              lowpass=0.3, volume=0.5, seed=7),
                         tone("sine", 180, slide=-2.0, attack=0.001, sustain=0.02, decay=0.08,
                              volume=0.4)),
    "poof": lambda: mix(tone("noise", 1200, slide=2.0, attack=0.002, sustain=0.05, decay=0.3,
                             lowpass=0.4, volume=0.45, seed=8),
                        cluck(9, pitch=1.4), gaps=[0.0, 0.02]),
    "cluck": lambda: cluck(11),
    "shove": lambda: mix(tone("noise", 300, attack=0.005, sustain=0.08, decay=0.15,
                              lowpass=0.2, volume=0.5, seed=12),
                         tone("square", 110, slide=-1.0, duty=0.5, attack=0.002, sustain=0.04,
                              decay=0.08, lowpass=0.3, volume=0.3)),
    "locked": lambda: mix(tone("square", 160, duty=0.5, attack=0.001, sustain=0.06, decay=0.04,
                               lowpass=0.4, volume=0.35),
                          tone("square", 150, duty=0.5, attack=0.001, sustain=0.06, decay=0.08,
                               lowpass=0.4, volume=0.35), gaps=[0.0, 0.12]),
    "unlock": lambda: mix(tone("noise", 4000, attack=0.001, sustain=0.01, decay=0.03,
                               lowpass=0.9, volume=0.4, seed=13),
                          tone("noise", 3000, attack=0.001, sustain=0.01, decay=0.05,
                               lowpass=0.9, volume=0.45, seed=14),
                          tone("square", 880, duty=0.25, attack=0.002, sustain=0.05, decay=0.15,
                               arp_time=0.06, arp_mult=1.335, volume=0.25),
                          gaps=[0.0, 0.08, 0.16]),
    "door": lambda: tone("noise", 400, slide=0.5, attack=0.05, sustain=0.2, decay=0.15,
                         lowpass=0.15, volume=0.45, seed=15),
    "closet": lambda: mix(tone("noise", 250, attack=0.002, sustain=0.03, decay=0.1,
                               lowpass=0.2, volume=0.5, seed=16),
                          tone("square", 90, slide=-0.5, attack=0.001, sustain=0.03,
                               decay=0.06, lowpass=0.3, volume=0.3)),
    "carousel_hum": lambda: carousel_hum(),
    # Security
    "beep": lambda: mix(*[tone("square", 1760, duty=0.5, attack=0.001, sustain=0.06, decay=0.02,
                               lowpass=0.6, volume=0.22) for _ in range(2)], gaps=[0.0, 0.12]),
    "switch": lambda: mix(tone("noise", 3500, attack=0.001, sustain=0.005, decay=0.02,
                               lowpass=0.8, volume=0.4, seed=21),
                          tone("square", 220, slide=-1.0, attack=0.001, sustain=0.02, decay=0.04,
                               lowpass=0.4, volume=0.3), gaps=[0.0, 0.01]),
    "shutter": lambda: mix(*[tone("noise", 900 - 40 * k, attack=0.001, sustain=0.01, decay=0.03,
                                  lowpass=0.35, volume=0.3, seed=22 + k) for k in range(8)],
                           tone("noise", 300, attack=0.001, sustain=0.04, decay=0.2,
                                lowpass=0.2, volume=0.6, seed=31),
                           tone("square", 70, slide=-1.0, attack=0.001, sustain=0.05, decay=0.15,
                                lowpass=0.3, volume=0.35),
                           gaps=[0.035 * k for k in range(8)] + [0.29, 0.29]),
    # Moments
    "checkpoint": lambda: mix(*[tone("square", f, duty=0.5, attack=0.003, sustain=0.08,
                                     decay=0.2, volume=0.25) for f in (392, 523, 659)],
                              gaps=[0.0, 0.1, 0.2]),
    "level_clear": lambda: mix(*[tone("square", f, duty=0.5, attack=0.003, sustain=0.1,
                                      decay=0.1 + 0.4 * (k == 5), volume=0.25)
                                 for k, f in enumerate((523, 523, 659, 784, 659, 1047))],
                               gaps=[0.0, 0.12, 0.24, 0.36, 0.48, 0.6]),
    # Menus
    "ui_move": lambda: tone("square", 880, duty=0.5, attack=0.001, sustain=0.015, decay=0.03,
                            volume=0.2),
    "ui_confirm": lambda: tone("square", 660, duty=0.5, attack=0.001, sustain=0.04, decay=0.1,
                               arp_time=0.04, arp_mult=2.0, volume=0.25),
    "ui_back": lambda: tone("square", 520, slide=-2.0, duty=0.5, attack=0.001, sustain=0.03,
                            decay=0.08, volume=0.22),
}


def carousel_hum():
    """A one-second loop of low motor drone with a soft rattle of belt slats.
    Every part repeats a whole number of times per second, so it loops cleanly."""
    n = RATE
    rnd = random.Random(17)
    out = []
    rattle = 0.0
    for i in range(n):
        t = i / RATE
        drone = 0.5 * math.sin(math.tau * 55 * t) + 0.25 * math.sin(math.tau * 110 * t + 1.0)
        wobble = 1.0 + 0.15 * math.sin(math.tau * 2 * t)
        # Slats clack 8 times a second.
        clack_t = (t * 8) % 1.0
        click = rnd.uniform(-1, 1) * max(0.0, 1.0 - clack_t * 25)
        rattle += (click - rattle) * 0.3
        out.append((drone * wobble * 0.35 + rattle * 0.25))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--music", action="store_true", help="also build the placeholder music")
    args = parser.parse_args()
    for name, make in SOUNDS.items():
        path = SFX_DIR / f"{name}.wav"
        write_wav(path, make())
        print(f"wrote {path.relative_to(REPO)}")
    if not args.music:
        return
    for name, samples in music.tracks(RATE).items():
        path = MUSIC_DIR / f"{name}.wav"
        write_wav(path, samples)
        print(f"wrote {path.relative_to(REPO)} ({len(samples) / RATE:.1f}s loop)")


if __name__ == "__main__":
    main()
