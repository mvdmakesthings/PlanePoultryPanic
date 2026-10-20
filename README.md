# Plane Poultry Panic

![Plane Poultry Panic cover: the player sprints through Arrivals with a flock of chickens behind them while the last flight takes off](cover-photo.png)

A 16-bit top-down action game: get through a chicken-overrun airport and catch the last flight out. Built with Godot 4.

![Amanda's walk cycle in all four directions](docs/images/player_walk.gif)

## Play

1. Install Godot 4 (on macOS: `brew install --cask godot`).
2. Run the game from the repo root. It opens on the main menu; New Game starts Level 1, Arrivals / Baggage Claim:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game
```

Or open `game/project.godot` in the Godot editor and press F5.

To jump straight into a level (with the default starting snacks), pass its scene, for example Level 2:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game res://scenes/levels/level_02_security.tscn
```

The one-room prototype is still there as a test bed for chicken behavior and items:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game res://scenes/levels/prototype_room.tscn
```

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD or arrow keys | Left stick or D-pad |
| Run (uses stamina) | Shift | Right shoulder |
| Use the selected item (throw a snack, spray the extinguisher), or throw a carried suitcase | Space | A |
| Switch inventory slot | Q / R, or mouse wheel | LB / Y |
| Drop the selected slot | G | Back |
| Eat a snack (heal) | E | X |
| Interact: push a cart, take an extinguisher, lift or put down a suitcase, unlock a door or vending machine, scan a boarding pass, flip a switch, hide in a closet or stall | F | B |
| Pause (Resume, Settings, Quit to Menu) | Esc | Start |
| Restart the prototype room (after winning or losing) | R | Start |

Every control can be remapped in Settings > Controls. Prompts and hints show keyboard keys or gamepad buttons, whichever you touched last. Menus work with the arrow keys or WASD, Enter, and Esc, or a gamepad, or the mouse.

In Level 1, find the maintenance key and use it on the locked door to **SECURITY**. That leads on to Level 2, the Security Checkpoint: take a fire extinguisher, get past the first powered chickens and up through a scanner lane, find your boarding pass in the screening bins, and scan it at the gate to the **FOOD COURT**. In Level 3, the Food Court, stock up (maintenance keys open vending machines) and get past the first chicken totem to the door to **ALL GATES**. Your inventory carries over from level to level. Hints at the top of the screen teach the controls as you go. The "YOU ARE HERE" map stands are checkpoints: reaching one autosaves, and after a knockout you retry from the latest one. Continue in the main menu picks up from there. In the prototype room, reach the green **GATE** without losing all five suitcases. Chickens chase you when they see you; throw a snack and they'll go eat it instead.

## Run the smoke tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/prototype_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/level_01_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/menus_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/level_02_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/level_03_smoke.tscn
```

The first covers the prototype room's systems (chickens, items, machinery); the second covers Level 1: its layout, its path from the start to the Security door, checkpoints, retrying and pausing; the third covers the main menu, settings and remapping; the fourth covers Level 2: arriving from Level 1 with the inventory, the extinguisher and mushroom patch, the scanner lanes, the shutter, hiding, the boarding pass and its gate, and checkpoints; the fifth covers Level 3: the kitchen key, vending machines, the totem forming at the roost, the exit and checkpoints. Every level test also checks that nothing was placed inside a wall. The tests use their own save and settings files, so they never touch yours. They drive the player with simulated input and exit non-zero on failure. Godot script errors don't fail them on their own, so also check the output for any `ERROR` or `WARNING` lines. In a fresh checkout, run `--headless --path game --import` once first so Godot knows the project's classes.

## Build for the browser (itch.io)

The project has a **Web** export preset (`game/export_presets.cfg`). It uses the single-threaded web build, so it runs on hosts that can't send special headers, like itch.io and GitHub Pages.

1. Install the web export templates once. In the Godot editor: **Editor > Manage Export Templates > Download and Install**. The templates must match your Godot version exactly.
2. Export from the repo root:

```bash
mkdir -p build/web
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --export-release "Web"
```

This writes `build/web/index.html` plus the `.wasm`, `.pck` and `.js` files next to it. `build/` is gitignored.

3. Try it locally before uploading. Opening `index.html` straight from disk won't work; it needs a web server:

```bash
python3 -m http.server 8060 --directory build/web
```

Then open <http://localhost:8060>. Click the game once so it gets keyboard focus.

4. Zip the *contents* of `build/web` (not the folder itself, so `index.html` sits at the top of the zip):

```bash
cd build/web && zip -r ../plane-poultry-panic-web.zip . && cd -
```

5. On itch.io, create or edit the project, set **Kind of project** to **HTML**, upload the zip and tick **This file will be played in the browser**. Set the embed size to 1280 × 720 (16:9, a clean multiple of the 320 × 180 game) and turn on the **Fullscreen button**. Leave **SharedArrayBuffer support** off; this build doesn't need it.

Browser build notes:

- The download is about 10 MB zipped (the engine is most of it; the game itself is under 200 KB), so expect a few seconds of loading on first visit.
- Players need to click the game before keys work. Until then, arrow keys and Space scroll the itch.io page instead.
- Gamepads work in Chrome, Firefox and Safari, but the browser only reports a pad after a button is pressed, and button layouts can differ from desktop for non-standard controllers.
- Browsers block sound until the player clicks or presses a key. The game has no audio yet; when it does, don't rely on a sound playing before the first input.
- Browser builds run slower than desktop ones, especially on laptops on battery. If a playtester reports stutter, ask which browser they used.

## Check performance

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game res://tests/level_01_perf.tscn
```

Runs Level 1 in a window with vsync off for three scenarios (normal play, every chicken chasing, 46 chickens) and prints frame times, draw calls and memory. The target is 60 FPS, which is 16.7 ms a frame, on a Steam Deck or a dual-core laptop, so the worst-1% numbers should stay well under that. On an Apple M1 a normal frame takes about 1.4 ms.

## Rebuild the sprites

Sprites are generated from Python sources in `tools/sprites/` (needs Pillow):

```bash
python3 tools/sprites/build.py --preview /tmp/sprite-previews
```

The walk GIF above is `player_walk.gif` from that preview folder, copied to `docs/images/`.

## Rebuild the sounds

Sound effects and the placeholder music are generated by Python scripts in `tools/audio/` (standard library only):

```bash
python3 tools/audio/build.py
```

Each sound is a short recipe in `tools/audio/build.py`. In the game, the AudioManager autoload plays them on three buses, Music, Effects and Ambience, so each has its own volume. Level 1's music is built from real chicken recordings: `tools/music/arrivals.py` arranges the cluck groove from `tools/music/groove.py` (a spooky-surf groove with cluck percussion and a melody played on a repitched cluck, through an SNES-style output stage) into a seamless 16-bar loop. It needs numpy and scipy (`pip install -r tools/music/requirements.txt`):

```bash
python3 tools/music/arrivals.py
```

Levels 2 and 3 (Security and the Food Court, one track in the GDD) share their own loop in the same style, in D minor and a little more urgent:

```bash
python3 tools/music/security.py
```

Older chiptune sketches are note lists in `tools/audio/music.py`, built only with `tools/audio/build.py --music` (as `chip_*.wav`); the game doesn't use them.

## Docs

- [Game design document](docs/game-design-document.md): how the game works
- [Roadmap](docs/roadmap.md): milestones from prototype to Steam
- [Art style guide](docs/art-style-guide.md): palette, sprite rules, sheet layouts
- [Storyline](docs/storyline.md): world and tone
