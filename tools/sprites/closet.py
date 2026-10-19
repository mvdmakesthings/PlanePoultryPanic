"""Supply closet door: 16x30, set into the back wall's face.

A slate-gray staff door with a small window, a yellow "staff only" plaque
and a handle. Two frames: closed, then open onto the dark closet.
"""
from PIL import Image

from palette import put, to_image

W, H = 16, 30


def _rect(g, x0, y0, x1, y1, key):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(g, y, x, key)


def door(frame):
    g = ["." * W for _ in range(H)]
    # Frame around the doorway.
    _rect(g, 0, 0, 15, 29, "O")
    _rect(g, 1, 1, 14, 29, "w")
    _rect(g, 2, 2, 13, 29, "O")
    if frame == 0:
        # Closed door: slate panel, window, plaque, handle, kick plate.
        _rect(g, 3, 3, 12, 29, "T")
        _rect(g, 3, 3, 12, 3, "w")
        _rect(g, 5, 5, 10, 9, "O")
        _rect(g, 6, 6, 9, 8, "k")
        put(g, 6, 6, "W")
        _rect(g, 5, 12, 10, 13, "Y")
        put(g, 12, 5, "y")
        _rect(g, 11, 17, 11, 18, "C")
        _rect(g, 3, 26, 12, 28, "p")
    else:
        # Open: the dark closet with a mop leaning inside, door swung in.
        _rect(g, 3, 3, 12, 29, "v")
        _rect(g, 3, 3, 4, 29, "T")
        _rect(g, 9, 6, 9, 24, "m")
        _rect(g, 8, 24, 10, 27, "W")
    return g


def sheet():
    out = Image.new("RGBA", (W * 2, H), (0, 0, 0, 0))
    for i in range(2):
        out.alpha_composite(to_image(door(i)), (i * W, 0))
    return out
