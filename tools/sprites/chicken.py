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


def chicken_side_walk(base, bob=True):
    body = base[:14]

    def frame(legs, head_forward, raise_body):
        g = list(body)
        if head_forward:
            for r in range(1, 8):
                put(g, r, 8, "." + g[r][8:15])
                # Fill the gap the shift leaves at the back of the neck.
                if g[r][7] != "." and g[r][9] != ".":
                    put(g, r, 8, "C")
        if raise_body:
            g = g[1:] + ["." * 16]
        g = g[:16 - len(legs)] + legs
        return g

    spread_a = ["....y....Y......", "...yy....YY....."]
    spread_b = ["....Y....y......", "...YY....yy....."]
    tucked = ["......Yy........", ".....YY.yy......"]
    return [frame(spread_a, True, False), frame(tucked, False, bob),
            frame(spread_b, True, False), frame(tucked, False, bob)]


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


# ---------- idle with peck ----------

def dip_head(grid, rows, cols, dy, dx=0):
    """Move the head block (rows x cols) down by dy and forward by dx."""
    g = list(grid)
    r0, r1 = rows
    c0, c1 = cols
    block = [g[r][c0:c1] for r in range(r0, r1)]
    for r in range(r0, r1):
        put(g, r, c0, "." * (c1 - c0))
    for i, text in enumerate(block):
        r = r0 + i + dy
        for j, ch in enumerate(text):
            c = c0 + j + dx
            if ch != "." and 0 <= c < 16:
                put(g, r, c, ch)
    return g


def idle_cycle():
    """Stand, dip, peck. Keyed by direction: down, up, right, left."""
    right = [SIDE, dip_head(SIDE, (0, 7), (8, 16), 2), dip_head(SIDE, (0, 7), (8, 16), 3)]
    return {
        "down": [FRONT, dip_head(FRONT, (0, 7), (3, 13), 1), dip_head(FRONT, (0, 7), (3, 13), 3)],
        "up": [BACK, dip_head(BACK, (0, 6), (3, 13), 1), dip_head(BACK, (0, 6), (3, 13), 2)],
        "right": right,
        "left": [mirror(f) for f in right],
    }


# ---------- powered-up chickens ----------

# Mushroom cap, centered on the comb. X = cap, x = cap shade, S = spot.
CAP = [
    "..OOOO..",
    ".OXSXXO.",
    "OXXXXSXO",
    "OxxxxxxO",
]
CAP_COLORS = {
    "flight": {"X": "q", "x": "b", "S": "C"},
    "rage": {"X": "R", "x": "r", "S": "C"},
    "egg": {"X": "H", "x": "d", "S": "h"},
}
# Two flicker states for rage flames, drawn only behind the body.
TAIL_FLAMES = [
    [".Y..", ".YY.", "yYYy", "yRRy"],
    ["..Y.", ".YY.", "yYYy", "RyyR"],
]
SIDE_FLAMES = [
    [".Y.", "yYy", "RyR"],
    ["Y..", "yYy", "yRy"],
]
# Flight sparkles: (row, col) per frame, drawn only on empty pixels.
SPARKLES = [[(1, 1), (9, 15)], [(4, 0), (0, 14)], [(2, 2), (8, 15)], [(6, 0), (1, 15)]]


def overlay(grid, sprite, top, left, behind=True):
    """Draw sprite onto grid. With behind=True only empty pixels are filled."""
    g = list(grid)
    for i, text in enumerate(sprite):
        for j, ch in enumerate(text):
            r, c = top + i, left + j
            if ch != "." and 0 <= r < len(g) and 0 <= c < 16 and (not behind or g[r][c] == "."):
                put(g, r, c, ch)
    return g


def add_cap(grid, mode):
    comb_rows = [r for r, row in enumerate(grid) if "R" in row]
    top = comb_rows[0]
    cols = [c for r in (top, top + 1) for c, ch in enumerate(grid[r]) if ch == "R"]
    left = (min(cols) + max(cols) + 1) // 2 - 4
    colors = CAP_COLORS[mode]
    cap = ["".join(colors.get(ch, ch) for ch in row) for row in CAP]
    # Clear the comb so no red shows around the cap.
    g = [row.replace("R", ".") if r in (top, top + 1) else row for r, row in enumerate(grid)]
    return overlay(g, cap, top - 1, left, behind=False)


def first_filled_row(grid, col):
    return next(r for r, row in enumerate(grid) if row[col] != ".")


def rage(grid, i, view):
    if view == "side":
        return overlay(grid, TAIL_FLAMES[i % 2], first_filled_row(grid, 2) - 4, 0)
    flame = SIDE_FLAMES[i % 2]
    top = first_filled_row(grid, 2) - 3
    g = overlay(grid, flame, top, 1)
    return overlay(g, [row[::-1] for row in SIDE_FLAMES[(i + 1) % 2]], top, 12)


def flight(grid, i, view):
    # Only the wings glow teal.
    if view == "side":
        rows, cols = range(9, 12), range(4, 11)
    else:
        rows, cols = range(6, 12), [*range(0, 4), *range(12, 16)]
    g = list(grid)
    for r in rows:
        for c in cols:
            if g[r][c] in "Cc":
                put(g, r, c, "q" if g[r][c] == "c" else g[r][c])
    for r in rows:
        for c in cols:
            if g[r][c] == "q":
                for nc in (c - 1, c + 1):
                    if 0 <= nc < 16 and g[r][nc] == "C":
                        put(g, r, nc, "q")
                        break
    return _sparkle(g, i)


def _sparkle(grid, i):
    g = list(grid)
    for r, c in SPARKLES[i % 4]:
        if g[r][c] == ".":
            put(g, r, c, "q")
    return g


def egg(grid, i, view):
    if view != "side":
        return grid
    # Bulging throat just behind the wattle.
    wattle = [(r, row.index("R")) for r, row in enumerate(grid) if "R" in row][-1]
    r, c = wattle
    return overlay(grid, [".CO", "ccO", "OO."], r, c, behind=False)


EFFECTS = {"flight": flight, "rage": rage, "egg": egg}


def powered_walk(mode):
    """Walk cycle for a powered chicken: mushroom cap plus the mode's effect."""
    base = walk_cycle()
    base["right"] = chicken_side_walk(SIDE, bob=False)
    out = {}
    for direction, view in (("down", "front"), ("up", "back"), ("right", "side")):
        out[direction] = [EFFECTS[mode](add_cap(f, mode), i, view)
                          for i, f in enumerate(base[direction])]
    out["left"] = [mirror(f) for f in out["right"]]
    return out
