"""Secrets and easter eggs (see the Secrets section of the GDD).

- secret_doors.png: 16x32 hidden entrances for the wall face, one row per
  kind, 2 frames (closed, open). Rows: 0 cracked panel with feathers
  poking out (Arrivals), 1 staff door with a crooked sign (Security),
  2 frosted freezer panel (Food Court), 3 emergency exit propped open
  with a feather (Gates), 4 pecked-open vent (Final Gate).
- mural.png: 48x24 chicken cave paintings for a secret room's back wall,
  one frame per panel of the story (5).
- pilot_cap.png: 16x16, the hidden Pilot Cap mushroom patch, 3 frames
  like mushroom_patch.png (resting, spores, spores higher), with a
  propeller frill that turns.
- secret_stashes.png: 16x16, one row per kind, 2 frames (full, searched).
  Rows: 0 CONFISCATED bin, 1 the chickens' snack hoard, 2 Amanda's own
  bag (tagged PP404 / 13C).
- suitcase_fragile.png: the FRAGILE suitcase, laid out like suitcase.png
  (14x16, lying, burst); it bursts into snacks instead of clothes.
- posters.png: 40x32 wall posters, one per frame: DO NOT EAT THE CARPET
  MUSHROOMS, THIS PLANTER IS NOT A FARM, BAWK WAS HERE scratched into
  the wall (no poster behind it), and the Cluck Shack's secret recipe.
- fuel_drum.png: a 16x24 leaking fuel drum, a floor prop, 2 frames of the
  glowing puddle pulsing.
- captain_hat.png: 16x16, a captain's hat hanging on a wall peg.
- captain_chicken.png: 16x16 chicken in a pilot's cap, 2 idle frames.
- stowaway_captain.png: the ending's stowaway window (laid out like
  stowaway.png) with the chicken wearing the captain's hat.
"""
from PIL import Image

import chicken
import ending
import items
from mushrooms import PATCH, SPORES
from palette import put, to_image
from set_dressing import _blank, _outline, _rect, _strip, _text, _text_width

DOOR_W, DOOR_H = 16, 32
DOOR_KINDS = ("cracked", "staff", "frost", "exit", "vent")


def _px(g, x, y, key):
    put(g, y, x, key)


# --- Secret doors -----------------------------------------------------------

def _dark_hole(g, x0, y0, x1, y1):
    _rect(g, x0, y0, x1, y1, "O")
    _rect(g, x0 + 1, y0 + 1, x1 - 1, y1, "v")


def door(kind, opened):
    g = _blank(DOOR_W, DOOR_H)
    if kind == "cracked":
        # A wall panel, cracked open by pecking. Feathers poke out.
        _rect(g, 1, 4, 14, 31, "O")
        _rect(g, 2, 5, 13, 31, "w")
        _rect(g, 2, 5, 13, 5, "W")
        if opened:
            _dark_hole(g, 3, 10, 12, 31)
            for x, y, key in [(4, 29, "Y"), (6, 30, "y"), (9, 29, "Y"), (11, 30, "y"), (5, 27, "C")]:
                _px(g, x, y, key)
        else:
            for x, y in [(7, 6), (8, 7), (7, 8), (6, 9), (7, 10), (8, 11), (9, 12), (8, 13),
                         (7, 14), (8, 15), (9, 16), (10, 17), (9, 18), (8, 19), (7, 20)]:
                _px(g, x, y, "O")
            for x, y in [(6, 12), (5, 13), (10, 15), (11, 15), (6, 21), (5, 22), (9, 21)]:
                _px(g, x, y, "O")
            # Feathers sticking out of the crack.
            for x, y in [(9, 11), (10, 10), (6, 16), (5, 15), (8, 21), (9, 22), (10, 22)]:
                _px(g, x, y, "C")
            _px(g, 11, 9, "c")
    elif kind == "staff":
        # A plain slate door with a STAFF ONLY sign hanging crooked.
        _rect(g, 1, 2, 14, 31, "O")
        _rect(g, 2, 3, 13, 31, "p" if not opened else "O")
        if opened:
            _dark_hole(g, 2, 3, 13, 31)
            _rect(g, 2, 3, 3, 31, "i")
        else:
            _rect(g, 2, 3, 13, 3, "i")
            _px(g, 11, 18, "F")
            _px(g, 11, 19, "y")
        # The sign: red, one corner dropped (hung by one screw).
        for i, y in enumerate(range(7, 12)):
            _rect(g, 3 + (i // 2), y, 12, y, "R")
        _rect(g, 3, 6, 9, 6, "O")
        _rect(g, 4, 9, 11, 9, "C")
        _px(g, 12, 12, "r")
        _px(g, 4, 6, "G")
    elif kind == "frost":
        # A steel freezer panel, frost creeping out around its edges.
        _rect(g, 1, 4, 14, 31, "O")
        _rect(g, 2, 5, 13, 31, "W")
        _rect(g, 2, 5, 13, 5, "L")
        _rect(g, 12, 6, 13, 31, "w")
        if opened:
            _rect(g, 3, 8, 12, 31, "O")
            _rect(g, 4, 9, 11, 31, "k")
            for x, y in [(5, 12), (9, 15), (6, 20), (10, 24), (7, 28)]:
                _px(g, x, y, "b")
        else:
            _rect(g, 4, 16, 6, 18, "w")
            _px(g, 5, 17, "O")
        # Frost along the bottom and the corners, whichever frame.
        for x, y in [(0, 31), (1, 30), (2, 30), (3, 31), (5, 30), (7, 31), (10, 30), (12, 31),
                     (14, 30), (15, 31), (1, 6), (14, 7), (0, 29), (15, 28)]:
            _px(g, x, y, "L")
        for x, y in [(4, 31), (8, 30), (11, 31), (13, 29)]:
            _px(g, x, y, "b")
    elif kind == "exit":
        # A green emergency exit under a lit EXIT sign, a feather wedged in it.
        _rect(g, 0, 0, 15, 6, "O")
        _rect(g, 1, 1, 14, 5, "j")
        _text(g, 1, 1, "EXIT", "l")
        _rect(g, 1, 8, 14, 31, "O")
        _rect(g, 2, 9, 13, 31, "g")
        _rect(g, 2, 9, 13, 9, "l")
        if opened:
            _dark_hole(g, 4, 10, 13, 31)
            _rect(g, 2, 10, 3, 31, "j")
        else:
            _rect(g, 3, 19, 12, 19, "C")
            _rect(g, 3, 20, 12, 20, "w")
            _rect(g, 12, 9, 13, 31, "j")
            # The feather propping it open a crack.
            _px(g, 13, 30, "C")
            _px(g, 14, 31, "C")
            _px(g, 14, 29, "c")
            _rect(g, 13, 10, 13, 29, "O")
    elif kind == "vent":
        # A vent low on the wall, its grille pecked through.
        _rect(g, 1, 17, 14, 30, "O")
        if opened:
            _dark_hole(g, 2, 18, 13, 30)
            # The grille hangs off one screw.
            for i in range(5):
                _px(g, 12 + (i % 2), 25 + i, "w")
            _px(g, 4, 29, "C")
        else:
            _rect(g, 2, 18, 13, 29, "w")
            for y in (20, 23, 26):
                _rect(g, 3, y, 12, y, "O")
            # Peck holes and a stray feather.
            for x, y in [(5, 21), (9, 24), (6, 27), (10, 21)]:
                _px(g, x, y, "v")
            _px(g, 13, 28, "C")
            _px(g, 14, 29, "C")
        _px(g, 2, 18, "G")
    return g


def doors_sheet():
    out = Image.new("RGBA", (DOOR_W * 2, DOOR_H * len(DOOR_KINDS)), (0, 0, 0, 0))
    for row, kind in enumerate(DOOR_KINDS):
        for col in range(2):
            out.alpha_composite(to_image(door(kind, col == 1)), (col * DOOR_W, row * DOOR_H))
    return out


# --- The mural ---------------------------------------------------------------

MURAL_W, MURAL_H = 48, 24
# Crude stamps for the chickens' cave paintings ("#" is the paint color).
GLYPHS = {
    "chicken": [".#..", "###.", ".###", ".##.", ".#.#"],
    "plane": ["#.......", "##..#...", "########", "....#...", "...#...."],
    "mushroom": [".###.", "#####", "..#..", "..#.."],
    "drum": ["###", "#.#", "###", "#.#", "###"],
    "tower": [".###.", "#####", "..#..", "..#..", "..#..", ".###."],
    "fence": ["#.#.#.#", "#######", "#.#.#.#"],
    "hat": [".###.", "#####"],
    "eye": ["#"],
    "door": ["###", "#.#", "#.#", "#.#"],
}


def _stamp(g, name, x, y, key, flip=False):
    for dy, row in enumerate(GLYPHS[name]):
        if flip:
            row = row[::-1]
        for dx, bit in enumerate(row):
            if bit == "#":
                put(g, y + dy, x + dx, key)


def mural(panel):
    g = _blank(MURAL_W, MURAL_H)
    # A rough patch of paint on the wall, edges uneven.
    _rect(g, 1, 1, MURAL_W - 2, MURAL_H - 2, "c")
    for x in range(1, MURAL_W - 3, 5):
        _px(g, x, 1, ".")
        _px(g, x + 2, MURAL_H - 2, ".")
    for y in (4, 11, 17):
        _px(g, 1, y, ".")
        _px(g, MURAL_W - 2, y + 2, ".")
    for x, y in [(6, 4), (30, 18), (41, 6), (17, 15)]:
        _px(g, x, y, "a")
    if panel == 0:
        # Chickens behind a farm fence, staring up at a plane.
        _stamp(g, "plane", 26, 3, "k")
        for x in (5, 11, 17):
            _stamp(g, "chicken", x, 13, "v")
            _px(g, x + 1, 13, "R")
        _stamp(g, "fence", 3, 18, "m")
        _stamp(g, "fence", 10, 18, "m")
        _stamp(g, "fence", 17, 18, "m")
        # Little "!!" of jealousy.
        _px(g, 13, 9, "R")
        _px(g, 13, 11, "R")
        _px(g, 15, 9, "R")
        _px(g, 15, 11, "R")
    elif panel == 1:
        # Fuel drums leaking by a runway; glowing mushrooms sprout.
        _stamp(g, "drum", 5, 13, "r")
        _stamp(g, "drum", 9, 13, "r")
        for x in range(4, 44, 3):
            _px(g, x, 20, "k")
        _stamp(g, "mushroom", 16, 15, "q")
        _stamp(g, "mushroom", 23, 14, "q")
        _stamp(g, "mushroom", 30, 16, "q")
        for x, y in [(14, 19), (13, 18), (18, 12), (25, 11), (32, 13)]:
            _px(g, x, y, "q")
        _stamp(g, "plane", 34, 4, "k")
    elif panel == 2:
        # One chicken eats; its eyes glow, and a whole flock lights up.
        _stamp(g, "mushroom", 5, 15, "q")
        _stamp(g, "chicken", 10, 14, "v", flip=True)
        _px(g, 10, 14, "q")
        for i, x in enumerate(range(18, 44, 5)):
            y = 5 if i % 2 else 11
            _stamp(g, "chicken", x, y, "v")
            _px(g, x + 1, y, "q")
        for x, y in [(15, 12), (16, 10), (17, 8)]:
            _px(g, x, y, "q")
    elif panel == 3:
        # The control tower taken, mushrooms in the carpet.
        _stamp(g, "tower", 6, 5, "k")
        _stamp(g, "chicken", 7, 2, "v")
        _px(g, 8, 2, "R")
        for x in range(4, 44):
            _px(g, x, 16, "t")
        for x in (16, 23, 30, 37):
            _stamp(g, "mushroom", x, 12, "R" if x % 2 else "H")
            _stamp(g, "chicken", x + 1, 17, "v")
    else:
        # A chicken in a captain's hat walks up to a plane's door.
        _stamp(g, "plane", 26, 8, "k")
        for x in range(25, 44):
            _px(g, x, 10, "k")
        _stamp(g, "door", 34, 7, "a")
        _stamp(g, "chicken", 22, 13, "v")
        _stamp(g, "hat", 22, 11, "B")
        _px(g, 24, 12, "Y")
        # Footprints leading up to it.
        for x in (6, 10, 14, 18):
            _px(g, x, 18, "v")
            _px(g, x + 1, 19, "v")
    return g


def mural_sheet():
    return _strip([mural(p) for p in range(5)], MURAL_W, MURAL_H)


# --- The Pilot Cap -------------------------------------------------------------

PILOT_COLORS = {"X": "F", "x": "Y", "S": "C", "t": "C", "u": "c"}


def pilot_cap(frame):
    g = ["".join(PILOT_COLORS.get(ch, ch) for ch in row) for row in PATCH]
    for r, c in SPORES[frame]:
        if g[r][c] == ".":
            put(g, r, c, "F")
    # The propeller frill on top of the big cap, turning.
    put(g, 1, 5, "O")
    blades = ["WW.WW", ".W.W.", "..W.."][frame]
    for i, ch in enumerate(blades):
        if ch != ".":
            put(g, 0, 3 + i, ch)
    put(g, 0, 5, "y")
    return g


def pilot_cap_sheet():
    return _strip([pilot_cap(f) for f in range(3)], 16, 16)


# --- Stashes ---------------------------------------------------------------

STASH_KINDS = ("confiscated", "hoard", "amanda_bag")


def stash(kind, searched):
    g = _blank(16, 16)
    if kind == "confiscated":
        # A gray security bin, stamped CONFISCATED in red (a red band).
        _rect(g, 1, 7, 14, 14, "O")
        _rect(g, 2, 8, 13, 13, "w")
        _rect(g, 2, 8, 13, 8, "W")
        _rect(g, 3, 10, 12, 11, "R")
        _rect(g, 4, 10, 4, 11, "C")
        _rect(g, 7, 10, 7, 11, "C")
        _rect(g, 10, 10, 10, 11, "C")
        if searched:
            # A rubber chicken, a tiny hat and a "suspicious" egg.
            _rect(g, 3, 3, 6, 7, "Y")
            _px(g, 4, 2, "R")
            _px(g, 7, 5, "y")
            _rect(g, 9, 5, 12, 5, "B")
            _rect(g, 10, 4, 11, 4, "B")
            _rect(g, 8, 6, 9, 7, "C")
        else:
            _rect(g, 3, 6, 12, 7, "k")
            _px(g, 6, 6, "Y")
            _px(g, 10, 6, "C")
    elif kind == "hoard":
        # A straw nest heaped with stolen snack bags.
        _rect(g, 1, 10, 14, 14, "O")
        _rect(g, 2, 10, 13, 13, "y")
        for x in range(2, 14, 2):
            _px(g, x, 11, "Y")
            _px(g, x + 1, 13, "m")
        if not searched:
            for x, y, key in [(3, 6, "R"), (4, 6, "R"), (3, 7, "r"), (4, 7, "r"), (3, 8, "R"), (4, 8, "R"),
                              (7, 5, "b"), (8, 5, "b"), (7, 6, "B"), (8, 6, "B"), (7, 7, "b"), (8, 7, "b"),
                              (7, 8, "B"), (8, 8, "B"), (11, 6, "F"), (12, 6, "F"), (11, 7, "Y"),
                              (12, 7, "Y"), (11, 8, "F"), (12, 8, "F"), (5, 9, "l"), (6, 9, "l"),
                              (9, 9, "R"), (10, 9, "R")]:
                _px(g, x, y, key)
            g = _outline(g)
        else:
            for x, y in [(4, 9), (8, 9), (11, 9), (6, 10)]:
                _px(g, x, y, "a")
    else:
        # Amanda's suitcase from her cancelled flight, a big white tag on it.
        frame = items.suitcase_frame(searched)
        for y, row in enumerate(frame):
            put(g, y, 1, "".join("H" if ch == "g" else "d" if ch == "j" else ch for ch in row))
        if not searched:
            _rect(g, 9, 5, 14, 9, "O")
            _rect(g, 10, 6, 13, 8, "C")
            _px(g, 11, 7, "B")
            _px(g, 12, 7, "B")
    return g


def stashes_sheet():
    out = Image.new("RGBA", (32, 16 * len(STASH_KINDS)), (0, 0, 0, 0))
    for row, kind in enumerate(STASH_KINDS):
        for col in range(2):
            out.alpha_composite(to_image(stash(kind, col == 1)), (col * 16, row * 16))
    return out


def fragile_suitcase():
    w, h = items.SUITCASE_SIZE
    out = Image.new("RGBA", (w * 2, h), (0, 0, 0, 0))
    lying = items.suitcase_frame(False)
    # FRAGILE stickers: red labels with a white stripe.
    for x0, y0 in [(1, 5), (6, 9)]:
        _rect(lying, x0, y0, x0 + 4, y0 + 2, "R")
        _rect(lying, x0 + 1, y0 + 1, x0 + 3, y0 + 1, "C")
    burst = items.suitcase_frame(True)
    # Snacks fly out instead of clothes.
    for x, y, key in [(2, 5, "R"), (3, 5, "R"), (2, 6, "r"), (3, 6, "r"),
                      (7, 4, "b"), (8, 4, "b"), (7, 5, "B"), (8, 5, "B"),
                      (10, 7, "F"), (11, 7, "F"), (10, 8, "Y"), (11, 8, "Y"),
                      (5, 8, "l"), (6, 8, "l")]:
        put(burst, y, x, key)
    out.alpha_composite(to_image(lying), (0, 0))
    out.alpha_composite(to_image(burst), (w, 0))
    return out


# --- Posters ---------------------------------------------------------------

POSTER_W, POSTER_H = 40, 32
POSTERS = [
    (["DO NOT", "EAT THE", "CARPET", "MUSHROOMS"], "C", "R", "R"),
    (["THIS", "PLANTER", "IS NOT", "A FARM"], "F", "v", "y"),
    (["BAWK", "WAS", "HERE"], None, "p", None),
    (["SECRET", "RECIPE", "", "1. RUN."], "C", "v", "b"),
]


def poster(frame):
    lines, paper, ink, trim = POSTERS[frame]
    g = _blank(POSTER_W, POSTER_H)
    if paper:
        _rect(g, 0, 0, POSTER_W - 1, POSTER_H - 1, "O")
        _rect(g, 1, 1, POSTER_W - 2, POSTER_H - 2, paper)
        _rect(g, 1, 1, POSTER_W - 2, 1, trim)
        _rect(g, 1, POSTER_H - 2, POSTER_W - 2, POSTER_H - 2, trim)
        # Tape at the top corners.
        _px(g, 1, 0, "W")
        _px(g, POSTER_W - 2, 0, "W")
    top = (POSTER_H - len(lines) * 6) // 2 + 1
    for i, line in enumerate(lines):
        _text(g, (POSTER_W - _text_width(line)) // 2, top + i * 6, line, ink)
    if not paper:
        # Scratched in: a few stray gouges, and a chicken's footprint.
        for x, y in [(6, 4), (7, 5), (31, 26), (32, 27), (33, 26)]:
            _px(g, x, y, ink)
    return g


def posters_sheet():
    return _strip([poster(f) for f in range(len(POSTERS))], POSTER_W, POSTER_H)


# --- Fuel drum, captain's hat, captain chicken -------------------------------

def fuel_drum(frame):
    g = _blank(16, 24)
    # Glowing teal puddle at the base.
    _rect(g, 1, 20, 14, 22, "q" if frame == 0 else "b")
    _rect(g, 3, 21, 9, 21, "b" if frame == 0 else "q")
    # The drum: rusty red with ribs and a hazard band.
    _rect(g, 3, 3, 12, 21, "O")
    _rect(g, 4, 4, 11, 20, "R")
    _rect(g, 4, 4, 11, 4, "e")
    _rect(g, 10, 5, 11, 20, "r")
    for y in (8, 16):
        _rect(g, 4, y, 11, y, "r")
    _rect(g, 4, 11, 11, 13, "F")
    for x in (5, 8, 11):
        _px(g, x, 12, "O")
    # A glowing drip running down from the bung.
    _px(g, 6, 5, "q")
    _px(g, 6, 6, "q")
    _px(g, 6, 9 + frame, "q")
    return g


def fuel_drum_sheet():
    return _strip([fuel_drum(f) for f in range(2)], 16, 24)


CAPTAIN_HAT = [
    "................",
    "................",
    "....OOOOOOOO....",
    "...OBBBBBBBBO...",
    "...OBBBYYBBBO...",
    "...OBBYFFYBBO...",
    "...OWWWWWWWWO...",
    "..OOOOOOOOOOOO..",
    "..OkkkkkkkkkkO..",
    "...OOOOOOOOOO...",
    ".......OO.......",
    ".......Ov.......",
    ".......Ov.......",
    "......OvvO......",
    "................",
    "................",
]


def captain_hat():
    return to_image(CAPTAIN_HAT)


def captain_chicken(frame):
    g = list(chicken.idle_cycle()["down"][frame])
    # A pilot's cap where the comb was: navy crown, gold badge, black peak.
    put(g, 0, 4, "OOOOOOOO")
    put(g, 1, 3, "OBBBYBBBBO")
    put(g, 2, 3, "OWWWWWWWWO")
    put(g, 3, 3, "OkkkkkkkkO")
    return g


def captain_chicken_sheet():
    return _strip([captain_chicken(f) for f in range(2)], 16, 16)


def stowaway_captain(frame):
    g = ending.stowaway(frame)
    if frame > 0:
        # The captain's hat from the crew room, on over the comb.
        _rect(g, 5, 3, 10, 4, "B")
        _px(g, 7, 3, "Y")
        _px(g, 8, 3, "Y")
        _rect(g, 4, 5, 11, 5, "W")
    return g


def stowaway_captain_sheet():
    return _strip([stowaway_captain(f) for f in range(3)], 16, 16)
