# Plane Poultry Panic: Art Style Guide

The rules every piece of in-game art follows. Consistency is what makes pixel art look professional, so when a new sprite breaks one of these rules, either the sprite changes or the rule changes here first.

**Status**: Draft. The palette and examples get locked in the M2 style test ([roadmap.md](roadmap.md)).

---

## Who Makes the Art

- **First pass (now)**: Claude makes all in-game pixel art (characters, chickens, tiles, objects, effects, UI) so the game can be built and playtested with real-looking art.
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
| Player | 16x32 frame |
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
| Purples and pinks (the player's hair, spore effects) | `#68386c` `#b55088` `#f6757a` |
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
- Based on the creator's reference photos: shoulder-length pink hair, a heather-gray tee with a mushroom print, a blue backpack, black leggings, black boots, and tattooed forearms.
- The pink hair (`#b55088` family) and blue backpack (`#124e89` family) are the player's signature colors. They make the player stand out against the gray terminal and the white chickens, so no other character or prop should use that pairing.
- At 16x32, details are hinted, not drawn: tattoos are a few ink pixels on each forearm, and the shirt print is a small mushroom shape.

### Normal Chickens
- Classic white farm hen: white body shaded with `#ead4aa`, red comb, yellow-orange beak and legs.
- Slightly dopey expression. They should look funny first and threatening second.

### Powered Chickens
Every powered state has a color cue **and** a shape or animation cue, so it still reads for colorblind players.

| Mode | Color cue | Shape / animation cue |
|---|---|---|
| Flight | Teal glowing mushroom cap, `#2ce8f5` glow on wings | Wings spread, hovering bob, particle trail |
| Rage | Red-and-white spotted mushroom cap, flames (`#f77622`, `#feae34`) | Puffed-up feathers, faster walk cycle, flickering flames |
| Egg Shooter | Yellow mushroom cap (`#feae34`) | Bulging throat, wind-up squash before each shot |

### Totems
Stacked chickens with a visible wobble. The bottom chicken looks strained, the top one looks smug. The final boss totem is taller and crowned with a giant glowing mushroom.

### Mushroom Patches
Clusters of 3-5 mushrooms growing out of carpet, planters, and spilled food. Each patch is one variety, colored to match the cap its chickens wear: teal glowcaps (flight), red spotted caps (rage), yellow caps (egg shooter). Patches glow softly and puff spores so they're easy to spot from across a room.

## Animation

| Animation | Frames | Speed |
|---|---|---|
| Idle | 2-4 | 4-6 FPS |
| Walk | 4 | 8-10 FPS |
| Run | 4-6 | 12 FPS |
| Chicken peck | 3-4 | 8 FPS |
| Hit / damage | 2 + blink | Fast |
| Feather poof (defeat) | 5-6 | 12 FPS |

- Favor **squash and stretch** and exaggerated poses. A few frames done well beat many stiff ones.
- Every attack has a **wind-up frame** so the player has a chance to react.

### Animation Sets

Left-facing frames are mirrored from right-facing ones, so each character only needs 3 drawn directions (down, up, right).

**Player**

| Animation | Directions | Frames | Needed by |
|---|---|---|---|
| Idle | 4 | 2 | M2 style test |
| Walk | 4 | 4 | M2 style test |
| Run | 4 | 4 (longer stride, forward lean, hair and backpack bounce) | M4 vertical slice |
| Throw | 4 | 3 | M4 |
| Eat | 1 (facing down) | 3 | M4 |
| Hurt | 4 | 1, plus blinking | M4 |
| Defeat | 1 | 4 | M4 |

Until the run cycle exists, running plays the walk cycle faster with small dust puffs at the player's heels. Running is a core mechanic tied to stamina, so it gets its own cycle before the vertical slice. That way players can see at a glance when they're spending stamina.

**Chickens**

| Animation | Directions | Frames | Needed by |
|---|---|---|---|
| Idle and peck | 4 | 3 | M2 style test |
| Walk | 4 | 4 | M2 style test |
| Chase (fast walk, wings out) | 4 | 4 | M4 |
| Eat snack | 1 | 3 | M4 |
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

1. **Draft**: Claude writes each sprite as a grid of palette colors in a source file under `game/assets/sprites/src/`.
2. **Build**: A script turns the sources into PNG sprite sheets in `game/assets/sprites/`. Source and output are both committed.
3. **Check**: Claude renders sheets and in-game screenshots to review them at 1x and 4x.
4. **Review**: You see screenshots or play the build and give feedback.
5. **Touch-ups**: You can open any PNG in Aseprite or LibreSprite and paint over it. Edited PNGs are then treated as the source.

### Import Settings (Godot)
- Texture filter: Nearest
- No mipmaps
- Sprite sheets on a regular grid with no padding, frames read left to right

### Naming
`<thing>_<state>_<direction>.png`, for example `chicken_walk_down.png`, `player_idle_left.png`, `tiles_arrivals.png`.

---

## Style Test Checklist (M2)

- [ ] Palette confirmed or swapped
- [ ] Player: idle and walk, 4 directions
- [ ] Normal chicken: idle and walk, plus one powered mode as a color and shape test
- [ ] Arrivals floor and wall tiles, one carousel piece
- [ ] Mock screenshot at 320x180, viewed at 4x
- [ ] Your sign-off, and any changes to this guide recorded
