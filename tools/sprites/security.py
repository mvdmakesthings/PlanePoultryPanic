"""Level 2, the Security Checkpoint: cold grays, scanner blues, and
black-and-yellow hazard edges.

- tiles_security.png: the area's floor and wall tiles, laid out exactly like
  tiles_arrivals.png so the same text maps and atlas names work.
- stanchion.png: a 48x16 run of queue posts joined by a blue belt.
- xray_machine.png: a 24x48 baggage X-ray machine, its belt running north.
- metal_detector.png: a 32x34 walk-through arch, 2 frames (idle, beeping).
- bin_table.png: a 48x20 roller table loaded with gray screening bins.
- item_boarding_pass.png: a 12x8 boarding pass, a key item.
- security_shutter.png: 32x32 roll-down grille, 4 frames from rolled up
  to closed.
- shutter_switch.png: a 10x14 wall switch, 2 frames (up = open, down = closed).
- stall_door.png: a 16x30 restroom stall door, 2 frames (closed, open).
- pass_gate.png: a 48x32 boarding-pass gate in the back wall, 4 frames
  like the Security door (locked, unlocked, opening, open).
- security_litter.png: 16x16 floor decals: a spilled bin, a lost shoe, a
  pecked belt, a confiscated water bottle.
"""
import random

from PIL import Image

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


def rubber_mat(seed):
    """Slate rubber matting with raised ribs, for the queue lanes."""
    g = _speckle("p", "k", 0.06, seed)
    for y in (1, 5, 9, 13):
        for x in range(SIZE):
            put(g, y, x, "T")
    return g


def cold_tile(seed):
    """Large cool-gray floor tiles, darker than Arrivals' white tile."""
    g = _speckle("w", "T", 0.04, seed)
    for i in range(SIZE):
        put(g, 0, i, "W")
        put(g, i, 0, "W")
        put(g, SIZE - 1, i, "T")
        put(g, i, SIZE - 1, "T")
    return g


def hazard(seed):
    """Black-and-yellow diagonal hazard stripes, scuffed. The stripes repeat
    every 8 pixels, so they tile seamlessly."""
    rnd = random.Random(seed)
    g = [""] * SIZE
    for y in range(SIZE):
        g[y] = "".join("Y" if (x + y) // 4 % 2 == 0 else "k" for x in range(SIZE))
    for _ in range(6):
        x, y = rnd.randrange(SIZE), rnd.randrange(SIZE)
        put(g, y, x, "y" if g[y][x] == "Y" else "p")
    return g


def tread(accent, seed):
    """Dark anti-slip floor in the screening area: a grid of raised slate
    studs with scanner-blue (or white) studs here and there."""
    g = _speckle("k", "p", 0.04, seed)
    for y in range(2, SIZE, 4):
        for x in range(2, SIZE, 4):
            put(g, y, x, "T")
            put(g, y + 1, x, "p")
    put(g, 6, 10, accent)
    put(g, 14, 2, accent)
    return g


def wall_top():
    return [("k" * SIZE) for _ in range(SIZE)]


def wall_lip():
    g = wall_top()
    g[14] = "p" * SIZE
    g[15] = "O" * SIZE
    return g


def wall_face_upper():
    """Steel-gray panels with a thin scanner-blue line and a panel seam."""
    g = ["W" * SIZE] + ["w" * (SIZE - 1) + "T" for _ in range(SIZE - 1)]
    g[8] = "b" * SIZE
    g[9] = "B" * SIZE
    return g


def wall_face_lower():
    """The lower panel, ending in a black-and-yellow hazard baseboard."""
    g = ["w" * (SIZE - 1) + "T" for _ in range(8)]
    g += ["T" * SIZE]
    for y in range(9, 14):
        g.append("".join("Y" if (x + y) // 3 % 2 == 0 else "O" for x in range(SIZE)))
    g += ["k" * SIZE, "O" * SIZE]
    return g


def wall_edge(side):
    g = wall_top()
    for i in range(SIZE):
        if side == "right":
            put(g, i, SIZE - 2, "p"); put(g, i, SIZE - 1, "O")
        elif side == "left":
            put(g, i, 1, "p"); put(g, i, 0, "O")
        elif side == "bottom":
            put(g, 1, i, "p"); put(g, 0, i, "O")
    return g


def tiles():
    """Same names and order as tiles_arrivals.png, so the atlas matches:
    "carpet" is rubber matting, "tile" is cold gray tile, "wood" is hazard
    striping, "carpet_pattern" is dark tread."""
    mat_a, mat_b = rubber_mat(1), rubber_mat(2)
    tile_a, tile_b = cold_tile(3), cold_tile(4)
    stripe_a, stripe_b = hazard(5), hazard(6)
    tread_a, tread_b = tread("b", 7), tread("W", 8)
    return [
        ("carpet_a", mat_a), ("carpet_b", mat_b),
        ("tile_a", tile_a), ("tile_b", tile_b),
        ("wood_a", stripe_a), ("wood_b", stripe_b),
        ("carpet_shadow", arrivals.shadowed(mat_a)), ("tile_shadow", arrivals.shadowed(tile_a)),
        ("wood_shadow", arrivals.shadowed(stripe_a)),
        ("wall_top", wall_top()), ("wall_lip", wall_lip()),
        ("wall_face_upper", wall_face_upper()), ("wall_face_lower", wall_face_lower()),
        ("wall_edge_right", wall_edge("right")), ("wall_edge_left", wall_edge("left")),
        ("wall_edge_bottom", wall_edge("bottom")),
        ("carpet_pattern_a", tread_a), ("carpet_pattern_b", tread_b),
        ("carpet_pattern_shadow", arrivals.shadowed(tread_a)),
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


# --- Queue stanchions -----------------------------------------------------

def stanchion():
    """Three chrome posts joined by a blue retractable belt, seen from the
    front. The base (about 48x4) is the solid part."""
    g = _blank(48, 16)
    for x in (1, 22, 44):
        # Post: lit on the left, a cap on top, a round weighted base.
        _rect(g, x, 3, x + 2, 13, "w")
        _rect(g, x, 3, x, 13, "C")
        _rect(g, x, 2, x + 2, 2, "W")
        _rect(g, x - 1, 13, x + 3, 14, "T")
        _rect(g, x - 1, 13, x + 3, 13, "w")
    for x0, x1 in ((4, 21), (25, 43)):
        # The belt sags a pixel in the middle.
        mid = (x0 + x1) // 2
        for x in range(x0, x1 + 1):
            sag = 1 if abs(x - mid) < (x1 - x0) // 3 else 0
            put(g, 5 + sag, x, "b")
            put(g, 6 + sag, x, "B")
    return _outline(g)


# --- X-ray machine --------------------------------------------------------

def xray_machine():
    """A baggage X-ray machine beside a lane, its belt running away from
    the camera: the long top with a little monitor, then the front face
    with the tunnel's lead curtain, and the in-feed rollers at the bottom.
    Its footprint (about 22x34 at the bottom) is the solid part."""
    g = _blank(24, 48)
    # Top surface: steel gray, lit on the left, with a scanner-blue stripe
    # down the middle and the out-feed rollers at the far end.
    _rect(g, 1, 1, 22, 33, "W")
    _rect(g, 1, 1, 1, 33, "C")
    _rect(g, 22, 1, 22, 33, "w")
    _rect(g, 11, 6, 12, 33, "b")
    for y in range(2, 6):
        _rect(g, 3, y, 20, y, "T" if y % 2 else "p")
    # The operator's monitor on top, glowing blue with a bag's outline.
    _rect(g, 4, 14, 9, 19, "k")
    _rect(g, 5, 15, 8, 18, "b")
    put(g, 16, 6, "C")
    put(g, 17, 7, "C")
    put(g, 17, 6, "B")
    _rect(g, 5, 20, 8, 21, "p")
    # A warning label near the front.
    _rect(g, 15, 26, 20, 29, "Y")
    _rect(g, 16, 27, 19, 27, "O")
    # Front face, in shadow, with the tunnel and its lead curtain strips.
    _rect(g, 1, 34, 22, 43, "w")
    _rect(g, 1, 34, 22, 34, "C")
    _rect(g, 4, 36, 19, 43, "O")
    for x in range(5, 19, 2):
        _rect(g, x, 37, x, 43, "p")
        _rect(g, x + 1, 37, x + 1, 43, "k")
    # In-feed rollers poking out at the floor, hazard edge along the base.
    _rect(g, 3, 44, 20, 45, "T")
    for x in range(3, 21, 3):
        put(g, 44, x, "W")
    for x in range(1, 23):
        put(g, 46, x, "Y" if x // 2 % 2 == 0 else "O")
    return _outline(g)


# --- Metal detector arch --------------------------------------------------

def metal_detector(frame):
    """A walk-through metal detector seen from the front: two gray posts
    and a header with a status light. Frame 0 is idle (green light),
    frame 1 beeping (red light, the posts' inner lights flashing).
    Only the feet of the posts are solid."""
    g = _blank(32, 34)
    beeping = frame == 1
    for x0 in (0, 26):
        _rect(g, x0 + 1, 6, x0 + 4, 32, "w")
        _rect(g, x0 + 1, 6, x0 + 1, 32, "W")
        _rect(g, x0 + 4, 6, x0 + 4, 32, "T")
        # A strip of sensor lights down the inner edge.
        inner = x0 + 4 if x0 == 0 else x0 + 1
        for y in range(10, 30, 4):
            put(g, y, inner, ("R" if beeping else "b"))
        _rect(g, x0, 32, x0 + 5, 33, "p")
    # Header with a blue stripe and the status light.
    _rect(g, 1, 1, 30, 6, "W")
    _rect(g, 1, 1, 30, 1, "C")
    _rect(g, 1, 6, 30, 6, "T")
    _rect(g, 3, 3, 28, 4, "B")
    _rect(g, 14, 2, 17, 5, "O")
    _rect(g, 15, 3, 16, 4, "R" if beeping else "l")
    return _outline(g)


# --- Bin table ------------------------------------------------------------

def bin_table():
    """A roller table loaded with gray screening bins: a shoe in one, a
    jacket in another, the third empty. The legs (about 46x6) are solid."""
    g = _blank(48, 20)
    # Table top: rollers seen from above, steel frame along the front.
    _rect(g, 1, 4, 46, 12, "T")
    for x in range(2, 46, 3):
        _rect(g, x, 5, x, 11, "W")
    _rect(g, 1, 12, 46, 13, "w")
    _rect(g, 1, 12, 46, 12, "W")
    for x in (3, 43):
        _rect(g, x, 14, x + 1, 18, "p")
    _rect(g, 3, 17, 44, 17, "k")
    # Bins: gray tubs, lit rims, a little inside showing.
    contents = ("shoe", "jacket", "")
    for i, x0 in enumerate((3, 18, 33)):
        _rect(g, x0, 2, x0 + 11, 10, "w")
        _rect(g, x0, 2, x0 + 11, 2, "W")
        _rect(g, x0 + 1, 3, x0 + 10, 7, "p")
        _rect(g, x0, 8, x0 + 11, 10, "T")
        if contents[i] == "shoe":
            _rect(g, x0 + 2, 5, x0 + 7, 6, "m")
            _rect(g, x0 + 6, 4, x0 + 8, 6, "m")
            put(g, 5, x0 + 3, "n")
        elif contents[i] == "jacket":
            _rect(g, x0 + 2, 3, x0 + 9, 7, "r")
            _rect(g, x0 + 2, 3, x0 + 9, 3, "R")
            put(g, 5, x0 + 5, "O")
    return _outline(g)


# --- Boarding pass --------------------------------------------------------

BOARDING_PASS = [
    "OOOOOOOOOOOO",
    "ObbbbbbBCCCO",
    "OCCCCCCBCOCO",
    "OCWWWCCBCCCO",
    "OCCCCCCBCOCO",
    "OCOCOOCBCOCO",
    "OCOCOOCBCCCO",
    "OOOOOOOOOOOO",
]


def boarding_pass():
    """A paper boarding pass: a blue airline header, a name line and a
    barcode, with the torn-off stub on the right."""
    return to_image(BOARDING_PASS)


# --- Roll-down shutter and its switch ------------------------------------

SHUTTER_W, SHUTTER_H = 32, 32
SHUTTER_FRAMES = 4
SHUTTER_HOUSING = 6


def shutter(frame):
    """A steel security grille that rolls down out of a ceiling housing.
    Frame 0 is rolled up (only the housing shows), frame 3 is closed down
    to the floor with its hazard-striped bottom bar."""
    g = _blank(SHUTTER_W, SHUTTER_H)
    # Housing: a gray box with a hazard edge underneath.
    _rect(g, 0, 0, 31, SHUTTER_HOUSING - 1, "w")
    _rect(g, 0, 0, 31, 0, "W")
    _rect(g, 0, SHUTTER_HOUSING - 1, 31, SHUTTER_HOUSING - 1, "T")
    bottom = SHUTTER_HOUSING - 1 + round((SHUTTER_H - SHUTTER_HOUSING) * frame / (SHUTTER_FRAMES - 1))
    if bottom >= SHUTTER_HOUSING:
        # The grille: steel bars with gaps you can see through.
        for y in range(SHUTTER_HOUSING, bottom + 1):
            for x in range(1, 31):
                if x % 3 == 1 or y % 4 == 0:
                    put(g, y, x, "W" if x % 3 == 1 else "T")
        _rect(g, 0, SHUTTER_HOUSING, 0, bottom, "T")
        _rect(g, 31, SHUTTER_HOUSING, 31, bottom, "T")
        # Bottom bar.
        bar = max(SHUTTER_HOUSING, bottom - 2)
        for x in range(0, 32):
            for y in range(bar, bottom + 1):
                put(g, y, x, "Y" if (x + y) // 2 % 2 == 0 else "k")
    return _outline(g)


def shutter_sheet():
    return _strip([shutter(f) for f in range(SHUTTER_FRAMES)], SHUTTER_W, SHUTTER_H)


def shutter_switch(frame):
    """A wall box with a big lever: up with a green light (shutter open),
    down with a red light (shutter closed)."""
    g = _blank(10, 14)
    _rect(g, 1, 1, 8, 12, "Y")
    _rect(g, 1, 1, 8, 1, "F")
    _rect(g, 8, 2, 8, 12, "y")
    for y in range(9, 13):
        for x in range(1, 9):
            if (x + y) // 2 % 2:
                put(g, y, x, "O")
    _rect(g, 3, 3, 6, 8, "k")
    up = frame == 0
    # The lever handle.
    if up:
        _rect(g, 4, 2, 5, 5, "W")
        _rect(g, 3, 1, 6, 2, "R")
    else:
        _rect(g, 4, 6, 5, 9, "W")
        _rect(g, 3, 9, 6, 10, "R")
    put(g, 3, 7, "l" if up else "R")
    return _outline(g)


def shutter_switch_sheet():
    return _strip([shutter_switch(f) for f in range(2)], 10, 14)


# --- Restroom stall -------------------------------------------------------

def stall_door(frame):
    """A restroom stall door set into the wall: pale partition panels with
    a little "occupied" slider and a gap at the bottom. Open, it shows the
    toilet inside."""
    g = _blank(16, 30)
    _rect(g, 0, 0, 15, 29, "O")
    _rect(g, 1, 1, 14, 29, "w")
    _rect(g, 2, 2, 13, 29, "O")
    if frame == 0:
        _rect(g, 3, 3, 12, 26, "W")
        _rect(g, 3, 3, 12, 3, "C")
        _rect(g, 12, 4, 12, 26, "w")
        # The slider lock: green for vacant.
        _rect(g, 9, 13, 11, 14, "O")
        put(g, 13, 10, "l")
        put(g, 14, 10, "g")
        # A coat hook and the gap under the door.
        put(g, 7, 6, "T")
        _rect(g, 3, 27, 12, 29, "k")
    else:
        # Open: the stall inside, a white toilet against the back.
        _rect(g, 3, 3, 12, 29, "p")
        _rect(g, 3, 3, 12, 14, "T")
        _rect(g, 5, 15, 10, 18, "C")
        _rect(g, 6, 19, 9, 23, "C")
        _rect(g, 6, 20, 9, 21, "W")
        _rect(g, 3, 3, 4, 29, "W")
    return g


def stall_sheet():
    return _strip([stall_door(f) for f in range(2)], 16, 30)


# --- Boarding-pass gate --------------------------------------------------

PASS_GATE_FRAMES = 4


def pass_gate(frame):
    """The way out of Security, set into the back wall like the Security
    door: a "FOOD COURT" sign over a doorway with two waist-high glass
    paddle gates and a pass reader. Frame 0 locked (red light), 1 unlocked
    (green light), 2 the paddles swinging open, 3 open."""
    W, H = 48, 32
    g = _blank(W, H)
    locked = frame == 0
    # Sign: charcoal panel with yellow letters, like the wayfinding signs.
    _rect(g, 2, 0, 45, 9, "O")
    _rect(g, 3, 1, 44, 8, "k")
    _rect(g, 3, 1, 44, 1, "p")
    title = "FOOD COURT"
    _text(g, (W - _text_width(title)) // 2, 3, title, "F")
    # Door frame and the bright corridor beyond.
    _rect(g, 2, 10, 45, 31, "O")
    _rect(g, 3, 11, 44, 31, "w")
    _rect(g, 3, 11, 44, 11, "W")
    _rect(g, 6, 13, 41, 31, "O")
    _rect(g, 7, 14, 40, 31, "e")
    for y in range(20, 32, 3):
        _rect(g, 7, y, 40, y, "n")
    _rect(g, 7, 14, 40, 15, "m")
    # Gate cabinets either side of the lane.
    for x0 in (7, 37):
        _rect(g, x0, 22, x0 + 3, 31, "T")
        _rect(g, x0, 22, x0 + 3, 22, "W")
    # Glass paddles: across the lane when shut, folding back as they open.
    reach = (12, 12, 6, 0)[frame]
    if reach:
        _rect(g, 11, 24, 10 + reach, 28, "b")
        _rect(g, 11, 24, 10 + reach, 24, "C")
        _rect(g, 37 - reach, 24, 36, 28, "b")
        _rect(g, 37 - reach, 24, 36, 24, "C")
    # Pass reader on the right cabinet: a glowing pad and a status light.
    _rect(g, 38, 18, 41, 21, "O")
    _rect(g, 39, 19, 40, 19, "b")
    put(g, 20, 39, "R" if locked else "l")
    put(g, 20, 40, "r" if locked else "g")
    _rect(g, 3, 31, 44, 31, "W")
    return g


def pass_gate_sheet():
    return _strip([pass_gate(f) for f in range(PASS_GATE_FRAMES)], 48, 32)


# --- Floor litter ---------------------------------------------------------

def _litter(kind):
    g = _blank(SIZE, SIZE)
    if kind == "bin":
        # A screening bin knocked on its side, spilling a phone and keys.
        _rect(g, 2, 5, 10, 11, "w")
        _rect(g, 2, 5, 10, 5, "W")
        _rect(g, 3, 6, 9, 10, "T")
        _rect(g, 11, 9, 13, 12, "k")
        put(g, 10, 12, "b")
        put(g, 13, 6, "Y")
        put(g, 13, 7, "Y")
        g = _outline(g)
    elif kind == "shoe":
        _rect(g, 4, 8, 11, 10, "m")
        _rect(g, 9, 6, 11, 8, "m")
        _rect(g, 4, 10, 11, 10, "v")
        put(g, 8, 5, "n")
        put(g, 9, 6, "n")
        g = _outline(g)
    elif kind == "belt":
        # A leather belt, pecked through, buckle shining.
        for x in range(2, 14):
            y = 8 + (1 if 5 < x < 10 else 0)
            put(g, y, x, "n")
            put(g, y + 1, x, "m")
        _rect(g, 2, 7, 4, 10, "Y")
        put(g, 8, 3, "O")
        put(g, 9, 7, ".")
        put(g, 8, 7, ".")
        g = _outline(g)
    elif kind == "bottle":
        # A confiscated water bottle on its side.
        _rect(g, 3, 7, 10, 10, "b")
        _rect(g, 3, 7, 10, 7, "C")
        _rect(g, 5, 8, 8, 9, "W")
        _rect(g, 11, 8, 12, 9, "B")
        g = _outline(g)
    return g


LITTER_KINDS = ("bin", "shoe", "belt", "bottle")


def litter_sheet():
    return _strip([_litter(k) for k in LITTER_KINDS], SIZE, SIZE)


def mock_screen():
    """A 320x180 Security scene for previews: a wall with the shutter,
    hazard floor at the lane, queue posts and a scanner."""
    t = by_name()
    scr = Image.new("RGBA", (320, 180), (38, 43, 68, 255))
    for row in range(12):
        for col in range(20):
            if row < 4:
                if col in (9, 10):
                    name = "tile_a"
                else:
                    name = ("wall_top", "wall_lip", "wall_face_upper", "wall_face_lower")[row]
            elif row == 4:
                name = "wood_shadow" if col in (9, 10) else "tile_shadow"
            elif row < 7 and col in (8, 9, 10, 11):
                name = "wood_" + "ab"[col % 2]
            elif row >= 8:
                name = "carpet_" + "ab"[(row + col) % 2]
            else:
                name = "tile_" + "ab"[(row * 7 + col * 3) % 2]
            scr.alpha_composite(to_image(t[name]), (col * 16, row * 16))
    scr.alpha_composite(to_image(shutter(2)), (144, 32))
    scr.alpha_composite(to_image(shutter_switch(0)), (184, 40))
    scr.alpha_composite(to_image(stall_door(0)), (32, 34))
    scr.alpha_composite(to_image(xray_machine()), (110, 40))
    scr.alpha_composite(to_image(metal_detector(1)), (220, 54))
    scr.alpha_composite(to_image(bin_table()), (240, 100))
    for x in (40, 88, 136):
        scr.alpha_composite(to_image(stanchion()), (x, 136))
    scr.alpha_composite(boarding_pass(), (260, 92))
    return scr
