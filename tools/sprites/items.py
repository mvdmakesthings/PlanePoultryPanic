"""Item pickups and HUD icons."""
from PIL import Image

from palette import PALETTE, to_image

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


# Fire extinguisher HUD icon: 8x12, red canister, black hose, silver valve.
EXTINGUISHER = [
    "..OOO...",
    ".OWWWO..",
    "OOOWOOO.",
    ".ORRROkO",
    "OCRRRrOk",
    "OCRRRrOk",
    "ORRRRrO.",
    "ORYYYrO.",
    "ORYOYrO.",
    "ORRRRrO.",
    "OrrrrrO.",
    ".OOOOO..",
]


def extinguisher():
    return to_image(EXTINGUISHER)


# Emergency cabinet on the wall: two 16x20 frames, full then empty.
def cabinet_frame(full):
    g = ["." * 16 for _ in range(20)]
    _box(g, 0, 0, 15, 19, "R")
    for x in range(1, 15):
        _px(g, x, 18, "r")
    for y in range(1, 19):
        _px(g, 14, y, "r")
    # Glass door with the extinguisher (or nothing) behind it.
    _box(g, 3, 3, 12, 16, "k")
    if full:
        for y, row in enumerate(EXTINGUISHER[1:]):
            for x, ch in enumerate(row):
                if ch != ".":
                    _px(g, 5 + x, 4 + y, ch)
    # Glass shine and a white label strip.
    _px(g, 4, 4, "W")
    _px(g, 4, 5, "W")
    _px(g, 5, 4, "W")
    for x in range(4, 12):
        _px(g, x, 1, "C")
    return g


def cabinet():
    from PIL import Image as _Image
    out = _Image.new("RGBA", (32, 20), (0, 0, 0, 0))
    out.alpha_composite(to_image(cabinet_frame(True)), (0, 0))
    out.alpha_composite(to_image(cabinet_frame(False)), (16, 0))
    return out


# Ice block drawn over a frozen chicken: 16x16, outline and highlights only,
# so the chicken shows through the middle.
ICE_SIZE = (18, 20)


def ice():
    """A see-through block of ice drawn over a frozen chicken, a pixel wider
    than the chicken's frame on each side and two taller, so the whole bird
    sits inside: a pale top face, a cyan front face the chicken shows
    through, shine streaks, a hard blue rim and frost along the base. Its
    solid shape is the cue, so freezing reads without relying on color."""
    def rgba(key, alpha):
        hexcode = PALETTE[key]
        return tuple(int(hexcode[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)

    w, h = ICE_SIZE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    face = 3  # the ledge between the top face and the front face
    for y in range(h):
        for x in range(w):
            if x in (0, w - 1) and y in (0, h - 1):
                continue
            if x in (0, w - 1) or y in (0, h - 1):
                img.putpixel((x, y), rgba("b", 235))
            elif y < face:
                img.putpixel((x, y), rgba("C", 110))
            elif y == face:
                img.putpixel((x, y), rgba("C", 150))
            else:
                img.putpixel((x, y), rgba("q", 45))
    # Shine: two diagonal streaks across the front face, and glints.
    for x, y in [(2, 14), (3, 13), (4, 12), (5, 11), (2, 10), (3, 9), (4, 8)]:
        img.putpixel((x, y), rgba("C", 170))
    for x, y in [(15, 5), (15, 6), (2, 1), (3, 1)]:
        img.putpixel((x, y), rgba("C", 230))
    # Frost crusted along the base.
    for x in range(1, w - 1):
        img.putpixel((x, h - 2), rgba("C", 220 if x % 3 else 150))
    for x in (4, 9, 13):
        img.putpixel((x, h - 3), rgba("C", 170))
    return img


# Rolling suitcase: two 14x16 frames, closed then burst open. A green hard
# shell with a telescoping handle, a yellow tag, and two small wheels.
SUITCASE_SIZE = (14, 16)


def suitcase_frame(burst):
    w, h = SUITCASE_SIZE
    g = ["." * w for _ in range(h)]
    if not burst:
        # Handle grip and its two posts.
        _box(g, 4, 0, 9, 2, "w")
        _px(g, 5, 3, "w")
        _px(g, 8, 3, "w")
        # Shell with a shaded right side and bottom, and two ribs.
        _box(g, 0, 4, 13, 14, "g")
        for y in range(5, 14):
            _px(g, 12, y, "j")
            _px(g, 4, y, "j")
            _px(g, 9, y, "j")
        for x in range(1, 13):
            _px(g, x, 13, "j")
        _px(g, 2, 6, "L")
        _px(g, 2, 7, "L")
        # Luggage tag hanging off the side.
        _px(g, 11, 6, "Y")
        _px(g, 11, 7, "y")
        # Wheels.
        for x in (2, 3, 10, 11):
            _px(g, x, 15, "O")
        return g
    # Burst: the lid flies up, clothes spill out of the open bottom shell.
    _box(g, 1, 0, 12, 3, "g")
    for x in range(2, 12):
        _px(g, x, 2, "j")
    _box(g, 0, 10, 13, 15, "g")
    for x in range(1, 13):
        _px(g, x, 14, "j")
    # A red shirt, a blue sock, a yellow sock, and a white tee mid-air.
    for x, y, key in [
        (2, 6, "R"), (3, 6, "R"), (4, 6, "R"), (3, 7, "r"),
        (8, 5, "b"), (9, 5, "b"), (9, 6, "B"),
        (11, 8, "Y"), (12, 8, "y"),
        (5, 9, "W"), (6, 9, "W"), (7, 9, "W"), (6, 8, "W"),
        (1, 9, "F"), (10, 10, "R"),
    ]:
        _px(g, x, y, key)
    for x in range(2, 12):
        _px(g, x, 11, "W" if x % 3 else "R")
    return g


def suitcase():
    out = Image.new("RGBA", (SUITCASE_SIZE[0] * 2, SUITCASE_SIZE[1]), (0, 0, 0, 0))
    for i in range(2):
        out.alpha_composite(to_image(suitcase_frame(i == 1)), (i * SUITCASE_SIZE[0], 0))
    return out


# Maintenance key HUD icon and pickup: 12x8. A brass key with a round bow
# (the hole shows through), lit on the top left, with two teeth.
MAINTENANCE_KEY = [
    ".OOOO.......",
    "OFFYyO......",
    "OF..yOOOOOOO",
    "OY..yFFFFFFO",
    "OYyyyYyyyyyO",
    ".OOOOOOyOyOO",
    "......OyOyO.",
    "......OOOOO.",
]


def maintenance_key():
    return to_image(MAINTENANCE_KEY)
