# Plane Poultry Panic

![Plane Poultry Panic cover: the player sprints through Arrivals with a flock of chickens behind them while the last flight takes off](cover-photo.png)

A 16-bit top-down action game: get through a chicken-overrun airport and catch the last flight out. Built with Godot 4.

![The player's walk cycle in all four directions](docs/images/player_walk.gif)

## Play

1. Install Godot 4 (on macOS: `brew install --cask godot`).
2. Run the game from the repo root. It starts in Level 1, Arrivals / Baggage Claim:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game
```

Or open `game/project.godot` in the Godot editor and press F5.

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
| Push a cart, take an extinguisher, pick up or put down a suitcase | F | B |
| Restart the prototype room (after winning or losing) | R | Start |

In Level 1, find the maintenance key and use it on the locked door to **SECURITY**. Hints at the top of the screen teach the controls as you go. In the prototype room, reach the green **GATE** without losing all five suitcases. Chickens chase you when they see you; throw a snack and they'll go eat it instead.

## Run the smoke tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/prototype_smoke.tscn
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://tests/level_01_smoke.tscn
```

The first covers the prototype room's systems (chickens, items, machinery); the second covers Level 1's layout and its path from the start to the Security door. Both drive the player with simulated input and exit non-zero on failure. Godot script errors don't fail them on their own, so also check the output for any `ERROR` or `WARNING` lines. In a fresh checkout, run `--headless --path game --import` once first so Godot knows the project's classes.

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
