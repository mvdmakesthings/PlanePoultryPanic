"""Secrets and easter eggs (see the Secrets section of the GDD).

- secret_doors.png: 16x32 hidden entrances for the wall face, one row per
  kind, 2 frames (closed, open). Rows: 0 cracked panel with feathers
  poking out (Arrivals), 1 staff door with a crooked sign (Security),
  2 frosted freezer panel (Food Court), 3 emergency exit propped open
  with a feather (Gates), 4 pecked-open vent (Final Gate).
- mural.png: 80x28 chicken wall paintings for a secret room's back wall,
  one frame per panel of the story (5), numbered with claw tallies.
- tiles_freezer.png: the Cluck Shack's walk-in freezer (Food Court secret
  room), laid out like tiles_arrivals.png: frosted diamond-plate floor,
  insulated steel walls with icicles.
- freezer_shelf.png: a 32x32 wire rack of iced-over frozen food, a floor prop.
- freezer_decor.png: 16x16, one per frame: 0 a wall thermometer reading
  freezing, 1 and 2 frost patches for the floor.
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
import random

from PIL import Image

import chicken
import ending
import items
import tiles
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

MURAL_W, MURAL_H = 80, 28
# Figures for the chickens' wall paintings, in palette keys ("." is bare
# wall). They're drawn like the game's own sprites, chunky and outlined,
# so each panel reads at a glance. All face right; flip for left.
FIGURES = {
    "chicken": [
        ".....R....",
        "....RRR...",
        "....CCCC..",
        "....CvCCY.",
        "C...CCCCYY",
        "CC..CCCR..",
        "CCCCCCCC..",
        "CCCCCCCc..",
        ".cCCCCcc..",
        "..cccc....",
        "...Y.Y....",
        "..YY.YY...",
    ],
    # A chicken pecking at the ground, head down.
    "pecking": [
        "C.........",
        "CC........",
        "CCCCCC....",
        "CCCCCCCC..",
        ".cCCCCCCC.",
        "..ccCCCvCR",
        "...Y.CCCCR",
        "..YY..RYY.",
    ],
    "chick": [
        "...R..",
        "..CvY.",
        "C.CCY.",
        "CCCC..",
        ".cCc..",
        "..Y...",
    ],
    "plane": [
        "BB......................",
        "BBB.....................",
        "BBBB....................",
        ".BBWWWWWWWWWWWWWWWWWW...",
        ".WWWbWbWbWbWbWbWbWbWWWW.",
        "..WWWWWWWWWWWWWWWWWWWbbW",
        "...wwwwwwwwwwwwwwwwwwww.",
        "........TTTTT...........",
        "......TTTTT.............",
    ],
    "mini_plane": [
        "B......",
        "BTTTTT.",
        ".TTTTTB",
        "..BB...",
    ],
    "barn": [
        "...RRRR...",
        "..RRRRRR..",
        ".RRRCCRRR.",
        "RRRRRRRRRR",
        ".CCCCCCCC.",
        ".CRrRRrRC.",
        ".CrRRRRrC.",
        ".CRrRRrRC.",
        ".CrRRRRrC.",
    ],
    "fence": [
        "n.n.n.n.n",
        "nnnnnnnnn",
        "n.n.n.n.n",
        "nnnnnnnnn",
        "n.n.n.n.n",
    ],
    "drum": [
        "rRRRr",
        "RRYRR",
        "rrrrr",
        "RRRRR",
        "rrrrr",
        "RRRRR",
        "rRRRr",
    ],
    "drum_tipped": [
        "rRrRrRr",
        "RRrRrYR",
        "RRrRrRR",
        "rRrRrRr",
    ],
    "mushroom": [
        ".qqqq.",
        "qqCqqq",
        "qqqqCq",
        "..CC..",
        "..CC..",
    ],
    "red_mushroom": [
        ".RRRR.",
        "RCRRCR",
        "..CC..",
        "..CC..",
    ],
    "purple_mushroom": [
        ".HHHH.",
        "HHhHHH",
        "..CC..",
        "..CC..",
    ],
    "tower": [
        "..TTTTTT..",
        ".kkkkkkkk.",
        "kbbkbbkbbk",
        "kbbkbbkbbk",
        "TTTTTTTTTT",
        "..wWWWWw..",
        "...wWWw...",
        "...wWWw...",
        "...wWWw...",
        "...wWWw...",
        "...wWWw...",
        "...wWWw...",
        "...wWWw...",
        "..wwWWww..",
    ],
    "flag": [
        "Rrrr",
        "RCCr",
        "Rrrr",
        "n...",
        "n...",
        "n...",
    ],
    "captain_hat": [
        "..kkkk..",
        ".kkYYkk.",
        "kkkkkkkk",
        "...NNNNN",
    ],
    # A parked plane facing left, its cabin door open behind the nose.
    "plane_door": [
        "........................BBB.",
        ".......................BBBB.",
        "......................BBBBB.",
        "...WWWWWWWWWWWWWWWWWWWWWWBB.",
        ".WWWWWOOOOWbWbWbWbWbWbWbWWW.",
        "WbbWWWOkkOWWWWWWWWWWWWWWWWW.",
        "WWWWWWOkkOWWWWWWWWWWWWWWWW..",
        ".wwwwwOkkOwwwwwwwwwwwwwwww..",
        "..wwwwOOOOwwwwwwwwwwwww.....",
        ".............TTTTTT.........",
        "...............TTTTTT.......",
    ],
    "stairs": [
        "......ww",
        ".....wW.",
        "....wW..",
        "...wW...",
        "..wW....",
        ".wW.....",
        "wW......",
    ],
}


def _figure(g, name, x, y, flip=False, swap=None):
    """Paint a figure onto g (no outline; see _figures)."""
    for dy, row in enumerate(FIGURES[name]):
        if flip:
            row = row[::-1]
        for dx, key in enumerate(row):
            if key != "." and 0 <= y + dy < len(g) and 0 <= x + dx < len(g[0]):
                put(g, y + dy, x + dx, (swap or {}).get(key, key))


def _layer(g, figures):
    """Paint figures on their own layer, outline them, and lay it over g.
    Each figure is (name, x, y), optionally followed by flip and a dict of
    key swaps."""
    top = _blank(MURAL_W, MURAL_H)
    for name, x, y, *rest in figures:
        flip = rest[0] if rest else False
        swap = rest[1] if len(rest) > 1 else None
        _figure(top, name, x, y, flip, swap)
    top = _outline(top)
    for y, row in enumerate(top):
        for x, key in enumerate(row):
            if key != ".":
                put(g, y, x, key)


def mural(panel):
    g = _blank(MURAL_W, MURAL_H)
    # A rough patch of whitewash on the wall, edges uneven, with a dark
    # border of smeared paint so it stands out from the wall behind.
    _rect(g, 0, 0, MURAL_W - 1, MURAL_H - 1, "v")
    _rect(g, 1, 1, MURAL_W - 2, MURAL_H - 2, "c")
    for x in range(2, MURAL_W - 2, 6):
        _px(g, x, 0, ".")
        _px(g, x + 3, MURAL_H - 1, ".")
    for y in (5, 13, 20):
        _px(g, 0, y, ".")
        _px(g, MURAL_W - 1, y + 2, ".")
    # Each panel is numbered in the corner, scratched in with a claw,
    # so the story can be read in order.
    for i in range(panel + 1):
        _rect(g, 3 + i * 2, 2, 3 + i * 2, 4, "e")
    if panel == 0:
        # Chickens on a farm stare up at a plane, wishing they could fly.
        _rect(g, 1, 22, MURAL_W - 2, MURAL_H - 2, "l")
        for x in range(2, MURAL_W - 2, 4):
            _px(g, x, 22, "g")
        _layer(g, [
            ("barn", 3, 13),
            ("fence", 14, 18), ("fence", 22, 18), ("fence", 30, 18),
            ("chicken", 16, 12), ("chicken", 29, 12),
            ("plane", 52, 3),
        ])
        # Both chickens look up: beaks tilted toward the plane.
        for x in (24, 37):
            _px(g, x, 15, ".")
        # A thought bubble: a little plane, the thing they want.
        _rect(g, 36, 3, 48, 9, "O")
        _rect(g, 37, 4, 47, 8, "C")
        _figure(g, "mini_plane", 39, 4)
        _px(g, 34, 10, "C"); _px(g, 33, 11, "C")
        _px(g, 34, 9, "O"); _px(g, 35, 10, "O"); _px(g, 32, 11, "O"); _px(g, 33, 12, "O")
        # The plane's contrail.
        for x in range(44, 52, 2):
            _px(g, x, 6, "W")
    elif panel == 1:
        # Fuel drums leak by a country runway; glowing mushrooms sprout.
        _rect(g, 1, 23, MURAL_W - 2, MURAL_H - 2, "p")
        for x in range(4, MURAL_W - 4, 6):
            _rect(g, x, 24, x + 2, 24, "C")
        _layer(g, [
            ("drum", 4, 15), ("drum", 10, 15), ("drum_tipped", 15, 18),
            ("plane", 54, 13),
        ])
        # The leak: a glowing puddle spreading from the tipped drum.
        _rect(g, 22, 21, 42, 22, "q")
        _rect(g, 24, 20, 38, 20, "q")
        _layer(g, [
            ("mushroom", 25, 15), ("mushroom", 32, 13), ("mushroom", 39, 16),
        ])
        for x, y in [(24, 11), (30, 9), (36, 8), (42, 12), (28, 6), (38, 4)]:
            _px(g, x, y, "q")
        # Warning drops dripping from the drum.
        _px(g, 21, 21, "q"); _px(g, 22, 19, "q")
    elif panel == 2:
        # One chicken eats a glowing mushroom; its eyes glow, and the whole
        # flock lights up with it, linked.
        glow = {"v": "q"}
        _layer(g, [
            ("pecking", 3, 17, False, glow),
            ("mushroom", 13, 20),
        ])
        # Its eye glows.
        for x, y in [(10, 20), (11, 21), (9, 21)]:
            _px(g, x, y, "q")
        # Waves of glow rolling out from the first chicken to the flock.
        for r in (5, 8, 11):
            for dy in range(-r, r + 1):
                if 2 <= 17 + dy <= MURAL_H - 3:
                    _px(g, 22 + int((r * r - dy * dy) ** 0.5), 17 + dy, "q")
        flock = []
        for i, x in enumerate(range(38, 76, 8)):
            flock.append(("chick", x, 4 if i % 2 else 12, False, glow))
            flock.append(("chick", x + 3, 20, False, glow))
        _layer(g, flock)
    elif panel == 3:
        # The chickens hold the control tower (their flag on top), and plant
        # mushrooms in the airport carpet.
        _rect(g, 1, 22, MURAL_W - 2, MURAL_H - 2, "t")
        for x in range(3, MURAL_W - 2, 4):
            _px(g, x, 24, "y")
            _px(g, x + 2, 26, "b")
        _layer(g, [
            ("tower", 4, 8),
            ("flag", 12, 2),
        ])
        # A chicken's head in each window of the cab.
        for x in (5, 8, 11):
            _px(g, x + 1, 10, "R")
            _rect(g, x, 11, x + 1, 11, "C")
        _layer(g, [
            ("red_mushroom", 18, 18), ("chicken", 24, 10), ("mushroom", 36, 17),
            ("pecking", 42, 14), ("purple_mushroom", 53, 18),
            ("chicken", 60, 10), ("red_mushroom", 71, 18),
        ])
    else:
        # A chicken in a captain's hat climbs the stairs to a plane's door.
        _rect(g, 1, 24, MURAL_W - 2, MURAL_H - 2, "p")
        _layer(g, [
            ("plane_door", 48, 9),
            ("stairs", 46, 18),
            ("chicken", 33, 12),
            ("captain_hat", 36, 9),
        ])
        # Footprints leading up to the stairs.
        for x in (4, 10, 16, 22):
            _px(g, x, 25, "v"); _px(g, x + 1, 26, "v")
            _px(g, x + 2, 25, "v")
    return g


def mural_sheet():
    return _strip([mural(p) for p in range(5)], MURAL_W, MURAL_H)


# --- The walk-in freezer ------------------------------------------------------

TILE = 16


def _frost(g, density, seed, keys="CW"):
    rnd = random.Random(seed)
    for y in range(len(g)):
        for x in range(len(g[0])):
            if g[y][x] != "." and rnd.random() < density:
                _px(g, x, y, rnd.choice(keys))


def _diamond_plate(seed):
    """Steel diamond-plate floor: raised dashes in a checker of 4px cells,
    alternating direction by row, lightly frosted."""
    g = ["w" * TILE for _ in range(TILE)]
    for cy in range(0, TILE, 4):
        for cx in range(0, TILE, 4):
            if (cx // 4 + cy // 4) % 2:
                continue
            if cy // 4 % 2:
                _px(g, cx + 1, cy + 2, "W"); _px(g, cx + 2, cy + 1, "W")
            else:
                _px(g, cx + 1, cy + 1, "W"); _px(g, cx + 2, cy + 2, "W")
    _frost(g, 0.025, seed, "C")
    return g


def _freezer_wall_top():
    return ["p" * TILE for _ in range(TILE)]


def _freezer_wall_lip():
    g = _freezer_wall_top()
    g[13] = "W" * TILE
    g[14] = "T" * TILE
    g[15] = "O" * TILE
    return g


def _freezer_face_upper():
    """Insulated white panels, frosted, with icicles hanging off the top."""
    g = ["W" * 7 + "w" + "W" * 7 + "w" for _ in range(TILE)]
    _frost(g, 0.18, 21, "C")
    icicles = {1: 4, 4: 2, 6: 5, 10: 3, 13: 6}
    for x in range(TILE):
        _px(g, x, 0, "C")
        _px(g, x, 1, "C")
        for y in range(2, 2 + icicles.get(x, 0)):
            _px(g, x, y, "C" if y < 1 + icicles[x] else "b")
    return g


def _freezer_face_lower():
    """Riveted steel kick plate, rimed with frost, down to the baseboard."""
    g = ["W" * 7 + "w" + "W" * 7 + "w" for _ in range(6)]
    _frost(g, 0.12, 22, "C")
    g += ["T" * TILE]
    g += ["w" * TILE for _ in range(6)]
    for x in (3, 11):
        _px(g, x, 9, "W")
        _px(g, x, 10, "T")
    g += ["C" * TILE, "T" * TILE, "O" * TILE]
    _px(g, 5, 13, "W"); _px(g, 12, 13, "W")
    return g


def _freezer_wall_edge(side):
    g = _freezer_wall_top()
    for i in range(TILE):
        if side == "right":
            _px(g, TILE - 2, i, "W"); _px(g, TILE - 1, i, "O")
        elif side == "left":
            _px(g, 1, i, "W"); _px(g, 0, i, "O")
        elif side == "bottom":
            _px(g, i, 1, "W"); _px(g, i, 0, "O")
    return g


def freezer_tiles():
    """The Cluck Shack's walk-in freezer: laid out like tiles_arrivals.png,
    with every floor the same frosted diamond plate (the room only uses one)
    and steel-and-frost walls."""
    plate_a, plate_b = _diamond_plate(31), _diamond_plate(32)
    floors = [
        ("carpet_a", plate_a), ("carpet_b", plate_b),
        ("tile_a", plate_a), ("tile_b", plate_b),
        ("wood_a", plate_a), ("wood_b", plate_b),
        ("carpet_shadow", tiles.shadowed(plate_a)), ("tile_shadow", tiles.shadowed(plate_a)),
        ("wood_shadow", tiles.shadowed(plate_a)),
    ]
    walls = [
        ("wall_top", _freezer_wall_top()), ("wall_lip", _freezer_wall_lip()),
        ("wall_face_upper", _freezer_face_upper()), ("wall_face_lower", _freezer_face_lower()),
        ("wall_edge_right", _freezer_wall_edge("right")), ("wall_edge_left", _freezer_wall_edge("left")),
        ("wall_edge_bottom", _freezer_wall_edge("bottom")),
    ]
    patterns = [
        ("carpet_pattern_a", plate_a), ("carpet_pattern_b", plate_b),
        ("carpet_pattern_shadow", tiles.shadowed(plate_a)),
    ]
    return floors + walls + patterns


def freezer_tiles_sheet():
    items = freezer_tiles()
    cols = tiles.COLUMNS
    rows = (len(items) + cols - 1) // cols
    out = Image.new("RGBA", (cols * TILE, rows * TILE), (0, 0, 0, 0))
    for i, (_, grid) in enumerate(items):
        out.alpha_composite(to_image(grid), ((i % cols) * TILE, (i // cols) * TILE))
    return out


SHELF_W, SHELF_H = 32, 32


def freezer_shelf():
    """A wire rack of frozen food, iced over: boxes of nuggets, a bag of
    peas, a tub of ice cream, icicles hanging off the shelves."""
    g = _blank(SHELF_W, SHELF_H)
    # Uprights and three wire shelves.
    for x in (1, SHELF_W - 2):
        _rect(g, x, 1, x, SHELF_H - 1, "w")
    for y in (10, 20, 29):
        _rect(g, 1, y, SHELF_W - 2, y, "W")
        for x in range(2, SHELF_W - 2, 3):
            _px(g, x, y + 1, "T")
    # Top shelf: boxes of frozen nuggets (yellow with a red band).
    for x in (3, 11, 19):
        _rect(g, x, 3, x + 6, 9, "Y")
        _rect(g, x, 5, x + 6, 6, "R")
        _rect(g, x, 3, x + 6, 3, "F")
    # Middle shelf: a green bag of peas and a stack of pink tubs.
    _rect(g, 3, 13, 12, 19, "g")
    _rect(g, 4, 12, 11, 12, "g")
    _rect(g, 5, 15, 10, 16, "l")
    for x in (15, 22):
        _rect(g, x, 14, x + 5, 19, "h")
        _rect(g, x, 14, x + 5, 14, "C")
        _rect(g, x + 1, 16, x + 4, 17, "H")
    # Bottom shelf: white boxes with a blue snowflake.
    for x in (3, 13, 22):
        _rect(g, x, 23, x + 7, 28, "C")
        _px(g, x + 3, 25, "b"); _px(g, x + 4, 25, "b")
        _px(g, x + 3, 26, "b"); _px(g, x + 4, 26, "b")
        _px(g, x + 2, 24, "b"); _px(g, x + 5, 27, "b")
    # Frost on everything, and icicles under each shelf.
    _frost(g, 0.08, 41, "C")
    for y in (10, 20):
        for x in (4, 9, 17, 26):
            _px(g, x, y + 1, "C")
            _px(g, x, y + 2, "C")
    return _outline(g)


def freezer_shelf_sheet():
    return to_image(freezer_shelf())


DECOR = 16


def freezer_decor(frame):
    """Small freezer pieces, one per frame: 0 a wall thermometer with its
    needle deep in the blue, 1 and 2 frost patches for the floor."""
    g = _blank(DECOR, DECOR)
    if frame == 0:
        for y in range(DECOR):
            for x in range(DECOR):
                d = ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5
                if d < 6.5:
                    _px(g, x, y, "C")
                elif d < 7.5:
                    _px(g, x, y, "w")
        # The cold half of the dial is blue; the needle points into it.
        for y in range(3, 13):
            for x in range(2, 8):
                if g[y][x] == "C" and ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5 > 3.5:
                    _px(g, x, y, "b")
        for x, y in [(7, 7), (6, 6), (5, 6), (4, 5)]:
            _px(g, x, y, "R")
        _px(g, 8, 8, "O")
        # Frost on the dial's rim.
        for x, y in [(4, 1), (5, 1), (11, 2), (12, 3), (2, 11)]:
            _px(g, x, y, "C")
        return _outline(g)
    rnd = random.Random(50 + frame)
    for y in range(DECOR):
        for x in range(DECOR):
            d = ((x - 8) / 7.0) ** 2 + ((y - 9) / 4.5) ** 2
            if d < 1.0 and rnd.random() < 1.2 - d:
                _px(g, x, y, "C" if d < 0.5 or rnd.random() < 0.5 else "W")
    return g


def freezer_decor_sheet():
    return _strip([freezer_decor(f) for f in range(3)], DECOR, DECOR)


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
