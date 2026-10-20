"""The opening cutscene: Amanda's cancelled gate in the arrival lounge.

- opening_backdrop.png: the 320x96 back wall of the gate lounge, with a big
  three-pane window whose glass is transparent (the tarmac shows through
  from behind) and the hangers for the departure board, which the game
  draws itself. The floor below comes from tiles_arrivals.png.
- opening_tarmac.png: the 162x57 view through the window: sky, the control
  tower, a parked plane and the tarmac. It sits behind the backdrop, lined
  up with the glass; the chickens outside are drawn by the game between
  the two.
- opening_boarding_pass.png: a 96x48 close-up of Amanda's boarding pass,
  2 frames: as printed, then with a red EXPIRED stamp across it.
"""
from PIL import Image

from palette import put, to_image
from set_dressing import _blank, _plane, _rect, _strip, _text, _text_width

# --- Backdrop -------------------------------------------------------------

BACKDROP_W, BACKDROP_H = 320, 96
# The window's outer frame, and the glass inside it (where the tarmac shows).
WINDOW = (8, 12, 175, 77)  # x0, y0, x1, y1 including the sill
GLASS = (11, 15, 172, 71)
MULLIONS = (64, 119)
# Where the departure board hangs; the game draws the board in this box.
BOARD = (184, 12, 312, 72)


def backdrop():
    g = _blank(BACKDROP_W, BACKDROP_H)
    # Wall top and its lip, as in tiles_arrivals.png.
    _rect(g, 0, 0, BACKDROP_W - 1, 7, "p")
    _rect(g, 0, 6, BACKDROP_W - 1, 6, "T")
    _rect(g, 0, 7, BACKDROP_W - 1, 7, "O")
    # Wall face: white panels with seams, the blue stripe, the baseboard.
    _rect(g, 0, 8, BACKDROP_W - 1, 84, "W")
    _rect(g, 0, 8, BACKDROP_W - 1, 8, "C")
    for x in range(15, BACKDROP_W, 16):
        _rect(g, x, 9, x, 84, "w")
    _rect(g, 0, 79, BACKDROP_W - 1, 79, "b")
    _rect(g, 0, 80, BACKDROP_W - 1, 81, "B")
    _rect(g, 0, 85, BACKDROP_W - 1, 85, "w")
    _rect(g, 0, 86, BACKDROP_W - 1, 86, "T")
    _rect(g, 0, 87, BACKDROP_W - 1, 94, "p")
    _rect(g, 0, 95, BACKDROP_W - 1, 95, "O")

    # The window: a dark steel frame, lit on the top and left.
    x0, y0, x1, y1 = WINDOW
    _rect(g, x0, y0, x1, y1 - 6, "O")
    _rect(g, x0 + 1, y0 + 1, x1 - 1, y1 - 7, "T")
    _rect(g, x0 + 1, y0 + 1, x1 - 1, y0 + 1, "w")
    _rect(g, x0 + 1, y0 + 1, x0 + 1, y1 - 7, "w")
    gx0, gy0, gx1, gy1 = GLASS
    _rect(g, gx0, gy0, gx1, gy1, ".")
    for mx in MULLIONS:
        _rect(g, mx - 1, gy0, mx + 1, gy1, "T")
        _rect(g, mx - 1, gy0, mx - 1, gy1, "w")
        _rect(g, mx + 1, gy0, mx + 1, gy1, "p")
    # Sill: a ledge seen from slightly above.
    _rect(g, x0 - 1, y1 - 5, x1 + 1, y1 - 4, "C")
    _rect(g, x0 - 1, y1 - 3, x1 + 1, y1 - 2, "w")
    _rect(g, x0 - 1, y1 - 1, x1 + 1, y1, "O")

    # Hangers for the departure board, from the ceiling.
    bx0, by0, bx1, _ = BOARD
    for x in (bx0 + 12, bx1 - 12):
        _rect(g, x, 8, x, by0 - 1, "O")
    # A gate number sign on the wall between the window and the board.
    _rect(g, 177, 18, 182, 30, "O")
    _rect(g, 178, 19, 181, 29, "k")
    _text(g, 178, 20, "A", "F")
    _text(g, 178, 26, "3", "F")
    return g


def backdrop_sheet():
    return to_image(backdrop())


# --- The view outside -----------------------------------------------------

TARMAC_W = GLASS[2] - GLASS[0] + 1
TARMAC_H = GLASS[3] - GLASS[1] + 1
HORIZON = 21
PLANE_AT = (86, 14)  # where the plane's 67x17 drawing sits in the view


def tarmac():
    g = _blank(TARMAC_W, TARMAC_H)
    for y in range(TARMAC_H):
        for x in range(TARMAC_W):
            if y < HORIZON:
                key = "b"
            elif y == HORIZON:
                key = "T"
            else:
                key = "p" if (x * 3 + y * 5) % 11 else "T"
            put(g, y, x, key)
    # Clouds.
    for cx, cy, w in ((8, 6, 6), (40, 3, 4), (70, 8, 5), (128, 4, 7)):
        _rect(g, cx, cy, cx + w, cy, "C")
        _rect(g, cx + 1, cy - 1, cx + w - 2, cy - 1, "C")
        _rect(g, cx + 1, cy + 1, cx + w, cy + 1, "W")
    # The control tower, far off on the horizon.
    _rect(g, 24, 8, 26, HORIZON - 1, "T")
    _rect(g, 22, 5, 28, 7, "w")
    _rect(g, 23, 6, 27, 6, "k")
    _rect(g, 22, 4, 28, 4, "T")
    # A low distant hangar.
    _rect(g, 40, 16, 62, HORIZON - 1, "w")
    _rect(g, 40, 16, 62, 16, "W")
    _rect(g, 46, 18, 56, HORIZON - 1, "T")
    # Taxi lines: yellow dashes, plus a lead-in line curving to the plane.
    for x in range(0, TARMAC_W, 6):
        _rect(g, x, 44, min(x + 2, TARMAC_W - 1), 44, "Y")
    for x in range(PLANE_AT[0], TARMAC_W, 5):
        put(g, 34, x, "Y")
    # The parked plane, going nowhere.
    plane = _blank(68, 18)
    _plane(plane)
    px, py = PLANE_AT
    for y, row in enumerate(plane):
        for x, ch in enumerate(row):
            if ch != "." and 0 <= px + x < TARMAC_W:
                put(g, py + y, px + x, ch)
    # Reflections on the glass: short diagonal glints, top-left light.
    for x0, length in ((4, 6), (58, 4), (112, 5)):
        for i in range(length):
            put(g, 1 + i, x0 + length - i, "C")
    return g


def tarmac_sheet():
    return to_image(tarmac())


# --- Boarding pass close-up -----------------------------------------------

PASS_W, PASS_H = 96, 48
STUB_X = 70


def _big_text(g, x, y, text, key):
    """The 3x5 font at double size."""
    small = _blank(_text_width(text), 5)
    _text(small, 0, 0, text, key)
    for sy, row in enumerate(small):
        for sx, ch in enumerate(row):
            if ch != ".":
                _rect(g, x + sx * 2, y + sy * 2, x + sx * 2 + 1, y + sy * 2 + 1, ch)


def boarding_pass(expired):
    g = _blank(PASS_W, PASS_H)
    _rect(g, 0, 0, PASS_W - 1, PASS_H - 1, "O")
    # Paper, shaded along the right and bottom edges.
    _rect(g, 1, 1, PASS_W - 2, PASS_H - 2, "C")
    _rect(g, PASS_W - 2, 2, PASS_W - 2, PASS_H - 2, "c")
    _rect(g, 2, PASS_H - 2, PASS_W - 2, PASS_H - 2, "c")
    # Blue airline header with the title.
    _rect(g, 1, 1, PASS_W - 2, 9, "B")
    _rect(g, 1, 1, PASS_W - 2, 1, "b")
    _text(g, 4, 3, "BOARDING PASS", "C")
    _text(g, STUB_X + 4, 3, "PP404", "F")
    # Perforation between the pass and its stub.
    for y in range(10, PASS_H - 2, 2):
        put(g, y, STUB_X, "w")
    # Passenger details.
    for i, (label, value) in enumerate((("NAME", "AMANDA"), ("TO", "HOME"), ("GATE", "A3"), ("SEAT", "13C"))):
        y = 13 + i * 8
        _text(g, 4, y, label, "w")
        _text(g, 24, y, value, "k")
    # The stub: departure time and a barcode.
    _text(g, STUB_X + 4, 13, "BOARD", "w")
    _text(g, STUB_X + 4, 19, "0900", "k")
    for x in range(STUB_X + 4, PASS_W - 5):
        if (x * 5) % 7 < 3:
            _rect(g, x, 28, x, 42, "O")
    # A little chicken footprint, because of course.
    for x, y in ((52, 38), (51, 37), (53, 37), (52, 36), (50, 36), (54, 36)):
        put(g, y, x, "T")
    if expired:
        # A red rubber stamp: a double-ruled box with patchy ink.
        sx0, sy0, sx1, sy1 = 6, 14, 89, 36
        for y in range(sy0, sy1 + 1):
            for x in range(sx0, sx1 + 1):
                edge = x in (sx0, sx0 + 1, sx1 - 1, sx1) or y in (sy0, sy0 + 1, sy1 - 1, sy1)
                inner = x in (sx0 + 3, sx1 - 3) or y in (sy0 + 3, sy1 - 3)
                if (edge or inner) and (x * 7 + y * 13) % 17:
                    put(g, y, x, "R")
        word = "EXPIRED"
        tx = sx0 + (sx1 - sx0 + 1 - (_text_width(word) * 2)) // 2
        _big_text(g, tx, sy0 + 6, word, "R")
        # Wear: a few gaps in the letters.
        for x, y in ((tx + 3, sy0 + 8), (tx + 20, sy0 + 13), (tx + 37, sy0 + 7), (tx + 49, sy0 + 12)):
            put(g, y, x, "C")
    return g


def boarding_pass_sheet():
    return _strip([boarding_pass(False), boarding_pass(True)], PASS_W, PASS_H)


def mock_screen():
    """The opening's first shot: backdrop, view and floor, without the
    departure board or characters the game adds."""
    import tiles
    t = tiles.by_name()
    scr = Image.new("RGBA", (320, 180), (38, 43, 68, 255))
    scr.alpha_composite(tarmac_sheet(), (GLASS[0], GLASS[1]))
    scr.alpha_composite(backdrop_sheet(), (0, 0))
    for row in range(6, 12):
        for col in range(20):
            name = "carpet_pattern_shadow" if row == 6 else f"carpet_pattern_{'ab'[(row + col) % 2]}"
            scr.alpha_composite(to_image(t[name]), (col * 16, row * 16))
    return scr
