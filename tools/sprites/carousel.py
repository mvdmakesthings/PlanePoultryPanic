"""Baggage carousel: modular 16x16 tiles in 3/4 view, 4 animation frames.

A carousel is a rectangle of tiles: corners, straight belt runs on each
side, and a raised center island. The belt runs clockwise. Every piece
is defined by "bands": the color at each distance from the island, with
belt bands getting moving slat seams. Corners sweep the same bands
around a quarter circle, so pieces line up at any carousel size.
"""
import math

from PIL import Image

from palette import to_image

FRAMES = 4
SLAT = 4  # pixels between slat seams
SEAM = "v"

# Bands across the back (top) belt, from the outside (row 0) to the
# island (row 15). Entries marked "*" are belt and get seams.
TOP_BANDS = [".", ".", "O", "C", "W", "w", "n*", "m*", "m*", "m*", "m*", "v", "O", "W", "w", "w"]
# Bands across the front (bottom) belt, from the island (row 0) to the
# floor (row 15). Rows 10-14 are the rim and the carousel's front skirt.
BOTTOM_BANDS = ["w", "w", "T", "p", "O", "n*", "m*", "m*", "m*", "v", "C", "W", "w", "T", "T", "O"]

PIECES = ("top_left", "top", "top_right", "left", "island", "right",
          "bottom_left", "bottom", "bottom_right", "chute")

# The baggage chute: a dark opening in the back rim with rubber flaps,
# drawn over a "top" piece. "." keeps the belt underneath.
CHUTE = [
    "..OOOOOOOOOOOO..",
    ".OWOOOOOOOOOOWO.",
    ".OwOkkkkkkkkOwO.",
    ".OwOpkpkpkpkOwO.",
    ".OwOpkpkpkpkOwO.",
    ".OwOpkpkpkpkOwO.",
    ".OwOpkpkpkpkOwO.",
    ".OwOpkpkpkpkOwO.",
    ".OwOp.p.p.p.OwO.",
    ".OwOp...p...OwO.",
    ".OTO........OTO.",
    "................",
    "................",
    "................",
    "................",
    "................",
]


def band(bands, idx, s, frame, direction):
    """Color at band idx; s is position along the belt, direction +1/-1."""
    if idx < 0 or idx >= len(bands):
        return "."
    ch = bands[idx]
    if ch.endswith("*"):
        return SEAM if math.floor(s - direction * frame) % SLAT == 0 else ch[0]
    return ch


def straight(piece, x, y, frame):
    if piece == "top":       # moves right
        return band(TOP_BANDS, y, x, frame, 1)
    if piece == "bottom":    # moves left
        return band(BOTTOM_BANDS, y, x, frame, -1)
    if piece == "left":      # moves up; island on the right
        return band(TOP_BANDS, x, y, frame, -1)
    if piece == "right":     # moves down; island on the left
        return band(TOP_BANDS, 15 - x, y, frame, 1)
    raise ValueError(piece)


def front_corner(r, side, down, s, frame):
    """Bottom corners: the front skirt only shows where the rim faces the
    viewer. Toward the side it tapers into the side rim's single outline."""
    idx = math.floor(r)
    if idx >= 13 and down < side:
        return "O" if idx == 13 else "."
    return band(BOTTOM_BANDS, idx, s, frame, 1)


def corner(piece, x, y, frame):
    px, py = x + 0.5, y + 0.5
    # Arc length along the belt's middle radius, increasing clockwise.
    arc = lambda theta: theta * 8
    if piece == "top_left":      # island at bottom-right; belt goes left -> top
        dx, dy = 16 - px, 16 - py
        r = math.hypot(dx, dy)
        return band(TOP_BANDS, math.floor(16 - r), arc(math.atan2(dy, dx)), frame, 1)
    if piece == "top_right":     # island at bottom-left; belt goes top -> right
        dx, dy = px, 16 - py
        r = math.hypot(dx, dy)
        return band(TOP_BANDS, math.floor(16 - r), arc(math.atan2(dx, dy)), frame, 1)
    if piece == "bottom_right":  # island at top-left; belt goes right -> bottom
        dx, dy = px, py
        r = math.hypot(dx, dy)
        return front_corner(r, dx, dy, arc(math.atan2(dy, dx)), frame)
    if piece == "bottom_left":   # island at top-right; belt goes bottom -> left
        dx, dy = 16 - px, py
        r = math.hypot(dx, dy)
        return front_corner(r, dx, dy, arc(math.atan2(dx, dy)), frame)
    raise ValueError(piece)


def island(x, y):
    # Plain light metal, so the island never reads as a hole in the floor.
    return "w"


def piece_grid(piece, frame):
    rows = []
    for y in range(16):
        row = ""
        for x in range(16):
            if piece == "island":
                row += island(x, y)
            elif piece == "chute":
                over = CHUTE[y][x]
                row += over if over != "." else straight("top", x, y, frame)
            elif piece in ("top", "bottom", "left", "right"):
                row += straight(piece, x, y, frame)
            else:
                row += corner(piece, x, y, frame)
        rows.append(row)
    return rows


def sheet():
    """Rows are pieces (see PIECES), columns are the 4 belt frames."""
    out = Image.new("RGBA", (16 * FRAMES, 16 * len(PIECES)), (0, 0, 0, 0))
    for row, piece in enumerate(PIECES):
        for frame in range(FRAMES):
            out.alpha_composite(to_image(piece_grid(piece, frame)), (frame * 16, row * 16))
    return out


def assemble(cols, rows, frame):
    """A whole carousel, cols x rows tiles (each at least 2), for previews."""
    out = Image.new("RGBA", (cols * 16, rows * 16), (0, 0, 0, 0))
    for r in range(rows):
        for c in range(cols):
            v = "top" if r == 0 else "bottom" if r == rows - 1 else "mid"
            h = "left" if c == 0 else "right" if c == cols - 1 else "mid"
            if v == "mid" and h == "mid":
                name = "island"
            elif v == "mid":
                name = h
            elif h == "mid":
                name = v
            else:
                name = f"{v}_{h}"
            out.alpha_composite(to_image(piece_grid(name, frame)), (c * 16, r * 16))
    return out
