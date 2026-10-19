# Plane Poultry Panic: Roadmap

How the game gets from design docs to a Steam launch. The design itself lives in [game-design-document.md](game-design-document.md).

## How This Roadmap Works

- **Playable first.** Every milestone ends with something you can run and play. Art and audio come after the mechanics feel good, not before.
- **Riskiest work first.** The parts most likely to fail (fun, chicken AI, totems) get tested early, while they're still cheap to change.
- **Milestones, not dates.** With a few hours a week, calendar dates would be guesses. Once the vertical slice (M4) is done, how long it took becomes the basis for a real estimate of the rest.
- **Who does what.** Claude writes the code and makes the pixel art and sound effects. You make the design calls, direct the art, and playtest. A composer and a store-art artist are commissioned along the way.

## Milestones at a Glance

| # | Milestone | Question it answers |
|---|---|---|
| M0 | Solid docs | Do we agree on what we're building? |
| M1 | Gray-box prototype | Is dodging and distracting chickens fun? |
| M2 | Style test | What does the game look like? |
| M3 | Risk prototypes | Do powered chickens, totems, and machinery work? |
| M4 | Vertical slice (Level 1) | What does "finished" look like, and how long does a level take? |
| M5 | Production (Levels 2-5) | Is the whole game there? |
| M6 | Systems and polish | Does it feel like a real product? |
| M7 | Beta | Do strangers enjoy it and finish it? |
| M8 | Launch | Is it on Steam? |

---

## M0: Solid Docs

- [x] Pick the engine (Godot 4.x)
- [x] Resolve contradictions between docs (resolution, controls, items, combat)
- [x] Consolidate docs: GDD as source of truth, roadmap, art style guide
- [x] Record decisions in the GDD decision log
- [ ] Review the updated docs and override any "Proposed" decisions you disagree with

## M1: Gray-Box Prototype

One room, colored shapes instead of art. Goal: find out whether the core loop is fun.

- [ ] Godot project in `game/` at 320x180 with pixel-perfect scaling
- [ ] Keyboard and gamepad input bindings
- [ ] Player: 8-directional movement, running with stamina, health with invincibility frames
- [ ] Chickens: wander, spot the player, chase, alert neighbors, give up
- [ ] Snacks: pick up, throw to distract, eat to heal
- [ ] Simple HUD: health, stamina, snack count
- [ ] Win (reach the exit) and lose (restart) states
- [ ] Install Godot and play it; tune speeds, sight range, and stamina until it feels right

**Done when** you've played it several times and want to keep playing, or you know exactly what's missing.

## M2: Style Test

- [ ] Lock the palette ([art-style-guide.md](art-style-guide.md))
- [ ] Player sprite: idle and walk in 4 directions (run cycle comes in M4)
- [ ] Normal chicken sprite: idle and walk
- [ ] Airport floor and wall tiles, one carousel piece
- [ ] Mock screenshot at real size (320x180, shown at 4x)
- [ ] Adjust until you're happy; update the style guide with what we learned

**Done when** the mock screenshot looks like the game you imagine.

## M3: Risk Prototypes

Still mostly gray-box. Each item should be playable in the prototype room.

- [ ] Chicken pathfinding around furniture (NavigationAgent2D)
- [ ] Mushroom patches and the three powered modes (flight, rage, egg shooter)
- [ ] Fire extinguisher (freeze cone, charges)
- [ ] Baggage carousel that carries and defeats chickens
- [ ] Totem formation at a roost, its attacks, and toppling it
- [ ] Hiding spots
- [ ] 6-slot inventory with stacking, cycling, dropping, and key items

**Done when** each system works and is fun, or has been simplified or cut. **Feature lock**: no new mechanics after this unless something is cut to make room.

## M4: Vertical Slice (Level 1, Arrivals)

Level 1 at close to final quality, start to finish.

- [ ] Full Level 1 layout built from tiles, with the tutorial flow
- [ ] Final-quality art for everything in the level, with animations
- [ ] Sound effects and placeholder music
- [ ] Checkpoints, death and retry, and autosave
- [ ] Main menu, pause menu, basic settings (audio, fullscreen, remapping)
- [ ] Context prompts that switch between keyboard and gamepad icons
- [ ] Runs well on Steam Deck, or a low-end PC as a stand-in
- [ ] 3-5 friends play it without help; watch silently and take notes
- [ ] **Measure how long M4 took** and re-plan M5-M8 from that

Business steps once the slice is solid:

- [ ] Create a Steamworks account and pay the Steam Direct fee
- [ ] Put up a "Coming Soon" store page with screenshots to start collecting wishlists
- [ ] Find and commission the chiptune composer (see the composer brief in the GDD)

**Done when** a stranger could play Level 1 and believe it's part of a finished game.

## M5: Production (Levels 2-5)

Build each level fully before starting the next, so the game is always playable from the start.

- [ ] Level 2: Security Checkpoint (boarding pass, first powered chickens, extinguisher, hiding)
- [ ] Level 3: Food Court (first totem, vending machines)
- [ ] Level 4: Gate Areas A, B, C (walkways, all systems combined, mid-level checkpoints)
- [ ] Level 5: Final Departure Gate (final boss, escape sequence)
- [ ] Opening scene, ending scene, PA and departure-board text
- [ ] Composer's tracks integrated as they arrive
- [ ] Playtest each level as it's finished

**Done when** the game can be played from the opening to the ending.

## M6: Systems and Polish

- [ ] Difficulty modes (Easy, Standard, Hard, Expert)
- [ ] Scoring screen
- [ ] Steam achievements
- [ ] Speedrun mode with level splits
- [ ] Full settings and accessibility options
- [ ] Screen shake, particles, hit flashes, and other feedback
- [ ] Music transitions and final audio mix
- [ ] Secrets and easter eggs

## M7: Beta

- [ ] Wider playtest (friends of friends, a small Discord, or a Steam playtest)
- [ ] Balance: difficulty curve, snack availability, chicken tuning
- [ ] Check total play time against the 30-minute target
- [ ] Bug fixing and performance on Windows, macOS, Linux, and Steam Deck
- [ ] Decide the final price using real play-time data (see the refund risk in the GDD)

## M8: Launch

- [ ] Commission Steam capsule art and key art
- [ ] Trailer (60-90 seconds of gameplay)
- [ ] Store page: description, feature list, screenshots, tags
- [ ] Steam content questionnaire
- [ ] Builds uploaded through Steamworks; achievements configured
- [ ] Meet Steam's waiting periods for new games and "Coming Soon" pages (check the current Steamworks rules)
- [ ] Launch, then watch reviews and fix critical bugs quickly

---

## Tools

| Need | Tool |
|---|---|
| Engine | Godot 4.x (free) |
| Version control | Git and GitHub |
| Pixel art | Generated by script from the shared palette; Aseprite (paid) or LibreSprite (free) for hand touch-ups |
| Sound effects | sfxr-style generation; Audacity for editing |
| Music | Commissioned composer |
| Task tracking | This file, or Linear if it grows |
