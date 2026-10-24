# Plane Poultry Panic

![Plane Poultry Panic cover: the player sprints through Arrivals with a flock of chickens behind them while the last flight takes off](cover-photo.png)

A 16-bit top-down action game: get through a chicken-overrun airport and catch the last flight out. Built with Godot 4.

![Amanda's walk cycle in all four directions](docs/images/player_walk.gif)

## Play

1. Install Godot 4 (on macOS: `brew install --cask godot`).
2. Run the game from the repo root. It opens on the main menu; New Game plays a short opening scene (skip it with Enter, Space, Esc, or the gamepad's A, B or Start), then starts Level 1, Arrivals / Baggage Claim:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game
```

Or open `game/project.godot` in the Godot editor and press F5.

To jump straight into a level (with the default starting snacks), pass its scene, for example Level 2:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game res://scenes/levels/level_02_security.tscn
```

To see the score screen without playing through, run it on its own; it shows a sample run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game res://scenes/ui/score_screen.tscn
```

The one-room prototype is still there as a test bed for chicken behavior and items:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game res://scenes/levels/prototype_room.tscn
```

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD or arrow keys | Left stick or D-pad |
| Run (uses stamina) | Shift | Hold the left stick in (L3) |
| Use the selected item (throw a snack, spray the extinguisher), or throw a carried suitcase | Space | A |
| Switch inventory slot | Q / R, or mouse wheel | LB / RB |
| Drop the selected slot | G | Back |
| Eat a snack (heal) | E | X |
| Interact: push a cart, take an extinguisher, lift or put down a suitcase, unlock a door or vending machine, scan a boarding pass, flip a switch or a walkway's speed panel, hide in a closet or stall | F | B |
| Pause (Resume, Settings, Quit to Menu) | Esc | Start |
| Restart the prototype room (after winning or losing) | R | Start |

Hits, stomps and slams shake the screen; turn that off with Settings > Screen Shake. Every control can be remapped in Settings > Controls. Prompts and hints show keyboard keys or gamepad buttons, whichever you touched last. Menus work with the arrow keys or WASD, Enter, and Esc, or a gamepad, or the mouse.

In Level 1, find the maintenance key and use it on the locked door to **SECURITY**. That leads on to Level 2, the Security Checkpoint: take a fire extinguisher, get past the first powered chickens and up through a scanner lane, find your boarding pass in the screening bins, and scan it at the gate to the **FOOD COURT**. In Level 3, the Food Court, stock up (maintenance keys open vending machines) and get past the first chicken totem to the door to **ALL GATES**. Level 4 runs through Gates A, B and C, joined by moving walkways: a speed panel on the corridor wall sets them to slow, normal or full, and at full speed chickens riding off the end get flung into the wall. The door to **GATE C13** at the far end leads on to Level 5, the Final Departure Gate: beat the **Supreme Totem** (three hits: shove carts into it, freeze its base, or lure it onto a walkway), then the doors start closing. Scan your boarding pass at the **BOARDING** door and run the jet bridge to the plane before the countdown runs out. Boarding plays the ending, then a departure board scores your run (time, items to spare, chickens that never saw you, secrets, and bonuses for no hits and no defeated chickens) and keeps your best score, which the main menu shows too. Your inventory carries over from level to level. Every level also hides two or three secrets (rooms behind odd-looking doors, stashes to search), each given away by something you can see if you look; the score screen counts them. Hints at the top of the screen teach the controls as you go; PA announcements at the bottom are the terminal talking (mostly jokes, sometimes a clue). The "YOU ARE HERE" map stands are checkpoints: reaching one autosaves, and after a knockout you retry from the latest one. Continue in the main menu picks up from there. In the prototype room, reach the green **GATE** without losing all five suitcases. Chickens chase you when they see you; throw a snack and they'll go eat it instead.

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

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/level_04_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/level_05_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/opening_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/secrets_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/scoring_smoke.tscn
```

The first covers the prototype room's systems (chickens, items, machinery); the second covers Level 1: its layout, its path from the start to the Security door, checkpoints, retrying and pausing, plus the game-feel effects (shake, hit-stop, flashes, particles, HUD feedback, music crossfades and ducking); the third covers the main menu, settings (including the screen shake toggle) and remapping; the fourth covers Level 2: arriving from Level 1 with the inventory, the extinguisher and mushroom patch, the scanner lanes, the shutter, hiding, the boarding pass and its gate, and checkpoints; the fifth covers Level 3: the kitchen key, vending machines, the totem forming at the roost, the exit and checkpoints; the sixth covers Level 4: walkways carrying, the speed panel, flinging, Gate B's roost and shutter, the exit and the checkpoints between gate areas; the seventh covers Level 5: the boss forming, its three hits (and ignoring snacks), the escape, running out of time, the checkpoint after the boss, and the ending; the eighth covers the opening scene: it plays through its beats (sped up), can be skipped from the keyboard or a gamepad, and lands in Level 1. The ninth covers the secrets: the `secret_found` hook and its save, each level's secret room (opening, going in, coming out), the stashes, the FRAGILE suitcase, the Pilot Caps, the gags, secrets staying found, and the ending's captain; the tenth covers scoring: the points and ranks, tracking time, items, chickens and hits in a real level, counting secrets, stats surviving a retry, Continue and the next level, the best score, the score screen and the main menu's best line. Every level test also checks that nothing was placed inside a wall. The tests use their own save, best-score and settings files, so they never touch yours. They drive the player with simulated input and exit non-zero on failure. Godot script errors don't fail them on their own, so also check the output for any `ERROR` or `WARNING` lines. In a fresh checkout, run `--headless --path game --import` once first so Godot knows the project's classes.

## Build for the browser (itch.io)

The project has a **Web** export preset (`game/export_presets.cfg`). It uses the single-threaded web build, so it runs on hosts that can't send special headers, like itch.io.

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

### Publish the browser build

The latest browser build is playable at **https://planepoultrypanic.mvdmakesthings.com/** and on itch.io at **https://mvdmakesthings.itch.io/plane-poultry-panic**.

- The website is hosted on Vercel (project `plane-poultry-panic` in the MVD Makes Things team), which deploys the separate public repo [plane-poultry-panic-play](https://github.com/mvdmakesthings/plane-poultry-panic-play) on every push. That repo holds only the exported files, so this repo (code, tools and docs) stays private. The domain is attached to the Vercel project, and Vercel handles its DNS and HTTPS certificate.
- itch.io uploads go through [butler](https://itch.io/docs/butler/), installed at `~/.local/share/butler/butler` from itch.io's own download server (the Homebrew package called "butler" is an unrelated app). Log it in once with `~/.local/share/butler/butler login`.

To publish a new version to both, set `config/version` in `game/project.godot`, then run from the repo root:

```bash
tools/publish_web.sh
```

It exports the Web build, copies it into the play repo (keeping its README, `vercel.json` and `.gitignore`) and pushes, then pushes the same build to itch.io's `html5` channel. Vercel deploys it a minute or so later. Set `SKIP_ITCH=1` to publish only the website. If the build hasn't changed, the website is left alone and itch.io receives an almost empty patch.

Browser build notes:

- The download is about 10 MB zipped (the engine is most of it; the game itself is under 200 KB), so expect a few seconds of loading on first visit.
- Players need to click the game before keys work. Until then, arrow keys and Space scroll the itch.io page instead.
- Gamepads work in Chrome, Firefox and Safari, but the browser only reports a pad after a button is pressed, and button layouts can differ from desktop for non-standard controllers.
- Browsers block sound until the player clicks or presses a key. The game has no audio yet; when it does, don't rely on a sound playing before the first input.
- Browser builds run slower than desktop ones, especially on laptops on battery. If a playtester reports stutter, ask which browser they used.

## Record the effects

`tests/juice_demo.tscn` stages the game-feel effects one after another in the prototype room: running dust, pickups, eating, an egg splat, a checkpoint, a peck, the extinguisher, a cart, a totem and the boss. It isn't a test; it's for recording. This writes one PNG per frame into a folder (create it first):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game --write-movie /tmp/juice/frame.png --fixed-fps 30 res://tests/juice_demo.tscn
```

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

Each sound is a short recipe in `tools/audio/build.py`. In the game, the AudioManager autoload plays them on three buses, Music, Effects and Ambience, so each has its own volume. Its `SOUNDS` table is the mix: each sound's volume trim (set from its measured loudness), random pitch and volume spread so repeats don't grate, and how much it dips the music. Its `MUSIC` table evens out the tracks, which crossfade when the level changes. If you redo a sound, check its trim. Level 1's music is built from real chicken recordings: `tools/music/arrivals.py` arranges the cluck groove from `tools/music/groove.py` (a spooky-surf groove with cluck percussion and a melody played on a repitched cluck, through an SNES-style output stage) into a seamless 16-bar loop. It needs numpy and scipy (`pip install -r tools/music/requirements.txt`):

```bash
python3 tools/music/arrivals.py
```

Levels 2 and 3 (Security and the Food Court, one track in the GDD) share their own loop in the same style, in D minor and a little more urgent:

```bash
python3 tools/music/security.py
```

Level 4 (the Gate Areas) has a faster loop, 132 BPM in A minor:

```bash
python3 tools/music/gates.py
```

Level 5's boss fight and escape have a 144 BPM loop, and the ending a gentler victory loop:

```bash
python3 tools/music/boss.py
```

```bash
python3 tools/music/victory.py
```

Older chiptune sketches are note lists in `tools/audio/music.py`, built only with `tools/audio/build.py --music` (as `chip_*.wav`); the game doesn't use them.

## Docs

- [Game design document](docs/game-design-document.md): how the game works
- [Roadmap](docs/roadmap.md): milestones from prototype to Steam
- [Art style guide](docs/art-style-guide.md): palette, sprite rules, sheet layouts
- [Storyline](docs/storyline.md): world and tone
- [Store page](docs/store-page.md): itch.io tagline, description, tags, and metadata
