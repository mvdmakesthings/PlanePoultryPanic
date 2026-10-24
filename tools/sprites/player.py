"""Player sprites: 16x32 frames, 32x32 for the run.

The idle, walk and run cycles are converted straight from the creator's
reference sheets by reference.py. Her standing poses from the idle sheet
are the base views here (FRONT, BACK and SIDE face down, up and right),
and everything the reference doesn't cover is built on them by stamping
small hand-drawn pieces: the action poses (throw, hurt, eat, defeat,
knocked out), the messy-hair overlay and the carried extinguisher.

Converted grids have a 1 px outline ring around the silhouette. Poses that
erase part of one (an arm, say) call reference.outlined afterwards to
outline the bared edge again.
"""
from palette import mirror, put
import reference

FRONT, BACK, SIDE = reference.base_views()
FRAME_W, FRAME_H = 16, 32

walk_cycle = reference.walk_cycle
idle_cycle = reference.idle_cycle
run_cycle = reference.run_cycle

# Where things are on the base views, in frame pixels.
# Her eyes and mouth facing the camera.
EYES = ((6, 7), (9, 7))
MOUTH = (8, 9)
# Rectangles (x0, y0, x1, y1), x1 and y1 exclusive, covering each hanging
# arm from the sleeve to the hand, outside the torso's outline.
ARMS = {
    "down": {"left": (1, 13, 5, 21), "right": (12, 13, 15, 21)},
    "up": {"left": (1, 13, 5, 21), "right": (12, 13, 15, 21)},
}
# From the side her near arm hangs between the backpack and the shirt.
SIDE_ARM = (2, 14, 5, 20)
# The side view's eye and mouth.
SIDE_EYE = (9, 7)
SIDE_MOUTH = (10, 9)
# Rows holding her hips and thighs, which fold away when her knees buckle.
THIGHS = (20, 24)


def stamp(grid, x, y, rows):
    """Draws rows onto a grid. "." leaves a pixel alone and "_" clears it."""
    g = list(grid)
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            gx, gy = x + dx, y + dy
            if ch != "." and 0 <= gx < len(g[0]) and 0 <= gy < len(g):
                put(g, gy, gx, "." if ch == "_" else ch)
    return g


def erase(grid, box):
    """Clears a rectangle, then outlines the edge it bared."""
    x0, y0, x1, y1 = box
    g = list(grid)
    for y in range(y0, y1):
        put(g, y, x0, "." * (x1 - x0))
    return reference.outlined(g)


def paint(grid, box, fill):
    """Fills a rectangle with one palette letter per column of fill."""
    x0, y0, x1, y1 = box
    g = list(grid)
    for y in range(y0, y1):
        put(g, y, x0, fill)
    return g


def _pixels(grid, pixels):
    g = list(grid)
    for x, y, ch in pixels:
        put(g, y, x, ch)
    return g


def _flip_rows(rows):
    return [r[::-1] for r in rows]


def _lowered(grid, rows=1):
    """The whole frame drops by rows pixels (the body lands)."""
    w = len(grid[0])
    return ["." * w for _ in range(rows)] + grid[:len(grid) - rows]


def swing_arm(grid, box, dy):
    """An arm swings low: its rectangle stretches down by dy pixels."""
    x0, y0, x1, y1 = box
    g = list(grid)
    for y in range(y1 - 1, y0 + dy - 1, -1):
        put(g, y, x0, grid[y - dy][x0:x1])
    return reference.outlined(g)


# ---------- actions: throw, eat, hurt, defeat ----------

# An arm raised high beside the head, hand up top: 4 wide, 10 tall.
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
# From the side: the arm pulled back and up behind her head...
ARM_BACK = [
    ".OO..",
    "OSSO.",
    "OSTO.",
    ".OSSO",
    "..OSO",
]
# ...and flung straight out in front at shoulder height.
ARM_FORWARD = [
    "..OOOO.",
    "WWTSSSO",
    "..OOOO.",
]


def _clear_side_arm(grid):
    """Hides the side view's near arm behind the backpack strap and shirt."""
    x0, y0, x1, y1 = SIDE_ARM
    g = paint(grid, (x0, y0, x1, y1 - 1), "Bww")
    return erase(g, (x0, y1 - 1, x1, y1))


def throw_frames(view):
    """Wind-up, release, follow-through, throwing with her right arm."""
    if view == "down":
        base = erase(FRONT, ARMS["down"]["left"])
        windup = stamp(base, 1, 3, ARM_RAISED)
        release = _lowered(stamp(base, 3, 13, FIST_FORWARD))
        follow = swing_arm(FRONT, ARMS["down"]["left"], 2)
        return [windup, release, follow]
    if view == "up":
        base = erase(BACK, ARMS["up"]["right"])
        windup = stamp(base, 11, 3, _flip_rows(ARM_RAISED))
        # Reaching forward, away from the camera: a short arm up at the shoulder.
        release = _lowered(stamp(base, 11, 10, _flip_rows(ARM_RAISED[7:])))
        follow = swing_arm(BACK, ARMS["up"]["right"], 2)
        return [windup, release, follow]
    base = _clear_side_arm(SIDE)
    windup = stamp(base, 3, 8, ARM_BACK)
    release = _lowered(stamp(base, 9, 12, ARM_FORWARD))
    follow = swing_arm(SIDE, SIDE_ARM, 2)
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


def _happy_eyes(grid):
    """Eyes squeezed shut with a smile: two short lines."""
    pixels = []
    for x, y in EYES:
        pixels += [(x - 1, y, "O"), (x, y, "O"), (x, y - 1, "S")]
    return _pixels(grid, pixels)


def eat_frames():
    """Facing the camera: bite from the bag, chew with happy eyes, yum."""
    base = erase(erase(FRONT, ARMS["down"]["left"]), ARMS["down"]["right"])
    bite = stamp(base, 3, 10, FOREARM_UP)
    bite = stamp(bite, 10, 10, FOREARM_UP)
    bite = stamp(bite, 5, 9, SNACK_BAG)
    chew = stamp(base, 3, 12, FOREARM_UP[:4])
    chew = stamp(chew, 10, 12, FOREARM_UP[:4])
    chew = stamp(chew, 5, 12, SNACK_BAG)
    chew = _happy_eyes(_pixels(chew, [(MOUTH[0] - 1, MOUTH[1], "S"), (MOUTH[0], MOUTH[1], "M")]))
    yum = stamp(base, 3, 12, FOREARM_UP[:4])
    yum = stamp(yum, 10, 12, FOREARM_UP[:4])
    yum = stamp(yum, 5, 12, SNACK_BAG)
    mx, my = MOUTH
    yum = _happy_eyes(_pixels(yum, [(mx - 1, my, "M"), (mx, my, "M"), (mx + 1, my, "M"), (mx, 17, "F")]))
    return [bite, chew, yum]


def eat_sheet():
    """Three 16x32 frames in one row (facing the camera only)."""
    from PIL import Image
    from palette import to_image
    out = Image.new("RGBA", (FRAME_W * 3, FRAME_H), (0, 0, 0, 0))
    for i, frame in enumerate(eat_frames()):
        out.alpha_composite(to_image(frame), (i * FRAME_W, 0))
    return out


def _flinch_face(grid):
    """Eyes squeezed shut, mouth open."""
    pixels = []
    for x, y in EYES:
        pixels += [(x - 1, y, "O"), (x, y, "O")]
    pixels += [(MOUTH[0] - 1, MOUTH[1], "O"), (MOUTH[0], MOUTH[1], "O")]
    return _pixels(grid, pixels)


def hurt_frame(view):
    """A flinch: arms flung up, eyes squeezed shut, mouth open."""
    if view == "down":
        g = erase(erase(FRONT, ARMS["down"]["left"]), ARMS["down"]["right"])
        g = stamp(g, 1, 3, ARM_RAISED)
        g = stamp(g, 11, 3, _flip_rows(ARM_RAISED))
        return _flinch_face(g)
    if view == "up":
        g = erase(erase(BACK, ARMS["up"]["left"]), ARMS["up"]["right"])
        g = stamp(g, 1, 3, ARM_RAISED)
        return stamp(g, 11, 3, _flip_rows(ARM_RAISED))
    g = stamp(_clear_side_arm(SIDE), 3, 8, ARM_BACK)
    ex, ey = SIDE_EYE
    mx, my = SIDE_MOUTH
    return _pixels(g, [(ex - 1, ey, "O"), (ex, ey, "O"), (mx, my, "O")])


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
    t0, t1 = THIGHS
    buckle = ["." * FRAME_W] * (t1 - t0) + flinch[:t0] + flinch[t1:]
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
# Run frames are wider, so the game centers the overlay on them.

MESS_SIZE = (24, 20)
MESS_MARGIN = 4
MESS_LEVELS = 3

# Tufts per direction, added on top of the previous level's. Each tuft is a
# root pixel on the head's outline followed by the pixels it puffs out
# through, in player-frame coordinates (they may go above or beside the
# frame). A tuft marked "lock" hangs inside the head instead (over the face).
# The left-facing idle frame is its own drawing, not a mirror of the right,
# so it has its own tufts.
HAIR_STRANDS = {
    "down": [
        # 1: a cowlick curling off the crown, a kink at one side.
        [[(8, 0), (8, -1), (9, -1)], [(13, 7), (14, 7)]],
        # 2: small tufts at the top left and both sides.
        [[(6, 0), (6, -1)], [(2, 6), (1, 6), (1, 7)], [(13, 9), (14, 9)]],
        # 3: a little frizz all round, and a lock fallen over the face.
        [[(10, 0), (10, -1), (11, -1)], [(3, 4), (2, 4)], [(12, 3), (13, 3)],
         ["lock", (7, 5), (7, 6)]],
    ],
    "up": [
        [[(7, 0), (7, -1), (6, -1)], [(3, 7), (2, 7)]],
        [[(10, 0), (10, -1)], [(13, 6), (14, 6), (14, 5)], [(2, 8), (1, 8)]],
        [[(5, 1), (5, 0), (4, 0)], [(14, 8), (15, 8)], [(4, 4), (3, 4)],
         ["lock", (7, 6), (8, 7)]],
    ],
    "right": [
        [[(7, 0), (7, -1), (6, -1)], [(2, 7), (1, 7)]],
        [[(4, 1), (4, 0)], [(1, 9), (0, 9), (0, 10)]],
        [[(5, 0), (5, -1), (4, -1)], [(3, 3), (2, 3)], [(12, 3), (13, 3)],
         ["lock", (9, 6), (9, 7)]],
    ],
    "left": [
        [[(8, 0), (8, -1), (9, -1)], [(12, 7), (13, 7)]],
        [[(10, 1), (10, 0)], [(12, 9), (13, 9), (13, 10)]],
        [[(6, 0), (6, -1), (5, -1)], [(3, 3), (2, 3)], [(2, 4), (1, 4)],
         ["lock", (5, 6), (5, 7)]],
    ],
}


def _hair_mess(base, strands_by_level, level):
    """One overlay frame: strands up to level, outlined, on a clear canvas."""
    w, h = MESS_SIZE
    m = MESS_MARGIN
    solid = lambda x, y: 0 <= x < FRAME_W and 0 <= y < FRAME_H and base[y][x] != "."
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
    idle = idle_cycle()
    for row, direction in enumerate(("down", "up", "right", "left")):
        base = idle[direction][0]
        for level in range(1, MESS_LEVELS + 1):
            g = _hair_mess(base, HAIR_STRANDS[direction], level)
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


def _hand(grid, direction):
    """The lowest skin pixel of the hand that carries things.

    Her left hand facing the camera (the viewer's right) and from behind
    (the viewer's left); from the side, whichever hand is drawn (the near
    one). Mid-stride that hand can swing out of view, so the other hand
    takes over.
    """
    w = len(grid[0])
    halves = {"down": range(w // 2, w), "up": range(w // 2)}.get(direction, range(w))
    for columns in (halves, range(w)):
        hand = None
        for y, row in enumerate(grid):
            for x in columns:
                if row[x] in "sS":
                    hand = (x, y)
        if hand is not None:
            return hand
    return None


def holding_extinguisher(grid, direction):
    """The extinguisher hangs from the hand, so it follows the arm's swing."""
    g = list(grid)
    w = len(grid[0])
    hand = _hand(grid, direction)
    if hand is None:
        return g
    left = min(max(hand[0] - 2, 0), w - len(HELD_EXTINGUISHER[0]))
    for dy, row in enumerate(HELD_EXTINGUISHER):
        for dx, ch in enumerate(row):
            y, x = hand[1] + dy, left + dx
            if ch != "." and 0 <= y < len(g) and 0 <= x < w:
                put(g, y, x, ch)
    return g


def _with_extinguisher(cycle):
    return {direction: [holding_extinguisher(f, direction) for f in frames]
            for direction, frames in cycle.items()}


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
    for cx, cy in ((EYES[0][0] - 1, EYES[0][1]), (EYES[1][0] + 1, EYES[1][1])):
        for dx, dy in ((-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)):
            put(g, cy + dy, cx + dx, "O")
        put(g, cy, cx - 1, "S")
        put(g, cy, cx + 1, "S")
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
