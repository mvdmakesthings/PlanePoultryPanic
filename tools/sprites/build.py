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
import final
import chicken
import closet
import effects
import ending
import foodcourt
import gate
import gates
import items
import mushrooms
import opening
import player
import roost
import easter_eggs
import security
import security_door
import set_dressing
import tiles
from palette import to_image

REPO = Path(__file__).resolve().parents[2]
SPRITES = REPO / "game" / "assets" / "sprites"
ICON = REPO / "game" / "icon.png"
ICON_SIZE = 512
DIRECTIONS = ("down", "up", "right", "left")
PREVIEW_BG = (38, 43, 68, 255)

# (file name, frames by direction, frame width, frame height, preview FPS)
SHEETS = [
    ("player_walk.png", player.walk_cycle(), 16, 32, 8),
    ("player_idle.png", player.idle_cycle(), 16, 32, 2),
    ("player_walk_extinguisher.png", player.walk_cycle_extinguisher(), 16, 32, 8),
    ("player_idle_extinguisher.png", player.idle_cycle_extinguisher(), 16, 32, 2),
    ("player_run.png", player.run_cycle(), 16, 32, 14),
    ("player_run_extinguisher.png", player.run_cycle_extinguisher(), 16, 32, 14),
    ("player_throw.png", player.throw_cycle(), 16, 32, 10),
    ("player_hurt.png", player.hurt_cycle(), 16, 32, 2),
    ("chicken_walk.png", chicken.walk_cycle(), 16, 16, 8),
    ("chicken_idle.png", chicken.idle_cycle(), 16, 16, 4),
    ("chicken_chase.png", chicken.chase_cycle(), 16, 16, 12),
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
    ("luggage_cart.png", items.cart),
    ("suitcase.png", items.suitcase),
    ("player_ko.png", player.ko_sheet),
    ("player_eat.png", player.eat_sheet),
    ("chicken_eat.png", chicken.eat_sheet),
    ("player_defeat.png", player.defeat_sheet),
    ("player_hair_mess.png", player.hair_mess_sheet),
    ("item_extinguisher.png", items.extinguisher),
    ("extinguisher_cabinet.png", items.cabinet),
    ("ice_block.png", items.ice),
    ("feather_poof.png", effects.poof),
    ("gate_door.png", gate.sheet),
    ("closet_door.png", closet.sheet),
    ("roost.png", roost.sheet),
    ("departure_board.png", set_dressing.departure_board_sheet),
    ("window.png", set_dressing.window_sheet),
    ("potted_plant.png", set_dressing.potted_plant_sheet),
    ("welcome_banner.png", set_dressing.welcome_banner_sheet),
    ("item_maintenance_key.png", items.maintenance_key),
    ("security_door.png", security_door.sheet),
    ("signs.png", set_dressing.signs_sheet),
    ("maintenance_cart.png", set_dressing.maintenance_cart_sheet),
    ("seating.png", set_dressing.seating_sheet),
    ("floor_litter.png", set_dressing.litter_sheet),
    ("map_stand.png", set_dressing.map_stand_sheet),
    ("tiles_security.png", security.tiles_sheet),
    ("stanchion.png", lambda: to_image(security.stanchion())),
    ("xray_machine.png", lambda: to_image(security.xray_machine())),
    ("metal_detector.png", lambda: set_dressing._strip(
        [security.metal_detector(f) for f in range(2)], 32, 34)),
    ("bin_table.png", lambda: to_image(security.bin_table())),
    ("item_boarding_pass.png", security.boarding_pass),
    ("security_shutter.png", security.shutter_sheet),
    ("shutter_switch.png", security.shutter_switch_sheet),
    ("stall_door.png", security.stall_sheet),
    ("pass_gate.png", security.pass_gate_sheet),
    ("security_litter.png", security.litter_sheet),
    ("tiles_food_court.png", foodcourt.tiles_sheet),
    ("restaurant_fronts.png", foodcourt.fronts_sheet),
    ("food_table.png", lambda: to_image(foodcourt.food_table())),
    ("vending_machine.png", foodcourt.vending_sheet),
    ("trash_bin.png", lambda: to_image(foodcourt.trash_bin())),
    ("food_litter.png", foodcourt.litter_sheet),
    ("gates_door.png", foodcourt.gates_door_sheet),
    ("tiles_gates.png", gates.tiles_sheet),
    ("walkway.png", gates.walkway_sheet),
    ("speed_panel.png", gates.speed_panel_sheet),
    ("gate_desk.png", lambda: to_image(gates.gate_desk())),
    ("gate_doors.png", gates.gate_doors_sheet),
    ("final_gate_door.png", gates.final_gate_sheet),
    ("gates_litter.png", gates.litter_sheet),
    ("tiles_final.png", final.tiles_sheet),
    ("night_window.png", final.night_window_sheet),
    ("boss_crown.png", final.crown_sheet),
    ("vent.png", final.vent_sheet),
    ("boarding_door.png", final.boarding_door_sheet),
    ("plane_door.png", final.plane_door_sheet),
    ("final_litter.png", final.litter_sheet),
    ("ending_sky.png", ending.sky),
    ("plane_side.png", ending.plane_sheet),
    ("stowaway.png", ending.stowaway_sheet),
    ("passenger_window.png", ending.passenger_window_sheet),
    ("departure_board_security.png", lambda: set_dressing.departure_board_sheet("security")),
    ("departure_board_food_court.png", lambda: set_dressing.departure_board_sheet("food_court")),
    ("departure_board_gates.png", lambda: set_dressing.departure_board_sheet("gates")),
    ("departure_board_final.png", lambda: set_dressing.departure_board_sheet("final")),
    ("opening_backdrop.png", opening.backdrop_sheet),
    ("opening_tarmac.png", opening.tarmac_sheet),
    ("opening_boarding_pass.png", opening.boarding_pass_sheet),
    ("departure_board_gates_b.png", lambda: set_dressing.departure_board_sheet("gates_b")),
    ("secret_doors.png", easter_eggs.doors_sheet),
    ("mural.png", easter_eggs.mural_sheet),
    ("pilot_cap.png", easter_eggs.pilot_cap_sheet),
    ("secret_stashes.png", easter_eggs.stashes_sheet),
    ("suitcase_fragile.png", easter_eggs.fragile_suitcase),
    ("posters.png", easter_eggs.posters_sheet),
    ("fuel_drum.png", easter_eggs.fuel_drum_sheet),
    ("captain_hat.png", easter_eggs.captain_hat),
    ("captain_chicken.png", easter_eggs.captain_chicken_sheet),
    ("stowaway_captain.png", easter_eggs.stowaway_captain_sheet),
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
    to_image(chicken.add_cap(chicken.SIDE, "rage")).resize((ICON_SIZE, ICON_SIZE), Image.NEAREST).save(ICON)
    print(f"wrote {ICON.relative_to(REPO)}")
    if args.preview:
        write_previews(args.preview)
        for name, build in IMAGES:
            img = build()
            img.resize((img.width * 8, img.height * 8), Image.NEAREST).save(
                args.preview / name.replace(".png", "_8x.png"))
        mock_screen().resize((1280, 720), Image.NEAREST).save(args.preview / "mock_arrivals_4x.png")
        final.mock_screen().resize((1280, 720), Image.NEAREST).save(args.preview / "mock_final_4x.png")
        gates.mock_screen().resize((1280, 720), Image.NEAREST).save(args.preview / "mock_gates_4x.png")
        foodcourt.mock_screen().resize((1280, 720), Image.NEAREST).save(args.preview / "mock_food_court_4x.png")
        security.mock_screen().resize((1280, 720), Image.NEAREST).save(args.preview / "mock_security_4x.png")
        opening.mock_screen().resize((1280, 720), Image.NEAREST).save(args.preview / "mock_opening_4x.png")
        wall = set_dressing.wall_preview(tiles.by_name())
        wall.resize((wall.width * 4, wall.height * 4), Image.NEAREST).save(
            args.preview / "mock_wall_4x.png")
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
