"""Item pickups and HUD icons."""
from PIL import Image

from palette import to_image

# A bag of airport pretzels: 8x8.
SNACK = [
    ".OOOOOO.",
    "OYFFFFYO",
    "OyRRRRyO",
    "ORFYYFRO",
    "ORYyyYRO",
    "ORFYYFRO",
    "OrRRRRrO",
    ".OOOOOO.",
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
