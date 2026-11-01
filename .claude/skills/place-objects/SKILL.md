---
name: place-objects
description: Create new furniture, decor or airport props for Plane Poultry Panic and place them in levels the way a commercial interior designer would, without hurting gameplay. Use when asked to add, make, draw, place, move, rearrange, declutter or audit props, furniture, set dressing, signs or wall decor in any level, or to check that items aren't overlapping, floating or in the way.
---

# Place objects

You are the airport's commercial interior designer as well as its level
designer. Every prop has to make sense where it stands (a luggage scale
belongs by the baggage carousels, not in a boss arena), sit properly
(flush to a wall, on a wall face, on the floor), and never get in the
way of play. When in doubt, leave it out: an empty floor reads better
than a busy one, and open floor is where chases happen.

## Where things live

- **Levels**: `game/scenes/levels/level_0N_*.tscn`. The room layout is the
  text `MAP` in `game/scripts/levels/level_0N_*.gd` (legend in
  `LevelBuilder`; 16px tiles). Code-built pieces such as carousels live
  in the level script's `_build()`.
- **Floor props** go under `Entities` (y-sorted). They are instanced
  scenes from `game/scenes/objects/`, usually a `StaticBody2D` with
  `floor_prop.gd`, the `nav_obstacles` group (so chickens path around
  them), a `Sprite2D` drawn above its origin (`offset = Vector2(0, -h/2)`),
  and a small `RectangleShape2D` base at the feet. The node's `position`
  is the **foot of the prop**, not its center.
- **Wall decor** (boards, clocks, posters, windows, signs) is a plain
  `Sprite2D` under `WallDecor` with `centered = false`, so `position` is
  the **top-left corner**. Hang it on a wall face only: the two wall rows
  just above a floor (`wall_face_upper` and `wall_face_lower`). The
  rows above those (`wall_lip`, `wall_top`) are the dark wall mass. Decor
  there looks like it's floating.
- **Overhead signs** (`sign_gantry.png`: GATES >, SECURITY, BAGGAGE) hang
  over a walkway. They are the one kind of `WallDecor` that may sit over
  floor, and they need `z_index = 1` so characters walk under them.
- **Litter** decals sit under `FloorLitter`; keep them out from under
  furniture, where nobody sees them. Never place a decal that looks like
  something Amanda could pick up (a bag of chips, fries, a shoe, a bottle,
  a key-like buckle, boarding passes): players walk over it expecting a
  pickup. Puddles, feathers, nests, footprints and spills are fine.
- **Art**: props are drawn in code in `tools/sprites/` (most furniture in
  `set_dressing.py`), registered in `tools/sprites/build.py`, and built
  with `python3 tools/sprites/build.py`. Follow `docs/art-style-guide.md`
  (ENDESGA 32 palette, 3/4 view, sizes) and add new sheets to it.
  When the user gives reference art, recreate it exactly; don't reinterpret it.

## Designer rules

1. **Zone by purpose.** Put each prop where an airport would:
   - Wayfinding (gate totems, flight kiosks, gantries): at decision points,
     like corridor mouths and next to the gate they name. A gate totem must
     show a gate that exists in that room (`TOTEM_CODES` in
     `set_dressing.py`). Change the codes and rebuild rather than show a
     wrong number.
   - Seating: in banks facing gates or windows, with their backs to walls or
     in grids on carpet. Never inside a queue lane.
   - Service (ATMs, luggage scales, vending, bins): against walls, near
     where people need them. Put scales near baggage claim, ATMs in halls,
     and bins by seating and doors.
   - Plants: soften corners and flank doors or machines. Don't put them in
     the middle of a walkway.
   - Keep restrooms, staff rooms and the boss arena nearly bare.
2. **Flush, not almost.** A prop against a wall should be flush (0-2px).
   Leave a gap Amanda can walk through (10px sideways, 6px front to back),
   or none. A 3-9px sliver looks open but blocks her.
3. **Wall decor on wall faces only.** Space it along the face. Don't
   cover other decor, and don't put floor props in front of boards or
   signs (their sprites rise into the wall face in 3/4 view).
4. **Rhythm, not rows.** Avoid lining every service prop along one wall at
   even spacing like a shelf. Cluster by purpose (an info cluster: board +
   kiosk; a rest cluster: seats + bin + plant) and leave breathing room.
5. **Don't repeat what's already there.** One clock per wall run, one
   kiosk per gate area. Don't put a GATES sign at the gate itself.

## Gameplay keep-clear (non-negotiable)

- Doorways, corridor mouths, metal-detector lanes and their exits: at least
  two tiles of open floor in the direction of travel.
- Carousel belts and chutes, walkways, hint zones' key spots, checkpoints,
  roosts, mushroom patches, the level start and the exit door: keep clear.
- Pickups (snacks, keys, boarding pass, suitcases, secret stashes) stay
  visible. Never cover one with a sprite.
- Chickens path with a 6px agent radius around `nav_obstacles`; gaps under
  12px are walls to them. Don't box off a pickup or seal a route.
- Placement must not change difficulty. If a prop would make a chase
  easier or harder, ask the user before placing it.

## Workflow

1. **Look first.** Render the levels and inspect the panels (use the Read
   tool on the PNGs):
   ```bash
   tools/placement/render.sh /tmp/placement --mark level_01_arrivals
   ```
   `--mark` labels every entity and outlines collision bases in red. Each
   panel covers a slice of the level at 2x; the script prints the width.
   Panel pixel `p` in panel `n` maps to level x = `n * width + p / 2`.
2. **Audit.** Run the placement check (headless, fast):
   ```bash
   cd game && godot --headless --path . res://tests/placement_check.tscn -- --level=res://scenes/levels/level_01_arrivals.tscn
   ```
   It reports `off wall`, `overlaps`, `into wall` and `pocket`, and
   ends with `PLACEMENT OK` or `PLACEMENT PROBLEMS: N`. `--names=A,B`
   limits it to some props. If a prop is placed that way on purpose (a bin
   sitting on a table, a joke poster beside a plant), give it
   `metadata/placement_ok = true` rather than leaving the warning.
3. **Find wall space.** For decor, ask for free wall-face spots near
   where you want it: `--free="W,H,X,Y[,NodeBeingMoved]"`. Separate several
   queries with `;`. Sizes are one frame (a clock is 16x16, a notice board
   32x16, a gantry 40x16).
4. **Make a new prop** if needed: draw it in `tools/sprites/` (one
   function per sheet, frames side by side), register it in `build.py`,
   build it, add a scene in `game/scenes/objects/` modeled on
   `atm.tscn` or `potted_plant.tscn` (base shape about the footprint,
   `shadow_radius` about half the width), and document it in the art guide.
   Animated props use a `Sprite2D` with `flipbook_sprite.gd` as its script.
5. **Place or move props** with a JSON spec so the whole pass is one
   reviewable change:
   ```bash
   cd game && python3 ../tools/placement/edit_scene.py spec.json
   ```
   See the docstring in `tools/placement/edit_scene.py` for `move`,
   `remove`, `set`, `unset` and `frame`. Use `frame` to pick a frame on an
   instanced prop. Setting `frame` on the prop's root does nothing, because
   the root is a `StaticBody2D`. New nodes are easiest to add by hand: copy
   a sibling block in the `.tscn` and add its `ext_resource`.
6. **Verify.** Re-run the check until every level reads `PLACEMENT OK`,
   re-render and look at every change, then run the smoke tests:
   ```bash
   cd game && for t in level_01 level_02 level_03 level_04 level_05; do godot --headless --path . res://tests/${t}_smoke.tscn 2>&1 | tail -1; done
   ```
   Also run `secrets_smoke`, `scoring_smoke` and `mushroom_spread_smoke`.
   The last one is randomly flaky near walls, so rerun it once before
   blaming a placement.
7. **Report** to the user what moved and why, in designer terms ("moved the
   ATM flush to the east wall"), plus anything you chose not to change.
   Record new design decisions in the GDD's decision log.
