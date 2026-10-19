"""Arrivals tileset: 16x16 floor and wall tiles in 3/4 view.

Floors repeat seamlessly. Walls are built from a top surface (seen from
above), a lip where the top meets the front face, and two face rows
(upper panel, lower panel with baseboard).
"""
import random

from PIL import Image

from palette import to_image

SIZE = 16
COLUMNS = 8

# One shade darker, for shadows cast by walls onto the floor.
DARKER = {"C": "W", "W": "w", "w": "T", "T": "p", "p": "k", "k": "O",
          "a": "e", "e": "n", "n": "m", "m": "v", "v": "O", "B": "k", "b": "B"}


def fill(key):
    return [key * SIZE for _ in range(SIZE)]


def put_px(grid, x, y, key):
    row = grid[y]
    grid[y] = row[:x] + key + row[x + 1:]


def speckle(base, keys, density, seed):
    """Random speckle. Per-pixel noise has no structure, so it tiles seamlessly."""
    rnd = random.Random(seed)
    g = fill(base)
    for y in range(SIZE):
        for x in range(SIZE):
            if rnd.random() < density:
                put_px(g, x, y, rnd.choice(keys))
    return g


def carpet(seed):
    return speckle("T", "pw", 0.14, seed)


def hard_tile(seed):
    g = speckle("W", "w", 0.03, seed)
    for i in range(SIZE):
        put_px(g, i, 0, "C")
        put_px(g, 0, i, "C")
        put_px(g, i, SIZE - 1, "w")
        put_px(g, SIZE - 1, i, "w")
    return g


def wood(joints, seed):
    """Four horizontal honey-colored planks, 4px tall.

    joints gives each plank's end-joint x, or None for no joint in this
    tile, which keeps planks long so the floor doesn't read as brick.
    """
    rnd = random.Random(seed)
    g = fill("a")
    for plank, joint in enumerate(joints):
        top = plank * 4
        for x in range(SIZE):
            put_px(g, x, top + 3, "e")
            if rnd.random() < 0.15:
                put_px(g, x, top + rnd.choice((0, 1)), "e")
        if joint is not None:
            for y in range(top, top + 3):
                put_px(g, joint, y, "n")
    return g


def shadowed(grid, rows=3):
    """Darken the top rows, as if a wall above casts a shadow."""
    g = list(grid)
    for y in range(rows):
        g[y] = "".join(DARKER.get(ch, ch) for ch in g[y])
    return g


def wall_top():
    return fill("p")


def wall_lip():
    g = fill("p")
    g[14] = "T" * SIZE
    g[15] = "O" * SIZE
    return g


def wall_face_upper():
    """White panels with a corporate-blue accent stripe."""
    g = ["C" * SIZE] + ["W" * (SIZE - 1) + "w" for _ in range(SIZE - 1)]
    g[9] = "b" * SIZE
    g[10] = "B" * SIZE
    g[11] = "B" * SIZE
    return g


def wall_face_lower():
    g = ["W" * (SIZE - 1) + "w" for _ in range(9)]
    g += ["w" * SIZE, "T" * SIZE] + ["p" * SIZE for _ in range(4)] + ["O" * SIZE]
    return g


def wall_edge(side):
    """Top surface of a side or bottom wall, with its outline facing the room."""
    g = fill("p")
    for i in range(SIZE):
        if side == "right":      # room is to the right
            put_px(g, SIZE - 2, i, "T"); put_px(g, SIZE - 1, i, "O")
        elif side == "left":     # room is to the left
            put_px(g, 1, i, "T"); put_px(g, 0, i, "O")
        elif side == "bottom":   # room is above
            put_px(g, i, 1, "T"); put_px(g, i, 0, "O")
    return g


def tiles():
    """Ordered (name, grid) pairs. Order sets each tile's atlas position."""
    carpet_a, carpet_b = carpet(1), carpet(2)
    tile_a, tile_b = hard_tile(3), hard_tile(4)
    wood_a, wood_b = wood((5, None, 12, None), 5), wood((None, 3, None, 9), 6)
    return [
        ("carpet_a", carpet_a), ("carpet_b", carpet_b),
        ("tile_a", tile_a), ("tile_b", tile_b),
        ("wood_a", wood_a), ("wood_b", wood_b),
        ("carpet_shadow", shadowed(carpet_a)), ("tile_shadow", shadowed(tile_a)),
        ("wood_shadow", shadowed(wood_a)),
        ("wall_top", wall_top()), ("wall_lip", wall_lip()),
        ("wall_face_upper", wall_face_upper()), ("wall_face_lower", wall_face_lower()),
        ("wall_edge_right", wall_edge("right")), ("wall_edge_left", wall_edge("left")),
        ("wall_edge_bottom", wall_edge("bottom")),
    ]


def by_name():
    return dict(tiles())


def sheet():
    items = tiles()
    rows = (len(items) + COLUMNS - 1) // COLUMNS
    out = Image.new("RGBA", (COLUMNS * SIZE, rows * SIZE), (0, 0, 0, 0))
    for i, (_, grid) in enumerate(items):
        out.alpha_composite(to_image(grid), ((i % COLUMNS) * SIZE, (i // COLUMNS) * SIZE))
    return out
