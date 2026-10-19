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

import chicken
import player
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


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--preview", type=Path, help="also write enlarged previews to this folder")
    args = parser.parse_args()

    SPRITES.mkdir(parents=True, exist_ok=True)
    for name, anims, w, h, _ in SHEETS:
        make_sheet(anims, w, h).save(SPRITES / name)
        print(f"wrote {(SPRITES / name).relative_to(REPO)}")
    if args.preview:
        write_previews(args.preview)
        print(f"wrote previews to {args.preview}")


if __name__ == "__main__":
    main()
