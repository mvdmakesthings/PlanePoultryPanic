"""Item pickups and HUD icons."""
from PIL import Image

from palette import to_image

# A bag of chips: 10x12. Wide silver crimped seals pinch in to a puffy red
# bag with a yellow brand stripe, a shine on the left, and a chip on the front.
SNACK = [
    "OOOOOOOOOO",
    "OWwWwWwWwO",
    ".ORRRRRRO.",
    "ORCRRRRRrO",
    "OYFYYYYYyO",
    "ORCRRRRRrO",
    "ORRRFFRRrO",
    "ORRFYYyRrO",
    "ORRRYyRRrO",
    ".ORRRRRrO.",
    "OWwWwWwWwO",
    "OOOOOOOOOO",
]

# Health luggage: 12x10, full and empty.
LUGGAGE_FULL = [
    "....OOOO....",
    "....O..O....",
    "OOOOOOOOOOOO",
    "ObbbbBBBBBBO",
    "ObCbbBBBBBBO",
    "ObbbbBBBBkBO",
    "OOOOOOOOOOOO",
    "ObbbbBBBBkBO",
    "OBBBBkkkkkkO",
    ".OOOOOOOOOO.",
]
LUGGAGE_EMPTY = [row.replace("b", "p").replace("B", "k").replace("C", "p") for row in LUGGAGE_FULL]


def snack():
    return to_image(SNACK)


def luggage():
    """Two 12x10 frames side by side: full, empty."""
    out = Image.new("RGBA", (24, 10), (0, 0, 0, 0))
    out.alpha_composite(to_image(LUGGAGE_FULL), (0, 0))
    out.alpha_composite(to_image(LUGGAGE_EMPTY), (12, 0))
    return out


# Egg projectile (6x7) and the splat it leaves (10x6).
EGG = [
    "..OO..",
    ".OCCO.",
    "OCCCcO",
    "OCCCcO",
    "OCCccO",
    ".OccO.",
    "..OO..",
]
SPLAT = [
    "...OOOO...",
    ".OOCCCCOO.",
    "OCCCYYCCcO",
    "OcCYyyYCCO",
    ".OcCCCCcO.",
    "..OOOOOO..",
]


def egg():
    """Two frames side by side, each 10x7: egg (centered), then splat."""
    out = Image.new("RGBA", (20, 7), (0, 0, 0, 0))
    out.alpha_composite(to_image(EGG), (2, 0))
    out.alpha_composite(to_image(SPLAT), (10, 1))
    return out


# Baggage cart: two 24x20 frames (wheels turning), facing right, handle at left.
CART_SIZE = (24, 20)


def _box(g, x0, y0, x1, y1, fill, outline="O"):
    """Filled rectangle with a 1px outline, inclusive coordinates."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            edge = x in (x0, x1) or y in (y0, y1)
            g[y] = g[y][:x] + (outline if edge else fill) + g[y][x + 1:]


def _px(g, x, y, key):
    g[y] = g[y][:x] + key + g[y][x + 1:]


def cart_frame(frame):
    w, h = CART_SIZE
    g = ["." * w for _ in range(h)]
    # Handle bar.
    _box(g, 0, 1, 3, 14, "W")
    for y in range(2, 14):
        _px(g, 2, y, "w")
    # Green suitcase with a carry handle and a yellow tag.
    _box(g, 8, 1, 11, 4, ".")
    _box(g, 4, 3, 14, 13, "g")
    for y in range(4, 13):
        _px(g, 13, y, "j")
    for x in range(5, 14):
        _px(g, x, 12, "j")
    _px(g, 6, 5, "Y")
    _px(g, 6, 6, "y")
    # Red suitcase beside it, with a light strap.
    _box(g, 14, 6, 22, 13, "R")
    for y in range(7, 13):
        _px(g, 21, y, "r")
        _px(g, 18, y, "C")
    # Platform.
    _box(g, 0, 13, 23, 16, "W")
    for x in range(1, 23):
        _px(g, x, 14, "C")
        _px(g, x, 15, "w")
    # Wheels; the spoke highlight moves between frames.
    for cx in (5, 18):
        _box(g, cx - 2, 16, cx + 1, 19, "k")
        sx, sy = ((cx - 1, 17), (cx, 18))[frame]
        _px(g, sx, sy, "T")
    return g


def cart():
    from PIL import Image as _Image
    out = _Image.new("RGBA", (CART_SIZE[0] * 2, CART_SIZE[1]), (0, 0, 0, 0))
    for i in range(2):
        out.alpha_composite(to_image(cart_frame(i)), (i * CART_SIZE[0], 0))
    return out
