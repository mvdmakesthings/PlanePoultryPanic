"""The boarding gate door: 48x32, set into the back wall's face.

A dark sign with "GATE 1" in departure-board orange and a green boarding
light sits above two glass sliding doors. Four frames: closed, opening,
mostly open, open, revealing the dark jet bridge behind.
"""
from PIL import Image

from palette import put, to_image

W, H = 48, 32
FRAMES = 4

# 3x5 pixel font for the sign.
FONT = {
    "G": ["###", "#..", "#.#", "#.#", "###"],
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    " ": ["..", "..", "..", "..", ".."],
}


def _rect(g, x0, y0, x1, y1, key):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(g, y, x, key)


def _text(g, x, y, text, key):
    for ch in text:
        glyph = FONT[ch]
        for dy, row in enumerate(glyph):
            for dx, bit in enumerate(row):
                if bit == "#":
                    put(g, y + dy, x + dx, key)
        x += len(glyph[0]) + 1


def door(frame):
    g = ["." * W for _ in range(H)]
    # Sign: dark panel, orange letters, green boarding light.
    _rect(g, 4, 0, 43, 9, "O")
    _rect(g, 5, 1, 42, 8, "k")
    _text(g, 11, 2, "GATE 1", "y")
    _rect(g, 36, 3, 38, 5, "g")
    put(g, 3, 36, "q")

    # Door frame: metal posts and header around the doorway.
    _rect(g, 2, 10, 45, 31, "O")
    _rect(g, 3, 11, 44, 31, "W")
    _rect(g, 3, 11, 44, 11, "C")
    _rect(g, 6, 13, 41, 31, "O")

    # The jet bridge behind the doors: dark, with floor lines leading in.
    _rect(g, 7, 14, 40, 31, "v")
    for y in range(22, 32, 3):
        _rect(g, 7, y, 40, y, "k")
    _rect(g, 7, 14, 40, 15, "O")

    # Glass panels slide outward from the middle as the frame advances.
    opening = (0, 6, 12, 17)[frame]
    half = 17  # each panel's width when closed
    for side in (-1, 1):
        width = half - opening
        if width <= 0:
            continue
        if side < 0:
            x0, x1 = 7, 7 + width - 1
        else:
            x0, x1 = 40 - width + 1, 40
        _rect(g, x0, 14, x1, 31, "T")
        _rect(g, x0, 14, x1, 14, "W")
        # Diagonal reflections on the glass.
        for y in range(16, 31):
            rx = x0 + (y - 16) // 2 + 2
            if x0 <= rx <= x1 and y % 6 < 3:
                put(g, y, rx, "w")
        # Panel edge and handle where the doors meet.
        edge = x1 if side < 0 else x0
        _rect(g, edge, 14, edge, 31, "O")
        handle = edge - 2 if side < 0 else edge + 2
        if x0 <= handle <= x1:
            _rect(g, handle, 21, handle, 24, "C")

    # Threshold strip at the floor.
    _rect(g, 3, 31, 44, 31, "w")
    return g


def sheet():
    out = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
    for i in range(FRAMES):
        out.alpha_composite(to_image(door(i)), (i * W, 0))
    return out
