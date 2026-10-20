"""Player sprites: 16x32 frames.

Base poses face down (FRONT), up (BACK), and right (SIDE). Walk cycles are
4 frames per direction: contact, passing, contact with the other leg,
passing with the other leg. Left-facing frames are mirrored from right-facing ones.
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
    "..OOOppppppOOO..",
    "....OpippipO....",
    "....OpippipO....",
    "....OpiOOipO....",
    "....OpiOOipO....",
    "....OpiOOipO....",
    "....OppOOppO....",
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
    "..OOOppppppOOO..",
    "....OppppppO....",
    "....OppppppO....",
    "....OpiOOipO....",
    "....OpiOOipO....",
    "....OpiOOipO....",
    "....OppOOppO....",
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
    "..OOOpppOOpO....",
    ".....OpipppO....",
    ".....OpipppO....",
    ".....OpipppO....",
    ".....OpipppO....",
    ".....OpipppO....",
    ".....OpppppO....",
    ".....OGNNNNOO...",
    ".....ONNNNNNO...",
    ".....OOOOOOOO...",
    "................",
]

# Side-view legs. The near leg is lit (p with an i shine), the far leg is
# in shadow (P), so the two read as separate limbs even when they cross.

# Contact, rows 23-30: near leg planted in front, far leg pushing off behind.
SIDE_CONTACT_NEAR_FRONT = [
    ".....OPPpipO....",
    ".....OPPOpipO...",
    "....OPPO.OpipO..",
    "....OPPO..OpiO..",
    "...OPPO...OpiO..",
    "...ONNO...ONNGO.",
    "..ONNNO...ONNNNO",
    "..OOOO....OOOOOO",
]

# Contact, rows 23-30: far leg planted in front, near leg pushing off behind.
SIDE_CONTACT_NEAR_BACK = [
    ".....OpipPPO....",
    "....OpipOPPO....",
    "....OpiO.OPPO...",
    "...OpiO...OPPO..",
    "...OpiO...OPPO..",
    "..ONNGO...ONNNO.",
    "..ONNNO...ONNNNO",
    "..OOOO....OOOOOO",
]

# Passing, rows 22-30: near leg straight under the body, far boot kicked up behind.
SIDE_PASSING_NEAR_PLANTED = [
    ".....OPPpipO....",
    ".....OPPpipO....",
    "....OPPOpipO....",
    "...OPPO.OpipO...",
    "..OPPO..OpipO...",
    "..ONNO..OpipO...",
    "..ONGO..ONNGNO..",
    "...OO...ONNNNNO.",
    "........OOOOOOO.",
]

# Passing, rows 22-30: far leg straight under the body, near boot kicked up behind.
SIDE_PASSING_FAR_PLANTED = [
    ".....OpipPPO....",
    ".....OpipPPO....",
    "....OpiOPPPO....",
    "...OpiO.OPPO....",
    "..OpiO..OPPO....",
    "..ONNO..OPPO....",
    "..ONGO..ONNNNO..",
    "...OO...ONNNNNO.",
    "........OOOOOOO.",
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
    # Each passing frame plants the leg that just landed in front.
    lowered = ["." * 16] + upper
    return [
        lowered + SIDE_CONTACT_NEAR_FRONT + ["." * 16],
        upper + SIDE_PASSING_NEAR_PLANTED + ["." * 16],
        lowered + SIDE_CONTACT_NEAR_BACK + ["." * 16],
        upper + SIDE_PASSING_FAR_PLANTED + ["." * 16],
    ]


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


# Side-view run legs, rows 22-30 under hips on row 22. Like the walk, the
# near leg is lit (p with an i shine) and the far leg is in shadow (P).
SIDE_RUN_LEGS = {
    # Push off: near leg reaching forward, far leg pushing off its toe behind.
    "near_front": [
        ".....OPPpipO....",
        "....OPPOOpipO...",
        "...OPPO..OpipO..",
        "..OPPO....OpiO..",
        ".OPPO.....OpiO..",
        ".ONNO.....ONNGO.",
        "ONNO......ONNNNO",
        "OOO.......OOOOOO",
        "................",
    ],
    # Push off with the other leg: far leg reaching forward, near leg behind.
    "near_back": [
        ".....OpipPPO....",
        "....OpipOOPPO...",
        "...OpiO..OPPO...",
        "..OpiO....OPPO..",
        ".OpiO.....OPPO..",
        ".ONGO.....ONNNO.",
        "ONNO......ONNNNO",
        "OOO.......OOOOOO",
        "................",
    ],
    # Flight: near knee driven up in front, far boot kicked up behind.
    "flight_near_up": [
        ".....OPPppipO...",
        "....OPPOOpppiO..",
        ".OOOPPO..OOpiO..",
        "ONNPPO....OpiO..",
        "ONGOO.....ONNGO.",
        ".OO.......ONNNNO",
        "..........OOOOOO",
        "................",
        "................",
    ],
    # Flight: far knee driven up in front, near boot kicked up behind.
    "flight_far_up": [
        ".....OpipPPPO...",
        "....OpiOOPPPPO..",
        ".OOOpiO..OOPPO..",
        "ONNpiO....OPPO..",
        "ONGOO.....ONNNO.",
        ".OO.......ONNNNO",
        "..........OOOOOO",
        "................",
        "................",
    ],
}


def _side_run_frame(legs, landing):
    g = list(SIDE[:22]) + SIDE_RUN_LEGS[legs] + ["." * 16]
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


# ---------- messy hair ----------
# Her hair gets messier as she loses health. Flyaway strands are an overlay
# drawn over whatever animation is playing, so every sheet stays tidy and
# only this one small sheet changes with health. Each overlay frame is
# 24x20 and lines up with the top-left of a 16x32 player frame moved 4px
# up and left (MESS_MARGIN), so strands can poke out above and beside the
# head. The game lines it up with the head in each frame by finding the top
# of the head (the first opaque row), so it follows bobbing and breathing.

MESS_SIZE = (24, 20)
MESS_MARGIN = 4
MESS_LEVELS = 3

# Tufts per view, added on top of the previous level's. Each tuft is a root
# pixel on the head's outline followed by the pixels it puffs out through,
# in player-frame coordinates (they may go above or beside the frame).
# A tuft marked "lock" hangs inside the head instead (over the face).
HAIR_STRANDS = {
    "down": [
        # 1: a cowlick curling off the crown, a kink at one side.
        [[(8, 0), (8, -1), (9, -1)], [(14, 7), (15, 7)]],
        # 2: small tufts at the top left and both sides.
        [[(5, 0), (5, -1)], [(1, 6), (0, 6), (0, 7)], [(14, 10), (15, 10)]],
        # 3: a little frizz all round, and a lock fallen over the face.
        [[(10, 0), (10, -1), (11, -1)], [(1, 4), (0, 4)], [(14, 4), (15, 4)],
         ["lock", (6, 5), (6, 6)]],
    ],
    "up": [
        [[(7, 0), (7, -1), (6, -1)], [(1, 7), (0, 7)]],
        [[(10, 0), (10, -1)], [(14, 6), (15, 6), (15, 5)], [(1, 10), (0, 10)]],
        [[(5, 0), (5, -1), (4, -1)], [(14, 9), (15, 9)], [(1, 4), (0, 4)],
         ["lock", (6, 6), (7, 7)]],
    ],
    "right": [
        [[(8, 0), (8, -1), (7, -1)], [(2, 7), (1, 7)]],
        [[(5, 1), (5, 0)], [(2, 9), (1, 9), (1, 10)]],
        [[(10, 0), (10, -1), (11, -1)], [(2, 4), (1, 4)], [(13, 3), (14, 3)],
         ["lock", (6, 4), (7, 5)]],
    ],
}


def _hair_mess(base, strands_by_level, level):
    """One overlay frame: strands up to level, outlined, on a clear canvas."""
    w, h = MESS_SIZE
    m = MESS_MARGIN
    solid = lambda x, y: 0 <= x < 16 and 0 <= y < 32 and base[y][x] != "."
    g = ["." * w for _ in range(h)]
    hair = set()
    for strands in strands_by_level[:level]:
        for strand in strands:
            if strand[0] == "lock":
                for i, (x, y) in enumerate(strand[1:]):
                    put(g, y + m, x + m, "d" if i else "H")
                continue
            for i, (x, y) in enumerate(strand):
                put(g, y + m, x + m, "H")
                hair.add((x, y))
    # Outline the strands where they stick out past the head, in the hair's
    # shadow color (a selective outline) so they stay soft, not wiry.
    for x, y in hair:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if (nx, ny) in hair or solid(nx, ny):
                continue
            if 0 <= nx + m < w and 0 <= ny + m < h:
                put(g, ny + m, nx + m, "d")
    return g


def hair_mess_sheet():
    """Rows are directions (down, up, right, left); columns are mess levels 1-3."""
    from PIL import Image
    from palette import to_image
    w, h = MESS_SIZE
    out = Image.new("RGBA", (w * MESS_LEVELS, h * 4), (0, 0, 0, 0))
    views = {"down": FRONT, "up": BACK, "right": SIDE}
    for row, direction in enumerate(("down", "up", "right", "left")):
        view = "right" if direction == "left" else direction
        for level in range(1, MESS_LEVELS + 1):
            g = _hair_mess(views[view], HAIR_STRANDS[view], level)
            if direction == "left":
                # The margins are equal on both sides, so flipping the whole
                # overlay mirrors it around the player frame too.
                g = mirror(g)
            out.alpha_composite(to_image(g), ((level - 1) * w, row * h))
    return out


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
