"""Level 3, the Food Court: warm yellows and oranges with restaurant colors.

- tiles_food_court.png: the area's floor and wall tiles, laid out exactly
  like tiles_arrivals.png so the same text maps and atlas names work.
- restaurant_fronts.png: 64x32 restaurant fronts for the wall face, one per
  frame: CLUCK SHACK, PIZZA PLANE, NOODLE GATE, JAVA JET.
- food_table.png: a 32x24 round table with two chairs, a floor prop.
- vending_machine.png: a 20x30 snack machine, 2 frames (stocked, emptied).
- trash_bin.png: a 12x16 overflowing trash bin, a floor prop.
- food_litter.png: 16x16 floor decals: spilled fries, a soda puddle, a
  dropped tray, a burger wrapper.
- gates_door.png: a 48x32 door to the gates in the back wall, 4 frames laid
  out like security_door.png (closed, closed, opening, open).
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


def checker(seed):
    """Cream and butterscotch checkerboard floor, 8px squares, scuffed."""
    rnd = random.Random(seed)
    g = []
    for y in range(SIZE):
        g.append("".join("c" if (x // 8 + y // 8) % 2 == 0 else "a" for x in range(SIZE)))
    for _ in range(5):
        x, y = rnd.randrange(SIZE), rnd.randrange(SIZE)
        put(g, y, x, "e" if g[y][x] == "a" else "a")
    return g


def warm_carpet(seed):
    """Rust-orange carpet around the restaurant fronts."""
    return _speckle("n", "em", 0.12, seed)


def honey_wood(joints, seed):
    """The seating plaza's wood, the same honey planks as Arrivals."""
    return arrivals.wood(joints, seed)


def diner_carpet(accent, seed):
    """Red diner carpet with a lattice of yellow dots."""
    g = _speckle("r", "v", 0.05, seed)
    for cx, cy in ((4, 4), (12, 12)):
        for y in range(SIZE):
            for x in range(SIZE):
                if abs(x - cx) + abs(y - cy) == 3:
                    put(g, y, x, "R")
        put(g, cy, cx, accent)
    return g


def wall_top():
    return ["m" * SIZE for _ in range(SIZE)]


def wall_lip():
    g = wall_top()
    g[14] = "n" * SIZE
    g[15] = "O" * SIZE
    return g


def wall_face_upper():
    """Cream plaster with an orange stripe."""
    g = ["C" * SIZE] + ["c" * (SIZE - 1) + "e" for _ in range(SIZE - 1)]
    g[9] = "Y" * SIZE
    g[10] = "y" * SIZE
    return g


def wall_face_lower():
    """Terracotta tiles down to a dark baseboard."""
    g = []
    for y in range(13):
        row = ""
        for x in range(SIZE):
            grout = y % 4 == 3 or (x + (4 if y // 4 % 2 else 0)) % 8 == 7
            row += "m" if grout else "n"
        g.append(row)
    g += ["v" * SIZE, "v" * SIZE, "O" * SIZE]
    return g


def wall_edge(side):
    g = wall_top()
    for i in range(SIZE):
        if side == "right":
            put(g, i, SIZE - 2, "n"); put(g, i, SIZE - 1, "O")
        elif side == "left":
            put(g, i, 1, "n"); put(g, i, 0, "O")
        elif side == "bottom":
            put(g, 1, i, "n"); put(g, 0, i, "O")
    return g


def tiles():
    """Same names and order as tiles_arrivals.png: "tile" is the checker
    floor, "carpet" rust carpet, "wood" the plaza's planks, and
    "carpet_pattern" red diner carpet."""
    check_a, check_b = checker(1), checker(2)
    carpet_a, carpet_b = warm_carpet(3), warm_carpet(4)
    wood_a, wood_b = honey_wood((5, None, 12, None), 5), honey_wood((None, 3, None, 9), 6)
    diner_a, diner_b = diner_carpet("F", 7), diner_carpet("C", 8)
    return [
        ("carpet_a", carpet_a), ("carpet_b", carpet_b),
        ("tile_a", check_a), ("tile_b", check_b),
        ("wood_a", wood_a), ("wood_b", wood_b),
        ("carpet_shadow", arrivals.shadowed(carpet_a)), ("tile_shadow", arrivals.shadowed(check_a)),
        ("wood_shadow", arrivals.shadowed(wood_a)),
        ("wall_top", wall_top()), ("wall_lip", wall_lip()),
        ("wall_face_upper", wall_face_upper()), ("wall_face_lower", wall_face_lower()),
        ("wall_edge_right", wall_edge("right")), ("wall_edge_left", wall_edge("left")),
        ("wall_edge_bottom", wall_edge("bottom")),
        ("carpet_pattern_a", diner_a), ("carpet_pattern_b", diner_b),
        ("carpet_pattern_shadow", arrivals.shadowed(diner_a)),
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


# --- Restaurant fronts ----------------------------------------------------

FRONT_W, FRONT_H = 64, 32
# (name, sign color, letter color, awning colors, what's on the menu board)
RESTAURANTS = [
    ("CLUCK SHACK", "R", "F", ("R", "C"), "drumstick"),
    ("PIZZA PLANE", "g", "C", ("g", "C"), "pizza"),
    ("NOODLE GATE", "k", "y", ("y", "F"), "bowl"),
    ("JAVA JET", "m", "c", ("m", "c"), "cup"),
]


def _menu_picture(g, x, y, kind):
    """A tiny lit picture on the menu board."""
    if kind == "drumstick":
        _rect(g, x, y, x + 3, y + 2, "e")
        _rect(g, x + 4, y + 1, x + 5, y + 1, "C")
    elif kind == "pizza":
        for i in range(4):
            _rect(g, x + i, y + i // 2, x + 6 - i, y + i // 2, "Y")
        put(g, y, x + 2, "R")
    elif kind == "bowl":
        _rect(g, x, y + 1, x + 5, y + 2, "C")
        _rect(g, x + 1, y + 3, x + 4, y + 3, "W")
        _rect(g, x + 1, y, x + 4, y, "F")
    elif kind == "cup":
        _rect(g, x + 1, y, x + 4, y + 3, "C")
        put(g, y + 1, x + 5, "C")
        put(g, y - 1, x + 2, "W")


def restaurant_front(frame):
    """A food stall set into the wall: its name lit on a sign, a striped
    awning, a dark kitchen window with a glowing menu board, and a counter
    along the bottom."""
    name, sign, ink, awning, food = RESTAURANTS[frame]
    g = _blank(FRONT_W, FRONT_H)
    # Sign.
    _rect(g, 0, 0, 63, 9, "O")
    _rect(g, 1, 1, 62, 8, sign)
    _text(g, (FRONT_W - _text_width(name)) // 2, 3, name, ink)
    # Awning: stripes with a scalloped edge.
    for x in range(64):
        color = awning[0] if x // 4 % 2 == 0 else awning[1]
        _rect(g, x, 10, x, 12, color)
        if x % 4 in (1, 2):
            put(g, 13, x, color)
    # Kitchen window with menu boards on the back wall.
    _rect(g, 2, 13, 61, 24, "O")
    _rect(g, 3, 14, 60, 23, "v")
    for bx in (6, 25, 44):
        _rect(g, bx, 15, bx + 13, 20, "k")
        for ly in (16, 18):
            _rect(g, bx + 8, ly, bx + 12, ly, "W")
    _menu_picture(g, 8, 16, food)
    _menu_picture(g, 27, 16, food)
    # Counter: a lit top edge and a front panel.
    _rect(g, 0, 24, 63, 25, "C")
    _rect(g, 0, 26, 63, 31, awning[0] if awning[0] != "C" else "W")
    _rect(g, 0, 31, 63, 31, "O")
    _rect(g, 4, 23, 9, 23, "W")  # a napkin holder
    put(g, 22, 50, "R")          # a ketchup bottle
    put(g, 23, 50, "R")
    return g


def fronts_sheet():
    return _strip([restaurant_front(f) for f in range(len(RESTAURANTS))], FRONT_W, FRONT_H)


# --- Props ----------------------------------------------------------------

def food_table():
    """A round orange table on a pedestal with a chair either side, a tray
    of fries left on top. The base (about 24x6) is solid."""
    g = _blank(32, 24)
    for x0 in (0, 25):
        _rect(g, x0 + 1, 6, x0 + 5, 14, "y")
        _rect(g, x0 + 1, 6, x0 + 5, 6, "Y")
        _rect(g, x0 + 1, 15, x0 + 5, 16, "D")
        _rect(g, x0 + 2, 17, x0 + 2, 21, "T")
        _rect(g, x0 + 4, 17, x0 + 4, 21, "T")
    _rect(g, 6, 8, 25, 13, "Y")
    _rect(g, 7, 7, 24, 7, "F")
    _rect(g, 6, 13, 25, 14, "y")
    _rect(g, 15, 15, 16, 20, "T")
    _rect(g, 11, 21, 20, 22, "T")
    # Tray of fries.
    _rect(g, 10, 8, 16, 11, "R")
    for x in (11, 13, 15):
        _rect(g, x, 6, x, 9, "F")
    return _outline(g)


def vending_machine(frame):
    """A snack machine: a glass front with rows of colorful bags, a keypad,
    and a delivery flap. Frame 1 is broken open and emptied."""
    g = _blank(20, 30)
    _rect(g, 1, 1, 18, 28, "B")
    _rect(g, 1, 1, 18, 1, "b")
    _rect(g, 18, 2, 18, 28, "k")
    _rect(g, 3, 3, 13, 21, "O")
    _rect(g, 4, 4, 12, 20, "k")
    if frame == 0:
        colors = ("R", "Y", "l", "y", "b", "h")
        for row, y in enumerate((5, 9, 13, 17)):
            for col, x in enumerate((5, 8, 11)):
                _rect(g, x - 0, y, x + 1, y + 2, colors[(row * 3 + col) % len(colors)])
            _rect(g, 4, y + 3, 12, y + 3, "T")
        put(g, 4, 4, "W")
        put(g, 5, 4, "W")
    else:
        for y in (8, 12, 16, 20):
            _rect(g, 4, y, 12, y, "T")
        # Cracked glass.
        for x, y in ((6, 6), (7, 7), (8, 7), (9, 8), (10, 10), (8, 9)):
            put(g, y, x, "W")
    # Keypad and coin slot.
    _rect(g, 14, 5, 16, 11, "w")
    for y in (6, 8, 10):
        put(g, y, 15, "O")
    _rect(g, 14, 13, 16, 14, "Y")
    # Delivery flap.
    _rect(g, 3, 23, 16, 26, "O")
    _rect(g, 4, 24, 15, 25, "p" if frame == 0 else "v")
    _rect(g, 2, 28, 17, 28, "k")
    return _outline(g)


def vending_sheet():
    return _strip([vending_machine(f) for f in range(2)], 20, 30)


def trash_bin():
    g = _blank(12, 16)
    _rect(g, 1, 5, 10, 14, "T")
    _rect(g, 1, 5, 1, 14, "w")
    _rect(g, 10, 5, 10, 14, "p")
    _rect(g, 0, 3, 11, 4, "w")
    _rect(g, 0, 3, 11, 3, "W")
    # Overflowing: a cup and a wrapper poking out the top.
    _rect(g, 3, 0, 4, 2, "C")
    put(g, 0, 4, "R")
    _rect(g, 6, 1, 9, 2, "Y")
    return _outline(g)


def _litter(kind):
    g = _blank(SIZE, SIZE)
    if kind == "fries":
        _rect(g, 3, 9, 7, 12, "R")
        _rect(g, 3, 9, 7, 9, "r")
        for x, y in ((8, 8), (10, 10), (9, 12), (12, 9), (6, 6), (11, 13)):
            put(g, y, x, "F")
            put(g, y, x + 1, "Y")
        g = _outline(g)
    elif kind == "soda":
        for y in range(7, 14):
            for x in range(2, 14):
                if ((x - 8) / 5.5) ** 2 + ((y - 10) / 3.0) ** 2 < 1.0:
                    put(g, y, x, "m")
        _rect(g, 4, 5, 6, 9, "C")
        _rect(g, 4, 5, 6, 5, "R")
        put(g, 4, 6, "W")
    elif kind == "tray":
        _rect(g, 1, 5, 14, 12, "y")
        _rect(g, 1, 5, 14, 5, "Y")
        _rect(g, 3, 7, 6, 10, "C")
        _rect(g, 9, 8, 12, 10, "e")
        g = _outline(g)
    elif kind == "wrapper":
        _rect(g, 4, 7, 11, 11, "F")
        _rect(g, 5, 8, 10, 10, "Y")
        put(g, 9, 7, "R")
        put(g, 9, 8, "R")
        g = _outline(g)
    return g


LITTER_KINDS = ("fries", "soda", "tray", "wrapper")


def litter_sheet():
    return _strip([_litter(k) for k in LITTER_KINDS], SIZE, SIZE)


# --- The door to the gates -----------------------------------------------

def gates_door(frame):
    """The boarding gate's glass doors under an "ALL GATES" sign. Laid out
    like security_door.png: frames 0 and 1 closed, 2 opening, 3 open."""
    g = gate.door((0, 0, 2, 3)[frame])
    _rect(g, 4, 0, 43, 9, "O")
    _rect(g, 5, 1, 42, 8, "k")
    title = "ALL GATES"
    _text(g, (48 - _text_width(title)) // 2, 3, title, "y")
    return g


def gates_door_sheet():
    return _strip([gates_door(f) for f in range(4)], 48, 32)


def mock_screen():
    """A 320x180 Food Court scene for previews."""
    t = by_name()
    scr = Image.new("RGBA", (320, 180), (38, 43, 68, 255))
    for row in range(12):
        for col in range(20):
            if row < 4:
                name = ("wall_top", "wall_lip", "wall_face_upper", "wall_face_lower")[row]
            elif row == 4:
                name = "carpet_shadow"
            elif row < 6:
                name = "carpet_" + "ab"[col % 2]
            elif 7 <= col <= 12 and row >= 7:
                name = "wood_" + "ab"[(row + col) % 2]
            else:
                name = "tile_" + "ab"[(row * 7 + col * 3) % 2]
            scr.alpha_composite(to_image(t[name]), (col * 16, row * 16))
    scr.alpha_composite(to_image(restaurant_front(0)), (16, 32))
    scr.alpha_composite(to_image(gates_door(3)), (128, 32))
    scr.alpha_composite(to_image(restaurant_front(2)), (224, 32))
    scr.alpha_composite(to_image(vending_machine(0)), (20, 110))
    scr.alpha_composite(to_image(vending_machine(1)), (44, 110))
    scr.alpha_composite(to_image(food_table()), (240, 120))
    scr.alpha_composite(to_image(trash_bin()), (290, 96))
    for i, k in enumerate(LITTER_KINDS):
        scr.alpha_composite(to_image(_litter(k)), (80 + 24 * i, 150))
    return scr
