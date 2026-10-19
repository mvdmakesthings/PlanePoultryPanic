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


# ---------- holding the fire extinguisher ----------

# A small extinguisher carried by its handle: 5x8.
HELD_EXTINGUISHER = [
    ".OO..",
    "OWWO.",
    "ORRrO",
    "OCRrO",
    "ORRrO",
    "OYYrO",
    "ORRrO",
    ".OOO.",
]

# Which column holds the carrying hand in each base view. It's the same
# (left) hand in every view: viewer's right from the front, viewer's left
# from behind.
HAND_COLUMN = {"down": 13, "up": 2, "right": 8}


def _hand_row(grid, column):
    """Lowest skin pixel in the hand column, so the extinguisher follows arm swing."""
    rows = [r for r in range(14, 24) if grid[r][column] in "sS"]
    return rows[-1] if rows else 20


def holding_extinguisher(grid, view):
    g = list(grid)
    column = HAND_COLUMN[view]
    top = _hand_row(g, column)
    left = min(max(column - 2, 0), 16 - len(HELD_EXTINGUISHER[0]))
    for dy, row in enumerate(HELD_EXTINGUISHER):
        for dx, ch in enumerate(row):
            y, x = top + dy, left + dx
            if ch != "." and 0 <= y < len(g) and 0 <= x < 16:
                put(g, y, x, ch)
    return g


def _with_extinguisher(cycle):
    out = {}
    for direction, view in (("down", "down"), ("up", "up"), ("right", "right")):
        out[direction] = [holding_extinguisher(f, view) for f in cycle[direction]]
    out["left"] = [mirror(f) for f in out["right"]]
    return out


def walk_cycle_extinguisher():
    return _with_extinguisher(walk_cycle())


def idle_cycle_extinguisher():
    return _with_extinguisher(idle_cycle())


# ---------- knocked out ----------

# The game-over pose: 32x20 frames, the player flat on their back with
# X eyes, head to the left, and stars circling above the head.
KO_SIZE = (32, 20)
# Centers of the plus-shaped stars in each frame, so they seem to circle.
KO_STARS = [((2, 2), (10, 1)), ((6, 1), (13, 2))]


def _x_eyes(grid):
    g = list(grid)
    for cx in (5, 10):
        for dx, dy in ((-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)):
            put(g, 7 + dy, cx + dx, "O")
        put(g, 7, cx - 1, "S")
        put(g, 7, cx + 1, "S")
    return g


def _lying(grid):
    """Rotate a 16x32 standing pose a quarter turn so the head is at the left."""
    w = len(grid[0])
    return ["".join(grid[c][w - 1 - r] for c in range(len(grid))) for r in range(w)]


def ko_frame(frame):
    w, h = KO_SIZE
    body = _lying(_x_eyes(FRONT))
    g = ["." * w for _ in range(h - len(body))] + body
    for cx, cy in KO_STARS[frame]:
        put(g, cy, cx, "L")
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            if 0 <= cy + dy < h:
                put(g, cy + dy, cx + dx, "F")
    return g


def ko_sheet():
    """Two 32x20 frames side by side; loop slowly (about 3 FPS)."""
    from PIL import Image
    from palette import to_image
    out = Image.new("RGBA", (KO_SIZE[0] * 2, KO_SIZE[1]), (0, 0, 0, 0))
    for i in range(2):
        out.alpha_composite(to_image(ko_frame(i)), (i * KO_SIZE[0], 0))
    return out
