"""Placeholder chiptune loops, until the commissioned soundtrack arrives.

Each track is a few channels of note lists, like a tiny tracker:
  lead   - a square wave melody
  bass   - a triangle wave bass line
  chords - a quiet thin square, arpeggiating the chord
  drums  - "k" kick, "s" snare, "h" hat, "." rest, one per step
  clucks - optional: short chicken "bok"s, each tuned to its note

Notes are written like "A4" or "C#5"; "-" holds the previous note and "."
is a rest. Every list is in steps: eighth notes, unless the track sets
"steps_per_beat" (4 makes them sixteenths). The loop length is a whole
number of bars, so tracks loop without a gap.
"""
import math
import random

NOTE_INDEX = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6,
              "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
STEPS_PER_BEAT = 2


def freq(note):
    name, octave = note[:-1], int(note[-1])
    return 440.0 * 2 ** ((NOTE_INDEX[name] + 12 * (octave - 4) - 9) / 12)


def _voice(kind, f, length, rate, volume, duty=0.5):
    """One note, with a quick attack and release so notes never click."""
    n = int(length * rate)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / rate
        phase += f / rate
        p = phase % 1.0
        if kind == "square":
            s = 1.0 if p < duty else -1.0
        elif kind == "triangle":
            s = 4.0 * abs(p - 0.5) - 1.0
        else:
            s = math.sin(math.tau * p)
        env = min(1.0, t / 0.005, (length - t) / 0.02)
        # Lead notes fade a little as they're held, like a plucked chip voice.
        if kind == "square":
            env *= 0.75 + 0.25 * math.exp(-t * 4)
        out.append(s * env * volume)
    return out


def _cluck(f, rate, volume):
    """A short tuned "bok": a nasal square chirp that drops in pitch, with a
    scratchy start, like the cluck sound effect but on a note."""
    rnd = random.Random(int(f))
    n = int(0.09 * rate)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / rate
        phase += f * 2 ** (-t * 7) * (1 + 0.06 * math.sin(math.tau * 35 * t)) / rate
        s = 1.0 if phase % 1.0 < 0.3 else -1.0
        if t < 0.006:
            s = s * 0.5 + rnd.uniform(-1, 1) * 0.5
        env = min(1.0, t / 0.003) * (1 - i / n) ** 1.5
        out.append(s * env * volume)
    return out


def _drum(kind, rate, rnd):
    if kind == "k":
        n = int(0.12 * rate)
        return [math.sin(math.tau * (60 + 120 * math.exp(-i / rate * 30)) * i / rate)
                * (1 - i / n) * 0.6 for i in range(n)]
    if kind == "s":
        n = int(0.1 * rate)
        return [rnd.uniform(-1, 1) * (1 - i / n) ** 2 * 0.3 for i in range(n)]
    n = int(0.03 * rate)
    return [rnd.uniform(-1, 1) * (1 - i / n) * 0.12 for i in range(n)]


def _render_channel(steps, kind, step_len, rate, total, volume, duty=0.5):
    out = [0.0] * total
    i = 0
    while i < len(steps):
        note = steps[i]
        if note in ".-":
            i += 1
            continue
        held = 1
        while i + held < len(steps) and steps[i + held] == "-":
            held += 1
        samples = _voice(kind, freq(note), held * step_len, rate, volume, duty)
        start = int(i * step_len * rate)
        for k, s in enumerate(samples):
            if start + k < total:
                out[start + k] += s
        i += held
    return out


def render(track, rate):
    step_len = 60.0 / track["bpm"] / track.get("steps_per_beat", STEPS_PER_BEAT)
    steps = len(track["lead"])
    total = int(round(steps * step_len * rate))
    channels = [
        _render_channel(track["lead"], "square", step_len, rate, total, 0.16, duty=0.25),
        _render_channel(track["bass"], "triangle", step_len, rate, total, 0.3),
        _render_channel(track["chords"], "square", step_len, rate, total, 0.05, duty=0.125),
    ]
    drums = [0.0] * total
    rnd = random.Random(3)
    for i, hit in enumerate(track["drums"]):
        if hit == ".":
            continue
        start = int(i * step_len * rate)
        for k, s in enumerate(_drum(hit, rate, rnd)):
            if start + k < total:
                drums[start + k] += s
    channels.append(drums)
    clucks = [0.0] * total
    for i, note in enumerate(track.get("clucks", [])):
        if note in ".-":
            continue
        start = int(i * step_len * rate)
        for k, s in enumerate(_cluck(freq(note), rate, 0.22)):
            if start + k < total:
                clucks[start + k] += s
    channels.append(clucks)
    return [sum(c[i] for c in channels) for i in range(total)]


def _seq(text):
    """Space-separated steps; "|" bar lines are ignored."""
    return [s for s in text.split() if s != "|"]


def _arp(chords, steps_per_chord=8):
    """Up-and-down arpeggios through each chord, one note per step."""
    out = []
    for chord in chords:
        notes = chord.split("/")
        pattern = notes + notes[-2:0:-1]
        out += [pattern[i % len(pattern)] for i in range(steps_per_chord)]
    return out


# Arrivals: driving and tense, for an airport after the end of the world.
# E Phrygian (the flat second, F against E, gives it menace) at 144 BPM in
# sixteenths: a pumping octave bass, fast arpeggios, a stabbing lead riff
# that climbs over E-F-E-D, then a second half that soars and ends on a
# tense B major chord that pulls back to the top of the loop.
ARRIVAL_CHORDS = {
    "E": "E3/G3/B3", "F": "F3/A3/C4", "D": "D3/F#3/A3", "G": "G3/B3/D4",
    "C": "C3/E3/G3", "B": "B2/D#3/F#3",
}
ARRIVAL_BARS = "E F E D E F G B E F E D C C B B".split()


def _pump_bass(roots):
    """Sixteenth-note bass: root, root, octave, root, four times a bar."""
    out = []
    for root in roots:
        out += [root + "2", root + "2", root + "3", root + "2"] * 4
    return out


def _drums(bars):
    main = "k.hhs.hkk.hhs.hh"
    fill = "k.hhs.hkk.s.ssss"
    lift = "k.hks.hkk.hks.hk"
    out = ""
    for bar in range(bars):
        if bar % 4 == 3:
            out += fill
        else:
            out += lift if bar >= 8 else main
    return list(out)


ARRIVALS = {
    "bpm": 144,
    "steps_per_beat": 4,
    "lead": _seq("""
        E5 - . E5 . E5 F5 - E5 - D5 - B4 - - - | F5 - . F5 . F5 G5 - F5 - E5 - C5 - - - |
        E5 - . E5 . E5 F5 - E5 - D5 - B4 - - - | D5 - . D5 . D5 E5 - D5 - C5 - A4 - - - |
        E5 - . E5 . E5 F5 - E5 - D5 - B4 - - - | F5 - . F5 . F5 G5 - F5 - E5 - C5 - - - |
        G5 - . G5 . G5 A5 - B5 - - - D6 - - - | B5 - - - A#5 - - - B5 - . B4 B4 - . . |
        B5 - - - - - - - A5 - G5 - F5 - E5 - | F5 - - - - - - - C6 - - - A5 - - - |
        G5 - - - F5 - E5 - D5 - E5 - F5 - G5 - | A5 - - - - - - - F#5 - - - D5 - - - |
        E5 - G5 - C6 - - - B5 - G5 - E5 - - - | C6 - - - B5 - - - G5 - - - E5 - - - |
        D#5 - F#5 - B5 - - - A5 - F#5 - D#5 - - - | B4 - - - D#5 - - - F#5 - - - A5 - B5 - |
    """),
    "bass": _pump_bass(ARRIVAL_BARS),
    "chords": _arp([ARRIVAL_CHORDS[c] for c in ARRIVAL_BARS], steps_per_chord=16),
    "drums": _drums(len(ARRIVAL_BARS)),
    # The flock chimes in on every fill bar.
    "clucks": _seq(" ".join(
        ". " * 12 + ("B4 B4 . E5" if bar % 8 == 3 else "E5 . E5 B4") if bar % 4 == 3 else ". " * 16
        for bar in range(len(ARRIVAL_BARS)))),
}

# Arrivals, sparser take: the same dark E Phrygian, but at 126 BPM in
# eighths with room to breathe: a gapped bass pulse, a slow chord walk, a
# half-time backbeat, and a lead that calls with held notes and answers.
SPARSE_BARS = "E E F F E E D D C C D D E E B B".split()


def _pulse_bass(roots):
    """Eighth-note bass with gaps: root, rest, root, root, rest, root, octave, rest."""
    out = []
    for root in roots:
        low, high = root + "2", root + "3"
        out += [low, ".", low, low, ".", low, high, "."]
    return out


def _chord_walk(names):
    """Quarter notes up and down the chord, one bar per chord."""
    out = []
    for name in names:
        a, b, c = ARRIVAL_CHORDS[name].split("/")
        out += [a, "-", b, "-", c, "-", b, "-"]
    return out


ARRIVALS_SPARSE = {
    "bpm": 126,
    "lead": _seq("""
        E5 - - - - - . . | G5 - F5 - E5 - - - | F5 - - - - - . . | A5 - G5 - F5 - - - |
        B5 - - - - - . . | A5 - G5 - F5 - E5 - | D5 - - - - - - - | . . . . F#5 - A5 - |
        C6 - - - - - . . | B5 - G5 - E5 - - - | D6 - - - - - . . | C6 - A5 - F#5 - - - |
        E5 - - - G5 - B5 - | E6 - - - - - . . | D#6 - - - - - - - | . . . . B5 - - - |
    """),
    "bass": _pulse_bass(SPARSE_BARS),
    "chords": _chord_walk(SPARSE_BARS),
    "drums": list("".join("k.h.s.ss" if bar % 8 == 7 else ("k.h.skh." if bar % 2 else "k.h.s.h.")
                          for bar in range(len(SPARSE_BARS)))),
    # The chickens answer the lead in its gaps: "bok bok" at the end of a
    # held note, and a little riff in the breaks.
    "clucks": _seq("""
        . . . . . . E5 E5 | . . . . . . . . | . . . . . . F5 F5 | . . . . . . . . |
        . . . . . . B4 B4 | . . . . . . . . | . . . . . . . . | D5 . D5 F#5 . . . . |
        . . . . . . E5 E5 | . . . . . . . . | . . . . . . D5 D5 | . . . . . . . . |
        . . . . . . . . | . . . . . . B4 E5 | . . . . . . . . | B4 . B4 D#5 . . . . |
    """),
}

# Main menu: upbeat and adventurous with a comic edge. C major, bouncy
# octave bass, a melody with little "bok bok" grace notes.
MENU = {
    "bpm": 132,
    "lead": _seq("""
        C5 - E5 - G5 - E5 - | A5 - G5 - E5 - . . | F5 - A5 - G5 - E5 - | D5 - - - . . G4 G4 |
        C5 - E5 - G5 - C6 - | B5 - A5 - G5 - . . | F5 - E5 - D5 - B4 - | C5 - - - - - . . |
        E5 E5 . E5 . C5 E5 - | G5 - - - G4 - - - | C5 - . G4 . . E4 - | A4 - B4 - A#4 A4 - . |
        G4 E5 - G5 A5 - F5 G5 | . E5 - C5 D5 B4 - . | C5 - E5 - G5 - E5 - | C5 - - - . . . . |
    """),
    "bass": _seq("""
        C3 C4 C3 C4 C3 C4 C3 C4 | A2 A3 A2 A3 A2 A3 A2 A3 | F2 F3 F2 F3 F2 F3 F2 F3 | G2 G3 G2 G3 G2 G3 G2 G3 |
        C3 C4 C3 C4 C3 C4 C3 C4 | A2 A3 A2 A3 A2 A3 A2 A3 | F2 F3 F2 F3 G2 G3 G2 G3 | C3 C4 C3 C4 C3 C4 C3 C4 |
        C3 C4 C3 C4 C3 C4 C3 C4 | E2 E3 E2 E3 E2 E3 E2 E3 | A2 A3 A2 A3 A2 A3 A2 A3 | F2 F3 F2 F3 F2 F3 F2 F3 |
        G2 G3 G2 G3 G2 G3 G2 G3 | G2 G3 G2 G3 G2 G3 G2 G3 | C3 C4 C3 C4 C3 C4 C3 C4 | C3 C4 C3 C4 G2 G3 G2 G3 |
    """),
    "chords": _arp(["C4/E4/G4", "A3/C4/E4", "F3/A3/C4", "G3/B3/D4",
                    "C4/E4/G4", "A3/C4/E4", "F3/A3/C4", "C4/E4/G4",
                    "C4/E4/G4", "E3/G3/B3", "A3/C4/E4", "F3/A3/C4",
                    "G3/B3/D4", "G3/B3/D4", "C4/E4/G4", "C4/E4/G4"]),
    "drums": list("k.h.s.h.k.k.s.h." * 8),
}


def tracks(rate):
    """Track name -> samples, one loop each."""
    chosen = {"arrivals": ARRIVALS, "arrivals_sparse": ARRIVALS_SPARSE, "menu": MENU}
    for name, track in chosen.items():
        lengths = {len(track[k]) for k in ("lead", "bass", "chords", "drums", "clucks") if k in track}
        assert len(lengths) == 1, f"{name}: channels differ in length {lengths}"
    return {name: render(track, rate) for name, track in chosen.items()}
