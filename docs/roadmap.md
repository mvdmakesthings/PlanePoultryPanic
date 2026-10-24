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

One room built with the style-test art (the art came first, by choice). Goal: find out whether the core loop is fun.

- [x] Godot project in `game/` at 320x180 with pixel-perfect scaling
- [x] Keyboard and gamepad input bindings
- [x] Player: 8-directional movement, running with stamina, health with invincibility frames
- [x] Chickens: wander, spot the player, chase, alert neighbors, give up
- [x] Snacks: pick up, throw to distract, eat to heal
- [x] Simple HUD: health, stamina, snack count
- [x] Win (reach the exit) and lose (restart) states
- [x] Automated smoke test (`game/tests/prototype_smoke.tscn`)
- [x] Install Godot (4.7, via Homebrew)
- [x] Play it; tune speeds, sight range, and stamina until it feels right (chickens slowed to 70 px/s with 64 px sight after the first play-test)

**Done when** you've played it several times and want to keep playing, or you know exactly what's missing.

## M2: Style Test

- [x] Lock the palette ([art-style-guide.md](art-style-guide.md))
- [x] Player sprite: idle and walk in 4 directions (run cycle comes in M4)
- [x] Normal chicken sprite: idle and walk, plus the three powered mushroom modes
- [x] Airport floor and wall tiles, and a mushroom patch
- [x] Baggage carousel (modular and animated)
- [x] Mock screenshot at real size (320x180, shown at 4x)
- [x] Adjust until you're happy; update the style guide with what we learned (signed off 2026-10-19)

**Done when** the mock screenshot looks like the game you imagine.

## M3: Risk Prototypes

Still mostly gray-box. Each item should be playable in the prototype room.

- [x] Chicken pathfinding around furniture (NavigationAgent2D)
- [x] Mushroom patches and the three powered modes (flight, rage, egg shooter)
- [x] Fire extinguisher (freeze cone, charges, kills mushroom patches)
- [x] Baggage carousel that carries and defeats chickens
- [x] Luggage carts the player shoves into chickens
- [x] Totem formation at a roost, its attacks (including sustained flight), and toppling it
- [x] Hiding spots (supply closet)
- [x] 6-slot inventory with stacking, cycling, dropping, and key items (key items are supported; the first real one, the maintenance key, arrives with Level 1)

**Done when** each system works and is fun, or has been simplified or cut. **Feature lock**: no new mechanics after this unless something is cut to make room.

## M4: Vertical Slice (Level 1, Arrivals)

Level 1 at close to final quality, start to finish.

- [x] Full Level 1 layout built from tiles, with the tutorial flow
- [x] Final-quality art for everything in the level, with animations (first pass by Claude: run cycle, messy hair, the Security door, key, signs, seats, litter, checkpoint stands; Amanda's throw, eat, hurt and defeat; the chickens' chase and eat)
- [x] Sound effects and placeholder music (Level 1 plays a loop built from the cluck groove, `tools/music/arrivals.py`)
- [x] Checkpoints, death and retry, and autosave
- [x] Main menu, pause menu, basic settings (audio, fullscreen, remapping)
- [x] Context prompts that switch between keyboard and gamepad icons
- [ ] Runs well on Steam Deck, or a low-end PC as a stand-in (measured on an Apple M1: 1.4 ms a frame in normal play, 2.4 ms with 46 chickens, worst frames under 9 ms, 40 MB of memory. Run `game/tests/level_01_perf.tscn` on a Deck or low-end PC to tick this off; see the README)
- [ ] 3-5 friends play it without help; watch silently and take notes
- [ ] **Measure how long M4 took** and re-plan M5-M8 from that

Business steps once the slice is solid:

- [ ] Create a Steamworks account and pay the Steam Direct fee
- [ ] Put up a "Coming Soon" store page with screenshots to start collecting wishlists
- [ ] Find and commission the chiptune composer (see the composer brief in the GDD)

**Done when** a stranger could play Level 1 and believe it's part of a finished game.

## M5: Production (Levels 2-5)

Build each level fully before starting the next, so the game is always playable from the start.

- [x] Level 2: Security Checkpoint (boarding pass, first powered chickens, extinguisher, hiding; played and approved 2026-10-19)
- [x] Level 3: Food Court (first totem, vending machines; played and approved 2026-10-19)
- [x] Level 4: Gate Areas A, B, C (walkways, all systems combined, mid-level checkpoints; played and approved 2026-10-19)
- [x] Level 5: Final Departure Gate (final boss, escape sequence, and the ending scene; built 2026-10-19, waiting on your playtest)
- [x] Opening scene: a 31-second in-engine cutscene on New Game at Amanda's cancelled gate (board flips to CANCELLED, boarding pass stamped EXPIRED, chickens on the tarmac, the PA announces the last flight from Gate C13), skippable, then Level 1
- [x] Ending scene, PA and departure-board text
- [ ] Composer's tracks integrated as they arrive
- [ ] Playtest each level as it's finished

**Done when** the game can be played from the opening to the ending.

## M6: Systems and Polish

- [ ] Difficulty modes (Easy, Standard, Hard, Expert)
- [x] Scoring screen (time, efficiency, stealth, discovery, Perfect Run and Pacifist bonuses, airline ranks, best score; built 2026-10-19)
- [ ] Steam achievements
- [ ] Speedrun mode with level splits
- [ ] Full settings and accessibility options
- [x] Screen shake (with a Settings toggle), particles, hit flashes, squash and stretch, hit-stop, and HUD feedback
- [x] Music transitions (crossfades, ducking under big cues) and a balanced sound mix
- [x] Secrets and easter eggs (11 secrets, gags, the mushroom lore in the opening, and the captain ending; see the GDD's Secrets section)
- [ ] Spreading mushrooms (sprouts Amanda can stomp, a cap per level; see the GDD's Spreading Mushrooms section). An approved exception to the M3 feature lock (2026-10-24): it adds pressure against dawdling using the existing patches, with no new item or enemy

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
