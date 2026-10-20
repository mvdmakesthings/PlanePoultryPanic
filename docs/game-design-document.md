# PLANE POULTRY PANIC
## Game Design Document v1.1

This is the single source of truth for how the game works. Related docs:

- [storyline.md](storyline.md): world, backstory, and tone
- [art-style-guide.md](art-style-guide.md): palette, sprite rules, and how art gets made
- [roadmap.md](roadmap.md): milestones from prototype to Steam launch

Numbers in this doc (speeds, durations, counts) are starting values. The prototype exists to tune them, so treat them as defaults, not promises.

---

## Table of Contents
1. [Game Overview](#game-overview)
2. [Core Loop](#core-loop)
3. [Controls](#controls)
4. [Player](#player)
5. [Items and Inventory](#items-and-inventory)
6. [Chickens](#chickens)
7. [Environment](#environment)
8. [Levels](#levels)
9. [UI and UX](#ui-and-ux)
10. [Progression and Replay](#progression-and-replay)
11. [Art Direction](#art-direction)
12. [Audio Direction](#audio-direction)
13. [Technical Specifications](#technical-specifications)
14. [Release and Business](#release-and-business)
15. [Risks](#risks)
16. [Decision Log](#decision-log)

---

## Game Overview

### Concept
Plane Poultry Panic is a 3/4-view action-adventure game. The player fights through a chicken-overrun airport terminal to catch the last flight to safety during a supernatural poultry apocalypse.

### Target Audience
- **Primary**: Indie game fans aged 16-35
- **Secondary**: Retro fans who love 16-bit games like *Zombies Ate My Neighbors*
- **Tertiary**: Casual players who want a short game they can finish in one sitting

### Platforms
- **Launch**: PC on Steam (Windows, macOS, Linux), Steam Deck verified
- **Later, if the game does well**: itch.io, Epic Games Store, Nintendo Switch

Steam Deck support means full gamepad support from the start, not as a late addition.

### Core Pillars
1. **Absurd Humor**: Apocalyptic stakes caused by ridiculous chickens
2. **Outsmart, Don't Outfight**: The player has no direct attack. Chickens are beaten with distractions, items, and airport machinery.
3. **Retro Charm**: An authentic 16-bit look with modern quality-of-life features
4. **Tight Experience**: A complete, satisfying campaign in about 30 minutes, built for replays

### Key Features
- 8-directional movement with stamina-limited running
- Chicken AI that wanders, chases, gets distracted, and powers up
- Six-slot inventory with dual-use snacks
- Airport machinery used as traps and puzzles
- Chicken totem bosses formed from stacked chickens
- Commissioned chiptune soundtrack
- Four difficulty modes, scoring, and achievements for replay value

---

## Core Loop

**Moment to moment**: Spot chickens, plan a route, sneak or sprint past, throw a snack when cornered, and heal when it's safe.

**Per level**: Find the key item that opens the exit, collect snacks and tools, survive or beat the set-piece encounter, and reach the exit checkpoint.

**Whole game**: Five connected airport areas, about 30 minutes in total. Get the boarding pass in Security and present it at the Final Departure Gate to win.

### Victory
Reach the Final Departure Gate alive, holding the boarding pass, and defeat or escape the final chicken totem to board the plane.

### Failure
When health reaches zero, the player restarts from the last checkpoint with their inventory as it was when they reached it, and full health. A short hint about what went wrong appears on the retry screen (based on what landed the last hit), with Retry from Checkpoint and Main Menu. Pickups already taken and doors already unlocked stay that way; chickens, carts and thrown items start fresh.

---

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move (8 directions) | WASD or arrow keys | Left stick or D-pad |
| Run (uses stamina) | Shift | Right shoulder (RB/R1) |
| Use selected item (throw a snack, spray the extinguisher), or throw a carried suitcase | Space | A / Cross |
| Interact (shove, take, pick up or put down a suitcase, open, hide) | F | B / Circle |
| Eat a snack (quick heal, from any slot) | E | X / Square |
| Previous / next slot | Q / R, or mouse wheel | LB / Y (Triangle) |
| Drop the selected slot | G | Back / Share |
| Pause | Esc | Start / Options |

- All bindings can be remapped in Settings.
- In the prototype, R also restarts, but only on the win or lose screen.
- Thrown items go in the direction the player is facing. Mouse aiming is not planned, so keyboard and gamepad play the same.

---

## Player

### Identity
**Amanda**, a stranded connecting passenger. She starts with a carry-on, a wallet, and an expired boarding pass from her cancelled flight.

### Attributes
| Attribute | Starting value |
|---|---|
| Health | 5 suitcases (luggage icons), each split into quarters |
| Walk speed | 100 px/s |
| Run speed | 150 px/s |
| Stamina | Drains in about 2.5 s of running, refills in about 4 s |
| Exhaustion | Running dry locks running until stamina is back to 30% |
| Inventory | 6 slots |

### Damage
- Chicken pecks cost half a suitcase, so it takes 10 pecks to lose all 5. Environmental hazards cost a whole suitcase. Eggs only sting: a quarter of a suitcase each. A partly lost suitcase is shown as a partly emptied icon.
- After a hit, the player is briefly knocked back and is invincible for 1.5 seconds (the sprite blinks).
- Her hair gets messier as she loses health: a cowlick below 75%, puffed-out tufts below 50%, and wild frizz with a lock over her face below 25%. Healing tidies it again. It shows how hurt she is at a glance, without looking at the HUD.
- A chicken that lands a peck bounces back about two tiles and is dazed for a moment before chasing again, so the player has a chance to run.

### Healing
Eating a snack restores one whole suitcase. E eats from any slot, whichever item is selected; at full health or with no snacks, a short "Full!" or "No snacks" pops up instead. Snacks are the only way to heal, so every snack is a choice between healing now and distracting chickens later.

### Hiding
Bathroom stalls and supply closets are hiding spots. Press Interact at the door to slip inside and again to come out. While hidden, the player can't be hurt and chickens lose track of them. Chickens that were chasing the player when they went in wait outside and peck at the door, which shakes. After about 5 seconds they give up, walk off out of sight along a clear path, and ignore the player for a few more seconds, so hiding is a real way to shake pursuers: once the door stops shaking, it's safe to come out.

---

## Items and Inventory

### Rules
- **6 slots** for usable items. Snacks stack up to 3 per slot, so a full bag is a real decision.
- **Key items** (boarding pass, maintenance keys, airport map) sit in a separate key-item row and never take up slots.
- Items can be dropped to make room.

### Usable Items
| Item | Use | Notes |
|---|---|---|
| Snack | Eat to heal a whole suitcase, or throw as a distraction. A thrown snack nobody has eaten can be picked back up. | Found in the food court, vending machines, and abandoned bags |
| Fire extinguisher | Spray a cone of foam (about 4 tiles long), plus a burst right around the player's feet. The spray swings toward the nearest unfrozen chicken within 4 tiles, whichever way the player faces, so it works mid-chase, and the foam hangs for half a second, catching chickens that run into it. Chickens in it freeze in a block of ice for 4 seconds, and a mushroom patch in it is destroyed for good | 3 charges, then it's empty. Taken from red emergency cabinets on the walls. Frozen chickens can't peck, but the carousel still carries them and carts still flatten them. A frozen chicken is a block of ice: shove it with Interact and it slides further than a cart, flattening any chicken it crashes into. The player is drawn carrying the extinguisher while it has charges. |

More usable items may come out of prototyping, but every new item has to earn its slot. Fewer items that each do a lot fits the game better than many small ones.

### Key Items
| Item | Purpose |
|---|---|
| Boarding pass | Found in the security bins in Level 2. Required to enter the Final Departure Gate. |
| Maintenance key | Opens one locked door, closet, or vending machine, then it's used up. Found on maintenance carts and in staff areas. |
| Airport map | Unlocks a terminal map on the pause screen that shows the current level, exits, and key-item locations. |

---

## Chickens

### How Chickens Are Defeated
The player can't attack directly. A chicken is defeated when it's caught by airport machinery (the baggage carousel's chute, moving walkways at speed, closing security gates), flattened by a luggage cart the player shoves, hit by a suitcase the player throws, or crushed when a totem collapses on top of it. A defeated chicken bursts into a comic puff of feathers, squawks, and is gone. No blood or gore, ever.

Fire extinguisher spray and distractions don't defeat chickens. They control them. That's what keeps the **Pacifist** run possible: get through without defeating a single chicken.

### Normal Chickens
- Wander and peck at the floor, or follow set patrol routes
- Spot the player within sight range when no wall is in the way
- Call nearby chickens when they spot the player
- Give up the chase when they lose sight of the player for a couple of seconds
- Drop everything to go after a thrown snack, then stop to eat it
- Chase slower than the player walks, so a careful player can always escape a single normal chicken

### Powered-Up Chickens
Chickens that eat from a mushroom patch power up for 30-60 seconds, then return to normal. Each patch grows one kind of mushroom, and the kind decides the mode. A powered chicken wears a cap of the mushroom it ate, so the player can read its mode at a glance and can see which power a patch gives before going near it:

| Mode | Behavior | Visual cue |
|---|---|---|
| Flight | Short hops over furniture and low obstacles | Glowing teal mushroom cap, glowing wings, particle trail |
| Rage | Faster than the player's walk, relentless chase | Red spotted mushroom cap, flames, puffed-up pose |
| Egg Shooter | Hangs back at range, winds up, and fires eggs; sees as far as it can shoot | Purple spotted mushroom cap; a loaded throat that shows from every side (pink pouch from the front, bulging cheeks from behind, a bulge in profile); wind-up before each shot |

Chickens head for mushroom patches when they can. Watching a patch and timing a route while the chickens around it are still normal is a core tactic.

### Chicken Totems (Bosses)
- **Formation**: Totems form at designer-placed roosts (straw nests) when 4 chickens settle there. Wandering chickens within about 7 tiles head for a roost; once settled they ignore the player. Placing roosts by hand keeps totems feeling emergent while staying under level-design control.
- **Buildup**: Stacking takes 2 seconds, with the settled chickens hopping and a flashing "!!" over the nest, so an alert player can break it up early with a thrown snack.
- **Abilities**: Lumbers after the player (slower than a walk); a ground stomp around itself after a shaking wind-up with a "!"; 3-egg barrages from range; calling nearby chickens into the chase when it spots the player; and sustained flight. Every 7 seconds or so, or whenever the player is in range behind furniture, it lifts off and flies straight at them for a few seconds, trailing teal sparks. A red zone marks the landing spot 0.7 seconds before it slams down with a stomp; the spot is fixed once marked, so the player can step out of it. In the air it's out of reach of carts and the belt, but spraying it still brings it down.
- **Toppling**: Freeze its base with the extinguisher, ram it with a luggage cart, or lure it onto the carousel belt. It falls away from the hit, flattening any chicken where its members land; its own chickens land dazed along the fall line. Three snacks lying beside it break it apart instead, with no defeats. The roost then rests for 20 seconds.

### AI States
Wander → Patrol → Investigate (snack or noise) → Pursue → Powered → Forming (totem)

Behavior priority, highest first:
1. Already eating or forming a totem: keep doing it
2. Snack nearby: investigate it
3. Player in sight: pursue
4. Mushroom patch reachable: go eat
5. Otherwise: wander or patrol

---

## Environment

### Machinery and Hazards
| Element | Effect |
|---|---|
| Baggage carousel | The belt around the solid center island is walkable and carries anything on it clockwise (chickens, snacks, the player). Chickens carried into the chute are defeated; the player can't fit through it. Chickens never walk into the chute on purpose, so the trick is getting one distracted on the belt, for example eating a snack thrown there. |
| Moving walkway | A two-tile belt between handrails, entered and left only at its ends, that carries the player, chickens and snacks east or west at 20 (slow), 45 (normal) or 110 (full) px/s, so walking with it is faster and against it slower. A speed panel on the wall steps it through the three speeds. At full speed a chicken riding off the far end is flung at 200 px/s and tumbles; hitting anything solid while still going 90 px/s or faster knocks it out (and any chicken it hits). Slower, it lands dazed. The player is never flung. |
| Security scanner and gates | Barriers to route around: X-ray machines and metal-detector arches (which beep as the player walks through) line the scanner lanes. A roll-down shutter closes a lane when its wall switch is flipped; a chicken under it as it slams down is defeated, and chickens path around it while it's shut. |
| Mushroom patch | Powers up chickens that eat there, then regrows after 15 seconds. Spraying it with the fire extinguisher (one charge) kills the patch for good. |

### Interactive Objects
| Element | Effect |
|---|---|
| Luggage cart | Shove it with Interact and it rolls about 4 tiles. A chicken it hits while rolling fast is defeated. Eggs splat against the whole cart, luggage included, so the player can hide behind one. A cart shoved into a wall slides along it instead, so it can never get stuck in a corner. |
| Rolling suitcase | Abandoned luggage lying around the terminal. Pick it up with Interact and the player holds it overhead in both hands, so it doesn't use an inventory slot. While carrying it they walk a little slower, can't run, and can't use, eat, or drop items or hide. Use throws it about 5 tiles the way the player is facing; Interact puts it down. A chicken it hits while it's still moving fast is defeated, and the suitcase bursts open in a shower of clothes and is gone, so each suitcase defeats one chicken at most. A throw that misses lands and can be picked up again. Taking a hit while carrying it drops it at the player's feet. |
| Vending machine | Opened with a maintenance key (used up). Drops 2-3 snacks in front of it. Stays open after a retry if it was opened before the checkpoint. |
| Boarding-pass gate | The way out of Security: glass paddle gates in a doorway that open when the player scans the boarding pass (Interact). The pass is only read, not used up. |
| Boarding gate | A door set into the back wall with a lit gate sign. Its glass doors slide open as the player approaches; walking into the doorway reaches the gate. |
| Emergency exit | Shortcut. Some are blocked, and some lead past extra danger. |
| Bathroom stall, supply closet | Hiding spot (see [Hiding](#hiding)) |
| Gate seating | Blocks egg projectiles |
| Flight information display, PA system | Story, jokes, and hints. The Arrivals departure board lists chicken-punned flights (Henver, Cluckland, Eggseter) whose statuses flicker and flip. |
| Potted plants | Solid floor props. The player, carts, and chickens go around them; chickens path around them like walls. |
| Welcome banner, windows | Set dressing. The banner names the city, "Welcome to Bawkston!" (Proposed); the windows look out on the tarmac and a parked plane. |

---

## Levels

### Structure
Five connected areas played in order, each introducing something new. Each level ends at a checkpoint. Level 4 also has a checkpoint between each gate section.

### Level 1: Arrivals / Baggage Claim (about 5 minutes)
- **Purpose**: Tutorial
- **Layout**: A large central carousel with pickup areas around it
- **Chickens**: Few, all normal
- **Teaches**: Movement, running, snack throwing and eating, interacting, the carousel as a hazard
- **Goal**: Find a maintenance key and unlock the door to Security
- **As built (M4)**: Amanda steps out of Gate 1 into an arrival lounge (walking, picking up snacks), crosses a hallway (running, a first chicken to distract with a snack, a luggage cart to shove), and comes down into Baggage Claim right beside the locked SECURITY door. The key is in a staff room in the far corner, past the big carousel and its chickens; an optional Lost & Found holds extra snacks. Hints at the top of the screen teach each control as she reaches it, plus one-offs the first time she's hurt, tries the locked door, or finds the key. Two map-stand checkpoints: at the bottom of the stairs into Baggage Claim, and in the staff room.

### Level 2: Security Checkpoint (about 5 minutes)
- **Purpose**: First powered chickens and the boarding pass
- **Layout**: Security lines, scanners, and closable gates
- **Chickens**: Medium density, first mushroom patch
- **Teaches**: The fire extinguisher, powered chickens, hiding
- **Goal**: Find the boarding pass in the security bins and reach the Food Court
- **As built (M5)**: Amanda comes in from Arrivals at the bottom of a queue hall with rope lanes. An extinguisher cabinet hangs by the entrance, and a chicken grazes at the first mushroom patch (rage) next to the queue's exit. Up in the scanner hall, three lanes lead north through the security wall, past X-ray machines; the first two have metal-detector arches that beep, the third a roll-down shutter on a wall switch that flattens a chicken caught under it and blocks the lane while shut. A flight patch sits outside the restrooms, whose stalls are hiding spots, and a supply closet is by the queue's exit. Past the scanners, the screening area's bins hold the boarding pass, near an egg-shooter patch. The gate to the Food Court at the end of the east corridor scans the pass (it isn't used up). Map-stand checkpoints in screening and in the corridor; a second extinguisher cabinet in the scanner hall.

### Level 3: Food Court (about 5 minutes)
- **Purpose**: Resource management and the first totem
- **Layout**: Central seating surrounded by restaurant stalls
- **Chickens**: High density, several mushroom patches
- **Teaches**: Totems, vending machines, choosing between stocking up and moving on
- **Goal**: Topple or escape the first totem and reach the gates
- **As built (M5)**: Amanda comes in from Security at the bottom of a big court ringed by four restaurant fronts (Cluck Shack, Pizza Plane, Noodle Gate, Java Jet; names Proposed), with two seating areas, about 16 snacks lying around and 14 chickens. Three vending machines stand near the entrance, but there are only two maintenance keys: one in the staff kitchen behind Pizza Plane, one beside a lost bag on the east side. Mushroom patches: rage by Cluck Shack, flight by Noodle Gate, egg shooter by the east seating. The door to ALL GATES (no key needed) is behind a sunken wooden seating plaza whose roost has four chickens ready to stack into the first totem, with two luggage carts and an extinguisher cabinet nearby. Restroom stalls in the top right are hiding spots. Map-stand checkpoints at the arrival and before the plaza. It shares Security's music.

### Level 4: Gate Areas (about 10 minutes)
- **Purpose**: Peak challenge using everything learned
- **Layout**: Gates A, B, and C in sequence, each harder than the last, with moving walkways between them
- **Chickens**: Very high density, regular totems
- **Goal**: Get through all three gate sections
- **As built (M5)**: Three gate lounges, A, B and C, left to right, each with numbered boarding gates, a departure board, a gate desk, seating rows and an extinguisher cabinet, joined by two corridors. Each corridor has a moving walkway each way and a speed panel; each walkway's far end faces a wall stub, so a chicken flung off at full speed hits it. Gate A: a rage patch and a luggage cart. Gate B: a roost, flight and egg patches, a vending machine, and a south room behind a shutter holding the maintenance key for it. Gate C: two roosts, all three mushroom kinds, a supply closet, suitcases and two carts, and the door to Gate C13 (no key needed). 26 chickens in all. Checkpoints: the level start, and map stands at the entrances to Gates B and C. It plays its own placeholder music.

### Level 5: Final Departure Gate (about 5 minutes)
- **Purpose**: Climax
- **Layout**: One large gate area with a central boss arena
- **Chickens**: Maximum density, the supreme chicken totem
- **Goal**: Present the boarding pass, beat the boss, and run for the plane in a short escape sequence

### Level Design Principles
- Clear sightlines so the player can plan
- At least two routes through most rooms, one safer and one faster
- Risk versus reward: shortcuts, optional loot rooms, mushroom patches worth spraying
- Show the takeover through the environment: nests in luggage, pecked signs, chicken graffiti

---

## UI and UX

### HUD
Kept minimal so the game stays readable at 320x180.
- **Top left**: Health as luggage icons; stamina bar underneath
- **Bottom**: The 6 inventory slots with the selected one highlighted and stack counts; key items shown as small icons next to them
- **Near objects**: Context prompts showing the right button for the current input device (keyboard or gamepad). Buttons are drawn as icons: keycaps for the keyboard; for a gamepad, round A, B, X and Y buttons in their Xbox colors and small pills for the rest. The last device touched decides, so prompts switch the moment the player picks up a controller or touches a key. Tutorial hints and menu footers use the same icons.

### Menus
- **Main menu**: Departure-board style with flickering text over a looping airport scene (Amanda running from chickens across the terminal floor). New Game, Continue, Settings, Credits, Quit. Credits comes later.
- **Pause menu**: Resume, Map (once the map is found), Settings, Quit to Menu
- **Settings**: Controls (remapping), Audio (master, music, effects), Video (fullscreen, window scale), Accessibility. Changes apply immediately, and each category has Reset to Defaults. Built so far: music, effects and ambience volume, fullscreen, and remapping each action's main key and gamepad button (a binding already in use swaps with it).

### Accessibility
- Full remapping for keyboard and gamepad
- Screen shake toggle
- Colorblind-safe chicken states: every powered mode also has a shape or animation cue, never color alone
- Text size option for menus and dialogue

---

## Progression and Replay

### Saving
- The game autosaves at every checkpoint, and when a level starts. There's no manual save, which keeps the tension.
- **Continue** resumes from the latest checkpoint. **New Game** asks before replacing a save.
- Checkpoints are "YOU ARE HERE" map stands that light up when reached. Level 1 has two: where Amanda comes down into Baggage Claim, and in the staff room. Level 2 has two: in the screening area and in the corridor to the Food Court. Level 3 has two: at the arrival and before the totem plaza. Level 4 has one at the entrance to each of Gates B and C (Gate A's is the level start).
- Leaving a level through its exit autosaves at the start of the next one, with the inventory carried over, so Continue resumes there.

### Difficulty Modes
| Mode | Changes |
|---|---|
| Easy | Calmer chickens, more snacks, longer extinguisher freeze |
| Standard | As designed |
| Hard | More chickens, powered modes trigger more often, fewer snacks |
| Expert | Maximum chickens, instant power-ups at mushroom patches, checkpoints only at the start of each level |

### Scoring
A score at the end of the run, made up of:
- **Time**: Faster runs score more
- **Efficiency**: Items used compared to items collected
- **Stealth**: Chickens avoided compared to chickens that spotted you
- **Discovery**: Secrets found and alternate routes taken

### Achievements (Steam)
| Achievement | Condition |
|---|---|
| Speed Runner | Finish in under 25 minutes |
| Pacifist | Finish without defeating any chickens |
| Hoarder | Finish with all 6 slots full |
| Explorer | Find every secret area |
| Perfect Run | Finish without taking damage |
| One per level | Finish each level, to track how far players get |

### Speedrun Mode
An optional on-screen timer with split times per level. Unlocks after finishing the game once.

---

## Art Direction

The full rules live in [art-style-guide.md](art-style-guide.md). In short:

- **Style**: 16-bit SNES era, inspired by *Zombies Ate My Neighbors*
- **View**: 3/4 view: floors seen from above, walls and characters seen from the front
- **Resolution**: 320x180, scaled up by whole numbers (4x at 720p, 6x at 1080p, 4x on Steam Deck)
- **Grid**: 16x16 tiles; player 16x32; chickens 16x16
- **Palette**: One shared 32-color palette for the whole game
- **Who makes it**: Claude makes first-pass pixel art so the game can be built and playtested. After the game is done, the creator redraws every sprite by hand at the same sizes and layouts. Store art is made or commissioned near launch.

---

## Audio Direction

### Music
Commissioned from a chiptune composer. Placeholder music is used until then.

| # | Track | Mood |
|---|---|---|
| 1 | Main theme | Upbeat and adventurous with a comic edge |
| 2 | Arrivals | Driving and tense: the energy of a dystopian, post-apocalyptic airport |
| 3 | Security and Food Court | Mid-tempo, growing urgency |
| 4 | Gate Areas | High energy, survival tension |
| 5 | Boss | Intense, with chicken-themed musical jokes |
| 6 | Victory | Triumphant relief with a travel motif |

Level 2 (Security) has its own placeholder in the same style: a 16-bar D minor loop that holds back for four bars, then brings in the groove and the cluck melody over sixteenth-note hats (`tools/music/security.py`).

Level 4 (Gate Areas) has its own: 132 BPM in A minor with four-on-the-floor kicks, a pumping octave bass and sixteenth hats (`tools/music/gates.py`).

Plus short stings for game over, checkpoint, and item fanfares.

Until the composer's tracks arrive, Level 1 plays a placeholder built from real chicken recordings (two CC0 recordings by JarredGibb on Freesound): a spooky-surf groove in E minor at 112 BPM with cluck percussion and a melody played on a repitched cluck, through an SNES-style output stage (`tools/music/arrivals.py`). The main menu is silent for now.

**Composer brief and timing**: Engage the composer once the vertical slice is playable, so they can hear and see the game. Ask for loopable tracks, stems if affordable, and a license covering the Steam release, trailers, and a possible soundtrack release.

### Sound Effects
Generated in a retro "sfxr" style by Claude, with real chicken recordings (licensed or recorded) mixed in for the clucks.
- **Chickens**: Natural clucks for normal chickens, distorted ones for powered states, layered clucking for totems, comic timing on eggs
- **Airport**: Quiet terminal ambience, distant PA announcements, carousel and walkway machinery
- **Feedback**: Satisfying pickup, throw, hit, and menu sounds

### Mixing
Positional audio for chickens and machinery, separate audio buses for music, effects, and ambience, and music that ducks under important cues.

---

## Technical Specifications

### Engine
**Godot 4.7** (GDScript), currently 4.7.2, the latest stable release. Free, lightweight, strong 2D tools, and exports to Windows, macOS, and Linux. Move to new stable releases (such as 4.8) once they ship and the smoke test passes on them; skip betas.

### Performance Targets
- 60 FPS on Steam Deck and on a dual-core 2.0 GHz PC with integrated graphics
- Under 512 MB of RAM and under 500 MB installed
- **Measured (M4, Level 1)** with `game/tests/level_01_perf.tscn` on an Apple M1: about 1.4 ms a frame in normal play (worst 1% about 6 ms), 1.5 ms with every chicken chasing, 2.4 ms with 46 chickens (worst 1% about 8.5 ms); about 40 MB of memory; 2.9 MB of assets. Still to check on a Steam Deck or a low-end PC.

### Display
- Base resolution 320x180 with the viewport stretched by whole-number multiples only, for crisp pixels
- Nearest-neighbor texture filtering, with 2D transforms snapped to pixels

### Project Layout
The Godot project lives in `game/`:
```
game/
├── project.godot
├── scenes/       characters/, levels/, objects/, ui/
├── scripts/      characters/, levels/, managers/, objects/, ui/
├── assets/       sprites/, audio/, fonts/
└── data/         level and balance configs
```

### Architecture
- **Autoloads (singletons)**: GameManager (game state, checkpoints), AudioManager, SaveSystem, InputSetup (default bindings)
- **Movement**: CharacterBody2D with `move_and_slide()` for the player and chickens
- **AI**: A state machine per chicken, with NavigationAgent2D for pathfinding around furniture
- **Triggers**: Area2D for pickups, hiding spots, checkpoints, and exits
- **Levels**: TileMapLayer for floors and walls, one scene per level
- **Communication**: Signals between systems instead of direct references
- **Pooling**: Reuse egg projectiles and feather effects instead of creating new ones

### Physics Layers
| Layer | Name | Used by |
|---|---|---|
| 1 | world | Walls, furniture, machinery |
| 2 | player | The player |
| 3 | chickens | All chickens |

---

## Release and Business

- **Store**: Steam first. Requires a Steamworks account and the per-game Steam Direct fee (currently $100, refunded after $1,000 in sales).
- **Store page timing**: Put a "Coming Soon" page up as early as the vertical slice allows, to collect wishlists. Wishlists drive Steam's launch visibility.
- **Price**: $9.99 target. See the refund risk below before locking it in.
- **Age rating**: Aim for a low rating: cartoon violence (feather poofs) and magic mushrooms that work like video-game power-ups. Answer Steam's content questionnaire accurately.
- **Store art**: Commission capsule images and key art from a pixel artist or illustrator. These matter more for clicks than any screenshot.

---

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| **Steam's 2-hour refund window**: a 30-minute game can be finished and refunded | High | Make replay value obvious on the store page (difficulty modes, speedrun mode, scoring, achievements). Revisit price after playtesters show how long people actually play. |
| **Scope vs. a few hours a week**: 5 levels with bosses is a long build | High | Build in milestones, not dates ([roadmap.md](roadmap.md)). Measure how long the Level 1 vertical slice takes and re-plan from real numbers. Cutting to 3 levels stays a fallback. |
| **Chicken AI complexity** | Medium | Prototype the AI first. Simplify behaviors that don't add fun. |
| **Pixel art consistency** | Medium | One palette, a written style guide, and a style test before production |
| **Composer cost and schedule** | Medium | Budget early. Bring the composer in after the vertical slice, when the game's mood is clear. |
| **Feature creep** | Medium | No new mechanics after the risk-prototype milestone unless something is cut to make room |
| **Mushrooms read as a drug reference** | Low | Keep mushrooms clearly magical: glowing, colorful, and giving video-game powers. Answer Steam's questionnaire accurately. |

---

## Decision Log

"You" means decided by the game's creator. "Proposed" means Claude chose it to fill a gap. Anything proposed is easy to change.

| Date | Decision | By |
|---|---|---|
| 2026-10-19 | Engine is Godot 4.x | You (original GDD) |
| 2026-10-19 | Base resolution 320x180 (16:9), replacing the conflicting 320x240 and 1080p | Proposed |
| 2026-10-19 | Chickens can be defeated comically (feather poof, no gore), but only by the environment and totem collapses; the player has no direct attack | You |
| 2026-10-19 | Launch with the full 5-level campaign | You |
| 2026-10-19 | Music is commissioned from a chiptune composer | You |
| 2026-10-19 | Docs consolidated: GDD is the source of truth, gameplay-mechanics merged in, todo replaced by roadmap, art style guide added | You |
| 2026-10-19 | Claude makes the in-game pixel art; Steam store art is commissioned | You |
| 2026-10-19 | 3/4 view, matching the *Zombies Ate My Neighbors* reference | Proposed |
| 2026-10-19 | Coins removed; vending machines are opened with maintenance keys | Proposed |
| 2026-10-19 | Key items don't use inventory slots; snacks stack 3 per slot | Proposed |
| 2026-10-19 | Airport map shows on the pause screen; no mini-map on the HUD | Proposed |
| 2026-10-19 | The optional flight-departure countdown becomes Speedrun Mode instead | Proposed |
| 2026-10-19 | Totems form at designer-placed roost spots | Proposed |
| 2026-10-19 | Throwing aims where the player faces; no mouse aiming | Proposed |
| 2026-10-19 | Steam first, with Steam Deck support from the start | Proposed |
| 2026-10-19 | Mushroom theme: power-ups come from mushroom patches instead of drug disposal boxes; powered chickens wear the cap of the mushroom they ate; the final totem is crowned with a giant mushroom | You |
| 2026-10-19 | Claude's sprites are first-pass art; the creator redraws all sprites by hand once the game is done | You |
| 2026-10-19 | Mushroom patches can be destroyed with one fire extinguisher charge | Proposed |
| 2026-10-19 | Egg-shooter cap is purple instead of yellow, because yellow blended into the beak and legs at 16x16 | Proposed |
| 2026-10-19 | Style test (M2) signed off: ENDESGA 32 palette, sprite sizes, and the Arrivals look are locked | You |
| 2026-10-19 | Luggage carts are a second way to defeat chickens, alongside the carousel chute | You |
| 2026-10-19 | The carousel belt is walkable and carries everything; only chickens fit through the chute | Proposed |
| 2026-10-19 | Health is tracked in quarter suitcases so eggs can deal a quarter of a peck's damage | You |
| 2026-10-19 | Chickens besieging a hiding spot give up and leave, rather than breaking the door, so hiding is a safe escape | You |
| 2026-10-19 | The player has 5 suitcases of health instead of 3 | You |
| 2026-10-19 | A chicken peck costs half a suitcase instead of a whole one, so the player survives 10 pecks | You |
| 2026-10-19 | Rolling suitcases can be carried overhead and thrown; a hit defeats the chicken | You |
| 2026-10-19 | A suitcase bursts open when it defeats a chicken (one defeat each), but a missed throw can be picked up again; carrying it slows the player and blocks running, items, and hiding | Proposed |
| 2026-10-19 | Player sprite is 16x32 (up from 16x24) so the look from the reference photos fits; chickens stay 16x16 | You |
| 2026-10-19 | The player's hair gets messier as her health drops | You |
| 2026-10-19 | The player character is named Amanda (she/her) | You |
| 2026-10-19 | Retrying from a checkpoint restores full health (the inventory is as it was) | Proposed |
| 2026-10-19 | Checkpoints are "YOU ARE HERE" map stands | Proposed |
| 2026-10-19 | Arrivals music should be energetic and dystopian, not slow and sad | You |
| 2026-10-19 | Level 1's placeholder music is built from the cluck groove (real chicken recordings as percussion and melody) | You |
| 2026-10-19 | Level 2 layout: queue hall, three scanner lanes (one with a shutter on a switch), screening area with the boarding pass, restroom stalls for hiding | You |
| 2026-10-19 | The way out of Security is a gate that scans the boarding pass without using it up | Proposed |
| 2026-10-19 | The inventory carries over between levels; clearing a level autosaves at the start of the next | Proposed |
| 2026-10-19 | Level 3 layout: restaurant-ringed court, three vending machines but two keys, the first totem at a seating plaza in front of the exit | You |
| 2026-10-19 | Security and the Food Court share one placeholder track, as in the music list | Proposed |
| 2026-10-19 | Moving walkways: handrails on both sides, three speeds set from a wall panel, chickens flung off the end at full speed are knocked out by hitting something solid; the player is never flung | Proposed |
| 2026-10-19 | Level 4 layout: Gates A, B, C joined by walkway corridors, with roosts in B and C and a shutter room in B | You |
