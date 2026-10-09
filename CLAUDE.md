# Block Party: Skyway

A 3D platformer for one player (Adventure across floating islands, and Speedrun on the courses Adventure finds), in Godot 4.7 with GDScript, built from Kenney's Platformer Kit. The concept is idea 19 in [game-ideas](https://github.com/LinuxGroove/game-ideas/blob/main/ideas/19-block-party-skyway.md). It shares the LinuxGroove add-on with the other games; **read game-ideas' [online-addon.md](https://github.com/LinuxGroove/game-ideas/blob/main/online-addon.md) before touching online features or the shared add-on.**

## Commands

```sh
godot --headless --path . --import
godot --headless --path . tools/check_scripts.tscn                  # every script compiles
godot --headless --path . tests/run_tests.tscn -- --games=2         # unit tests, the island's stars and bot runs of the course
godot --headless --path . tests/run_tests.tscn -- --only=_test_island   # one test
godot --path . -- --play=sunny                                      # straight onto an island
godot --path . -- --course=sawmill                                  # straight into a speedrun
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 tools/screenshot.tscn -- /tmp/shot.png course=sawmill
```

Run the script check and the tests before every commit. A new `class_name` needs an `--import` before the script check finds it. Headless runs reimport assets and rewrite many `*.glb.import` files and `icon.png.import`; revert those (`git checkout -- '*.import'`, `rm icon.png.import`) unless you meant to change them.

## Layout

| Path | What |
|---|---|
| `game/game_config.gd` | `GAME_ID`, the astronauts, setting defaults (camera comfort), music, input map |
| `game/player/` | `Hero` (every move, on the physics tick), `HeroInput` (one tick of controls; tests fill it), `BlobShadow` |
| `game/camera/` | `SkyCamera` (the calm camera) and `CameraZone` (an angle for part of a level) |
| `game/world/` | `Kit` (Kenney models and layers), `Level` (islands in code), `things/` (pickups, crates, springs, saws, spikes, platforms, crabs, islanders, flags, doors, the Skyway bridge) |
| `game/levels/` | One script per island or course: `SunnyIsle`, `SawMillSprint` |
| `game/play/` | `Play` (one visit to a level, Adventure or Speedrun), `Worlds` (stars and gems per world), `Courses` (medal times), `Ghost` and `GhostRunner`, `Levels` |
| `game/progress.gd` | `Progress` autoload: stars, gems, coins, found courses, best times (user://progress.cfg) and ghosts (user://ghosts/) |
| `game/ui/` | Title (with a backdrop of the island), HUD, pause menu, results, how to play |
| `addons/linuxgroove/` | Shared LinuxGroove add-on |
| `addons/com.heroiclabs.nakama/` | Vendored Nakama client with a local patch (see its `VENDORED.md`) |
| `tests/run_tests.gd` | Headless test runner; add checks with `check(ok, "what")` |
| `tests/course_pilot.gd` | Drives the hero along legs (run, jump, steer to a landing spot, wall kicks), for course and island tests |
| `tools/` | Script checker, screenshots, `version.sh`, `release.sh` |

## How the game is built

- **Levels are code.** A level extends `Level` and builds in `build()`: `land(x0, z0, x1, z1, top, depth)` lays grass blocks on whole metres with one box of collision, `ledge()` a thin slab, `ramp()` a slope that rises 0.76 (the hero steps up the rest), `add(thing, at)` places a thing, `camera_zone()` sets the camera for a box. `finish()` batches the blocks into MultiMeshes. X runs east, Z south; courses mostly run north (-z). Speedrun builds the same course without coins, checkpoints or the gem (`is_speedrun()`).
- **The hero** is a `CharacterBody3D` with its own state machine (ground, air, wall, dive, slide, pound, hurt, locked), tuned in constants at the top of `hero.gd`. Kenney's rig has no clips for dives, slides and flips, so the body is tipped in code. `Hero.step()` reads `hero.input`, which `Play` fills from the controls each tick and tests and the pilot fill themselves.
- **The camera is gentle on purpose** (some players get motion sick): behind and above, angles set per area by `CameraZone`s with slow blends, the right stick only nudges it and it eases back, open areas let it turn freely, and the follow-behind mode is a setting. Never add camera shake, head bob or quick cuts; keep turn speed, field of view and follow in the comfort settings.
- **Layers**: 1 world, 2 hero, 4 pickups. Things that react to the hero are `Area3D`s with mask 2; set `monitorable` in `_init()`, since things get added from inside physics signals. Levels set `DISABLE_MODE_KEEP_ACTIVE` on their bodies so the speedrun countdown can pause a level without the floor disappearing.
- **Stars and gems** are ids like `sunny/tower`, listed per world in `Worlds` and per course in `Courses`; `_test_data` checks every listed one is placed. Course medal times come from the pilot's run (gold or better) printed by the tests; Patrol, the fourth medal, is a little under it.
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
