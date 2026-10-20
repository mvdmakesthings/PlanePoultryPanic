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
# Run frames, 6 per direction: contact (one foot lands in front, body low),
# passing (that leg under her, the other swinging through), flight (the
# swinging knee driven up in front, the landed leg pushing off behind), then
# the same three with the legs swapped. Longer stride than the walk, knees
# driven high, arms pumping, and the backpack bouncing a beat behind.


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
    rows = SIDE_RUN_LEGS[legs] if legs in SIDE_RUN_LEGS else SIDE_PASSING[legs]
    g = list(SIDE[:22]) + rows + ["." * 16]
    if landing:
        g = _lowered(g)
        # The backpack lags the landing by another pixel.
        pack = [g[r][0:5] for r in range(12, 22)]
        for i, text in enumerate(pack):
            put(g, 13 + i, 0, text)
    return g


# The walk's passing legs work as the run's passing frames: one leg straight
# under the body, the other boot swinging through behind it.
SIDE_PASSING = {
    "pass_near_planted": SIDE_PASSING_NEAR_PLANTED,
    "pass_far_planted": SIDE_PASSING_FAR_PLANTED,
}


def side_run():
    # After the near foot lands in front, the far leg swings through and its
    # knee drives up while the near leg pushes off behind; then the reverse.
    return [
        _side_run_frame("near_front", True),
        _side_run_frame("pass_near_planted", True),
        _side_run_frame("flight_far_up", False),
        _side_run_frame("near_back", True),
        _side_run_frame("pass_far_planted", True),
        _side_run_frame("flight_near_up", False),
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
    # Passing: the landed leg straight under her, the other coming through.
    pass_a = _lowered(swing_arm(with_legs(base, left, short_leg(right)), (12, 15)))
    pass_b = _lowered(swing_arm(with_legs(base, short_leg(left), right), (1, 4)))
    return [push_a, pass_a, flight, push_b, pass_b, flight]


def run_cycle():
    """Run frames keyed by direction: down, up, right, left."""
    right = side_run()
    return {
        "down": front_back_run(FRONT),
        "up": front_back_run(BACK),
        "right": right,
        "left": [mirror(f) for f in right],
    }


# ---------- actions: throw, eat, hurt, defeat ----------
# Poses are made by stamping small hand-drawn pieces (arms, a snack bag,
# faces) onto the base views. In a stamp, "." leaves the pixel alone and
# "_" clears it.


def stamp(grid, x, y, rows):
    g = list(grid)
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            gx, gy = x + dx, y + dy
            if ch != "." and 0 <= gx < len(g[0]) and 0 <= gy < len(g):
                put(g, gy, gx, "." if ch == "_" else ch)
    return g


def _flip_rows(rows):
    return [r[::-1] for r in rows]


# Front view: her right arm hangs at the viewer's left (cols 1-2), her left
# arm at the viewer's right (cols 13-14), both from row 15 to the hand on row 20.
CLEAR_ARM_FRONT_LEFT = ["__"] * 6
CLEAR_ARM_FRONT_RIGHT = ["__"] * 6

# An arm raised high beside the head, hand up top: 4 wide, rows 3-12.
ARM_RAISED = [
    ".OO.",
    "OSSO",
    "OSSO",
    "OsSO",
    "OSSO",
    "OTSO",
    "OSTO",
    "OSSO",
    "OSSO",
    "OwwO",
]
# A fist thrust toward the camera, in front of the chest.
FIST_FORWARD = [
    "OSSO",
    "OSTO",
    ".OO.",
]


def _clear_front_arm(g, side):
    """Removes a hanging forearm (side: "left" or "right" as the viewer sees it)."""
    if side == "left":
        g = stamp(g, 1, 15, CLEAR_ARM_FRONT_LEFT)
        return stamp(g, 2, 21, ["_"])
    g = stamp(g, 13, 15, CLEAR_ARM_FRONT_RIGHT)
    return stamp(g, 13, 21, ["_"])


def _clear_side_arm(g):
    """Paints the side view's near arm over with shirt, so it can be redrawn."""
    g = stamp(g, 8, 16, ["WW", "WW", "WW", "ww"])
    return stamp(g, 8, 20, ["PP"])


def throw_frames(view):
    """Wind-up, release, follow-through, throwing with her right arm."""
    if view == "down":
        base = _clear_front_arm(FRONT, "left")
        windup = stamp(base, 0, 3, ARM_RAISED)
        release = _lowered(stamp(base, 1, 14, FIST_FORWARD))
        follow = swing_arm(swing_arm(FRONT, (1, 4)), (1, 4))
        return [windup, release, follow]
    if view == "up":
        base = _clear_front_arm(BACK, "right")
        windup = stamp(base, 12, 3, _flip_rows(ARM_RAISED))
        # Reaching forward, away from the camera: a short arm up at the shoulder.
        release = _lowered(stamp(base, 12, 10, _flip_rows(ARM_RAISED[7:])))
        follow = swing_arm(swing_arm(BACK, (12, 15)), (12, 15))
        return [windup, release, follow]
    base = _clear_side_arm(SIDE)
    # Pulled back and up behind her head...
    windup = stamp(base, 4, 8, [
        ".OO..",
        "OSSO.",
        "OSTO.",
        ".OSSO",
        "..OSO",
    ])
    # ...then flung straight out in front at shoulder height.
    release = _lowered(stamp(base, 9, 12, [
        "..OOOO.",
        "WWTSSSO",
        "..OOOO.",
    ]))
    follow = swing_arm(swing_arm(SIDE, (8, 10)), (8, 10))
    return [windup, release, follow]


def throw_cycle():
    right = throw_frames("right")
    return {
        "down": throw_frames("down"),
        "up": throw_frames("up"),
        "right": right,
        "left": [mirror(f) for f in right],
    }


# The snack bag she eats from, 6x5, like item_snack.png in miniature.
SNACK_BAG = [
    "OWWWWO",
    "ORRRRO",
    "OYFYYO",
    "ORRRrO",
    ".OOOO.",
]
# A forearm raised in front of the body, hand on top.
FOREARM_UP = ["OSO", "OSO", "OTO", "OSO", "OwO"]
HAPPY_EYES = [(4, 7, "O"), (5, 6, "O"), (6, 7, "O"), (5, 7, "S"),
              (9, 7, "O"), (10, 6, "O"), (11, 7, "O"), (10, 7, "S")]


def _pixels(grid, pixels):
    g = list(grid)
    for x, y, ch in pixels:
        put(g, y, x, ch)
    return g


def eat_frames():
    """Facing the camera: bite from the bag, chew with happy eyes, yum."""
    base = _clear_front_arm(_clear_front_arm(FRONT, "left"), "right")
    bite = stamp(base, 3, 9, FOREARM_UP)
    bite = stamp(bite, 10, 9, FOREARM_UP)
    bite = stamp(bite, 5, 8, SNACK_BAG)
    chew = stamp(base, 3, 12, FOREARM_UP[:4])
    chew = stamp(chew, 10, 12, FOREARM_UP[:4])
    chew = stamp(chew, 5, 12, SNACK_BAG)
    chew = _pixels(chew, HAPPY_EYES + [(7, 9, "O"), (8, 9, "M"), (4, 9, "s"), (11, 9, "s")])
    yum = stamp(base, 3, 12, FOREARM_UP[:4])
    yum = stamp(yum, 10, 12, FOREARM_UP[:4])
    yum = stamp(yum, 5, 12, SNACK_BAG)
    yum = _pixels(yum, HAPPY_EYES + [(6, 9, "M"), (7, 9, "M"), (8, 9, "M"), (9, 9, "M"), (8, 17, "F")])
    return [bite, chew, yum]


def eat_sheet():
    """Three 16x32 frames in one row (facing the camera only)."""
    from PIL import Image
    from palette import to_image
    out = Image.new("RGBA", (16 * 3, 32), (0, 0, 0, 0))
    for i, frame in enumerate(eat_frames()):
        out.alpha_composite(to_image(frame), (i * 16, 0))
    return out


def hurt_frame(view):
    """A flinch: arms flung up, eyes squeezed shut, mouth open."""
    if view == "down":
        g = _clear_front_arm(_clear_front_arm(FRONT, "left"), "right")
        g = stamp(g, 0, 3, ARM_RAISED)
        g = stamp(g, 12, 3, _flip_rows(ARM_RAISED))
        return _pixels(g, [(4, 7, "O"), (5, 7, "O"), (10, 7, "O"), (11, 7, "O"),
                           (7, 9, "O"), (8, 9, "O")])
    if view == "up":
        g = _clear_front_arm(_clear_front_arm(BACK, "left"), "right")
        g = stamp(g, 0, 3, ARM_RAISED)
        return stamp(g, 12, 3, _flip_rows(ARM_RAISED))
    g = _clear_side_arm(SIDE)
    g = stamp(g, 4, 8, [".OO..", "OSSO.", "OSTO.", ".OSSO", "..OSO"])
    return _pixels(g, [(10, 6, "S"), (11, 6, "O"), (10, 5, "S"), (12, 8, "O"), (12, 9, "O")])


def hurt_cycle():
    right = [hurt_frame("right")]
    return {"down": [hurt_frame("down")], "up": [hurt_frame("up")], "right": right,
            "left": [mirror(f) for f in right]}


# Defeat: 32x32 frames, played once before the knocked-out loop. Standing
# frames sit in the middle 16 columns; lying frames line up with
# player_ko.png (body on the bottom rows, head to the left).
DEFEAT_SIZE = (32, 32)


def defeat_frames():
    w, h = DEFEAT_SIZE
    flinch = hurt_frame("down")
    # Knees buckle: the thighs fold away and the whole body drops 4px.
    buckle = ["." * 16] * 4 + flinch[:22] + flinch[26:]
    lying = _lying(_x_eyes(FRONT))
    frames = []
    for pose in (flinch, buckle):
        g = ["." * w for _ in range(h)]
        frames.append(stamp(g, 8, 0, pose))
    # Falling back: lying, but still 4px off the floor.
    g = ["." * w for _ in range(h)]
    frames.append(stamp(g, 0, h - len(lying) - 5, lying))
    # Flat, with puffs of dust at both ends.
    g = ["." * w for _ in range(h)]
    g = stamp(g, 0, h - len(lying) - 1, lying)
    frames.append(_pixels(g, [(0, 29, "W"), (1, 30, "C"), (0, 31, "w"),
                              (31, 29, "W"), (30, 30, "C"), (31, 31, "w")]))
    return frames


def defeat_sheet():
    """Four 32x32 frames in one row; play once at about 8 FPS, then player_ko.png."""
    from PIL import Image
    from palette import to_image
    w, h = DEFEAT_SIZE
    out = Image.new("RGBA", (w * 4, h), (0, 0, 0, 0))
    for i, frame in enumerate(defeat_frames()):
        out.alpha_composite(to_image(frame), (i * w, 0))
    return out


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
