"""Effects: the feather poof a chicken leaves when it's defeated."""
import math

from PIL import Image

from palette import put, to_image

POOF_SIZE = 24
POOF_FRAMES = 6
# Puff radius per frame; the feathers fly outward and drift down.
PUFF_RADIUS = [4, 6, 6, 5, 3, 0]
FEATHER_ANGLES = [i * math.tau / 8 + 0.3 for i in range(8)]


def poof_frame(i):
    g = ["." * POOF_SIZE for _ in range(POOF_SIZE)]
    cx = cy = POOF_SIZE // 2
    r = PUFF_RADIUS[i]
    for y in range(POOF_SIZE):
        for x in range(POOF_SIZE):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if r and d < r - 1:
                put(g, y, x, "C" if d < r - 2.5 else "c")
            elif r and d < r and i < 3:
                put(g, y, x, "O")
    # Feathers: 2px streaks flying out, falling a little more each frame.
    dist = 3 + i * 1.8
    for k, a in enumerate(FEATHER_ANGLES):
        x = round(cx + math.cos(a) * dist)
        y = round(cy + math.sin(a) * dist + i * i * 0.25)
        tip = "c" if i < 4 else "w"
        for dx, ch in ((0, "C" if i < 4 else "c"), (1 if k % 2 else -1, tip)):
            if 0 <= x + dx < POOF_SIZE and 0 <= y < POOF_SIZE:
                put(g, y, x + dx, ch)
    # A bit of red comb flies up for comic effect.
    if 1 <= i <= 3:
        put(g, cy - 4 - i * 2, cx + 1, "R")
    return g


def poof():
    out = Image.new("RGBA", (POOF_SIZE * POOF_FRAMES, POOF_SIZE), (0, 0, 0, 0))
    for i in range(POOF_FRAMES):
        out.alpha_composite(to_image(poof_frame(i)), (i * POOF_SIZE, 0))
    return out
