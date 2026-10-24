# Plane Poultry Panic: Art Style Guide

The rules every piece of in-game art follows. Consistency is what makes pixel art look professional, so when a new sprite breaks one of these rules, either the sprite changes or the rule changes here first.

**Status**: Locked. The style test ([roadmap.md](roadmap.md), M2) was signed off on 2026-10-19. New art follows these rules; changing a rule means updating this guide first.

---

## Who Makes the Art

- **First pass (now)**: Claude makes all in-game pixel art (characters, chickens, tiles, objects, effects, UI) so the game can be built and playtested with real-looking art.
- **Amanda's reference art**: her idle, walk and run sheets are converted straight from the creator's reference sheets in `tools/sprites/reference/` by `tools/sprites/reference.py`, which cuts out each frame, shrinks it to size with a majority vote per pixel, snaps it to the palette and outlines it. Her other animations are built on the converted standing poses. To change her look, replace those sheets (same layout: rows down, up, right, left on magenta; 2 idle, 4 walk and 6 run frames) and rebuild.
- **Final art (after the game is done)**: You redraw every sprite by hand, using Claude's sprites as templates. Keep the same frame sizes, sheet layouts, and file names, so each redrawn sheet drops straight into the game with no code changes.
- **Art direction**: You approve the style and give feedback throughout.
- **Store art**: Steam capsule images and key art, made by you or commissioned near launch. These are large illustrations, not in-game sprites, and they drive store-page clicks.
- **AI disclosure**: Steam asks developers to disclose AI-generated content that ships in the game or on the store page. Check the current rules before launch, especially if any first-pass sprites are still in the game.

## Look and Feel

- **Era**: 16-bit SNES, with *Zombies Ate My Neighbors* as the main reference
- **Mood**: Bright and cartoony at first glance, with the airport slowly turning wrong as you go deeper
- **Readability first**: At 320x180, the player must be able to tell the player, a normal chicken, and a powered chicken apart in under a second. When style and readability clash, readability wins.

---

## Resolution and Scale

| Thing | Size |
|---|---|
| Screen | 320x180 (20 x about 11 tiles visible) |
| Tile | 16x16 |
| Player | 16x32 frame, 32x32 while running (her strides are too wide for 16) |
| Chicken | 16x16 frame, about 12x12 of visible bird |
| Chicken totem | 16 px wide, each stacked chicken adds about 10 px of height |
| Items and pickups | 8x8 or 16x16 |
| HUD icons | 8x8 to 12x12 |

- Art is drawn at 1x and never scaled up or down by fractions in-game. The whole screen scales by whole numbers (4x, 6x).
- Everything sits on whole-pixel positions. No sub-pixel or rotated sprites, except deliberate effects like thrown snacks.

## View

**3/4 view**, the angle used by *Zombies Ate My Neighbors* and *Zelda: A Link to the Past*:

- Floors are seen from directly above.
- Walls show a top edge plus a front face 1-2 tiles tall.
- Characters, chickens, and furniture are seen from slightly above the front: you see the front of the body and a bit of the top of the head.
- Characters have 4 facing directions drawn (down, up, left, right). Diagonal movement uses the nearest left or right sprite.

## Palette

One shared palette for the whole game. No colors outside it, ever.

**Proposed starting palette: ENDESGA 32**, a widely used, free 32-color palette with good warm and cool ranges. It gets confirmed or swapped in the style test.

| Role | Colors |
|---|---|
| Outlines and deepest shadow | `#181425` `#262b44` |
| Terminal grays and whites (walls, floors) | `#3a4466` `#5a6988` `#8b9bb4` `#c0cbdc` `#ffffff` |
| Corporate blue (signage, branding) | `#124e89` `#0099db` |
| Gate-area teal and glow | `#193c3e` `#2ce8f5` |
| Food court yellows and warm floors | `#feae34` `#fee761` `#e4a672` |
| Departure-board orange | `#f77622` `#d77643` |
| Reds (combs, rage mode, danger) | `#a22633` `#e43b44` `#ff0044` `#be4a2f` |
| Greens (plants, exit signs, healing) | `#265c42` `#3e8948` `#63c74d` |
| Browns (luggage, wood, carousels) | `#3e2731` `#733e39` `#b86f50` `#c28569` |
| Skin tones | `#e8b796` `#c28569` `#b86f50` `#733e39` |
| Purples and pinks (the player's hair, egg-shooter caps, spore effects) | `#68386c` `#b55088` `#f6757a` |
| Light warm (chicken shading, paper) | `#ead4aa` |

### Color Rules
- **Max 16 colors per sprite**, usually far fewer. A chicken needs around 6.
- **Shading uses 2-3 steps** per material: base, shadow, and sometimes a highlight.
- **Shadows shift cooler and darker** (toward blue or purple), not just darker. Highlights shift warmer.
- **Reserved colors**: `#ff0044` only for danger (rage mode, damage flashes, hazard edges). `#2ce8f5` glow only for supernatural effects (flight mode, totems). Keeping these special keeps them readable.

## Light and Shading
- Light comes from the **top left** everywhere.
- Characters and objects cast a small, flat dark ellipse under them (`#181425` at about 40% opacity). This anchors them to the floor and shows height when chickens fly.
- No gradients and no dithering on characters. Light dithering is allowed on large floor and wall areas.

## Outlines
- **Characters, chickens, items, and pickups**: a 1-pixel dark outline (`#181425`). This keeps them readable on busy floors.
- **Environment tiles**: no outlines. They read through shading and color instead, which pushes them into the background.
- **Selective outline**: where an outline sits against a lit area, it may lighten to `#262b44` or the shadow tone of the material.

---

## Characters

### Player
- Converted from the creator's reference sheets: shoulder-length mauve-pink hair with side-swept bangs, a heather-gray tee with a small crest print, a blue backpack, black leggings, charcoal boots, and tattooed forearms.
- The pink hair (`#b55088` family) and blue backpack (`#124e89` family) are the player's signature colors. They make the player stand out against the gray terminal and the white chickens, so no other character or prop should use that pairing.
- At 16x32, details are hinted, not drawn: each eye is a light and a dark pixel, the tattoos a few ink pixels on each forearm, and the shirt print a couple of gray pixels.

### Normal Chickens
- Classic white farm hen: white body shaded with `#ead4aa`, red comb, yellow-orange beak and legs.
- Slightly dopey expression. They should look funny first and threatening second.

### Powered Chickens
Every powered state has a color cue **and** a shape or animation cue, so it still reads for colorblind players.

| Mode | Color cue | Shape / animation cue |
|---|---|---|
| Flight | Teal glowing mushroom cap, `#2ce8f5` glow on wings | Wings spread, hovering bob, particle trail |
| Rage | Red-and-white spotted mushroom cap, flames (`#f77622`, `#feae34`) | Puffed-up feathers, faster walk cycle, flickering flames |
| Egg Shooter | Purple mushroom cap (`#b55088`, pink spots) | Bulging throat, wind-up squash before each shot |

### Totems
Stacked chickens with a visible wobble. The bottom chicken looks strained, the top one looks smug. The final boss totem is taller and crowned with a giant glowing mushroom.

### Mushroom Patches
Clusters of 3-5 mushrooms growing out of carpet, planters, and spilled food. Each patch is one variety, colored to match the cap its chickens wear: teal glowcaps (flight), red spotted caps (rage), purple caps (egg shooter). Patches glow softly and puff spores so they're easy to spot from across a room.

## Animation

| Animation | Frames | Speed |
|---|---|---|
| Idle | 2-4 | 4-6 FPS |
| Walk | 4 | 8-10 FPS |
| Run | 4-6 | 12-14 FPS |
| Chicken peck | 3-4 | 8 FPS |
| Hit / damage | 2 + blink | Fast |
| Feather poof (defeat) | 5-6 | 12 FPS |

- Favor **squash and stretch** and exaggerated poses. A few frames done well beat many stiff ones.
- Every attack has a **wind-up frame** so the player has a chance to react.

### Game-Feel Effects (Juice)
Feedback drawn in code by the `Juice` autoload (`game/scripts/managers/juice.gd`) and `ParticleBurst` (`game/scripts/objects/particle_burst.gd`), so it needs no extra frames in any character sheet:

- **Screen shake**: whole-pixel camera jolts that die away over a quarter second, 1-3 px for everyday hits and slams, up to 6-8 px for the boss. Players can turn it off in Settings (Screen Shake), so nothing may depend on it to be readable.
- **Hit-stop**: the action nearly freezes for a few frames (0.04-0.1 s; 0.25 s when the boss falls) so big hits land.
- **Hit flashes**: the whole sprite flashes one solid palette color, keeping its silhouette, and fades back within a fifth of a second. Amanda flashes the reserved danger red `#ff0044` when hurt; chickens and totems flash white `#ffffff`. Don't flash in other colors.
- **Squash and stretch**: sprites briefly scale (about 1.3 x 0.7) around their feet and spring back. This is the one allowed exception to "no fractional scaling", because it lasts a fraction of a second.
- **Particles**: small 8x8 bits from `effects_particles.png` (below) that arc up, land on the floor and blink out over the last fifth of their life. They never fade with transparency, and always sit on whole pixels.
- **HUD**: suitcases jitter a pixel after a hit, a slot pops up two pixels when it changes, and the stamina bar blinks red and white while Amanda is out of breath.

### Animation Sets

Left-facing frames are mirrored from right-facing ones, so each character only needs 3 drawn directions (down, up, right). Amanda's converted idle, walk and run sheets are the exception: the reference draws all four.

**Player**

| Animation | Directions | Frames | Needed by |
|---|---|---|---|
| Idle | 4 | 2 | M2 style test |
| Walk | 4 | 4 | M2 style test |
| Run | 4 | 6, in 32x32 frames (a full sprint from the reference sheets: long strides, arms pumping, hair streaming) | M4 vertical slice |
| Throw | 4 | 3 (wind-up, release, follow-through) | M4, done |
| Eat | 1 (facing down) | 3 (bite, chew, yum) | M4, done |
| Hurt | 4 | 1, plus blinking | M4, done |
| Defeat | 1 | 4, then the knocked-out loop | M4, done |

Running is a core mechanic tied to stamina, so it has its own cycle: players can see at a glance when they're spending stamina. Every M4 player animation is done: run, throw, eat, hurt and defeat. Action animations (throw, eat, hurt) play for a moment over the walk or idle, then hand back.

The idle, walk and run sheets are converted from the reference art (see Who Makes the Art). The action poses are built by stamping small hand-drawn pieces (raised arms, a fist, the snack bag, faces) onto her converted standing poses in `tools/sprites/player.py`, so a new reference sheet changes these sheets too. The reference's down- and up-facing run rows are three-quarter views (she sprints across the screen with her face or her back to the camera), so those rows read as a sideways sprint rather than a run toward or away from the camera.

**Messy hair**: the player's hair gets messier as she loses health (see the GDD). Rather than a messy copy of every sheet, one overlay sheet holds flyaway tufts that are drawn over whatever animation is playing.

**Chickens**

| Animation | Directions | Frames | Needed by |
|---|---|---|---|
| Idle and peck | 4 | 3 | M2 style test |
| Walk | 4 | 4 | M2 style test |
| Chase (fast walk, wings out) | 4 | 4 | M4, done |
| Eat snack | 1 | 3 | M4, done |
| Flight hop | 4 | 4 | M3 risk prototypes |
| Egg shot (wind-up and fire) | 4 | 3 | M3 |
| Feather poof | 1 | 6 | M3 |
| Totem stack and topple | 1 | 6 each | M3 |

## Environment

- **Tiles**: 16x16, designed to repeat seamlessly. Each area gets a small set: floor variants, wall top, wall face, corners, and transitions.
- **Area color identity**:

| Area | Dominant colors |
|---|---|
| Arrivals / Baggage Claim | Clean whites and grays, blue signage, brown carousel belts |
| Security | Cold grays, scanner blues, black-and-yellow hazard edges |
| Food Court | Warm yellows and oranges, restaurant color accents |
| Gate Areas | Teal carpet, orange departure boards |
| Final Departure Gate | Dark blues, night windows, supernatural teal glow |

- **The takeover gets worse as you go**: more nests, feathers, pecked signs, and chicken graffiti in later areas.

## UI

- Same palette and pixel rules as the game; no smooth or anti-aliased UI.
- Menus use a **departure-board** style: dark panels, orange or yellow text, flicker effects.
- Health is shown as **luggage icons**: full, damaged (strapped with tape), and empty (outline only).
- **Font**: a free-licensed pixel font (for example *m5x7* or another open pixel font), checked for commercial use before shipping, about 7-8 px tall for body text.

---

## How Sprites Get Made

1. **Draft**: Claude writes each sprite as a grid of palette keys in Python files under `tools/sprites/` (`palette.py`, `player.py`, `chicken.py`). Walk cycles and other animations are built from the base poses in code.
2. **Build**: `tools/sprites/build.py` turns the grids into PNG sprite sheets in `game/assets/sprites/`. Source and output are both committed.
3. **Check**: Claude renders enlarged previews and animated GIFs to review at 1x and 4x.
4. **Review**: You see the previews or play the build and give feedback.
5. **Touch-ups and final art**: You can open any PNG in Aseprite or LibreSprite and paint over it. Once a sheet is edited by hand, the PNG becomes its source: remove it from `build.py`'s `SHEETS` list so a rebuild doesn't overwrite your work.

### Building the Sheets
Needs Python 3 and Pillow (`pip install -r tools/sprites/requirements.txt`). From the repo root:

```bash
python3 tools/sprites/build.py --preview /tmp/sprite-previews
```

`--preview` is optional; it writes enlarged frame grids and an animated walk GIF to the folder you name.

The same run writes the game icon, `game/icon.png`: the side-view chicken wearing the red rage mushroom cap, scaled up to 512x512 with nearest-neighbor so the pixels stay sharp. `project.godot` points `config/icon` at it, so it shows in the window, taskbar, and dock.

### Sheet Layout
- One PNG per animation: `<thing>_<animation>.png`, for example `player_walk.png`, `chicken_walk.png`, `tiles_arrivals.png`
- **Rows** are directions in this order: down, up, right, left
- **Columns** are frames, read left to right
- Frames sit on a regular grid with no padding: 16x32 for the player (32x32 for her run), 16x16 for chickens
- Keep this layout when redrawing a sheet so it drops into the game unchanged

### Current Sheets
| Sheet | Frame size | Frames | Notes |
|---|---|---|---|
| `player_walk.png` | 16x32 | 4 per direction | Converted from the reference walk sheet: contact, passing, contact, passing, with her head centered in the frame and her feet on the second-to-last row. Left-facing frames are their own drawings, not mirrors. |
| `player_walk_extinguisher.png`, `player_idle_extinguisher.png` | 16x32 | Same as walk and idle | The same cycles with a small extinguisher hanging from the lowest hand (her left from the front and back, the near one from the side), found in every frame so it swings with the arm |
| `player_idle.png` | 16x32 | 2 per direction | Converted from the reference idle sheet: a slight breathing shift between the two frames. Play slowly (about 2 FPS). The first frame of each direction is the base for the action poses. |
| `player_run.png`, `player_run_extinguisher.png` | 32x32 | 6 per direction | Converted from the reference run sheet, in square frames because the widest stride is 32 px: push-off, flight and landing on each leg, head centered in the frame. Play at 14 FPS. |
| `player_hair_mess.png` | 24x20 | 3 per direction (one per mess level) | Flyaway hair drawn over the player: a cowlick (below 75% health), puffed-out tufts (below 50%), wild frizz with a lock over the face (below 25%). Each frame covers the player frame's top 16 rows plus a 4 px margin above and to each side. The game lines it up with the top of the head in each animation frame, and centers it on the wider run frames, so new sheets keep working as long as the head is the topmost thing drawn. |
| `player_throw.png` | 16x32 | 3 per direction | Wind-up (arm raised high beside the head; pulled back in profile), release (fist toward the camera, or arm flung forward in profile, body a pixel lower), follow-through (hand swung low). Throws snacks and suitcases; plays at 10 FPS. |
| `player_eat.png` | 16x32 | 3, in one row (facing the camera only) | Bite with the bag at her mouth, chew with happy closed eyes, yum with a crumb falling. Plays at 7 FPS. |
| `player_hurt.png` | 16x32 | 1 per direction | A flinch: arms flung up, eyes squeezed shut, mouth open. Shown for a moment after a hit, blinking. |
| `player_defeat.png` | 32x32 | 4, in one row | Flinch, knees buckle, falling back (lying 4px off the floor), flat with dust puffs. Plays once at 8 FPS, then `player_ko.png` takes over; the lying frames line up with it. |
| `player_ko.png` | 32x20 | 2, in one row (not per direction) | Game over: flat on their back, head to the left, X eyes, with stars circling above the head. Loop slowly (about 3 FPS). Drawn centered over the spot the player fell. |
| `chicken_walk.png` | 16x16 | 4 per direction | Head bobs forward on side-view contact frames; front and back views waddle. |
| `chicken_idle.png` | 16x16 | 3 per direction | Stand, dip, peck. Hold the first frame and play the peck now and then. |
| `chicken_chase.png` | 16x16 | 4 per direction | The walk's poses with the wings flapping: up on contact frames (lifted off the back in profile, raised out from the shoulders front and back), flicked down on passing frames. In profile the beak opens in a squawk on the up-strokes. Front and back keep the body centered so both wings fit. Plays at 12 FPS while chasing. |
| `chicken_eat.png` | 16x16 | 3, in one row (facing the camera only) | Peck at the snack on the floor, head up with a chip in its beak, chomp with crumbs flying. Loops at 6 FPS while eating a snack or a mushroom; the snack itself is drawn by the game, not in these frames. |
| `chicken_flight_walk.png` | 16x16 | 4 per direction | Teal glowcap, glowing wings, drifting sparkles |
| `chicken_rage_walk.png` | 16x16 | 4 per direction | Red spotted cap, flickering flames behind the body |
| `chicken_egg_walk.png` | 16x16 | 4 per direction | Purple spotted cap and a loaded throat: a pink pouch from the front, pink cheeks from behind, a bulge in profile |

Powered chickens skip the side-view body bob so their caps fit inside the 16x16 frame. The cap is drawn in code over the comb, so any new chicken animation gets caps automatically.

### Tilesets and Objects
Sheets that aren't animations use their own layouts.

**`tiles_arrivals.png`**: 16x16 tiles, 8 per row, read left to right then top to bottom. Atlas coordinates are (column, row).

| Atlas | Tile | Use |
|---|---|---|
| (0,0) (1,0) | `carpet_a`, `carpet_b` | Gray speckled carpet; mix both to hide repetition |
| (2,0) (3,0) | `tile_a`, `tile_b` | Light terminal floor tile with grout lines |
| (4,0) (5,0) | `wood_a`, `wood_b` | Honey wood planks |
| (6,0) (7,0) (0,1) | `carpet_shadow`, `tile_shadow`, `wood_shadow` | First floor row under a wall; top rows darkened by the wall's shadow |
| (1,1) | `wall_top` | Top of a wall, seen from above |
| (2,1) | `wall_lip` | Front edge of the wall top, directly above the face |
| (3,1) | `wall_face_upper` | Upper wall panel with the blue accent stripe |
| (4,1) | `wall_face_lower` | Lower wall panel with the baseboard |
| (5,1) (6,1) | `wall_edge_right`, `wall_edge_left` | Side walls; the outline faces the room |
| (7,1) | `wall_edge_bottom` | Bottom wall; the outline faces the room above |
| (0,2) (1,2) | `carpet_pattern_a`, `carpet_pattern_b` | Classic patterned airport carpet: slate diamonds on a dark ground, blue or orange centers. Mix both; the diamond lattice stays continuous across them |
| (2,2) | `carpet_pattern_shadow` | First patterned-carpet row under a wall |

A north wall stacks four tiles from top to bottom: `wall_top`, `wall_lip`, `wall_face_upper`, `wall_face_lower`, then a shadow floor tile.

**`mushroom_patch.png`**: 16x16 frames. Rows are varieties (flight, rage, egg shooter); columns are 3 frames (resting, spores rising, spores drifting higher). Loop slowly, about 3 FPS.

**`mushroom_sprout.png`**: 16x16 frames, the buds a patch spreads (see the GDD's Spreading Mushrooms). Rows are varieties, like `mushroom_patch.png`; columns are 2 frames: a fresh bud, then a bigger one with a second nub, shown for the sprout's second half. No spores, since a sprout isn't ripe. Same baseline as a patch, so a sprout that ripens swaps to the patch sheet without moving. The game wobbles it for its last 2 seconds.

**`item_snack.png`**: one 10x12 bag of chips, used for pickups, thrown snacks, and the HUD.

**`hud_luggage.png`**: two 12x10 health icons side by side: full, then empty.

**`egg.png`**: two 10x7 frames side by side: an egg in flight, then its splat.

**`luggage_cart.png`**: two 24x20 frames of a baggage cart facing right (wheels turning). Flip it for left.

**`suitcase.png`**: two 14x16 frames of a rolling suitcase standing upright, handle up: closed, then burst open with clothes flying out. The player carries the closed frame overhead.

**`gate_door.png`**: four 48x32 frames of the boarding gate (closed, opening, mostly open, open). It sits on the wall face, 3 tiles wide and covering both face rows, with its sign in the top 10 rows.

**`item_extinguisher.png`**: one 8x12 fire extinguisher for the HUD.

**`extinguisher_cabinet.png`**: two 16x20 frames of the red emergency cabinet that hangs on the wall face: full, then empty.

**`ice_block.png`**: one 18x20 see-through block of ice drawn over a frozen chicken, a pixel wider than the chicken's frame on each side and two taller so the whole bird sits inside: a pale top face, a cyan front face the chicken shows through (partly transparent pixels), two shine streaks, a hard blue rim and frost crusted along the base. The solid block is the shape cue, so freezing reads without relying on color.

**`chicken_frozen.png`**: a frozen chicken, one 16x16 frame per direction (rows down, up, right, left): the chase cycle's wings-up squawk, stuck. Feathers go pale frosted blue with a deep-blue outline, the comb a cold purple, the beak and feet drained pale, and rime sits on every upward-facing edge. Frozen chickens switch to it instead of being tinted.

**`closet_door.png`**: two 16x30 frames of the supply closet door on the wall face: closed, then open with a mop inside.

**`roost.png`**: one 24x14 straw nest with a lost luggage tag and a feather, drawn flat on the floor. Totems themselves are built in code from `chicken_idle.png` frames stacked 10 px apart, with a `chicken_rage_walk.png` frame (the red spotted cap) on top.

**`feather_poof.png`**: six 24x24 frames of a defeated chicken bursting into feathers. Play once at 12 FPS.

**`effects_particles.png`**: 8x8 particle frames, made by `tools/sprites/effects.py`. One row per kind, 4 columns. The particle's position is the center of its frame. Particles have no outline, so they read as effects rather than pickups. "Life" rows play their 4 columns over the particle's life; "variant" rows hold 4 different bits and the game picks one at random.

| Row | Kind | Columns | Used for |
|---|---|---|---|
| 0 | `dust` | Life: puff swells, breaks up, specks | Running footsteps, hop landings, cart slams, vent drops; a fast ring of it for stomps and topples |
| 1 | `feather` | Variants | Pecks, vent drops |
| 2 | `crumb` | Variants | Amanda or a chicken eating a snack |
| 3 | `foam` | Life: puddle shrinking away | Left on the floor after a spray |
| 4 | `egg` | Variants: shell and yolk bits | Egg splats |
| 5 | `spark` | Life: star cooling and shrinking | Cart slams |
| 6 | `sparkle` | Life: dot, cross, big cross, cross | Pickups, unlocked doors, vending payouts, checkpoints |
| 7 | `confetti` | Variants: blue, red, green, yellow | Checkpoints |

Dust is mid-gray `#8b9bb4` with white highlights so it shows on both light tile and dark carpet. Add new kinds as new rows at the bottom.

**`departure_board.png`**: four 64x28 frames of the flight information display that hangs on the wall face. A "DEPARTURES" title over three flights; the destinations stay put while the statuses flip and flicker like a split-flap board. Loop at about 3 FPS. Text uses a 3x5 pixel font (in `tools/sprites/set_dressing.py`) with yellow titles, orange destinations, and red for cancellations.

**`departure_board_security.png`**, **`departure_board_food_court.png`**, **`departure_board_gates.png`**, **`departure_board_final.png`**: the same 64x28 board, 4 frames, with each area's flights (listed in `AREA_FLIGHTS` in `tools/sprites/set_dressing.py`).

**`window.png`**: three 32x24 frames of a window on the wall face, looking out at the tarmac: plain tarmac with the control tower, a parked plane's nose, then the same plane's tail. Hang the nose and tail windows 40 px apart (left edge to left edge) and the plane lines up across them. The bottom 3 rows are the sill.

**`potted_plant.png`**: two 16x24 floor planters side by side: a leafy ficus in terracotta, then a snake plant in a chrome planter. They stand on the floor and block movement, with the pot's base (about 12x6) as the solid part.

**`welcome_banner.png`**: one 48x18 banner hanging from a rod on the wall face: "WELCOME TO BAWKSTON!" The city name is **Proposed**, not final.

**`item_maintenance_key.png`**: one 12x8 brass key, for the pickup and the HUD's key-item row. Key item pickups twinkle in code.

**`security_door.png`**: four 48x32 frames of the locked door to Security (locked with barrier tape and a red light, unlocked with a green light, opening, open). It sits on the wall face like the boarding gate, with the same doorway.

**`signs.png`**: 64x11 wayfinding signs for the wall face, one per frame: BAGGAGE CLAIM (down arrow), SECURITY (left arrow), STAFF ONLY (white on red), ARRIVALS (right arrow), LOST+FOUND, RESTROOMS (left arrow), FOOD COURT (right arrow), SCREENING (white on blue). The 3x5 font has every letter but Q, and every digit. Add new signs as new frames at the end.

**`maintenance_cart.png`**: one 24x24 janitor's cart (mop bucket, spray bottles, trash bag). A solid floor prop; its base is about 22x6.

**`seating.png`**: one 48x24 row of three airport seats facing the viewer. A solid floor prop; its base is about 44x8.

**`floor_litter.png`**: four 16x16 floor decals: feathers, a pecked bag of chips, a cracked egg, chicken footprints. Drawn flat under everything, no collision.

**`map_stand.png`**: three 16x28 frames of the "YOU ARE HERE" airport map on a post that marks a checkpoint: switched off, then lit with a tiny floor plan whose red dot blinks (alternate frames 1 and 2 at about 2 FPS). A solid floor prop; its base is about 8x4.

**`carousel.png`**: modular baggage carousel, 16x16 tiles. Rows are pieces; columns are 4 animation frames of the belt moving clockwise (play at about 8 FPS so the slats creep along).

| Row | Piece |
|---|---|
| 0-2 | `top_left`, `top`, `top_right` |
| 3-5 | `left`, `island`, `right` |
| 6-8 | `bottom_left`, `bottom`, `bottom_right` |
| 9 | `chute`: a `top` piece with the baggage chute opening and rubber flaps |

Build any size of carousel (at least 2x2 tiles) as a rectangle: corners at the corners, `top` and `bottom` along the long edges, `left` and `right` along the short edges, and `island` filling the middle. The bottom pieces include the front skirt, so the carousel looks raised off the floor. Draw the carousel on a tile layer above the floor, since the outside of each corner is transparent.

### Security (Level 2)
Made by `tools/sprites/security.py`.

**`tiles_security.png`**: the same layout and tile names as `tiles_arrivals.png`, so text maps work unchanged, in Security's colors: `carpet` is slate rubber matting with ribs (the queue), `tile` is cool gray tile, `wood` is black-and-yellow hazard striping (scanner lanes), `carpet_pattern` is dark tread with blue and white studs (screening). Wall faces are steel gray with a scanner-blue line and a hazard-striped baseboard.

**`stanchion.png`**: one 48x16 run of three chrome queue posts joined by a sagging blue belt. A solid floor prop; its base is about 48x4.

**`xray_machine.png`**: one 24x48 baggage X-ray machine beside a lane, its belt running away from the camera: a long top with a monitor, the front face with the lead-curtain tunnel, rollers and a hazard edge at the floor. Its footprint (about 22x34) is solid.

**`metal_detector.png`**: two 32x34 frames of a walk-through arch: idle (green light, blue sensor lights), then beeping (red). Only the feet of its two posts are solid; walking between them beeps.

**`bin_table.png`**: one 48x20 roller table with three gray screening bins (a shoe, a red jacket, empty). A solid floor prop; its legs are about 46x6.

**`item_boarding_pass.png`**: one 12x8 boarding pass with a blue header, a barcode and a stub, for the pickup and the HUD's key-item row.

**`security_shutter.png`**: four 32x32 frames of a steel grille rolling down out of its ceiling housing, from rolled up to closed with a hazard-striped bottom bar. Placed with its bottom edge on the floor line across a 2-tile passage.

**`shutter_switch.png`**: two 10x14 frames of the wall box with a big lever: up with a green light (shutter open), down with a red light (closed).

**`stall_door.png`**: two 16x30 frames of a restroom stall door on the wall face, like `closet_door.png`: closed with a green "vacant" slider, then open onto the toilet.

**`pass_gate.png`**: four 48x32 frames of the boarding-pass gate set into the back wall, laid out like `security_door.png`: a FOOD COURT sign over glass paddle gates and a pass reader (locked with a red light, unlocked green, paddles folding back, open). The corridor beyond is warm wood, a hint of the Food Court.

**`security_litter.png`**: four 16x16 floor decals: a spilled screening bin, a lost shoe, a pecked-through belt, a confiscated water bottle.

### Food Court (Level 3)
Made by `tools/sprites/foodcourt.py`.

**`tiles_food_court.png`**: the same layout and tile names as `tiles_arrivals.png`, in warm colors: `tile` is a cream and butterscotch checker floor (8px squares), `carpet` rust carpet (along the restaurant fronts), `wood` the honey planks of the seating plaza, `carpet_pattern` red diner carpet with a yellow dot lattice (seating areas). Walls are cream plaster with an orange stripe over terracotta tiles; wall tops are dark brown.

**`restaurant_fronts.png`**: 64x32 restaurant fronts for the wall face, one per frame: CLUCK SHACK (red), PIZZA PLANE (green), NOODLE GATE (charcoal and orange), JAVA JET (brown). Each has a lit name sign, a striped awning, a dark kitchen window with menu boards, and a counter along the bottom. Add new restaurants as frames at the end.

**`food_table.png`**: one 32x24 round orange table with a chair on each side and a tray of fries. A solid floor prop; its base is about 26x6.

**`vending_machine.png`**: two 20x30 frames of a blue snack machine: stocked with colorful bags, then broken open and empty. A solid floor prop; its base is about 18x6.

**`trash_bin.png`**: one 12x16 overflowing trash bin. A solid floor prop.

**`food_litter.png`**: four 16x16 floor decals: spilled fries, a soda puddle with its cup, a dropped tray, a burger wrapper.

**`gates_door.png`**: four 48x32 frames of the door to the gates, laid out like `security_door.png` (closed, closed, opening, open): the boarding gate's glass doors under an ALL GATES sign.

### Gate Areas (Level 4)
Made by `tools/sprites/gates.py`. The palette key `t` is the gate teal `#193c3e`.

**`tiles_gates.png`**: the same layout and tile names as `tiles_arrivals.png`: `carpet` is dark teal carpet, `carpet_pattern` the lounges' teal grid carpet with orange dots, `tile` and `wood` as in Arrivals. Walls are pale gray with an orange departure-board stripe and a teal baseboard.

**`walkway.png`**: moving-walkway pieces, 16x16. Rows: top-left end, top middle, top-right end, bottom-left end, bottom middle, bottom-right end. Columns: 4 frames of the belt (dark rubber, light slats 8 px apart) creeping 2 px east per frame; the game plays them backward for a westbound walkway and faster at higher speeds. The ends are steel comb plates with a hazard stripe and only use column 0. The top row carries the far handrail along its top edge, the bottom row the near handrail along its bottom edge. The walkway draws itself from this sheet, two tiles tall and any number long.

**`speed_panel.png`**: three 12x14 frames of the walkway control box on the wall: the dial and light at slow (green), normal (yellow) and full (red).

**`gate_desk.png`**: one 32x24 gate agent's podium with a monitor and a boarding-pass printer. A solid floor prop; its base is about 28x6.

**`gate_doors.png`**: six closed 48x32 boarding gates for the wall face, one per frame: GATE A1, A2, B4, B5, C8, C9, drawn like `gate_door.png` with a red "closed" light.

**`final_gate_door.png`**: four 48x32 frames of the door to GATE C13, laid out like `security_door.png` (closed, closed, opening, open).

**`gates_litter.png`**: four 16x16 floor decals: a nest with an egg, scattered boarding passes, a pecked neck pillow, a spilled coffee.

### Opening Cutscene
Made by `tools/sprites/opening.py`. The scene (`game/scenes/cutscenes/opening.tscn`) also reuses the player and chicken sheets, `seating.png`, `potted_plant.png`, `suitcase.png`, `item_snack.png`, `floor_litter.png`, and `tiles_arrivals.png` for the floor. The departure board and the PA panel are drawn by the game in the menus' departure-board style, not from a sheet.

**`opening_backdrop.png`**: one 320x96 back wall of the gate lounge: wall top and lip, white panels with the blue stripe and baseboard (matching `tiles_arrivals.png`), a big three-pane window, a small "A3" gate sign, and the two hangers for the departure board. The window glass (x 11-172, y 15-71) is transparent; the view outside shows through from behind. Keep the glass and the board's spot (x 184-312, y 12-72) where they are, since the game lines things up with them.

**`opening_tarmac.png`**: one 162x57 view through the window, the size of the glass: sky and clouds, the control tower and a hangar on the horizon, a parked plane, and the tarmac with taxi lines, plus glints on the glass. The game draws the chickens outside between this and the backdrop.

**`opening_boarding_pass.png`**: two 96x48 frames of Amanda's boarding pass, shown as a close-up: as printed (name, destination HOME, gate A3, seat 13C, flight PP404, a barcode stub, and a chicken footprint), then with a red double-ruled EXPIRED stamp across it.

### Final Departure Gate (Level 5)
Made by `tools/sprites/final.py`.

**`tiles_final.png`**: the same layout and tile names as `tiles_arrivals.png`, at night: `carpet` is deep blue night carpet, `tile` dark slate tile, `carpet_pattern` the boarding area's navy carpet with teal-glowing diamonds, `wood` the jet bridge's ribbed floor. Walls are navy with a glowing teal line (the reserved `#2ce8f5`, allowed here because the boarding area is the chickens' seat of power).

**`night_window.png`**: three 32x24 night windows for the wall face: stars over the tarmac with runway lights, then the last plane's lit nose and tail (hang them 40 px apart, like `window.png`).

**`boss_crown.png`**: two 24x20 frames of the Supreme Totem's crown, a giant glowing teal mushroom cap with pale spots and a halo of spores that pulses between frames. The game draws it on top of the stack.

**`vent.png`**: two 16x12 frames of a wall vent: shut, then the grille knocked open with a feather drifting out as a chicken drops.

**`boarding_door.png`**: four 48x32 frames of Gate C13's BOARDING door, laid out like `security_door.png`: sealed (red light, teal-and-black barrier tape), unlocked, opening, open onto the jet bridge.

**`plane_door.png`**: four 48x32 frames of the airplane's door at the end of the jet bridge: the white fuselage with a blue stripe around a door that swings open onto the warm cabin.

**`final_litter.png`**: four 16x16 floor decals: glowing spore dust, a crushed mushroom, a huge feather, a dropped LAST CALL sign.

### Ending
Made by `tools/sprites/ending.py`.

**`ending_sky.png`**: one 320x180 night backdrop: stars, the moon, the dark terminal and control tower on the horizon, the tarmac with runway lights. Light dithering in the sky.

**`plane_side.png`**: two 128x40 frames of the last plane side on, facing right: wheels down, then wheels up with the engine glowing.

**`stowaway.png`**: three 16x16 frames of a cabin window: empty, a chicken's head popping up, then the chicken winking with a glowing teal eye. Shown scaled up 6x as a deliberate close-up.

**`passenger_window.png`**: two 16x16 frames of the next cabin window along: Amanda in profile facing the front of the plane, a blue headrest behind her pink hair, then the same with her eyes shut (a blink). Shown beside `stowaway.png` at the same 6x, so she sits one window ahead of the chicken, none the wiser.

### Secrets and Easter Eggs
Made by `tools/sprites/easter_eggs.py` (see the Secrets section of the GDD). The secret rooms themselves are painted from each level's own tileset; these are the extras. Keep these layouts and names as they are: the game picks rows and frames by number.

**`secret_doors.png`**: 16x32 hidden entrances for the wall face (placed like a closet door), 2 columns (closed, open) and one row per kind: 0 a cracked wall panel with feathers poking out (Arrivals), 1 a slate staff door with its red STAFF ONLY sign hanging crooked (Security), 2 a steel freezer panel with frost creeping out (Food Court), 3 a green emergency exit under a lit EXIT sign, a feather wedged in it (Gates), 4 a vent low on the wall with its grille pecked through (Final Gate). The tell is always visible when closed.

**`mural.png`**: five 80x28 frames, the chickens' paintings on each secret room's back wall. Each panel is numbered with claw tallies (I to IIIII) so the story reads in order, and the figures are drawn like the game's own sprites (outlined white chickens with red combs, blue-tailed planes) so they read at a glance: two chickens behind a farm fence beside a barn, one dreaming of a plane in a thought bubble while a plane flies off; fuel drums leaking a glowing puddle by a country runway, teal mushrooms sprouting from it; one chicken pecking a teal mushroom, its eye glowing, waves of glow rolling out to a flock with glowing eyes; the control tower with a chicken in every window and the chickens' flag on top, chickens planting mushrooms in the airport carpet; a chicken in a captain's hat walking up the stairs to a parked plane's open door.

**`tiles_freezer.png`**: the Cluck Shack's walk-in freezer (the Food Court's secret room), laid out exactly like `tiles_arrivals.png` so the room's text map works unchanged: every floor is frosted steel diamond plate, the walls are insulated white panels with frost and icicles over a riveted kick plate. The room uses it through its `tiles_texture` instead of the level's.

**`freezer_shelf.png`**: one 32x32 wire rack of iced-over frozen food (nugget boxes, a bag of peas, ice-cream tubs, snowflake boxes), icicles under the shelves. A solid floor prop.

**`freezer_decor.png`**: three 16x16 frames: 0 a wall thermometer with its needle deep in the blue, 1 and 2 frost patches for the floor.

**`pilot_cap.png`**: three 16x16 frames of the hidden Pilot Cap patch, laid out like one row of `mushroom_patch.png` (resting, spores, spores higher): pale-yellow caps with white spots and a little white propeller frill on top that turns between frames.

**`secret_stashes.png`**: 16x16, 2 columns (full, searched) and one row per kind: 0 a gray security bin with a red CONFISCATED band (searched: a rubber chicken, a tiny hat and an egg), 1 a straw nest heaped with stolen snack bags (searched: crumbs), 2 Amanda's own pink suitcase with a big white tag (searched: burst open).

**`suitcase_fragile.png`**: laid out like `suitcase.png` (two 14x16 frames, lying and burst): red FRAGILE stickers on the lying one; the burst one spills snack bags instead of clothes.

**`posters.png`**: four 40x32 frames: DO NOT EAT THE CARPET MUSHROOMS (white, red ink), THIS PLANTER IS NOT A FARM (yellow), BAWK WAS HERE scratched into the wall (no paper, mostly transparent), and the Cluck Shack's SECRET RECIPE card ("1. RUN.").

**`fuel_drum.png`**: two 16x24 frames of a rusty red fuel drum with a hazard band, leaking a glowing teal drip into a puddle that pulses. A floor prop (Arrivals' staff room), also seen outside the window in the opening.

**`captain_hat.png`**: one 16x16 captain's hat (navy, gold badge, white band, black peak) hanging on a wall peg.

**`captain_chicken.png`**: two 16x16 idle frames of a normal chicken wearing a pilot's cap, built from the chicken's front-facing idle frames.

**`stowaway_captain.png`**: laid out like `stowaway.png`, with the chicken wearing the captain's hat. The ending uses it when every secret was found.

**`departure_board_gates_b.png`**: Gate B's board, laid out like the other boards: HOME (DLAY / 4EVR), RUNWAY 2 (MUSH / ROOM), GATE C13 (LAST CALL).

### Import Settings (Godot)
- Texture filter: Nearest
- No mipmaps

---

## Style Test Checklist (M2)

- [x] Palette confirmed (ENDESGA 32)
- [x] Player: idle and walk, 4 directions
- [x] Normal chicken: idle and walk, plus all three powered modes
- [x] Arrivals floor and wall tiles
- [x] Baggage carousel
- [x] Mock screenshot at 320x180, viewed at 4x (`build.py --preview` writes `mock_arrivals_4x.png`)
- [x] Your sign-off, and any changes to this guide recorded (2026-10-19)
