# Plane Poultry Panic

![Plane Poultry Panic cover: the player sprints through Arrivals with a flock of chickens behind them while the last flight takes off](cover-photo.png)

A 16-bit top-down action game: get through a chicken-overrun airport and catch the last flight out. Built with Godot 4.

![The player's walk cycle in all four directions](docs/images/player_walk.gif)

## Play the prototype

1. Install Godot 4 (on macOS: `brew install --cask godot`).
2. Run the game from the repo root:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game
```

Or open `game/project.godot` in the Godot editor and press F5.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD or arrow keys | Left stick or D-pad |
| Run (uses stamina) | Shift | Right shoulder |
| Use the selected item (throw a snack, spray the extinguisher), or throw a carried suitcase | Space | A |
| Switch inventory slot | Q / R, or mouse wheel | LB / Y |
| Drop the selected slot | G | Back |
| Eat a snack (heal) | E | X |
| Push a cart, take an extinguisher, pick up or put down a suitcase | F | B |
| Restart (after winning or losing) | R | Start |

Reach the green **GATE** without losing all five suitcases. Chickens chase you when they see you; throw a snack and they'll go eat it instead.

## Run the smoke test

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/prototype_smoke.tscn
```

It drives the player with simulated input and exits non-zero on failure. Godot script errors don't fail it on their own, so also check the output for any `ERROR` lines.

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

## Rebuild the sprites

Sprites are generated from Python sources in `tools/sprites/` (needs Pillow):

```bash
python3 tools/sprites/build.py --preview /tmp/sprite-previews
```

The walk GIF above is `player_walk.gif` from that preview folder, copied to `docs/images/`.

## Docs

- [Game design document](docs/game-design-document.md): how the game works
- [Roadmap](docs/roadmap.md): milestones from prototype to Steam
- [Art style guide](docs/art-style-guide.md): palette, sprite rules, sheet layouts
- [Storyline](docs/storyline.md): world and tone
