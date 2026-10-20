"""Effects: the feather poof a chicken leaves when it's defeated."""
import math

from PIL import Image

from palette import put, to_image

POOF_SIZE = 24
POOF_FRAMES = 6
# Puff radius per frame; the feathers fly outward and drift down.
PUFF_RADIUS = [4, 6, 6, 5, 3, 0]
FEATHER_ANGLES = [i * math.tau / 8 + 0.3 for i in range(8)]


def poof_frame(i):
    g = ["." * POOF_SIZE for _ in range(POOF_SIZE)]
    cx = cy = POOF_SIZE // 2
    r = PUFF_RADIUS[i]
    for y in range(POOF_SIZE):
        for x in range(POOF_SIZE):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if r and d < r - 1:
                put(g, y, x, "C" if d < r - 2.5 else "c")
            elif r and d < r and i < 3:
                put(g, y, x, "O")
    # Feathers: 2px streaks flying out, falling a little more each frame.
    dist = 3 + i * 1.8
    for k, a in enumerate(FEATHER_ANGLES):
        x = round(cx + math.cos(a) * dist)
        y = round(cy + math.sin(a) * dist + i * i * 0.25)
        tip = "c" if i < 4 else "w"
        for dx, ch in ((0, "C" if i < 4 else "c"), (1 if k % 2 else -1, tip)):
            if 0 <= x + dx < POOF_SIZE and 0 <= y < POOF_SIZE:
                put(g, y, x + dx, ch)
    # A bit of red comb flies up for comic effect.
    if 1 <= i <= 3:
        put(g, cy - 4 - i * 2, cx + 1, "R")
    return g


def poof():
    out = Image.new("RGBA", (POOF_SIZE * POOF_FRAMES, POOF_SIZE), (0, 0, 0, 0))
    for i in range(POOF_FRAMES):
        out.alpha_composite(to_image(poof_frame(i)), (i * POOF_SIZE, 0))
    return out


# ---------- particles ----------
# effects_particles.png: 8x8 frames, one row per kind, 4 columns. Rows whose
# kind "animates" play their columns over the particle's life (dust, foam,
# spark, sparkle); the rest are 4 variants the game picks from at random
# (feather, crumb, egg, confetti). The particle's position is the frame's
# center. Small bits have no outline, so they read as effects, not pickups.
PARTICLE_SIZE = 8
PARTICLE_KINDS = ["dust", "feather", "crumb", "foam", "egg", "spark", "sparkle", "confetti"]


def _centered(pattern):
    """Pads a small pattern (list of strings) into the middle of an 8x8 frame."""
    h, w = len(pattern), max(len(r) for r in pattern)
    top, left = (PARTICLE_SIZE - h) // 2, (PARTICLE_SIZE - w) // 2
    g = ["." * PARTICLE_SIZE for _ in range(PARTICLE_SIZE)]
    for y, row in enumerate(pattern):
        put(g, top + y, left, row.ljust(w, "."))
    return g


PARTICLES = {
    # A puff kicked up by a running foot: swells, breaks up, fades to specks.
    # Mid gray with white highlights, so it shows on light tile and dark carpet.
    "dust": [
        [".ww.", "wLWw", ".ww."],
        [".wL.", "wLWw", "wwWw", ".ww."],
        ["w.L..", "wW..w", ".w.Ww", "..w.."],
        ["w..w", "....", "..w."],
    ],
    # Loose feathers: white vanes, cream shading at the quill.
    "feather": [
        ["....Lc", "..LLc.", ".LLc..", "cc...."],
        [".LLLc.", "cLLLLc"],
        [".L.", "LLc", "LLc", ".Lc", ".c."],
        ["..Lc", ".Lc.", "c..."],
    ],
    # Chip crumbs.
    "crumb": [
        ["YY", "Yy"],
        ["Y"],
        ["FY.", "YYy"],
        ["y", "Y"],
    ],
    # Foam left on the floor: a puddle that shrinks away.
    "foam": [
        ["..LLW.", ".LLLLW", "WLLWww", ".Www.."],
        [".LLW", "LLWw", ".Ww."],
        ["L.W", ".W.", "W.."],
        ["L.", ".W"],
    ],
    # Egg bits: shell shards and yolk drops.
    "egg": [
        ["LL", "Lc"],
        ["FY", "YY"],
        ["L.", "cL"],
        ["Y"],
    ],
    # A spark off metal: a bright star that cools and shrinks.
    "spark": [
        ["..F..", ".FLF.", "FLLLF", ".FLF.", "..F.."],
        [".Y.", "YFY", ".Y."],
        ["y.", ".Y"],
        ["y"],
    ],
    # A twinkle: grows into a cross, then shrinks.
    "sparkle": [
        ["L"],
        [".F.", "FLF", ".F."],
        ["..F..", "..L..", "FLLLF", "..L..", "..F.."],
        [".F.", "FLF", ".F."],
    ],
    # Confetti: one bit per color.
    "confetti": [
        ["bb", "bB"],
        ["RR", "r."],
        ["ll.", ".lg"],
        ["FY"],
    ],
}


def particles():
    s = PARTICLE_SIZE
    out = Image.new("RGBA", (s * 4, s * len(PARTICLE_KINDS)), (0, 0, 0, 0))
    for row, kind in enumerate(PARTICLE_KINDS):
        for col, pattern in enumerate(PARTICLES[kind]):
            out.alpha_composite(to_image(_centered(pattern)), (col * s, row * s))
    return out
