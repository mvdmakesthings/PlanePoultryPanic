"""Shared palette and helpers for grid-based sprites.

Each sprite is a list of equal-length strings. Every character is a key
into PALETTE, and "." is transparent. All colors come from ENDESGA 32
(see docs/art-style-guide.md).
"""
from PIL import Image

PALETTE = {
    "O": "181425",  # outline
    "H": "b55088",  # hair base
    "h": "f6757a",  # hair light
    "d": "68386c",  # hair dark
    "S": "e8b796",  # skin
    "s": "c28569",  # skin shadow
    "T": "5a6988",  # tattoo ink
    "M": "be4a2f",  # mouth
    "W": "c0cbdc",  # shirt
    "w": "8b9bb4",  # shirt shadow
    "L": "ffffff",  # shirt print / highlight
    "B": "124e89",  # backpack
    "b": "0099db",  # backpack light
    "k": "262b44",  # backpack dark
    "P": "262b44",  # leggings
    "p": "3a4466",  # leggings light
    "N": "262b44",  # boots
    "G": "8b9bb4",  # boot shine
    # chicken
    "C": "ffffff",
    "c": "ead4aa",
    "e": "c28569",
    "R": "e43b44",
    "r": "a22633",
    "Y": "feae34",
    "y": "f77622",
}


def to_image(grid):
    h, w = len(grid), len(grid[0])
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(grid):
        assert len(row) == w, f"row {y} is {len(row)} wide: {row!r}"
        for x, ch in enumerate(row):
            if ch != ".":
                rgb = tuple(int(PALETTE[ch][i:i + 2], 16) for i in (0, 2, 4))
                img.putpixel((x, y), rgb + (255,))
    return img


def mirror(grid):
    """Flip horizontally, e.g. to make left-facing frames from right-facing ones."""
    return [row[::-1] for row in grid]


def put(grid, row, col, text):
    """Overwrite part of a row in place. "." in text is written too (clears)."""
    r = grid[row]
    grid[row] = r[:col] + text + r[col + len(text):]


def blank_rows(n, width=16):
    return ["." * width for _ in range(n)]
