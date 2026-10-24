"""Player sheets converted straight from the creator's reference art.

The sheets in reference/ are big pixel-art renders of Amanda (she stands
about 370 px tall) laid out like the game's sheets: one row per direction
(down, up, right, left) and one column per frame. Each figure is cut out,
keyed off the magenta background, shrunk until she stands FIGURE_HEIGHT
pixels tall, snapped to her palette colors and given a 1 px outline.

Shrinking takes a majority vote: every target pixel becomes the most
common palette color in the block of source pixels it covers. Averaging
would blur her eyes and the shirt print into gray; voting keeps them.

Frames are placed with her head centered in the frame and her feet on the
second-to-last row, so the sprite stays put as the animation plays.
"""
from collections import Counter
from pathlib import Path

from PIL import Image

from palette import PALETTE

try:
    import numpy as np
except ImportError:  # pragma: no cover - slow fallback
    np = None

REFERENCE = Path(__file__).resolve().parent / "reference"
DIRECTIONS = ("down", "up", "right", "left")
FRAME_HEIGHT = 32
# How tall the tallest figure in each row of a sheet comes out, in pixels.
FIGURE_HEIGHT = {"idle": 31, "walk": 31, "run": 30}
# (file, frames per direction, frame width). Running strides are too wide
# for a 16 px frame, so the run gets square frames.
SHEETS = {
    "idle": ("amanda_idle.webp", 2, 16),
    "walk": ("amanda_walk.webp", 4, 16),
    "run": ("amanda_run.webp", 6, 32),
}

# Her colors. Several letters share a color in PALETTE; these are the ones
# converted grids use. The outline color is left out of the vote (her
# near-black leggings would otherwise turn into it) and drawn as a ring
# around the silhouette instead.
KEYS = "PpiwWLHhdSsMBb"
RGB = {k: tuple(int(PALETTE[k][i:i + 2], 16) for i in (0, 2, 4)) for k in KEYS}
BY_RGB = {v: k for k, v in RGB.items()}
COLORS = [RGB[k] for k in KEYS]
# Perceptual-ish weights for picking the nearest color.
WEIGHTS = (2, 4, 3)

# Background keying: how far from the corner color a pixel must be to count
# as part of her, with a soft ramp for anti-aliased edges.
KEY_NEAR, KEY_FAR = 60, 140

_cache = {}


def _load(name):
    """The keyed sheet as an RGBA image."""
    if name not in _cache:
        file, _, _ = SHEETS[name]
        im = Image.open(REFERENCE / file).convert("RGB")
        _cache[name] = _key_out(im)
    return _cache[name]


def _key_out(im):
    bg = im.getpixel((0, 0))
    if np is not None:
        a = np.asarray(im).astype(np.int32)
        d = np.sqrt(((a - np.array(bg)) ** 2).sum(axis=2))
        alpha = np.clip((d - KEY_NEAR) * 255 / (KEY_FAR - KEY_NEAR), 0, 255).astype(np.uint8)
        return Image.fromarray(np.dstack([a.astype(np.uint8), alpha]), "RGBA")
    out = Image.new("RGBA", im.size)
    src, dst = im.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b = src[x, y]
            d = ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5
            a = 0 if d < KEY_NEAR else 255 if d > KEY_FAR else int((d - KEY_NEAR) * 255 / (KEY_FAR - KEY_NEAR))
            dst[x, y] = (r, g, b, a)
    return out


def _runs(occupied):
    out, start = [], None
    for i, o in enumerate(list(occupied) + [False]):
        if o and start is None:
            start = i
        if not o and start is not None:
            out.append((start, i))
            start = None
    return out


def _figures(name):
    """Bounding boxes of every figure in a sheet: boxes[row][column]."""
    im = _load(name)
    _, columns, _ = SHEETS[name]
    alpha = im.getchannel("A")
    w, h = im.size
    if np is not None:
        a = np.asarray(alpha) > 128
        col_runs, row_runs = _runs(a.any(axis=0)), _runs(a.any(axis=1))
    else:
        px = alpha.load()
        col_runs = _runs(any(px[x, y] > 128 for y in range(h)) for x in range(w))
        row_runs = _runs(any(px[x, y] > 128 for x in range(w)) for y in range(h))
    assert len(col_runs) == columns and len(row_runs) == len(DIRECTIONS), (
        f"{name}: found {len(col_runs)} columns and {len(row_runs)} rows")
    boxes = []
    for y0, y1 in row_runs:
        row = []
        for x0, x1 in col_runs:
            cell = alpha.crop((x0, y0, x1, y1)).getbbox()
            row.append((x0 + cell[0], y0 + cell[1], x0 + cell[2], y0 + cell[3]))
        boxes.append(row)
    return boxes


def _nearest(rgb):
    r, g, b = rgb
    wr, wg, wb = WEIGHTS
    return min(COLORS, key=lambda c: wr * (c[0] - r) ** 2 + wg * (c[1] - g) ** 2 + wb * (c[2] - b) ** 2)


def _shrink(figure, scale):
    """Majority-vote downscale of an RGBA figure to palette colors.

    Returns a grid of palette letters ("." where fewer than half the source
    pixels are opaque).
    """
    w = max(1, round(figure.width * scale))
    h = max(1, round(figure.height * scale))
    if np is not None:
        return _shrink_numpy(figure, scale, w, h)
    src = figure.load()
    cache = {}
    grid = []
    for y in range(h):
        sy0, sy1 = int(y / scale), max(int((y + 1) / scale), int(y / scale) + 1)
        row = ""
        for x in range(w):
            sx0, sx1 = int(x / scale), max(int((x + 1) / scale), int(x / scale) + 1)
            votes, total, opaque = Counter(), 0, 0
            for sy in range(sy0, min(sy1, figure.height)):
                for sx in range(sx0, min(sx1, figure.width)):
                    r, g, b, a = src[sx, sy]
                    total += 1
                    if a < 128:
                        continue
                    opaque += 1
                    key = (r // 8, g // 8, b // 8)
                    if key not in cache:
                        cache[key] = _nearest((r, g, b))
                    votes[cache[key]] += 1
            row += BY_RGB[votes.most_common(1)[0][0]] if total and opaque * 2 >= total else "."
        grid.append(row)
    return grid


def _shrink_numpy(figure, scale, w, h):
    a = np.asarray(figure).astype(np.int32)
    rgb, alpha = a[:, :, :3], a[:, :, 3] >= 128
    colors = np.array(COLORS, dtype=np.int32)
    weights = np.array(WEIGHTS, dtype=np.int32)
    # Nearest palette color for every source pixel.
    dist = ((rgb[:, :, None, :] - colors[None, None, :, :]) ** 2 * weights).sum(axis=3)
    index = dist.argmin(axis=2)
    ys = [(int(y / scale), max(int((y + 1) / scale), int(y / scale) + 1)) for y in range(h)]
    xs = [(int(x / scale), max(int((x + 1) / scale), int(x / scale) + 1)) for x in range(w)]
    grid = []
    for sy0, sy1 in ys:
        row = ""
        for sx0, sx1 in xs:
            block_alpha = alpha[sy0:sy1, sx0:sx1]
            if block_alpha.size == 0 or block_alpha.sum() * 2 < block_alpha.size:
                row += "."
                continue
            votes = np.bincount(index[sy0:sy1, sx0:sx1][block_alpha], minlength=len(COLORS))
            row += KEYS[int(votes.argmax())]
        grid.append(row)
    return grid


def outlined(grid):
    """A 1 px outline on every edge pixel of the silhouette.

    Pixels already on the edge keep shielding the inside, so running this
    again after erasing part of a grid only outlines the newly bared edge.
    """
    h, w = len(grid), len(grid[0])
    out = []
    for y, row in enumerate(grid):
        new = ""
        for x, ch in enumerate(row):
            if ch == ".":
                new += "."
                continue
            edge = any(
                nx < 0 or ny < 0 or nx >= w or ny >= h or grid[ny][nx] == "."
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
            new += "O" if edge else ch
        out.append(new)
    return out


def _head_center(grid):
    """Horizontal center of the hair: the widest span in the top rows."""
    top = [y for y, row in enumerate(grid) if row.strip(".")]
    head_rows = top[:max(1, len(top) * 3 // 10)]
    xs = [x for y in head_rows for x, ch in enumerate(grid[y]) if ch != "."]
    return (min(xs) + max(xs)) / 2


def _placed(grid, width, height):
    """Head centered, feet on the second-to-last row, on a width x height canvas."""
    gh, gw = len(grid), len(grid[0])
    x = round((width - 1) / 2 - _head_center(grid))
    x = max(min(x, width - gw), 0) if gw <= width else (width - gw) // 2
    y = height - 1 - gh
    canvas = ["." * width for _ in range(height)]
    for gy, row in enumerate(grid):
        cy = y + gy
        if not 0 <= cy < height:
            continue
        for gx, ch in enumerate(row):
            cx = x + gx
            if ch != "." and 0 <= cx < width:
                canvas[cy] = canvas[cy][:cx] + ch + canvas[cy][cx + 1:]
    return canvas


def cycle(name):
    """Frames of one reference sheet as grids, keyed by direction."""
    sheet = _load(name)
    _, _, width = SHEETS[name]
    out = {}
    for direction, row in zip(DIRECTIONS, _figures(name)):
        tallest = max(y1 - y0 for _, y0, _, y1 in row)
        scale = FIGURE_HEIGHT[name] / tallest
        frames = []
        for box in row:
            grid = outlined(_shrink(sheet.crop(box), scale))
            frames.append(_placed(grid, width, FRAME_HEIGHT))
        out[direction] = frames
    return out


def idle_cycle():
    return cycle("idle")


def walk_cycle():
    return cycle("walk")


def run_cycle():
    return cycle("run")


def base_views():
    """Her standing poses (first idle frame) facing down, up and right."""
    idle = idle_cycle()
    return idle["down"][0], idle["up"][0], idle["right"][0]
