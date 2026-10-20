"""Level 4, the Gate Areas: teal carpet and orange departure-board accents.

- tiles_gates.png: the area's floor and wall tiles, laid out exactly like
  tiles_arrivals.png so the same text maps and atlas names work.
- walkway.png: moving-walkway pieces, 16x16. Rows: top-left end, top
  middle, top-right end, bottom-left end, bottom middle, bottom-right end.
  Columns: 4 frames of the belt creeping east (the game plays them
  backward for a westbound belt). Ends don't move; only use column 0.
- speed_panel.png: a 12x14 walkway control panel, 3 frames (slow, normal,
  full).
- gate_desk.png: a 32x24 gate podium with a monitor, a floor prop.
- gate_doors.png: closed 48x32 boarding gates for the wall face, one per
  frame: A1, A2, B4, B5, C8, C9.
- final_gate_door.png: a 48x32 door to the last gate in the back wall, 4
  frames laid out like security_door.png (closed, closed, opening, open).
- gates_litter.png: 16x16 floor decals: a nest with an egg, scattered
  boarding passes, a pecked neck pillow, a spilled coffee.
"""
import random

from PIL import Image

import gate
import tiles as arrivals
from palette import put, to_image
from set_dressing import _blank, _outline, _rect, _strip, _text, _text_width

SIZE = 16


# --- Tiles ----------------------------------------------------------------

def _speckle(base, keys, density, seed):
    rnd = random.Random(seed)
    g = [base * SIZE for _ in range(SIZE)]
    for y in range(SIZE):
        for x in range(SIZE):
            if rnd.random() < density:
                put(g, y, x, rnd.choice(keys))
    return g


def teal_carpet(seed):
    return _speckle("t", "jk", 0.14, seed)


def teal_pattern(accent, seed):
    """Gate-lounge carpet: an orange-dotted teal grid."""
    g = _speckle("t", "k", 0.05, seed)
    for i in range(SIZE):
        put(g, 0, i, "j")
        put(g, i, 0, "j")
    for x, y in ((8, 8), (0, 0)):
        put(g, y, x, accent)
    put(g, 4, 12, "D")
    put(g, 12, 4, "D")
    return g


def wall_face_upper():
    """Pale gray panels with an orange departure-board stripe."""
    g = ["C" * SIZE] + ["W" * (SIZE - 1) + "w" for _ in range(SIZE - 1)]
    g[9] = "y" * SIZE
    g[10] = "D" * SIZE
    return g


def wall_face_lower():
    g = ["W" * (SIZE - 1) + "w" for _ in range(9)]
    g += ["w" * SIZE, "T" * SIZE] + ["t" * SIZE for _ in range(4)] + ["O" * SIZE]
    return g


def tiles():
    """Same names and order as tiles_arrivals.png: "carpet" is teal carpet,
    "tile" the Arrivals terminal tile, "wood" honey planks, and
    "carpet_pattern" the lounges' teal grid carpet."""
    carpet_a, carpet_b = teal_carpet(1), teal_carpet(2)
    tile_a, tile_b = arrivals.hard_tile(3), arrivals.hard_tile(4)
    wood_a, wood_b = arrivals.wood((5, None, 12, None), 5), arrivals.wood((None, 3, None, 9), 6)
    grid_a, grid_b = teal_pattern("y", 7), teal_pattern("Y", 8)
    shade = lambda g: ["".join({"t": "O", "j": "t", "k": "O"}.get(c, c) for c in row) if y < 3 else row
                       for y, row in enumerate(g)]
    return [
        ("carpet_a", carpet_a), ("carpet_b", carpet_b),
        ("tile_a", tile_a), ("tile_b", tile_b),
        ("wood_a", wood_a), ("wood_b", wood_b),
        ("carpet_shadow", shade(carpet_a)), ("tile_shadow", arrivals.shadowed(tile_a)),
        ("wood_shadow", arrivals.shadowed(wood_a)),
        ("wall_top", arrivals.wall_top()), ("wall_lip", arrivals.wall_lip()),
        ("wall_face_upper", wall_face_upper()), ("wall_face_lower", wall_face_lower()),
        ("wall_edge_right", arrivals.wall_edge("right")), ("wall_edge_left", arrivals.wall_edge("left")),
        ("wall_edge_bottom", arrivals.wall_edge("bottom")),
        ("carpet_pattern_a", grid_a), ("carpet_pattern_b", grid_b),
        ("carpet_pattern_shadow", shade(grid_a)),
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


# --- Moving walkway -------------------------------------------------------

WALKWAY_FRAMES = 4


def _walkway_piece(half, piece, frame):
    """One 16x16 piece. half is "top" or "bottom" of the 2-tile belt; piece
    is "left", "middle" or "right". The top half has the far handrail along
    its top edge; the bottom half has the near handrail and a skirt along
    its bottom edge. The belt is dark rubber with light slats 8 px apart,
    shifted 2 px a frame; the ends are steel comb plates."""
    g = _blank(SIZE, SIZE)
    belt_rows = range(4, 16) if half == "top" else range(0, 12)
    for y in belt_rows:
        for x in range(SIZE):
            if piece == "middle":
                slat = (x - frame * 2) % 8 == 0
                g_key = "T" if slat else ("k" if y % 2 else "p")
            else:
                # Comb plate: brushed steel with grooves running along the belt.
                g_key = "w" if y % 3 else "T"
                if (piece == "left" and x > 12) or (piece == "right" and x < 3):
                    g_key = "Y" if (x + y) % 4 < 2 else "O"
            put(g, y, x, g_key)
    if half == "top":
        # Far handrail: a black rubber rail on a glass side panel.
        _rect(g, 0, 0, 15, 0, "O")
        _rect(g, 0, 1, 15, 1, "k")
        _rect(g, 0, 2, 15, 2, "W")
        _rect(g, 0, 3, 15, 3, "T")
    else:
        _rect(g, 0, 12, 15, 12, "T")
        _rect(g, 0, 13, 15, 13, "W")
        _rect(g, 0, 14, 15, 14, "k")
        _rect(g, 0, 15, 15, 15, "O")
    # Rounded rail ends.
    if piece == "left":
        for y in range(SIZE):
            if g[y][0] != ".":
                put(g, y, 0, "O")
    elif piece == "right":
        for y in range(SIZE):
            if g[y][15] != ".":
                put(g, y, 15, "O")
    return g


def walkway_sheet():
    out = Image.new("RGBA", (SIZE * WALKWAY_FRAMES, SIZE * 6), (0, 0, 0, 0))
    for row, (half, piece) in enumerate((h, p) for h in ("top", "bottom") for p in ("left", "middle", "right")):
        for frame in range(WALKWAY_FRAMES):
            if piece != "middle" and frame:
                continue
            out.alpha_composite(to_image(_walkway_piece(half, piece, frame)), (frame * SIZE, row * SIZE))
    return out


def speed_panel(frame):
    """A wall control box with a three-step dial and a light: green slow,
    yellow normal, red full."""
    g = _blank(12, 14)
    _rect(g, 1, 1, 10, 12, "w")
    _rect(g, 1, 1, 10, 1, "W")
    _rect(g, 10, 2, 10, 12, "T")
    _rect(g, 3, 3, 8, 8, "k")
    # Dial marks and the needle pointing at this speed.
    for x in (3, 5, 8):
        put(g, 3, x, "W")
    needle = ((4, 6), (5, 5), (7, 6))[frame]
    put(g, needle[1], needle[0], "C")
    put(g, 7, 5, "C")
    put(g, 6, 5 if frame != 2 else 6, "C")
    _rect(g, 4, 10, 7, 11, ("l", "Y", "R")[frame])
    return _outline(g)


def speed_panel_sheet():
    return _strip([speed_panel(f) for f in range(3)], 12, 14)


# --- Gate furniture -------------------------------------------------------

def gate_desk():
    """A gate agent's podium: a teal-fronted desk with a monitor and a
    boarding-pass printer. The base (about 28x6) is solid."""
    g = _blank(32, 24)
    _rect(g, 2, 8, 29, 21, "t")
    _rect(g, 2, 8, 29, 9, "W")
    _rect(g, 2, 10, 29, 10, "w")
    _rect(g, 29, 10, 29, 21, "O")
    _rect(g, 4, 13, 27, 14, "y")
    _rect(g, 4, 15, 27, 15, "D")
    _rect(g, 3, 22, 28, 22, "k")
    # Monitor (back facing us) and printer on top.
    _rect(g, 6, 1, 15, 7, "k")
    _rect(g, 7, 2, 14, 6, "p")
    _rect(g, 10, 7, 11, 7, "T")
    _rect(g, 19, 4, 25, 7, "W")
    _rect(g, 20, 3, 24, 3, "C")
    return _outline(g)


GATE_LABELS = ("GATE A1", "GATE A2", "GATE B4", "GATE B5", "GATE C8", "GATE C9")


def _relabel(g, title, ink="y"):
    _rect(g, 4, 0, 43, 9, "O")
    _rect(g, 5, 1, 42, 8, "k")
    _text(g, (48 - _text_width(title)) // 2, 3, title, ink)
    return g


def gate_doors_sheet():
    """Closed boarding gates with their numbers, for set dressing."""
    frames = []
    for i, title in enumerate(GATE_LABELS):
        g = _relabel(gate.door(0), title)
        # A red "closed" light on the sign instead of a boarding light.
        put(g, 4, 40, "R")
        frames.append(g)
    return _strip(frames, 48, 32)


def final_gate_door(frame):
    """The door on to the last flight's gate, laid out like
    security_door.png: frames 0 and 1 closed, 2 opening, 3 open."""
    g = gate.door((0, 0, 2, 3)[frame])
    return _relabel(g, "GATE C13", "F")


def final_gate_sheet():
    return _strip([final_gate_door(f) for f in range(4)], 48, 32)


def _litter(kind):
    g = _blank(SIZE, SIZE)
    if kind == "nest":
        for y in range(8, 14):
            for x in range(2, 14):
                if ((x - 7.5) / 5.5) ** 2 + ((y - 11) / 2.6) ** 2 < 1.0:
                    put(g, y, x, "a" if (x + y) % 3 else "n")
        _rect(g, 5, 9, 9, 11, "m")
        _rect(g, 6, 7, 8, 10, "C")
        put(g, 7, 6, "c")
        put(g, 6, 12, "C")
        g = _outline(g)
    elif kind == "passes":
        for x0, y0 in ((2, 5), (8, 9), (4, 11)):
            _rect(g, x0, y0, x0 + 5, y0 + 2, "C")
            _rect(g, x0, y0, x0 + 1, y0 + 2, "b")
            put(g, y0 + 1, x0 + 4, "O")
    elif kind == "pillow":
        for y in range(5, 12):
            for x in range(2, 14):
                d = ((x - 8) / 6) ** 2 + ((y - 8.5) / 3.5) ** 2
                if 0.25 < d < 1.0:
                    put(g, y, x, "h")
        _rect(g, 7, 10, 9, 11, "C")
        put(g, 6, 4, "C")
        g = _outline(g)
    elif kind == "coffee":
        for y in range(8, 14):
            for x in range(3, 15):
                if ((x - 9) / 5.5) ** 2 + ((y - 11) / 2.5) ** 2 < 1.0:
                    put(g, y, x, "m")
        _rect(g, 2, 6, 6, 9, "C")
        _rect(g, 2, 7, 6, 7, "n")
        g = _outline(g)
    return g


LITTER_KINDS = ("nest", "passes", "pillow", "coffee")


def litter_sheet():
    return _strip([_litter(k) for k in LITTER_KINDS], SIZE, SIZE)


def mock_screen():
    """A 320x180 gate-area scene for previews: the lounge wall, a walkway."""
    t = by_name()
    scr = Image.new("RGBA", (320, 180), (38, 43, 68, 255))
    for row in range(12):
        for col in range(20):
            if row < 4:
                name = ("wall_top", "wall_lip", "wall_face_upper", "wall_face_lower")[row]
            elif row == 4:
                name = "carpet_shadow"
            elif row < 8:
                name = "carpet_pattern_" + "ab"[(row + col) % 2]
            else:
                name = "carpet_" + "ab"[(row + col) % 2]
            scr.alpha_composite(to_image(t[name]), (col * 16, row * 16))
    sheet = walkway_sheet()
    for i in range(14):
        piece = 0 if i == 0 else 2 if i == 13 else 1
        for half in (0, 1):
            tile = sheet.crop((0, (half * 3 + piece) * 16, 16, (half * 3 + piece + 1) * 16))
            scr.alpha_composite(tile, (32 + i * 16, 128 + half * 16))
    scr.alpha_composite(gate_doors_sheet().crop((0, 0, 48, 32)), (16, 32))
    scr.alpha_composite(final_gate_sheet().crop((144, 0, 192, 32)), (200, 32))
    scr.alpha_composite(to_image(speed_panel(2)), (100, 40))
    scr.alpha_composite(to_image(gate_desk()), (120, 80))
    for i, k in enumerate(LITTER_KINDS):
        scr.alpha_composite(to_image(_litter(k)), (180 + 20 * i, 96))
    return scr
