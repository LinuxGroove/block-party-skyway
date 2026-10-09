# Block Party: Skyway

Explore every island. Then race through it.

A 3D platformer for Linux handhelds and PCs, built with Godot 4. Design:
[idea 19](https://github.com/LinuxGroove/game-ideas/blob/main/ideas/19-block-party-skyway.md)
in game-ideas.

## How it plays

- **Adventure**: eight worlds of floating islands, joined by the Skyway, a
  rainbow bridge. Each world has an island to explore, four courses behind
  its doors and a boss, with ten stars and a handful of gems to find: help
  the islanders, beat the clock in a silver coin rush, climb to the highest
  point and look off the beaten path. Five stars open the boss's door, and
  beating the boss brings back the Skyway to the next world.
  Falling costs a heart and puts you back at the last flag; nothing found is
  ever lost.

  | World | Its courses | Its boss |
  |---|---|---|
  | Sunny Isles | Saw Mill Sprint, Crab Shore Dash, Windmill Hills, Treetop Hop | Captain Pinch |
  | Frosty Peaks | Ice Rink Rush, Chimney Hop, Toy Train Express, Gift Stack Climb | The Big Chill |
  | Pirate Cove | Dock Dash, Cannon Cove, Shipwreck Climb, Rigging Run | Polly |
  | Spooky Hollow | Crypt Creep, Ghost Bridge, Pumpkin Patch, Haunted Tower | The Night Keeper |
  | Snack Valley | Layer Cake Climb, Donut Hop, Kitchen Dash, Fizzy Crossing | The Hungry Hog |
  | Gear Works | Belt Rush, Piston Climb, Fan Tower, Crusher Row | The Big Press |
  | Sky Castle | Rampart Run, Drawbridge Dash, Spire Climb, Siege Gauntlet | The Siege Tower |
  | Star Station | Moon Hop, Laser Hall, Vent Climb, Orbit Ring | King Thud |

  Beat King Thud and the Skyway leads on to **the Star Road**: Stardust
  Plaza and eight harder courses that mix the worlds, ending in the
  Starlight Finale. Screenshots of every level are in
  [docs/screenshots](docs/screenshots/README.md).
- **Speedrun**: every course Adventure finds is a time trial. A countdown, a
  clock to the hundredth, bronze, silver and gold (and one more for the very
  quick), your best run's ghost beside you, and one button to start again.
- **Moves**: run, jump and double jump, high jump (crouch, then jump), long
  jump (crouch while running, then jump), dive and belly slide, ground pound
  (crouch in the air), and wall kicks.
- **A calm camera**: it sits behind and above and turns slowly at set
  places on each course. The right stick nudges it and it eases back.
  Settings for turn speed, field of view and a camera that follows behind
  you. No camera shake, ever.

When the game starts with the internet on, it tells the LinuxGroove game
server once, so we can count how many people play and on what: a random id
made on the first run, the game's version, the OS and the CPU, and nothing
else. It never signs in, and with no network nothing is sent. Set
`DO_NOT_TRACK=1` to turn it off.

## Controls

Controller first; mouse and keyboard always work.

| Action | Controller | Keyboard and mouse |
|---|---|---|
| Move | Left stick | WASD |
| Nudge the camera | Right stick | Arrow keys |
| Camera behind you | Right stick click | Q or middle click |
| Jump | A | Space |
| Run (hold) | X | Shift |
| Crouch, ground pound | LT or LB | Ctrl or C |
| Dive | RT or RB | F or right click |
| Talk, read | Y | E or Enter |
| Start again (Speedrun) | View / Back | R |
| Pause | Menu / Start | Esc |

## Building and testing

You need Godot 4.7.

```sh
godot --headless --path . --import
godot --headless --path . tools/check_scripts.tscn             # every script compiles
godot --headless --path . tests/run_tests.tscn -- --games=2    # unit tests, every island's stars and boss, bot runs of every course
godot --headless --path . tests/run_tests.tscn -- --world=frosty   # one world's tests
godot --path . -- --play=sunny                                 # straight onto Sunny Isles (or any island or boss)
godot --path . -- --course=sawmill                             # straight into a speedrun of Saw Mill Sprint
```

`tools/screenshot.tscn` saves screenshots of menus and levels without a
screen (run it under `xvfb-run`; options are listed at the top of
`tools/screenshot.gd`). `-- --all=docs/screenshots` remakes every level's
screenshot and the page that lists them.

## Snap

`snapcraft pack` builds a strictly confined snap, `block-party-skyway`, with
the exported game. See [docs/packaging.md](docs/packaging.md).

Pushing to `main` builds the snap and publishes it to the `edge` channel;
a GitHub release publishes to `candidate`. The **Windows and macOS** workflow
exports both from Linux and attaches the zips to releases.

## Layout

| Path | What |
|---|---|
| `game/player/` | The hero (every move on the physics tick), its input and the blob shadow |
| `game/camera/` | The calm camera and the camera zones levels place |
| `game/world/` | `Level` and `Island` (building islands from Kenney blocks in code), bosses and the things in levels |
| `game/levels/` | One folder per world: its data, island, four courses and boss |
| `game/play/` | The play scene (Adventure and Speedrun), worlds, courses and medals, ghosts |
| `game/ui/` | Title, HUD, pause menu, results, how to play |
| `addons/linuxgroove/` | The shared LinuxGroove add-on (settings, input and glyphs, theme, screen fitting, online) |
| `addons/com.heroiclabs.nakama/` | Vendored Nakama client, for online features to come |
| `assets/kenney/` | Kenney packs (CC0) |
| `tests/`, `tools/` | Test runner, each world's tests and the course pilot; script checker, screenshots, versioning and release scripts |
| `docs/screenshots/` | A screenshot of every level |
| `snap/` | Snap packaging |

Code is MIT (see `LICENSE`); assets and other credits in [CREDITS.md](CREDITS.md).
