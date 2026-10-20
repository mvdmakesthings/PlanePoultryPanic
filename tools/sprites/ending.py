"""The ending scene's art: the last plane leaving at night.

- ending_sky.png: one 320x180 night backdrop: stars, a big moon, the dark
  terminal and control tower on the horizon, and the tarmac.
- plane_side.png: the last plane seen side on, 128x40, 2 frames: wheels
  down, then wheels up with the engines' glow.
- stowaway.png: one cabin window, 16x16, 3 frames: dark, a chicken's head
  popping up, the chicken winking with a glowing teal eye.
"""
import math
import random

from PIL import Image

from palette import PALETTE, put, to_image
from set_dressing import _blank, _outline, _rect, _strip, _text, _text_width


def _rgb(key):
    return tuple(int(PALETTE[key][i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def sky():
    """The night backdrop. Light dithering on the sky is allowed for large
    areas (see the style guide)."""
    W, H = 320, 180
    img = Image.new("RGBA", (W, H), _rgb("O"))
    px = img.load()
    # Sky: deepest at the top, a band of navy toward the horizon, dithered.
    for y in range(0, 132):
        for x in range(W):
            # Denser toward the horizon: every 4th, then every 2nd, then all.
            if y > 100 or (y > 84 and (x + y) % 2 == 0) or (y > 66 and (x + 2 * y) % 4 == 0):
                px[x, y] = _rgb("k")
            if y > 118 and (x + y) % 2 == 0:
                px[x, y] = _rgb("B")
    rnd = random.Random(13)
    for _ in range(90):
        x, y = rnd.randrange(W), rnd.randrange(100)
        px[x, y] = _rgb("W" if rnd.random() < 0.7 else "C")
    # The moon, with a couple of craters.
    cx, cy, r = 250, 34, 14
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                px[x, y] = _rgb("c" if (x - cx) + (y - cy) > 6 else "C")
    for dx, dy in ((-4, -3), (5, 4), (-2, 6)):
        px[cx + dx, cy + dy] = _rgb("c")
        px[cx + dx + 1, cy + dy] = _rgb("c")
    # The terminal and control tower on the horizon, lit windows here and there.
    for x in range(0, 200):
        top = 120 if x < 150 else 126
        for y in range(top, 132):
            px[x, y] = _rgb("O")
        if x % 6 < 2 and x < 150:
            px[x, 124] = _rgb("F" if (x // 6) % 3 else "y")
    for y in range(92, 132):
        for x in range(170, 178):
            px[x, y] = _rgb("O")
    for x in range(164, 184):
        for y in range(86, 94):
            px[x, y] = _rgb("p")
    for x in range(166, 182, 3):
        px[x, 89] = _rgb("b")
    px[173, 84] = _rgb("R")
    # Tarmac with runway edge lights.
    for y in range(132, H):
        for x in range(W):
            px[x, y] = _rgb("k" if y < 150 else "O")
    for x in range(4, W, 16):
        px[x, 148] = _rgb("Y")
        px[x + 8, 160] = _rgb("b")
    return img


PLANE_W, PLANE_H = 128, 40


def plane(frame):
    """The last plane, side on, facing right: white fuselage with a blue
    stripe and a row of lit windows, a swept tail, an engine under the
    wing, and wheels (down in frame 0, tucked up in frame 1)."""
    g = _blank(PLANE_W, PLANE_H)
    # Fuselage: a long rounded body.
    for x in range(8, 124):
        top, bottom = 12, 26
        if x > 112:
            curve = (x - 112) / 12.0
            top = 12 + round(curve * 5)
            bottom = 26 - round(curve * 3)
        if x < 20:
            top = 12 + round((20 - x) / 12.0 * 3)
        for y in range(top, bottom + 1):
            put(g, y, x, "C" if y < 18 else "W")
    _rect(g, 10, 21, 118, 22, "B")
    _rect(g, 10, 23, 118, 23, "b")
    for x in range(26, 108, 5):
        put(g, 16, x, "F")
        put(g, 16, x + 1, "F")
    # Cockpit windows.
    _rect(g, 114, 15, 118, 16, "k")
    # Tail fin and the airline's teal-free blue flash.
    for y in range(1, 13):
        _rect(g, 3 + (y - 1) * 5 // 11, y, 7 + (y - 1) * 13 // 11, y, "B")
    _rect(g, 4, 2, 6, 2, "b")
    # Wing (seen edge-on, a dark wedge) and the engine.
    _rect(g, 50, 24, 80, 25, "w")
    _rect(g, 58, 26, 72, 30, "T")
    _rect(g, 58, 26, 72, 26, "W")
    _rect(g, 72, 27, 73, 29, "O")
    if frame == 1:
        put(g, 28, 56, "y")
        put(g, 28, 57, "Y")
    else:
        for x in (36, 96):
            _rect(g, x, 27, x, 33, "T")
            _rect(g, x - 2, 34, x + 2, 36, "O")
            _rect(g, x - 1, 35, x + 1, 35, "p")
    return _outline(g)


def plane_sheet():
    return _strip([plane(f) for f in range(2)], PLANE_W, PLANE_H)


def stowaway(frame):
    """A cabin window up close at night: empty, then a chicken's head pops
    up into it, then it winks, one eye glowing mushroom teal."""
    g = _blank(16, 16)
    _rect(g, 2, 1, 13, 14, "W")
    _rect(g, 3, 2, 12, 13, "O")
    _rect(g, 4, 3, 11, 12, "k")
    put(g, 4, 4, "p")
    if frame > 0:
        # Comb, head, beak.
        _rect(g, 6, 5, 8, 5, "R")
        _rect(g, 5, 6, 10, 12, "C")
        _rect(g, 9, 9, 11, 10, "Y")
        # The eye: plain at first, then glowing teal (a little magic left).
        put(g, 8, 8, "O" if frame == 1 else "q")
        if frame == 2:
            put(g, 7, 8, "q")
        put(g, 11, 10, "R")
    return g


def stowaway_sheet():
    return _strip([stowaway(f) for f in range(3)], 16, 16)
