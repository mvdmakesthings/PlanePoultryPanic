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


# ---------- running ----------
# Run frames: push off (legs wide, body low), flight (both feet off the
# floor), push off with the other leg, flight. Longer stride than the walk,
# knees driven high, arms pumping, and the backpack bouncing a beat behind.


def _lowered(grid, rows=1):
    """The whole frame drops by rows pixels (the body lands)."""
    return ["." * 16 for _ in range(rows)] + grid[:len(grid) - rows]


def _draw_leg(g, points, near):
    """A 2px-wide leg along points (hip to ankle), then a boot at the ankle.
    The near leg gets a lit edge; the far leg is all shadow."""
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(steps + 1):
            x = round(x0 + (x1 - x0) * i / steps)
            y = round(y0 + (y1 - y0) * i / steps)
            put(g, y, x, "P")
            put(g, y, x + 1, "p" if near else "P")
            if abs(x1 - x0) > abs(y1 - y0):
                # A mostly flat stretch (a foot kicked back) needs height too.
                put(g, y + 1, x, "P")
                put(g, y + 1, x + 1, "P")
    ax, ay = points[-1]
    put(g, ay + 1, ax, "GNN")
    put(g, ay + 2, ax - 1, "NNNN")


def _outline_below(g, top):
    """Outline the legs: transparent pixels from row top down that touch them."""
    out = list(g)
    for y in range(top, len(g)):
        for x in range(16):
            if g[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < 16 and top <= ny < len(g) and g[ny][nx] not in ".O":
                    put(out, y, x, "O")
                    break
    return out


# Side-view leg poses as (far leg points, near leg points), hip to ankle,
# for a body whose hips sit on row 22.
SIDE_RUN_LEGS = {
    # Push off: near leg reaching forward, far leg pushing back.
    "near_front": ([(6, 22), (4, 25), (2, 27)], [(7, 22), (9, 25), (11, 27)]),
    "near_back": ([(7, 22), (9, 25), (11, 27)], [(6, 22), (4, 25), (2, 27)]),
    # Flight: one knee driven up in front, the other foot kicked up behind.
    "flight_near_up": ([(6, 22), (5, 25), (2, 24)], [(7, 22), (10, 23), (9, 26)]),
    "flight_far_up": ([(7, 22), (10, 23), (9, 26)], [(6, 22), (5, 25), (2, 24)]),
}


def _side_run_frame(legs, landing):
    g = list(SIDE[:22]) + blank_rows(10)
    far, near = SIDE_RUN_LEGS[legs]
    _draw_leg(g, far, near=False)
    _draw_leg(g, near, near=True)
    g = _outline_below(g, 22)
    if landing:
        g = _lowered(g)
        # The backpack lags the landing by another pixel.
        pack = [g[r][0:5] for r in range(12, 22)]
        for i, text in enumerate(pack):
            put(g, 13 + i, 0, text)
    return g


def side_run():
    return [
        _side_run_frame("near_front", True),
        _side_run_frame("flight_near_up", False),
        _side_run_frame("near_back", True),
        _side_run_frame("flight_far_up", False),
    ]


def very_short_leg(leg):
    # Knee driven high: two shin rows gone, foot two rows up.
    return leg[:2] + leg[4:] + [".....", "....."]


def front_back_run(base):
    left, right = leg_columns(base)
    pump = lambda grid, cols: swing_arm(swing_arm(grid, cols), cols)
    push_a = _lowered(pump(with_legs(base, long_leg(left), very_short_leg(right)), (12, 15)))
    push_b = _lowered(pump(with_legs(base, very_short_leg(left), long_leg(right)), (1, 4)))
    flight = with_legs(base, short_leg(left), short_leg(right))
    return [push_a, flight, push_b, flight]


def run_cycle():
    """Run frames keyed by direction: down, up, right, left."""
    right = side_run()
    return {
        "down": front_back_run(FRONT),
        "up": front_back_run(BACK),
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


def run_cycle_extinguisher():
    return _with_extinguisher(run_cycle())


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
