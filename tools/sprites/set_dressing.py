"""Set dressing for the terminal: things that make it look like an airport.

- departure_board.png: a 64x28 flight information display for the wall
  face, 4 frames of split-flap flicker.
- window.png: 32x24 windows for the wall face showing the tarmac outside,
  3 frames: plain tarmac, a parked plane's nose, the same plane's tail.
- potted_plant.png: 16x24 floor planters, 2 frames: leafy ficus, snake plant.
- welcome_banner.png: a 48x18 hanging banner, "WELCOME TO BAWKSTON".
"""
import math

from PIL import Image

from palette import put, to_image

# 3x5 pixel font for signs and boards.
FONT = {
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "G": [".##", "#..", "#.#", "#.#", ".##"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#.#", "###", "###", "#.#", "#.#"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "W": ["#.#", "#.#", "#.#", "###", "#.#"],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "?": ["##.", "..#", ".#.", "...", ".#."],
    "!": [".#.", ".#.", ".#.", "...", ".#."],
    "#": ["#.#", "###", "#.#", "###", "#.#"],
    " ": ["...", "...", "...", "...", "..."],
}


def _rect(g, x0, y0, x1, y1, key):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(g, y, x, key)


def _text(g, x, y, text, key):
    for ch in text:
        for dy, row in enumerate(FONT[ch]):
            for dx, bit in enumerate(row):
                if bit == "#":
                    put(g, y + dy, x + dx, key)
        x += 4


def _text_width(text):
    return len(text) * 4 - 1


def _blank(w, h):
    return ["." * w for _ in range(h)]


def _outline(g):
    """Ring every opaque pixel's transparent neighbors with the outline color."""
    h, w = len(g), len(g[0])
    out = list(g)
    for y in range(h):
        for x in range(w):
            if g[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and g[ny][nx] not in ".O":
                    put(out, y, x, "O")
                    break
    return out


def _strip(frames, w, h):
    out = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, grid in enumerate(frames):
        out.alpha_composite(to_image(grid), (i * w, 0))
    return out


# --- Departure board ------------------------------------------------------

BOARD_W, BOARD_H = 64, 28
BOARD_FRAMES = 4
BOARD_ROWS = (9, 15, 21)
STATUS_X = 4 + 9 * 4  # destinations are padded to 8 letters plus a space

# Destinations stay put; statuses flip like a split-flap board.
# Each entry is (text, color) per frame, or None for a blank (flicker).
FLIGHTS = [
    ("HENVER", [("LATE", "y"), None, ("LATE", "y"), None]),
    ("CLUCKLND", [("CNCL", "R"), ("CNCL", "R"), ("CNCL", "D"), ("CNCL", "R")]),
    ("EGGSETER", [("????", "y"), ("#?#?", "D"), ("FOWL", "y"), ("?#?#", "D")]),
]


def departure_board(frame):
    g = _blank(BOARD_W, BOARD_H)
    _rect(g, 0, 0, BOARD_W - 1, BOARD_H - 1, "O")
    # Casing: a slim slate bezel, lit on the top edge.
    _rect(g, 1, 1, BOARD_W - 2, BOARD_H - 2, "p")
    _rect(g, 1, 1, BOARD_W - 2, 1, "T")
    _rect(g, 2, 2, BOARD_W - 3, BOARD_H - 3, "O")
    title = "DEPARTURES"
    _text(g, (BOARD_W - _text_width(title)) // 2, 3, title, "F")
    # Faint row dividers, like the gaps between flap modules.
    for y in BOARD_ROWS:
        _rect(g, 3, y - 1, BOARD_W - 4, y - 1, "v")
    for (dest, statuses), y in zip(FLIGHTS, BOARD_ROWS):
        _text(g, 4, y + 1, dest, "Y")
        status = statuses[frame]
        if status is not None:
            text, color = status
            _text(g, STATUS_X, y + 1, text, color)
    # Glare on the glass, top-left light.
    put(g, 3, 3, "T")
    put(g, 4, 3, "T")
    put(g, 3, 4, "T")
    return g


def departure_board_sheet():
    return _strip([departure_board(f) for f in range(BOARD_FRAMES)], BOARD_W, BOARD_H)


# --- Windows --------------------------------------------------------------

WIN_W, WIN_H = 32, 24
GLASS_X, GLASS_Y = 2, 2
GLASS_W, GLASS_H = 28, 18
HORIZON = 8  # glass row where the far tarmac edge sits
# The nose and tail frames show one continuous plane when the windows are
# placed this far apart (left edge to left edge) on the wall.
PLANE_WINDOW_SPACING = 40


def _outside(width, plane):
    """The view outside: sky, a distant tower, tarmac with a taxi line."""
    g = _blank(width, GLASS_H)
    for y in range(GLASS_H):
        for x in range(width):
            if y < HORIZON:
                key = "b"
            elif y == HORIZON:
                key = "T"
            else:
                key = "p" if (x * 3 + y * 5) % 11 else "T"
            put(g, y, x, key)
    # A couple of soft clouds.
    for cx, cy in ((10, 5), (24, 5), (48, 3)):
        if cx < width:
            _rect(g, cx, cy, min(cx + 3, width - 1), cy, "W")
            if cy > 0 and cx + 1 < width:
                put(g, cy - 1, cx + 1, "W")
    # Taxi line: yellow dashes across the tarmac.
    for x in range(0, width, 4):
        _rect(g, x, 14, min(x + 1, width - 1), 14, "Y")
    if plane:
        _plane(g)
    else:
        # Control tower on the horizon.
        _rect(g, 19, 3, 21, HORIZON - 1, "T")
        _rect(g, 18, 2, 22, 3, "w")
        _rect(g, 18, 1, 22, 1, "T")
    return g


def _plane(g):
    """A parked airliner facing left, side on, about 66 px long. The nose
    window shows the cockpit and door; the tail window shows the wing,
    engine and tail fin."""
    top, bottom = 7, 13
    nose, tail = 1, 66
    for x in range(nose, tail + 1):
        # Round the nose and taper the tail cone upward.
        if x < nose + 4:
            t, b = top + (nose + 4 - x) // 2, bottom - (nose + 4 - x) // 3
        elif x > tail - 9:
            t, b = top, bottom - (x - (tail - 9)) // 2
        else:
            t, b = top, bottom
        for y in range(t, b + 1):
            put(g, y, x, "C" if y < 11 else "W")
        put(g, b, x, "w")
    # Cockpit windows, cabin windows, a door, and the blue cheatline.
    _rect(g, nose + 2, 8, nose + 4, 8, "k")
    for x in range(nose + 11, tail - 11, 3):
        put(g, 9, x, "k")
    _rect(g, nose + 7, 8, nose + 8, 12, "w")
    _rect(g, nose + 4, 11, tail - 9, 11, "B")
    # Wing sweeping down toward us, with an engine slung underneath.
    for i in range(4):
        _rect(g, 47 + i, 12 + i, 57 + i * 2, 12 + i, "W" if i == 0 else "w")
    _rect(g, 45, 14, 51, 17, "W")
    _rect(g, 45, 17, 51, 17, "w")
    _rect(g, 45, 14, 45, 17, "k")
    # Landing gear.
    for x in (nose + 6, 55, 57):
        _rect(g, x, bottom + 1, x, bottom + 3, "O")
    # Swept tail fin with a red comb logo.
    for y in range(1, top):
        x0 = tail - 10 + (y - 1)
        _rect(g, x0 + (top - y) // 2 + 2, y, tail - 1, y, "B")
    _rect(g, tail - 3, 2, tail - 2, 3, "R")
    put(g, 1, tail - 2, "R")
    put(g, 2, tail - 1, "R")


def window(frame):
    """frame 0: tarmac and tower; 1: plane nose; 2: plane tail."""
    g = _blank(WIN_W, WIN_H)
    _rect(g, 0, 0, WIN_W - 1, WIN_H - 1, "O")
    # Metal frame, light on top and left.
    _rect(g, 1, 1, WIN_W - 2, WIN_H - 3, "w")
    _rect(g, 1, 1, WIN_W - 2, 1, "W")
    _rect(g, 1, 1, 1, WIN_H - 3, "W")
    if frame == 0:
        outside, offset = _outside(GLASS_W, plane=False), 0
    else:
        outside = _outside(PLANE_WINDOW_SPACING + GLASS_W, plane=True)
        offset = 0 if frame == 1 else PLANE_WINDOW_SPACING
    for y in range(GLASS_H):
        put(g, GLASS_Y + y, GLASS_X, outside[y][offset:offset + GLASS_W])
    # Mullion down the middle.
    _rect(g, 16, GLASS_Y, 16, GLASS_Y + GLASS_H - 1, "w")
    # Reflections: two short diagonal glints, top-left light.
    for x0, length in ((4, 4), (20, 3)):
        for i in range(length):
            put(g, GLASS_Y + 1 + i, x0 + length - i, "C")
    # Sill: a ledge seen from slightly above.
    _rect(g, 0, WIN_H - 3, WIN_W - 1, WIN_H - 3, "C")
    _rect(g, 0, WIN_H - 2, WIN_W - 1, WIN_H - 2, "w")
    _rect(g, 0, WIN_H - 1, WIN_W - 1, WIN_H - 1, "O")
    return g


def window_sheet():
    return _strip([window(f) for f in range(3)], WIN_W, WIN_H)


# --- Potted plants --------------------------------------------------------

PLANT_W, PLANT_H = 16, 24


def _pot(g, top):
    """A terracotta pot from row top to the bottom, with soil showing."""
    _rect(g, 3, top + 2, 12, PLANT_H - 2, "m")
    _rect(g, 4, top + 2, 4, PLANT_H - 2, "n")
    _rect(g, 11, top + 2, 12, PLANT_H - 2, "v")
    _rect(g, 4, PLANT_H - 2, 11, PLANT_H - 2, "v")
    # Rim: wider band, lit on top.
    _rect(g, 2, top, 13, top + 1, "n")
    _rect(g, 2, top, 13, top, "a")
    _rect(g, 12, top, 13, top + 1, "m")
    # Soil seen through the rim.
    _rect(g, 4, top, 11, top, "v")


def ficus():
    g = _blank(PLANT_W, PLANT_H)
    # Leafy crown: overlapping blobs, shaded from the top left.
    blobs = ((8, 6, 5.2), (4.5, 10, 3.8), (11.5, 10, 3.8), (8, 12, 3.5))
    for y in range(PLANT_H):
        for x in range(PLANT_W):
            px, py = x + 0.5, y + 0.5
            inside = [(px - cx, py - cy, r) for cx, cy, r in blobs
                      if math.hypot(px - cx, py - cy) < r]
            if not inside:
                continue
            dx, dy, r = inside[0]
            light = -(dx + dy) / r  # positive toward the top left
            leafy = (x * 5 + y * 3) % 7 == 0
            if light > 0.6 or (leafy and light > 0.0):
                key = "l"
            elif light < -0.5 or (leafy and light < 0.0):
                key = "j"
            else:
                key = "g"
            put(g, y, x, key)
    # Trunk peeking out between the leaves and the pot.
    _rect(g, 7, 14, 8, 16, "m")
    _pot(g, 16)
    return _outline(g)


def snake_plant():
    g = _blank(PLANT_W, PLANT_H)
    # Upright blades, each lit on its left edge with a yellow rim.
    blades = ((4, 7, -1), (7, 2, 0), (10, 4, 1), (12, 9, 1), (5, 11, 0))
    for x0, top, lean in blades:
        for y in range(top, 18):
            x = x0 + (lean if y < top + 4 else 0)
            put(g, y, x, "l")
            put(g, y, x + 1, "g")
            put(g, y, x + 2, "j")
            if y == top:
                put(g, y, x, "F")
                put(g, y, x + 2, ".")
        for y in range(top + 3, 18, 3):
            put(g, y, x0 + 1, "j")
    _pot(g, 16)
    # A gray chrome planter instead of terracotta.
    for y in range(16, PLANT_H):
        row = g[y].replace("a", "C").replace("n", "W").replace("m", "w").replace("v", "T")
        g[y] = row
    return _outline(g)


def potted_plant_sheet():
    return _strip([ficus(), snake_plant()], PLANT_W, PLANT_H)


# --- Welcome banner -------------------------------------------------------

BANNER_W, BANNER_H = 48, 18
# Proposed: the city the airport serves. Not final until signed off.
CITY = "BAWKSTON!"


def welcome_banner():
    g = _blank(BANNER_W, BANNER_H)
    # Hanging rod with round end caps.
    _rect(g, 1, 0, BANNER_W - 2, 2, "O")
    _rect(g, 2, 1, BANNER_W - 3, 1, "w")
    _rect(g, 0, 0, 1, 2, "O")
    _rect(g, BANNER_W - 2, 0, BANNER_W - 1, 2, "O")
    # Fabric: blue, lit on the left, shaded on the right.
    bottom = BANNER_H - 1
    _rect(g, 3, 3, BANNER_W - 4, bottom, "O")
    _rect(g, 4, 3, BANNER_W - 5, bottom - 1, "B")
    _rect(g, 4, 3, 4, bottom - 1, "b")
    _rect(g, BANNER_W - 5, 3, BANNER_W - 5, bottom - 1, "k")
    # A sag fold across the middle, darker where the cloth dips.
    _rect(g, 5, 9, BANNER_W - 6, 9, "k")
    # Lettering: white greeting, yellow city name.
    line1 = "WELCOME TO"
    _text(g, (BANNER_W - _text_width(line1)) // 2, 4, line1, "C")
    _text(g, (BANNER_W - _text_width(CITY)) // 2 + 1, 10, CITY, "F")
    return g


def welcome_banner_sheet():
    return to_image(welcome_banner())


# --- Preview --------------------------------------------------------------

def wall_preview(tiles_by_name):
    """A 320x112 slice of the north wall with every piece in place."""
    scr = Image.new("RGBA", (320, 112), (38, 43, 68, 255))
    rows = ("wall_top", "wall_lip", "wall_face_upper", "wall_face_lower",
            "carpet_pattern_shadow")
    for row, name in enumerate(rows):
        for col in range(20):
            scr.alpha_composite(to_image(tiles_by_name[name]), (col * 16, row * 16))
    for row in range(5, 7):
        for col in range(20):
            name = "carpet_pattern_" + ("a" if (col * 7 + row * 3) % 5 < 3 else "b")
            scr.alpha_composite(to_image(tiles_by_name[name]), (col * 16, row * 16))
    scr.alpha_composite(to_image(departure_board(0)), (16, 33))
    scr.alpha_composite(to_image(window(0)), (96, 34))
    scr.alpha_composite(to_image(window(1)), (136, 34))
    scr.alpha_composite(to_image(window(2)), (136 + PLANE_WINDOW_SPACING, 34))
    scr.alpha_composite(to_image(welcome_banner()), (232, 34))
    scr.alpha_composite(to_image(ficus()), (288, 60))
    scr.alpha_composite(to_image(snake_plant()), (80, 64))
    return scr
