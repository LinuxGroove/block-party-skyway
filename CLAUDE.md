# Block Party: Skyway

A 3D platformer for one player (Adventure across floating islands, and Speedrun on the courses Adventure finds), in Godot 4.7 with GDScript, built from Kenney's Platformer Kit. The concept is idea 19 in [game-ideas](https://github.com/LinuxGroove/game-ideas/blob/main/ideas/19-block-party-skyway.md). It shares the LinuxGroove add-on with the other games; **read game-ideas' [online-addon.md](https://github.com/LinuxGroove/game-ideas/blob/main/online-addon.md) before touching online features or the shared add-on.**

## Commands

```sh
godot --headless --path . --import
godot --headless --path . tools/check_scripts.tscn                  # every script compiles
godot --headless --path . tests/run_tests.tscn -- --games=2         # unit tests, every world's islands and bosses, bot runs of every course
godot --headless --path . tests/run_tests.tscn -- --world=frosty    # the data checks and one world's tests
godot --headless --path . tests/run_tests.tscn -- --course=sawmill  # one course's bot runs
godot --headless --path . tests/run_tests.tscn -- --only=_test_moves    # one test of run_tests.gd
godot --path . -- --play=sunny                                      # straight onto an island (or a boss's arena)
godot --path . -- --course=sawmill                                  # straight into a speedrun
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 tools/screenshot.tscn -- /tmp/shot.png course=sawmill
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 tools/screenshot.tscn -- --all=docs/screenshots [world=frosty]
python3 tools/palettes.py                                           # the worlds' block colour maps
```

Run the script check and the tests before every commit. A new `class_name` needs an `--import` before the script check finds it. Headless runs reimport assets and rewrite many `*.glb.import` files and `icon.png.import`; revert those (`git checkout -- '*.import'`, `rm icon.png.import`) unless you meant to change them.

## Layout

| Path | What |
|---|---|
| `game/game_config.gd` | `GAME_ID`, the astronauts, setting defaults (camera comfort), music, input map |
| `game/player/` | `Hero` (every move, on the physics tick), `HeroInput` (one tick of controls; tests fill it), `BlobShadow` |
| `game/camera/` | `SkyCamera` (the calm camera) and `CameraZone` (an angle for part of a level) |
| `game/world/` | `Kit` (Kenney models by name, theme kits by prefix, layers), `Level` (levels in code), `Island` (a world's island), `boss/` (`BossArena`, `Boss`), `things/` (pickups, crates, springs, saws, spikes, platforms, critters, launchers, spinners, crushers, wind, islanders, flags, doors, gates, the Skyway bridge) |
| `game/levels/<world>/` | One folder per world: `<world>_world.gd` (its data), the island, its four courses and its boss's arena |
| `game/play/` | `Play` (one visit to a level, Adventure or Speedrun), `Worlds` (the eight worlds and their data), `Courses` (medal times), `Ghost` and `GhostRunner`, `Levels` |
| `game/progress.gd` | `Progress` autoload: stars, gems, coins, found courses, best times (user://progress.cfg) and ghosts (user://ghosts/) |
| `game/ui/` | Title (with a backdrop of the island), HUD, pause menu, results, how to play |
| `addons/linuxgroove/` | Shared LinuxGroove add-on |
| `addons/com.heroiclabs.nakama/` | Vendored Nakama client with a local patch (see its `VENDORED.md`) |
| `tests/run_tests.gd` | Headless test runner; add checks with `check(ok, "what")` |
| `tests/worlds/<world>_tests.gd` | A world's island and boss tests (`run()`), and the pilot's legs through each of its courses (`legs()`) |
| `tests/course_pilot.gd` | Drives the hero along legs (run, jump, steer to a landing spot, wall kicks), for course and island tests |
| `tools/` | Script checker, screenshots, `palettes.py`, `probe_models.gd` (model sizes), `version.sh`, `release.sh` |
| `docs/screenshots/<world>/` | A screenshot of every level, made by `tools/screenshot.tscn -- --all=docs/screenshots` |

## How the game is built

- **Eight worlds**, in `Worlds.ORDER`: Sunny Isles, Frosty Peaks, Pirate Cove, Spooky Hollow, Snack Valley, Gear Works, Sky Castle and Star Station. Each has an island (extends `Island`), four courses and a boss's arena (extends `BossArena`), all listed in its `<world>_world.gd` with their stars (ten: five on the island, one per course, one for the boss), gems, medal times, music, sky and block palette. A world opens once the boss before it is beaten; its island's `BossDoor` opens at the world data's boss `door` stars, and `SkywayGate`s lead to the worlds either side. Level ids are unique across worlds.
- **Levels are code.** A level extends `Level` and builds in `build()`: `land(x0, z0, x1, z1, top, depth)` lays grass blocks on whole metres with one box of collision, `ledge()` a thin slab, `ramp()` a slope that rises 0.76 (the hero steps up the rest), `ice()` a slippery slab, `water()` a sheet that sends the hero back to the flag, `add(thing, at)` places a thing, `camera_zone()` sets the camera for a box. `add_coin()`, `add_gem()`, `add_heart()` and `add_checkpoint()` leave themselves out of Speedrun, so a course is written once for both modes. `finish()` batches the blocks into MultiMeshes and gives `block-*` pieces the world's colour map. X runs east, Z south; courses mostly run north (-z). Theme kit models go by prefix: `holiday:`, `pirate:`, `grave:`, `food:`, `factory:`, `castle:`, `station:` (`tools/probe_models.gd` prints their sizes).
- **The hero** is a `CharacterBody3D` with its own state machine (ground, air, wall, dive, slide, pound, hurt, locked), tuned in constants at the top of `hero.gd`. Kenney's rig has no clips for dives, slides and flips, so the body is tipped in code. `Hero.step()` reads `hero.input`, which `Play` fills from the controls each tick and tests and the pilot fill themselves.
- **The camera is gentle on purpose** (some players get motion sick): behind and above, angles set per area by `CameraZone`s with slow blends, the right stick only nudges it and it eases back, open areas let it turn freely, and the follow-behind mode is a setting. Never add camera shake, head bob or quick cuts; keep turn speed, field of view and follow in the comfort settings.
- **Layers**: 1 world, 2 hero, 4 pickups. Things that react to the hero are `Area3D`s with mask 2; set `monitorable` in `_init()`, since things get added from inside physics signals. Levels set `DISABLE_MODE_KEEP_ACTIVE` on their bodies so the speedrun countdown can pause a level without the floor disappearing.
- **Stars and gems** are ids like `sunny/tower`, listed in the world's data with each course's star and gem; `_test_world_data` checks every listed one is placed (or `given` by a script), that the island has every door and gate, and that courses build for Speedrun without extras. Course medal times come from the pilot's run printed by the tests: gold about 9% over it, silver about 35%, bronze about 90%, and Patrol, the fourth medal, about 5% under.
- **Bosses** extend `Boss`: they move in `think()`, set `open` when a stomp, pound or dive can hit them, and lose a heart per hit (`max_health`, usually 3). The arena adds the boss with `add_boss()`; beating it drops the star at `star_spot`.
- **Ghosts** are positions at 20 Hz (`Ghost`), gzipped, one file per course: the best run only.
- **Everything works offline.** No server or network is needed. Online features would need the game's GameDef on game-server first (it's registered with no features yet).
- **Launch ping.** `game/main.gd` calls `LGLaunchPing.send(GameConfig.GAME_ID)` at startup: one anonymous request to the game server's `/launch` (game, random install id, version, OS, CPU) so the server counts every player. It's skipped headless, from source and with `DO_NOT_TRACK` set, and never blocks or retries.

## The shared add-on

`addons/linuxgroove/` and `addons/com.heroiclabs.nakama/` are copies shared with [Foam Frenzy](https://github.com/LinuxGroove/foam-frenzy), [Graveyard Hollow](https://github.com/LinuxGroove/LampLighters), [Tiptoe](https://github.com/LinuxGroove/tiptoe) and [Joyride Junction](https://github.com/LinuxGroove/joyride-junction). Fix shared behaviour in the add-on, not with a workaround here, keep it game-agnostic, and port the change to the other games in the same piece of work. When the change affects how games should use the add-on, update online-addon.md in game-ideas too. Keep the `_disconnect_peer` and `_close` patch in `NakamaMultiplayerPeer.gd` when updating nakama-godot.

## Style

- Match the surrounding code: `##` doc comments on classes and non-obvious functions, short comments only where the reason isn't obvious.
- Connect signals with methods (or `bind`), not lambdas; a lambda on an autoload signal stays connected after its screen is freed.
- Build pieces so tests can drive them without a scene change: levels build without a play scene, `Play` runs as a plain child, and the pilot drives the hero.
- Controller first: every move works on a pad, and the mouse and keyboard always work too.
- Player-facing text is plain and short, in the game's words (islands, courses, stars, gems, the Skyway), and names moves by their action (Jump, Run, Crouch, Dive), not by a button.

## Releases

Pushing to `main` builds the snap and publishes it to the `edge` channel; a GitHub release publishes to `candidate`. The **Windows and macOS** workflow (`desktop.yml`) exports both from Linux with the `Windows Desktop` and `macOS` presets: pushes to `main` keep the zips as artifacts for 5 days, and releases get them attached. They aren't signed by Microsoft or Apple, and the release notes tell players how to open them. CI injects the server key from the `GAME_SERVER_KEY` secret, so never commit the real key; `SERVER_KEY` stays `defaultkey` in git.

Versions are `vYYYY.WW.MINOR`, derived from git by `tools/version.sh` (`2026.41.0` on a tag, `2026.41.0+3.g1a2b3c4d` after it); CI stamps it into `project.godot` before building and nobody edits it by hand. Make releases with the **Release** workflow (Actions, Release, Run workflow), which refuses commits whose CI hasn't passed. Commit subjects become the release notes, so write them for players.
