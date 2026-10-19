"""Normal chicken sprites: 16x16 frames.

Side view faces right. Walk cycles are 4 frames per direction; the side
walk bobs the head forward on contact frames, and the front and back
views waddle side to side.
"""
from palette import mirror, put

SIDE = [
    "................",
    "..........RR....",
    ".........RRRR...",
    "........OCCCCO..",
    "........OCCOCYY.",
    "..O.....OCCCCyO.",
    ".OCO....OCCCRO..",
    ".OCCO..OCCCCrO..",
    ".OCCCOOCCCCCO...",
    ".OCCCCCCCCCCO...",
    ".OcCCCccCCCCO...",
    "..OcCCCccCCcO...",
    "...OcccccccO....",
    "....OOOOOOO.....",
    ".....y...y......",
    "....yy..yy......",
]

FRONT = [
    "................",
    "......RRRR......",
    ".....RRRRRR.....",
    "....OCCCCCCO....",
    "....OCOCCOCO....",
    "....OCCYYCCO....",
    "...OCCCyyCCCO...",
    "..OcCCCRRCCCcO..",
    ".OcCCCCRRCCCCcO.",
    ".OcCCCCCCCCCCcO.",
    ".OccCCCCCCCCccO.",
    "..OccCCCCCCccO..",
    "...OccccccccO...",
    "....OOOOOOOO....",
    ".....y....y.....",
    "....yy....yy....",
]

BACK = [
    "................",
    "......RRRR......",
    ".....RRRRRR.....",
    "....OCCCCCCO....",
    "....OCCCCCCO....",
    "....OcCCCCcO....",
    "...OCCCCCCCCO...",
    "..OcCCCCCCCCcO..",
    ".OcCCCcCCcCCCcO.",
    ".OcCCCcCCcCCCcO.",
    ".OccCCCccCCCccO.",
    "..OccCCccCCccO..",
    "...OccccccccO...",
    "....OOOOOOOO....",
    ".....y....y.....",
    "....yy....yy....",
]


def chicken_side_walk(base):
    body = base[:14]

    def frame(legs, head_forward, raise_body):
        g = list(body)
        if head_forward:
            for r in range(1, 8):
                put(g, r, 8, "." + g[r][8:15])
        if raise_body:
            g = g[1:] + ["." * 16]
        g = g[:16 - len(legs)] + legs
        return g

    spread_a = ["....y....Y......", "...yy....YY....."]
    spread_b = ["....Y....y......", "...YY....yy....."]
    tucked = ["......Yy........", ".....YY.yy......"]
    return [frame(spread_a, True, False), frame(tucked, False, True),
            frame(spread_b, True, False), frame(tucked, False, True)]


def chicken_waddle(base):
    body = base[:14]

    def shifted(dx):
        if dx > 0:
            return ["." * dx + r[:-dx] for r in body]
        if dx < 0:
            return [r[-dx:] + "." * -dx for r in body]
        return list(body)

    left_up = [".....y..........", "....yy....yy...."]
    right_up = ["..........y.....", "....yy....yy...."]
    both = [".....y....y.....", "....yy....yy...."]
    # Weight shifts onto the planted foot; the other foot lifts.
    return [shifted(-1) + right_up, body + both, shifted(1) + left_up, body + both]


def walk_cycle():
    """Walk frames keyed by direction: down, up, right, left."""
    right = chicken_side_walk(SIDE)
    return {
        "down": chicken_waddle(FRONT),
        "up": chicken_waddle(BACK),
        "right": right,
        "left": [mirror(f) for f in right],
    }
