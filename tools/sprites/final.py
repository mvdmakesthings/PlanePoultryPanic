"""Level 5, the Final Departure Gate: dark blues, night windows, and the
supernatural teal glow of the chickens' power.

- tiles_final.png: the area's floor and wall tiles, laid out exactly like
  tiles_arrivals.png so the same text maps and atlas names work.
- night_window.png: 32x24 windows for the wall face at night, 3 frames:
  stars over the dark tarmac, the last plane's lit nose, its tail.
- boss_crown.png: the Supreme Totem's crown, a giant glowing mushroom,
  24x20, 2 frames (glow pulsing).
- vent.png: a 16x12 ceiling-height wall vent, 2 frames (shut, grille
  knocked open as a chicken drops out).
- boarding_door.png: the Gate C13 boarding door, 48x32, 4 frames laid out
  like security_door.png (sealed, unlocked, opening, open), with a pass
  reader.
- plane_door.png: the airplane's door at the end of the jet bridge, 48x32,
  4 frames (closed, closed, opening, open).
- final_litter.png: 16x16 floor decals: teal spore dust, a crushed
  mushroom, a huge feather, a dropped "LAST CALL" sign.
"""
import math
import random

from PIL import Image

import tiles as arrivals
from palette import put, to_image
from set_dressing import _blank, _outline, _rect, _strip, _text, _text_width

SIZE = 16


def _speckle(base, keys, density, seed):
    rnd = random.Random(seed)
    g = [base * SIZE for _ in range(SIZE)]
    for y in range(SIZE):
        for x in range(SIZE):
            if rnd.random() < density:
                put(g, y, x, rnd.choice(keys))
    return g


# --- Tiles ----------------------------------------------------------------

def night_carpet(seed):
    """Deep blue carpet, a faint teal glint here and there."""
    g = _speckle("k", "Bp", 0.12, seed)
    rnd = random.Random(seed + 100)
    if rnd.random() < 0.6:
        put(g, rnd.randrange(SIZE), rnd.randrange(SIZE), "t")
    return g


def dark_tile(seed):
    """Slate tile under night lighting."""
    g = _speckle("p", "k", 0.05, seed)
    for i in range(SIZE):
        put(g, 0, i, "T")
        put(g, i, 0, "T")
        put(g, SIZE - 1, i, "k")
        put(g, i, SIZE - 1, "k")
    return g


def jet_bridge(seed):
    """The jet bridge's ribbed rubber floor."""
    g = _speckle("T", "p", 0.05, seed)
    for y in range(0, SIZE, 4):
        for x in range(SIZE):
            put(g, y, x, "p")
    return g


def arena_pattern(accent, seed):
    """The boarding area's carpet: navy with a teal-glowing diamond."""
    g = _speckle("k", "O", 0.05, seed)
    for y in range(SIZE):
        for x in range(SIZE):
            if abs(x - 8) + abs(y - 8) == 6:
                put(g, y, x, "B")
    put(g, 8, 8, accent)
    return g


def wall_face_upper():
    """Navy panels with a thin glowing teal line."""
    g = ["B" * SIZE] + ["k" * (SIZE - 1) + "O" for _ in range(SIZE - 1)]
    g[9] = "t" * SIZE
    g[10] = "q" * SIZE
    g[11] = "t" * SIZE
    return g


def wall_face_lower():
    g = ["k" * (SIZE - 1) + "O" for _ in range(9)]
    g += ["p" * SIZE, "O" * SIZE] + ["v" * SIZE for _ in range(4)] + ["O" * SIZE]
    return g


def wall_top():
    return ["O" * SIZE for _ in range(SIZE)]


def wall_lip():
    g = wall_top()
    g[14] = "k" * SIZE
    g[15] = "O" * SIZE
    return g


def wall_edge(side):
    g = wall_top()
    for i in range(SIZE):
        if side == "right":
            put(g, i, SIZE - 2, "k")
        elif side == "left":
            put(g, i, 1, "k")
        elif side == "bottom":
            put(g, 1, i, "k")
    return g


def tiles():
    """Same names and order as tiles_arrivals.png: "carpet" is night carpet,
    "tile" dark slate tile, "wood" the jet bridge's ribbed floor, and
    "carpet_pattern" the boarding area's glowing diamond carpet."""
    carpet_a, carpet_b = night_carpet(1), night_carpet(2)
    tile_a, tile_b = dark_tile(3), dark_tile(4)
    bridge_a, bridge_b = jet_bridge(5), jet_bridge(6)
    arena_a, arena_b = arena_pattern("q", 7), arena_pattern("t", 8)
    shade = lambda g: ["".join({"k": "O", "p": "k", "B": "k", "T": "p", "t": "k", "q": "t"}.get(c, c)
                               for c in row) if y < 3 else row for y, row in enumerate(g)]
    return [
        ("carpet_a", carpet_a), ("carpet_b", carpet_b),
        ("tile_a", tile_a), ("tile_b", tile_b),
        ("wood_a", bridge_a), ("wood_b", bridge_b),
        ("carpet_shadow", shade(carpet_a)), ("tile_shadow", shade(tile_a)),
        ("wood_shadow", shade(bridge_a)),
        ("wall_top", wall_top()), ("wall_lip", wall_lip()),
        ("wall_face_upper", wall_face_upper()), ("wall_face_lower", wall_face_lower()),
        ("wall_edge_right", wall_edge("right")), ("wall_edge_left", wall_edge("left")),
        ("wall_edge_bottom", wall_edge("bottom")),
        ("carpet_pattern_a", arena_a), ("carpet_pattern_b", arena_b),
        ("carpet_pattern_shadow", shade(arena_a)),
    ]


def by_name():
    return dict(tiles())


def tiles_sheet():
    items = tiles()
    cols = arrivals.COLUMNS
    rows = (len(items) + cols - 1) // cols
    out = Image.new("RGBA", (cols * SIZE, rows * SIZE), (0, 0, 0, 0))
    for i, (_, grid) in enumerate(items):
        out.alpha_composite(to_image(grid), ((i % cols) * SIZE, (i // cols) * SIZE))
    return out


# --- Night windows --------------------------------------------------------

def night_window(frame):
    """The tarmac at night: stars, runway lights, and in frames 1 and 2 the
    last plane's lit nose and tail (hang them 40 px apart, like window.png)."""
    g = _blank(32, 24)
    _rect(g, 0, 0, 31, 23, "O")
    _rect(g, 1, 1, 30, 20, "O")
    # Sky, horizon, tarmac.
    _rect(g, 2, 2, 29, 11, "k")
    _rect(g, 2, 12, 29, 19, "O")
    rnd = random.Random(frame + 3)
    for _ in range(6):
        put(g, rnd.randrange(2, 11), rnd.randrange(2, 30), "W")
    for x in range(3, 30, 5):
        put(g, 15, x, "Y")
    for x in range(5, 30, 7):
        put(g, 18, x, "b")
    if frame == 1:
        # Nose: a white fuselage with lit cabin windows and the cockpit.
        _rect(g, 8, 9, 29, 15, "W")
        _rect(g, 8, 9, 29, 9, "C")
        _rect(g, 4, 11, 7, 14, "W")
        _rect(g, 5, 10, 8, 11, "p")
        for x in range(12, 29, 3):
            put(g, 12, x, "F")
        _rect(g, 8, 14, 29, 15, "w")
        put(g, 13, 4, "R")
    elif frame == 2:
        _rect(g, 2, 9, 22, 15, "W")
        _rect(g, 2, 9, 22, 9, "C")
        for x in range(3, 18, 3):
            put(g, 12, x, "F")
        # Tail fin.
        for i in range(8):
            _rect(g, 14 + i, 2 + i, 22, 2 + i, "B")
        put(g, 3, 21, "R")
        _rect(g, 2, 14, 22, 15, "w")
    # Frame and sill.
    _rect(g, 0, 21, 31, 23, "p")
    _rect(g, 0, 21, 31, 21, "T")
    return g


def night_window_sheet():
    return _strip([night_window(f) for f in range(3)], 32, 24)


# --- The boss's crown -----------------------------------------------------

def crown(frame):
    """A giant glowing teal mushroom cap with spots, worn like a crown,
    with a halo of spores that pulses between frames."""
    g = _blank(24, 20)
    for y in range(3, 14):
        for x in range(1, 23):
            d = ((x - 11.5) / 11.0) ** 2 + ((y - 13) / 10.0) ** 2
            if d < 1.0 and y < 14:
                put(g, y, x, "t" if d > 0.72 else "q")
    # Highlights and pale spots.
    for x, y in ((6, 6), (12, 4), (17, 7), (9, 10), (15, 11)):
        put(g, y, x, "C")
        put(g, y, x + 1, "W")
    # Stem collar.
    _rect(g, 8, 14, 15, 16, "c")
    _rect(g, 8, 16, 15, 16, "e")
    g = _outline(g)
    # Glowing spores around it (outside the outline).
    spots = ((1, 1), (22, 2), (0, 9), (23, 11)) if frame == 0 else ((3, 0), (20, 0), (1, 13), (22, 15))
    for x, y in spots:
        put(g, y, x, "q")
    return g


def crown_sheet():
    return _strip([crown(f) for f in range(2)], 24, 20)


# --- Vents ----------------------------------------------------------------

def vent(frame):
    g = _blank(16, 12)
    _rect(g, 0, 0, 15, 11, "O")
    _rect(g, 1, 1, 14, 10, "p")
    if frame == 0:
        for y in range(2, 10, 2):
            _rect(g, 2, y, 13, y, "T")
    else:
        # Grille knocked open: dark inside, a feather drifting out.
        _rect(g, 2, 2, 13, 9, "O")
        _rect(g, 2, 9, 13, 10, "T")
        put(g, 6, 7, "C")
        put(g, 7, 8, "c")
    return g


def vent_sheet():
    return _strip([vent(f) for f in range(2)], 16, 12)


# --- Doors ----------------------------------------------------------------

def boarding_door(frame):
    """Gate C13's boarding door: a teal-lit sign, a sliding door to the jet
    bridge and a pass reader. Frame 0 sealed (red, chains of barrier tape),
    1 unlocked (green), 2 opening, 3 open onto the lit jet bridge."""
    W, H = 48, 32
    g = _blank(W, H)
    _rect(g, 2, 0, 45, 9, "O")
    _rect(g, 3, 1, 44, 8, "k")
    _rect(g, 3, 8, 44, 8, "t")
    title = "BOARDING"
    _text(g, (W - _text_width(title)) // 2, 2, title, "q")
    _rect(g, 2, 10, 45, 31, "O")
    _rect(g, 3, 11, 44, 31, "T")
    _rect(g, 3, 11, 44, 11, "W")
    _rect(g, 6, 13, 41, 31, "O")
    _rect(g, 7, 14, 40, 31, "W")
    for y in range(18, 32, 4):
        _rect(g, 7, y, 40, y, "w")
    opening = (0, 0, 9, 17)[frame]
    for side in (-1, 1):
        width = 17 - opening
        if width <= 0:
            continue
        x0, x1 = (7, 7 + width - 1) if side < 0 else (40 - width + 1, 40)
        _rect(g, x0, 14, x1, 31, "B")
        _rect(g, x0, 14, x1, 14, "b")
        edge = x1 if side < 0 else x0
        _rect(g, edge, 14, edge, 31, "O")
    _rect(g, 42, 18, 44, 23, "O")
    put(g, 19, 43, "R" if frame == 0 else "l")
    put(g, 21, 43, "b")
    if frame == 0:
        for x in range(5, 43):
            for y, offset in ((22, 0), (23, 1)):
                put(g, y, x, "q" if (x + offset) // 2 % 2 == 0 else "O")
    return g


def boarding_door_sheet():
    return _strip([boarding_door(f) for f in range(4)], 48, 32)


def plane_door(frame):
    """The airplane's door, seen from the end of the jet bridge: the white
    fuselage with a blue stripe and round windows around a door that swings
    open onto the warm, lit cabin."""
    W, H = 48, 32
    g = _blank(W, H)
    _rect(g, 0, 0, 47, 31, "C")
    _rect(g, 0, 0, 47, 1, "W")
    _rect(g, 0, 22, 47, 23, "B")
    _rect(g, 0, 24, 47, 24, "b")
    for x in (3, 39, 44):
        _rect(g, x, 8, x + 2, 10, "k")
        put(g, 8, x, "b")
    # Door outline and the doorway.
    _rect(g, 10, 2, 37, 31, "w")
    _rect(g, 12, 4, 35, 31, "O")
    _rect(g, 13, 5, 34, 31, "a")
    _rect(g, 13, 5, 34, 7, "F")
    _rect(g, 13, 28, 34, 31, "r")
    # The door itself swings to the right as it opens.
    width = (22, 22, 11, 0)[frame]
    if width:
        _rect(g, 13, 5, 12 + width, 31, "W")
        _rect(g, 13, 5, 12 + width, 5, "C")
        if width > 10:
            _rect(g, 19, 9, 23, 13, "k")
            put(g, 10, 19, "b")
            _rect(g, 28, 18, 30, 18, "T")
        _rect(g, 12 + width, 5, 12 + width, 31, "w")
    # "Welcome aboard" step plate.
    _rect(g, 12, 31, 35, 31, "T")
    return g


def plane_door_sheet():
    return _strip([plane_door(f) for f in range(4)], 48, 32)


def _litter(kind):
    g = _blank(SIZE, SIZE)
    if kind == "spores":
        for x, y in ((3, 4), (8, 2), (12, 6), (5, 10), (10, 12), (13, 11), (2, 13), (7, 7)):
            put(g, y, x, "q" if (x + y) % 3 else "t")
    elif kind == "mushroom":
        _rect(g, 3, 8, 11, 11, "q")
        _rect(g, 3, 8, 11, 8, "C")
        _rect(g, 8, 11, 12, 12, "c")
        put(g, 9, 5, "C")
        g = _outline(g)
    elif kind == "feather":
        for i in range(10):
            put(g, 12 - i // 2, 3 + i, "C")
            put(g, 13 - i // 2, 3 + i, "c" if i % 2 else "W")
        put(g, 13, 2, "e")
        g = _outline(g)
    elif kind == "sign":
        _rect(g, 0, 4, 15, 11, "y")
        _rect(g, 0, 5, 15, 10, "O")
        _text(g, 0, 5, "LAST", "y")
        g = _outline(g)
    return g


LITTER_KINDS = ("spores", "mushroom", "feather", "sign")


def litter_sheet():
    return _strip([_litter(k) for k in LITTER_KINDS], SIZE, SIZE)


def mock_screen():
    t = by_name()
    scr = Image.new("RGBA", (320, 180), (24, 20, 37, 255))
    for row in range(12):
        for col in range(20):
            if row < 4:
                name = ("wall_top", "wall_lip", "wall_face_upper", "wall_face_lower")[row]
            elif row == 4:
                name = "tile_shadow"
            elif 5 <= col <= 14 and 6 <= row <= 10:
                name = "carpet_pattern_" + "ab"[(row + col) % 2]
            else:
                name = "tile_" + "ab"[(row * 7 + col * 3) % 2]
            scr.alpha_composite(to_image(t[name]), (col * 16, row * 16))
    scr.alpha_composite(to_image(night_window(0)), (16, 34))
    scr.alpha_composite(to_image(night_window(1)), (56, 34))
    scr.alpha_composite(to_image(night_window(2)), (96, 34))
    scr.alpha_composite(to_image(boarding_door(1)), (160, 32))
    scr.alpha_composite(to_image(vent(1)), (230, 36))
    scr.alpha_composite(to_image(plane_door(3)), (260, 32))
    scr.alpha_composite(to_image(crown(0)), (148, 90))
    for i, k in enumerate(LITTER_KINDS):
        scr.alpha_composite(to_image(_litter(k)), (40 + 24 * i, 140))
    return scr
