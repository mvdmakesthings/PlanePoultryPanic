"""Player sprites: 16x32 frames.

Base poses face down (FRONT), up (BACK), and right (SIDE). Walk cycles are
4 frames per direction: contact, passing, contact with the other leg,
passing. Left-facing frames are mirrored from right-facing ones.
"""
from palette import blank_rows, mirror, put

FRONT = [
    ".....OOOOOO.....",
    "...OOhhhHHHOO...",
    "..OhhHHHHHHHdO..",
    "..OhHHHHHHHHdO..",
    ".OHHHHHHHHHHHdO.",
    ".OHHHdSSSSdHHdO.",
    ".OHHdSSSSSSdHdO.",
    ".OHHSOSSSSOSHdO.",
    ".OHHSSSSSSSSHdO.",
    ".OHHsSSMMSSsHdO.",
    ".OHHHsSSSSsHHdO.",
    ".OdHHHOssOHHHdO.",
    "..OddBWWWWBddO..",
    ".OwWWBWWWWBWWwO.",
    ".OwWWBTTTTBWWwO.",
    ".OSOwBWTTWBwOSO.",
    ".OTOwBWWWWBwOTO.",
    ".OSOwkWWWWkwOTO.",
    ".OTOwWWWWWWwOSO.",
    ".OSOwwWWWWwwOSO.",
    ".OsOOPPPPPPOOsO.",
    "..OOOPPPPPPOOO..",
    "....OPpPPpPO....",
    "....OPpPPpPO....",
    "....OPpOOpPO....",
    "....OPpOOpPO....",
    "....OPpOOpPO....",
    "....OPPOOPPO....",
    "...OGNNOONNGO...",
    "...ONNNOONNNO...",
    "...OOOOOOOOOO...",
    "................",
]

BACK = [
    ".....OOOOOO.....",
    "...OOhhhHHHOO...",
    "..OhhHHHHHHHdO..",
    "..OhHHHHHHHHdO..",
    ".OHHhHHHhHHHHdO.",
    ".OHHhHHHhHHhHdO.",
    ".OHHHhHHHhHhHdO.",
    ".OHHHhHHHhHHhdO.",
    ".OHHHHhHHHhHhdO.",
    ".OdHHHhHHHhHHdO.",
    ".OdHHHHHHHHHHdO.",
    ".OdHHdHHHHdHHdO.",
    ".OOdHdBBBBdHdOO.",
    ".OwOkbbBBBBkOwO.",
    ".OwOkbBBBBBkOwO.",
    ".OSOkbBBBBBkOSO.",
    ".OTOkbBkkBBkOTO.",
    ".OSOkbBBBBBkOTO.",
    ".OTOkbBBBBBkOSO.",
    ".OSOkkBBBBkkOSO.",
    ".OsOOkkkkkkOOsO.",
    "..OOOPPPPPPOOO..",
    "....OPPPPPPO....",
    "....OPPPPPPO....",
    "....OPpOOpPO....",
    "....OPpOOpPO....",
    "....OPpOOpPO....",
    "....OPPOOPPO....",
    "...OGNNOONNGO...",
    "...ONNNOONNNO...",
    "...OOOOOOOOOO...",
    "................",
]

SIDE = [
    "......OOOOO.....",
    "....OOhhhHHO....",
    "...OhhHHHHHHO...",
    "..OhHHHHHHHHHO..",
    "..OHHHHHHHHHhO..",
    "..OHHHHHHdSSSO..",
    "..OHHHHHHdSOSO..",
    "..OHHHHHHdSSSSO.",
    "..OHHHHHHdSSMO..",
    "..OHHHHHHHsSO...",
    "..OdHHHHHHHOO...",
    ".OOdHHHdHHsO....",
    ".OBOdHdOWWO.....",
    "OBbBOdOWWWWO....",
    "ObbBBOwWWWWO....",
    "ObBBBOwWWLWO....",
    "ObBkBOwWTSWO....",
    "ObBBBOwWTSWO....",
    "ObBkBOwWSTWO....",
    "OkBBBOwwSSwO....",
    ".OkkkOPPsSPO....",
    "..OOOPPPOOPO....",
    ".....OPpPPPO....",
    ".....OPpPPPO....",
    ".....OPpPPPO....",
    ".....OPpPPPO....",
    ".....OPpPPPO....",
    ".....OPPPPPO....",
    ".....OGNNNNOO...",
    ".....ONNNNNNO...",
    ".....OOOOOOOO...",
    "................",
]

# Side-view legs, rows 23-30, near (lit) leg in front.
SIDE_STRIDE_NEAR_FRONT = [
    ".....OPPPpPO....",
    ".....OPPOPpO....",
    "....OPPO.OPpO...",
    "....OPPO.OPpO...",
    "...OPPO...OPpO..",
    "...OGNNO..OGNNO.",
    "..ONNNNO.ONNNNO.",
    "..OOOOOO.OOOOOO.",
]

# Side-view legs, rows 23-30, near (lit) leg behind.
SIDE_STRIDE_NEAR_BACK = [
    ".....OPpPPPO....",
    ".....OPpOPPO....",
    "....OPpO.OPPO...",
    "....OPpO.OPPO...",
    "...OPpO...OPPO..",
    "...OGNNO..OGNNO.",
    "..ONNNNO.ONNNNO.",
    "..OOOOOO.OOOOOO.",
]

# Side-view legs, rows 22-30, back foot lifting.
SIDE_PASSING = [
    ".....OPpPPPO....",
    ".....OPpPPPO....",
    ".....OPpPPPO....",
    ".....OPpPPPO....",
    "....OPPOPpPO....",
    "...OPPOOPpPO....",
    "...ONNOOGNNNOO..",
    "....OO.ONNNNNO..",
    ".......OOOOOOO..",
]


def leg_columns(grid):
    """Split rows 22-30 into left (cols 3-7) and right (cols 8-12) legs."""
    rows = grid[22:31]
    return [r[3:8] for r in rows], [r[8:13] for r in rows]


def short_leg(leg):
    # Foot lifted: drop a shin row, leave the bottom row empty.
    return leg[:3] + leg[4:] + ["....."]


def long_leg(leg):
    # Foot planted toward the camera: repeat a shin row, foot one row lower.
    return leg[:4] + [leg[3]] + leg[4:]


def with_legs(base, left, right):
    g = base[:22] + blank_rows(10)
    for i in range(10):
        l = left[i] if i < len(left) else "....."
        r = right[i] if i < len(right) else "....."
        put(g, 22 + i, 3, l)
        put(g, 22 + i, 8, r)
    return g


def swing_arm(grid, cols):
    """Hand swings forward: forearm (rows 15-21) moves down one pixel."""
    g = list(grid)
    a, b = cols
    seg = [g[r][a:b] for r in range(15, 22)]
    for i, text in enumerate(seg):
        put(g, 16 + i, a, text)
    return g


def front_back_walk(base):
    left, right = leg_columns(base)
    stand = with_legs(base, left, right)
    f0 = swing_arm(with_legs(base, long_leg(left), short_leg(right)), (12, 15))
    f2 = swing_arm(with_legs(base, short_leg(left), long_leg(right)), (1, 4))
    return [f0, stand, f2, stand]


def side_walk(base):
    upper = base[:22]
    # Contact frames: legs spread, so the hips (and whole upper body) drop 1px.
    lowered = ["." * 16] + upper
    f0 = lowered + SIDE_STRIDE_NEAR_FRONT + ["." * 16]
    f2 = lowered + SIDE_STRIDE_NEAR_BACK + ["." * 16]
    passing = upper + SIDE_PASSING + ["." * 16]
    return [f0, passing, f2, passing]


def walk_cycle():
    """Walk frames keyed by direction: down, up, right, left."""
    right = side_walk(SIDE)
    return {
        "down": front_back_walk(FRONT),
        "up": front_back_walk(BACK),
        "right": right,
        "left": [mirror(f) for f in right],
    }


def breathe(grid):
    """Head and hair sink 1px by dropping the neck row (row 11)."""
    return ["." * 16] + grid[:11] + grid[12:]


def idle_cycle():
    """Two-frame breathing idle keyed by direction: down, up, right, left."""
    right = [SIDE, breathe(SIDE)]
    return {
        "down": [FRONT, breathe(FRONT)],
        "up": [BACK, breathe(BACK)],
        "right": right,
        "left": [mirror(f) for f in right],
    }
