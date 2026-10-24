"""Mushroom patches: 16x16 objects, one row per variety, 3 frames each.

Frames: resting, spores rising, spores drifting higher. Each variety uses
the same cap colors as the chickens that eat it (see chicken.CAP_COLORS).

Sprouts (mushroom_sprout.png) are the buds a patch spreads: 16x16, one
row per variety, 2 frames (a fresh bud, then a bigger one about to ripen).
They sit on the same baseline as a patch, so a ripening sprout swaps
sheets without jumping.
"""
from PIL import Image

from chicken import CAP_COLORS
from palette import put, to_image

VARIETIES = ("flight", "rage", "egg")
SPORE = {"flight": "q", "rage": "F", "egg": "h"}

# X = cap, x = cap shade, S = spot, t = stem, u = stem shade.
PATCH = [
    "................",
    "................",
    "...OOOOO........",
    "..OXXSXXO.......",
    ".OXSXXXSXO......",
    ".OXXXXXXXO......",
    ".OxxxxxxxO..OOO.",
    "...OOtuOO..OXSXO",
    "....OtuO..OxxxxO",
    "....OtuO...OtuO.",
    "....OtuO...OtuO.",
    ".OOO.OtuO..OtuO.",
    "OXSXOtuOjgjOtuOj",
    "jOtOgtugjggtugjj",
    ".jgjggggggjgggj.",
    "..jj.jjjj..jjj..",
]
SPROUTS = [
    [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "......OOOO......",
        ".....OXSXXO.....",
        ".....OxxxxO.....",
        "......OtuO......",
        ".....gOtuOg.....",
        "......jjjj......",
    ],
    [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "......OOOO......",
        ".....OXXSXO.....",
        "....OXSXXXXO....",
        "....OxxxxxxO..O.",
        "......OtuO...OXO",
        "......OtuO...OtO",
        "....jgOtuOgjgOtO",
        ".....jjjjjj.jjj.",
    ],
]
# Spore pixels per frame: (row, col).
SPORES = [[], [(1, 4), (5, 13), (9, 1)], [(0, 6), (3, 12), (7, 0)]]


def patch(variety, frame):
    colors = dict(CAP_COLORS[variety], t="C", u="c")
    g = ["".join(colors.get(ch, ch) for ch in row) for row in PATCH]
    for r, c in SPORES[frame]:
        if g[r][c] == ".":
            put(g, r, c, SPORE[variety])
    return g


def sheet():
    out = Image.new("RGBA", (16 * len(SPORES), 16 * len(VARIETIES)), (0, 0, 0, 0))
    for row, variety in enumerate(VARIETIES):
        for col in range(len(SPORES)):
            out.alpha_composite(to_image(patch(variety, col)), (col * 16, row * 16))
    return out


def sprout(variety, frame):
    colors = dict(CAP_COLORS[variety], t="C", u="c")
    return ["".join(colors.get(ch, ch) for ch in row) for row in SPROUTS[frame]]


def sprout_sheet():
    out = Image.new("RGBA", (16 * len(SPROUTS), 16 * len(VARIETIES)), (0, 0, 0, 0))
    for row, variety in enumerate(VARIETIES):
        for col in range(len(SPROUTS)):
            out.alpha_composite(to_image(sprout(variety, col)), (col * 16, row * 16))
    return out
