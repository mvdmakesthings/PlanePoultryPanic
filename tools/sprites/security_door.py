"""The locked door to Security: 48x32, set into the back wall's face.

A corporate-blue sign reading "SECURITY" sits above a pair of steel
sliding doors with a key lock and a status light. Four frames: locked
(red light, a yellow-and-black barrier tape across the doors), unlocked
(green light), opening, open onto the dark corridor beyond. It fits the
same spot and doorway as the boarding gate (see gate.py).
"""
from PIL import Image

from palette import put, to_image
from set_dressing import _rect, _text, _text_width

W, H = 48, 32
FRAMES = 4


def door(frame):
    g = ["." * W for _ in range(H)]
    locked = frame == 0
    # Sign: blue panel with white letters.
    _rect(g, 4, 0, 43, 9, "O")
    _rect(g, 5, 1, 42, 8, "B")
    _rect(g, 5, 1, 42, 1, "b")
    title = "SECURITY"
    _text(g, (W - _text_width(title)) // 2, 3, title, "C")

    # Door frame: metal posts and header around the doorway.
    _rect(g, 2, 10, 45, 31, "O")
    _rect(g, 3, 11, 44, 31, "W")
    _rect(g, 3, 11, 44, 11, "C")
    _rect(g, 6, 13, 41, 31, "O")
    # The corridor beyond: dark, with floor lines leading in.
    _rect(g, 7, 14, 40, 31, "v")
    for y in range(22, 32, 3):
        _rect(g, 7, y, 40, y, "k")
    _rect(g, 7, 14, 40, 15, "O")

    # Steel panels slide outward from the middle as the doors open.
    opening = (0, 0, 8, 17)[frame]
    half = 17
    for side in (-1, 1):
        width = half - opening
        if width <= 0:
            continue
        x0, x1 = (7, 7 + width - 1) if side < 0 else (40 - width + 1, 40)
        _rect(g, x0, 14, x1, 31, "w")
        _rect(g, x0, 14, x1, 14, "W")
        # Small wired-glass window high on each panel.
        wx = x0 + 3 if side < 0 else x1 - 7
        if x0 <= wx and wx + 4 <= x1:
            _rect(g, wx, 17, wx + 4, 20, "O")
            _rect(g, wx + 1, 18, wx + 3, 19, "k")
            put(g, 18, wx + 1, "T")
        # Kick plate along the bottom.
        _rect(g, x0, 28, x1, 30, "T")
        edge = x1 if side < 0 else x0
        _rect(g, edge, 14, edge, 31, "O")

    # Key lock and status light on the right post.
    _rect(g, 42, 18, 44, 23, "O")
    put(g, 19, 43, "R" if locked else "l")
    put(g, 20, 43, "r" if locked else "g")
    put(g, 22, 43, "Y")

    if locked:
        # Yellow-and-black barrier tape across the closed doors.
        for x in range(5, 43):
            for y, offset in ((23, 0), (24, 1)):
                put(g, y, x, "F" if (x + offset) // 2 % 2 == 0 else "O")
    # Threshold strip at the floor.
    _rect(g, 3, 31, 44, 31, "w")
    return g


def sheet():
    out = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
    for i in range(FRAMES):
        out.alpha_composite(to_image(door(i)), (i * W, 0))
    return out
