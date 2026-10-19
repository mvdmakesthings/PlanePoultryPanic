"""Build sprite sheets from the grid sources in this folder.

Usage (from the repo root):
    python3 tools/sprites/build.py                  # write sheets to game/assets/sprites/
    python3 tools/sprites/build.py --preview DIR    # also write enlarged previews to DIR

Sheet layout: one PNG per animation, one row per direction (down, up,
right, left), one column per frame, no padding. See
docs/art-style-guide.md for the full rules.
"""
import argparse
from pathlib import Path

from PIL import Image

import carousel
import chicken
import items
import mushrooms
import player
import tiles
from palette import to_image

REPO = Path(__file__).resolve().parents[2]
SPRITES = REPO / "game" / "assets" / "sprites"
DIRECTIONS = ("down", "up", "right", "left")
PREVIEW_BG = (38, 43, 68, 255)

# (file name, frames by direction, frame width, frame height, preview FPS)
SHEETS = [
    ("player_walk.png", player.walk_cycle(), 16, 32, 8),
    ("player_idle.png", player.idle_cycle(), 16, 32, 2),
    ("chicken_walk.png", chicken.walk_cycle(), 16, 16, 8),
    ("chicken_idle.png", chicken.idle_cycle(), 16, 16, 4),
    ("chicken_flight_walk.png", chicken.powered_walk("flight"), 16, 16, 8),
    ("chicken_rage_walk.png", chicken.powered_walk("rage"), 16, 16, 10),
    ("chicken_egg_walk.png", chicken.powered_walk("egg"), 16, 16, 8),
]

# Sheets that aren't organized by direction: (file name, image builder).
# Tile and object layouts are documented in docs/art-style-guide.md.
IMAGES = [
    ("tiles_arrivals.png", tiles.sheet),
    ("mushroom_patch.png", mushrooms.sheet),
    ("carousel.png", carousel.sheet),
    ("item_snack.png", items.snack),
    ("hud_luggage.png", items.luggage),
    ("egg.png", items.egg),
]


def make_sheet(anims, w, h):
    frames = len(anims["down"])
    out = Image.new("RGBA", (w * frames, h * len(DIRECTIONS)), (0, 0, 0, 0))
    for row, direction in enumerate(DIRECTIONS):
        for col, grid in enumerate(anims[direction]):
            out.alpha_composite(to_image(grid), (col * w, row * h))
    return out


def floor_shadow(width):
    img = Image.new("RGBA", (width, 3), (0, 0, 0, 0))
    for x in range(1, width - 1):
        img.putpixel((x, 1), (24, 20, 37, 110))
    for x in range(3, width - 3):
        img.putpixel((x, 0), (24, 20, 37, 70))
        img.putpixel((x, 2), (24, 20, 37, 70))
    return img


def write_previews(out_dir, scale=6):
    """Per sheet: an animated GIF of all four directions and an 8x frame grid."""
    out_dir.mkdir(parents=True, exist_ok=True)
    cell = 24
    for name, anims, w, h, fps in SHEETS:
        stem = name.removesuffix(".png")
        frames = len(anims["down"])
        gif_frames = []
        for i in range(frames):
            canvas = Image.new("RGBA", (cell * 4 + 8, h + 12), PREVIEW_BG)
            for k, direction in enumerate(DIRECTIONS):
                x, y = 4 + k * cell, 6
                canvas.alpha_composite(floor_shadow(w - 2), (x + 1, y + h - 2))
                canvas.alpha_composite(to_image(anims[direction][i]), (x, y))
            canvas = canvas.resize((canvas.width * scale, canvas.height * scale), Image.NEAREST)
            gif_frames.append(canvas.convert("RGB"))
        gif_frames[0].save(out_dir / f"{stem}.gif", save_all=True,
                           append_images=gif_frames[1:], duration=1000 // fps, loop=0)

        sheet = make_sheet(anims, w, h)
        grid = Image.new("RGBA", (4 + frames * (w + 4), 4 + len(DIRECTIONS) * (h + 4)), PREVIEW_BG)
        for row in range(len(DIRECTIONS)):
            for col in range(frames):
                tile = sheet.crop((col * w, row * h, (col + 1) * w, (row + 1) * h))
                grid.alpha_composite(tile, (4 + col * (w + 4), 4 + row * (h + 4)))
        grid.resize((grid.width * 8, grid.height * 8), Image.NEAREST).save(out_dir / f"{stem}_8x.png")


def mock_screen():
    """A 320x180 Arrivals scene built from the real tiles and sprites."""
    t = tiles.by_name()
    scr = Image.new("RGBA", (320, 192), PREVIEW_BG)
    floor = lambda col: "carpet" if col < 8 else "tile" if col < 14 else "wood"
    for row in range(12):
        for col in range(20):
            if col == 0:
                name = "wall_edge_right"
            elif col == 19:
                name = "wall_edge_left"
            elif row < 4:
                name = ("wall_top", "wall_lip", "wall_face_upper", "wall_face_lower")[row]
            elif row == 4:
                name = f"{floor(col)}_shadow"
            else:
                name = f"{floor(col)}_{'ab'[(row * 7 + col * 3) % 2]}"
            scr.alpha_composite(to_image(t[name]), (col * 16, row * 16))

    scr.alpha_composite(carousel.assemble(6, 3, 0), (32, 96))

    walk = chicken.walk_cycle()
    things = [
        (to_image(player.FRONT), 150, 92),
        (to_image(walk["right"][0]), 64, 93),  # riding the carousel
        (to_image(walk["left"][1]), 112, 150),
        (to_image(chicken.idle_cycle()["down"][2]), 40, 150),
        (to_image(chicken.powered_walk("flight")["left"][0]), 200, 104),
        (to_image(chicken.powered_walk("rage")["down"][1]), 250, 140),
        (to_image(chicken.powered_walk("egg")["right"][2]), 190, 158),
        (to_image(mushrooms.patch("flight", 1)), 240, 84),
        (to_image(mushrooms.patch("rage", 2)), 280, 120),
        (to_image(mushrooms.patch("egg", 0)), 100, 66),
    ]
    for img, x, y in sorted(things, key=lambda it: it[2] + it[0].height):
        scr.alpha_composite(floor_shadow(img.width - 2), (x + 1, y + img.height - 2))
        scr.alpha_composite(img, (x, y))
    return scr.crop((0, 0, 320, 180))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--preview", type=Path, help="also write enlarged previews to this folder")
    args = parser.parse_args()

    SPRITES.mkdir(parents=True, exist_ok=True)
    for name, anims, w, h, _ in SHEETS:
        make_sheet(anims, w, h).save(SPRITES / name)
        print(f"wrote {(SPRITES / name).relative_to(REPO)}")
    for name, build in IMAGES:
        build().save(SPRITES / name)
        print(f"wrote {(SPRITES / name).relative_to(REPO)}")
    if args.preview:
        write_previews(args.preview)
        for name, build in IMAGES:
            img = build()
            img.resize((img.width * 8, img.height * 8), Image.NEAREST).save(
                args.preview / name.replace(".png", "_8x.png"))
        mock_screen().resize((1280, 720), Image.NEAREST).save(args.preview / "mock_arrivals_4x.png")
        frames = []
        for f in range(carousel.FRAMES):
            img = Image.new("RGBA", (6 * 16 + 16, 4 * 16 + 16), (90, 105, 136, 255))
            img.alpha_composite(carousel.assemble(6, 4, f), (8, 8))
            frames.append(img.resize((img.width * 6, img.height * 6), Image.NEAREST).convert("RGB"))
        frames[0].save(args.preview / "carousel.gif", save_all=True, append_images=frames[1:],
                       duration=125, loop=0)
        print(f"wrote previews to {args.preview}")


if __name__ == "__main__":
    main()
