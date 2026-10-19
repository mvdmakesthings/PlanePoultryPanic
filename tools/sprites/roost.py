"""The roost: a 24x14 nest of straw and lost luggage where chickens gather
to form a totem. Drawn on the floor; chickens stand in its middle.
"""
import math

from PIL import Image

from palette import put, to_image

W, H = 24, 14


def nest():
    g = ["." * W for _ in range(H)]
    cx, cy = W / 2, H / 2
    for y in range(H):
        for x in range(W):
            # Flattened ring: the floor is seen at an angle.
            d = math.hypot((x + 0.5 - cx) / (W / 2), (y + 0.5 - cy) / (H / 2))
            if d < 0.55:
                put(g, y, x, "m")  # dark hollow in the middle
            elif d < 0.8:
                put(g, y, x, "F" if (x * 3 + y * 5) % 7 < 3 else "a")
            elif d < 1.0:
                put(g, y, x, "O" if d > 0.9 else ("e" if (x + y) % 3 else "a"))
    # Straw strands poking out.
    for x, y in ((2, 4), (21, 5), (4, 11), (19, 11), (11, 0)):
        put(g, y, x, "F")
    # A lost luggage tag and a feather in the straw.
    put(g, 3, 6, "R")
    put(g, 3, 7, "R")
    put(g, 9, 17, "C")
    put(g, 9, 18, "c")
    return g


def sheet():
    return to_image(nest())
