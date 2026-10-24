"""Promo art for the itch.io page, built from the game's own sprites.

    python3 tools/sprites/promo.py

writes, into docs/images/:
  - itch_banner.png: 960x288 header banner (drawn at 320x96, scaled 3x).
    Amanda sprints across the terminal with chickens on her heels, under
    a departure-board title.
  - itch_background.png: 256x256 seamless tile for the page background
    (drawn at 64x64, scaled 4x): dim terminal carpet with chicken tracks.

and, given a staged in-game shot (see game/tests/store_shots.gd),

    python3 tools/sprites/promo.py devlog /tmp/shot.png "THE HEADLINE" 0.4.0

writes a devlog cover, devlog_v<version>.png: 1280x720, the middle 256x144
of the shot (a little above center) scaled 5x under a departure-board
headline (at most about 26 characters).
"""
import sys
from pathlib import Path

from PIL import Image

import chicken
import items
import mushrooms
import player
import tiles
from palette import PALETTE, put, to_image
from set_dressing import FONT

OUT = Path(__file__).resolve().parents[2] / "docs" / "images"
SHADOW = (24, 20, 37, 110)


def rgb(key, alpha=255):
    return tuple(int(PALETTE[key][i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def draw_text(img, x, y, text, key, scale=1, shadow=None, outline=None):
    """3x5 sign font, each font pixel drawn as a scale x scale block, with an
    optional 1-pixel dark outline and a 1-pixel drop shadow."""
    passes = []
    if outline:
        passes += [(outline, dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
    if shadow:
        passes += [(shadow, 1, 1), (shadow, 0, 1)]
    for pass_key, dx, dy in passes + [(key, 0, 0)]:
        cx = x
        for ch in text:
            for gy, row in enumerate(FONT[ch]):
                for gx, bit in enumerate(row):
                    if bit == "#":
                        for sy in range(scale):
                            for sx in range(scale):
                                img.putpixel((cx + gx * scale + sx + dx, y + gy * scale + sy + dy), rgb(pass_key))
            cx += 4 * scale


def blend(img, x, y, key, alpha):
    """Mixes a palette color into a pixel, keeping the pixel fully opaque."""
    base = img.getpixel((x, y))
    top = rgb(key)
    a = alpha / 255
    img.putpixel((x, y), tuple(round(base[i] * (1 - a) + top[i] * a) for i in range(3)) + (255,))


def text_width(text, scale=1):
    return (len(text) * 4 - 1) * scale


def floor_shadow(img, cx, y, w):
    for x in range(cx - w // 2, cx + w // 2):
        img.putpixel((x, y), SHADOW)
    for x in range(cx - w // 2 + 2, cx + w // 2 - 2):
        img.putpixel((x, y - 1), SHADOW)
        img.putpixel((x, y + 1), SHADOW)


def place(img, grid, x, y):
    """Draws a sprite grid with its top-left at x, y, plus a floor shadow."""
    sprite = to_image(grid)
    floor_shadow(img, x + sprite.width // 2, y + sprite.height - 1, sprite.width - 4)
    img.alpha_composite(sprite, (x, y))


def banner():
    w, h = 320, 96
    img = Image.new("RGBA", (w, h), rgb("O"))
    t = tiles.by_name()
    # Back wall: top, lip, the two face rows, then a shadowed floor row.
    for col in range(w // 16):
        for row, name in enumerate(("wall_top", "wall_face_upper", "wall_face_lower")):
            img.alpha_composite(to_image(t[name]), (col * 16, row * 16))
        img.alpha_composite(to_image(t["carpet_pattern_shadow"]), (col * 16, 48))
        for row in (64, 80):
            name = "carpet_pattern_a" if (col + row // 16) % 2 else "carpet_pattern_b"
            img.alpha_composite(to_image(t[name]), (col * 16, row))

    # Departure-board title panel.
    title, tag = "PLANE POULTRY PANIC", "ESCAPE THE AIRPORT. CATCH THE LAST FLIGHT."
    pw = max(text_width(title, 3), text_width(tag)) + 16
    px, py, ph = (w - pw) // 2, 5, 36
    for y in range(py, py + ph):
        for x in range(px, px + pw):
            edge = y in (py, py + ph - 1) or x in (px, px + pw - 1)
            img.putpixel((x, y), rgb("O" if edge else "k"))
    for x in range(px + 1, px + pw - 1):
        img.putpixel((x, py + 1), rgb("p"))
    draw_text(img, (w - text_width(title, 3)) // 2, py + 5, title, "F", scale=3, shadow="y", outline="O")
    draw_text(img, (w - text_width(tag)) // 2, py + 26, tag, "C")
    # Boarding light on the board's corner.
    for y in range(py + 4, py + 7):
        for x in range(px + pw - 8, px + pw - 5):
            img.putpixel((x, y), rgb("g"))

    # The chase, left to right: chickens on Amanda's heels, a flung snack,
    # a flight chicken overhead, and a totem waiting at the far end.
    run = player.run_cycle()["right"]
    chase = chicken.chase_cycle()["right"]
    rage = chicken.powered_walk("rage")["right"]
    flight = chicken.powered_walk("flight")["right"]
    egg = chicken.powered_walk("egg")["right"]
    place(img, chase[0], 22, 74)
    place(img, egg[2], 46, 66)
    place(img, chase[2], 70, 76)
    place(img, rage[1], 96, 70)
    place(img, run[2], 136, 58)
    snack = items.snack()
    img.alpha_composite(snack, (118, 56))
    place(img, flight[0], 190, 52)
    img.alpha_composite(to_image(mushrooms.patch("flight", 1)), (226, 74))

    # A four-chicken totem, the capped one on top, like the game builds it.
    idle = chicken.idle_cycle()["down"][0]
    top = chicken.powered_walk("rage")["down"][1]
    floor_shadow(img, 278, 89, 12)
    for i, grid in enumerate([idle, idle, idle, top]):
        img.alpha_composite(to_image(grid), (270, 74 - i * 10))
    return img.resize((w * 3, h * 3), Image.NEAREST)


# A chicken footprint: three toes and a heel, 5x5.
TRACK = [
    "#.#.#",
    ".###.",
    "..#..",
    "..#..",
    "..#..",
]


def background():
    size = 64
    img = Image.new("RGBA", (size, size))
    t = tiles.by_name()
    for row in range(size // 16):
        for col in range(size // 16):
            name = "carpet_pattern_a" if (row + col) % 2 else "carpet_pattern_b"
            img.alpha_composite(to_image(t[name]), (col * 16, row * 16))
    # Dim it, so page text in front stays easy to read.
    img.alpha_composite(Image.new("RGBA", (size, size), (24, 20, 37, 150)))
    # A trail of chicken tracks wandering across the tile; every track sits
    # fully inside the tile so the pattern repeats without seams.
    for (tx, ty) in ((6, 4), (16, 12), (12, 24), (24, 32), (36, 28), (44, 40), (40, 52), (52, 58)):
        for gy, row in enumerate(TRACK):
            for gx, bit in enumerate(row):
                if bit == "#" and tx + gx < size and ty + gy < size:
                    blend(img, tx + gx, ty + gy, "T", 110)
    # A lone feather.
    for x, y, key in ((56, 10, "c"), (57, 10, "C"), (58, 11, "C"), (59, 11, "c")):
        blend(img, x, y, key, 150)
    return img.resize((size * 4, size * 4), Image.NEAREST)


def devlog_cover(shot_path, headline, tag):
    """Crops a 1280x720 shot (the 320x180 game at 4x) to its middle 256x144
    and puts a departure-board headline across the top."""
    shot = Image.open(shot_path).convert("RGBA").resize((320, 180), Image.NEAREST)
    img = shot.crop((32, 6, 288, 150))
    w = img.width
    pw = max(text_width(headline, 2), text_width(tag)) + 22
    px, py, ph = (w - pw) // 2, 3, 27
    for y in range(py, py + ph):
        for x in range(px, px + pw):
            edge = y in (py, py + ph - 1) or x in (px, px + pw - 1)
            img.putpixel((x, y), rgb("O" if edge else "k"))
    for x in range(px + 1, px + pw - 1):
        img.putpixel((x, py + 1), rgb("p"))
    draw_text(img, (w - text_width(headline, 2)) // 2, py + 5, headline, "F", scale=2, shadow="y", outline="O")
    draw_text(img, (w - text_width(tag)) // 2, py + 19, tag, "C")
    # Boarding light on the board's corner.
    for y in range(py + 4, py + 7):
        for x in range(px + pw - 7, px + pw - 4):
            img.putpixel((x, y), rgb("g"))
    return img.resize((w * 5, img.height * 5), Image.NEAREST)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    if len(sys.argv) == 5 and sys.argv[1] == "devlog":
        shot, headline, version = sys.argv[2:]
        cover = devlog_cover(shot, headline, f"PLANE POULTRY PANIC  +  UPDATE V{version}")
        cover.save(OUT / f"devlog_v{version}.png")
        print(f"wrote {OUT / f'devlog_v{version}.png'}")
        sys.exit()
    banner().save(OUT / "itch_banner.png")
    background().save(OUT / "itch_background.png")
    print(f"wrote {OUT / 'itch_banner.png'}")
    print(f"wrote {OUT / 'itch_background.png'}")
