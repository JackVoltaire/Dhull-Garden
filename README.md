# Dhull Garden

A game about raising Dhulls in a garden, built with [Godot](https://godotengine.org), in the
spirit of the Sonic Adventure 2 Battle Chao Garden. The garden runs on the real-world clock,
with dated events like Animal Crossing, and has minigames in both 2D and 3D.

## Getting started

1. Install **Godot 4.7** (the standard build; the project uses GDScript, not C#).
2. In the Project Manager choose **Import**, then select this folder's `project.godot`.
3. Press **F5** to run. The game continues the save in slot 0 (or starts one) and drops you
   on the dream island, a look-test level, with a third-person character.

The first time the editor opens the project it generates `*.uid` files next to scripts and
`*.import` files next to assets. Commit both: Godot uses them to keep references intact when
files move. The `*.translation` files generated from `localization/strings.csv` are ignored.

## Controls

| Action     | Keyboard and mouse | Gamepad      |
| ---------- | ------------------ | ------------ |
| Move       | WASD / arrow keys  | Left stick   |
| Look       | Mouse              | Right stick  |
| Jump       | Space              | A / Cross    |
| Sprint     | Shift (hold)       | L3 (hold)    |
| Interact   | E                  | X / Square   |
| Pause      | Esc                | Start        |
| Debug menu | F3 (debug builds)  |              |

Bindings live in **Project > Project Settings > Input Map**. Code refers to actions by name
(`move_forward`, `jump`, …), never to physical keys.

## Project layout

```
systems/            Game-wide systems, one folder each. Most are autoloads.
  settings/         `Settings`: player preferences in user://settings.cfg
  clock/            `Clock`: real-world local time, day phases, debug time travel
  calendar/         `Calendar`: dated events and seasons; CalendarEvent resource
  saves/            `Saves`: save slots, backups, migrations, time away
  audio/            `Audio`: music crossfades and one-shot sounds
  scenes/           `Scenes`: fading scene changes with background loading
  minigames/        `Minigames`: launching minigames and returning results; MinigameSpot
  interaction/      Interactable things in the world and the player's Interactor
  game/             `Game`: pausing and quitting
  data/             ResourceDir: loads every resource in a data folder
data/               Game content as .tres resources
  events/           One CalendarEvent per file
  minigames/        One MinigameDefinition per file
scenes/
  main/             Entry scene: loads the save and enters the garden
  levels/           Level, the root script of walkable areas
  levels/dream_island/  Look-test floating island: art direction, sky and effects
  levels/sandbox/   Greybox garden for trying out movement and mechanics
  environment/      SkyCycle (sky and light by time of day), CloudSea, ScreenTexture, and the
                    drawn clouds/ and sun_moon/
  player/           Player scene and its controller script
  props/            Reusable things placed in levels: waterfall/, shiny_spot/, goth_tree/
  minigames/        Minigame scenes. sample/ holds placeholder 2D and 3D minigames
  ui/pause_menu/    Pause overlay (autoload, so it works in every scene)
  debug/            F3 developer menu (autoload, debug builds only)
localization/       strings.csv: every player-facing string, by key and language
tests/              Test runner and unit tests
assets/             Shared imported resources, by type
  models/           One folder per model: <name>.blend (the source) and <name>.glb
  materials/        The toon material palette (toon_*.tres)
  shaders/          stylized_water.gdshader and other shared shaders
  audio/ fonts/ models/ textures/
```

Scenes are grouped **by feature**: a scene, its script and any resources only it uses sit
together in one folder. `assets/` is for things shared across features.

## Systems

Autoloads load in the order listed in Project Settings > Globals; each may use the ones
above it.

- **Real-world time.** Read the time from `Clock` (`now_local()`, `phase()`,
  `day_fraction()`), never from `Time` directly, so time travel works everywhere. Connect to
  `minute_changed`, `hour_changed`, `phase_changed` and `day_changed` to react as time passes.
- **Events.** To add one, create a `CalendarEvent` resource in `data/events/`: a yearly date
  range (which may span New Year), the nth weekday of a month, or a weekday every week, plus
  optional hours. `Calendar` emits `event_started` and `event_ended`, and
  `get_active_events()` tells you what's on now. Seasons follow the
  `game/southern_hemisphere` setting. The four events in `data/events/` are examples.
- **Saving.** Persistent state lives in systems, not in scene nodes, because scenes are freed
  whenever the player switches between the garden and a minigame. A system registers with
  `Saves.register(id, self)` and implements `get_save_data() -> Dictionary` and
  `apply_save_data(data: Dictionary)`. Save files keep exact types (ints stay ints, Vector3s
  survive) and the previous save is kept as a backup. When the data layout changes, bump
  `Saves.VERSION` and add a migration step in `_migrate_step()`. `game_loaded` reports
  `seconds_away`, how long the game was closed, for things that should happen in the
  meantime.
- **Interaction.** The player walks up to things and presses Interact. Anything usable is an
  `Interactable` (an Area3D with a collision shape for its reach and a `prompt` verb); connect
  its `interacted` signal or extend it. The player's `Interactor` picks the nearest one and
  shows "[E] Dig"-style prompts.
- **Minigames.** Create a scene (2D, 3D or UI) and a `MinigameDefinition` in
  `data/minigames/`. To open it from the world, place a `MinigameSpot` (for example an
  instance of `scenes/props/shiny_spot/`) and set its `minigame` and `context`. The minigame
  reads `Minigames.context` and ends with `Minigames.finish({"score": ...})`, which returns the
  player to the exact spot they left from and emits `minigame_finished` with the result. Code
  can also call `Minigames.launch(definition, context)` directly. Running a minigame scene on
  its own with F6 restarts it when it finishes.
- **Scenes.** Change scenes with `Scenes.change_scene(path, params)`. If the new scene's root
  has `setup(params: Dictionary)`, it gets `params` before `_ready()`.
- **Settings.** `Settings.get_value("audio/music_volume")` and `set_value()`; every setting
  and its default is listed in `Settings.DEFAULTS`.
- **Audio.** `Audio.play_music(stream)` crossfades; `Audio.play_sfx(stream)` plays a one-off
  sound. Buses (Music, SFX, Ambience, UI) are in `default_bus_layout.tres`.
- **Text.** Put player-facing text in `localization/strings.csv` and use the key: Controls
  translate their `text` automatically, and in code use `tr("KEY")`. Add a column to add a
  language.
- **Look.** The art direction and moodboard are in the design notes. The toon materials live in
  `assets/materials/`; editing one recolors everything that uses it. Each draws a thin ink
  outline through its **Next Pass**, `toon_ink_outline.tres` (an inverted hull: raise its
  **Grow Amount** for thicker lines). `SkyCycle` colors the sky, sunlight, fog and shadow tint
  from gradients that run from midnight to midnight, and shows the drawn sun by day and the moon
  by night; in the editor, drag its **Preview Hour** to see any time of day. `stylized_water.gdshader` draws the jagged lines
  on water; tune its lanes, jaggedness and dashes per material. Instance
  `scenes/environment/screen_texture.tscn` in a level for film grain, faint scanlines and a
  vignette over the whole screen.
- **Cutouts.** Things on the ground are 3D models, but tree tops, clouds, the sun and the moon
  are 2D drawings, like cardboard cutouts, animated in steps with 3 or 4 frames. The drawings in
  the repo are placeholders. To make one, draw its frames side by side in one image (PNG, or SVG
  like the placeholders), all the same size, and turn on **Mipmaps > Generate** in its import
  settings. A strip can hold several drawings one after another (`variants`); each copy picks
  one. Next to the image, save a QuadMesh resource, shaped like one frame, whose material uses
  `cardboard_cutout.gdshader`, and set the material's `frames`, `frame_count`, `fps` and
  `variants`. Place it with a MeshInstance3D (the tree tops in `scenes/props/goth_tree/`), or a
  `CloudSea` for many clouds. Cutouts face the camera and are lit as if they faced the sky; each
  copy starts on its own frame and may be mirrored. A cutout's shadow is its whole drawing, cast
  towards the light; set `shadow_offset` to about half the mesh's width so it doesn't shadow
  itself. The sun and moon use `sky_cutout.gdshader` instead, which ignores light and fog; they
  hang far out along the Sun light's +Z axis.
- **Debug menu.** F3 shows the date, day phase, season and active events, and has buttons to
  jump the clock forward, save, load, wipe the save, switch levels and launch any minigame.

## Conventions

- **Naming:** `snake_case` for files and folders, `PascalCase` for node names and
  `class_name`s, `snake_case` for functions and variables, `_leading_underscore` for private
  members. These follow the
  [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- **Static typing:** type every variable, parameter and return value (`:=` where the type is
  obvious). It catches errors in the editor and makes scripts faster.
- **Signals up, calls down:** a node may call methods on its children, but reports to its
  parent or siblings with signals. Cross-scene communication goes through an autoload.
- **Content is data:** events, minigames and similar content are `.tres` resources in `data/`,
  found automatically. Give each a stable `id`; it ends up in save files, so never rename it.
- **Pausing:** call `Game.set_paused()` and listen for `Game.paused_changed`; don't set
  `get_tree().paused` directly. Nodes that must keep running while paused (menus) set
  **Process > Mode** to *Always* or *When Paused*.
- **Physics layers** (named in Project Settings > Layer Names > 3D Physics):

  | Layer | Name   | Used by                                      |
  | ----- | ------ | -------------------------------------------- |
  | 1     | world  | Level geometry. The camera spring arm only collides with this layer. |
  | 2     | player | The player body, so the camera doesn't collide with it. |
  | 3     | interactable | Interactables. Only the player's Interactor detects them. |

- **Greyboxing:** block out levels with CSG nodes (see `sandbox.tscn`) and replace them with
  Blender models once a layout feels right.

## Models (Blender)

Models are made in **Blender 5.2 LTS**. Each one lives in its own folder,
`assets/models/<name>/`, as `<name>.blend`, the file you edit, and `<name>.glb`, the export Godot
uses. Godot is set not to read `.blend` files itself, so the project works on machines without
Blender.

1. Edit or create `<name>.blend`.
2. Name each material after a palette file in `assets/materials/`, such as `toon_grass` or
   `toon_bark`. Godot then uses the shared toon material instead of the Blender one.
3. Name objects with a collision suffix where needed: `-col` (the mesh plus matching collision),
   `-convcol` (the mesh plus simpler convex collision), or `-colonly` / `-convcolonly` (an
   invisible collider only).
4. Export with **File > Export > glTF 2.0**, format **glTF Binary (.glb)**, to
   `<name>.glb` in the same folder. The default settings are right (+Y up, apply modifiers).
5. For a new model, after Godot imports it once, run `python3 tools/link_model_materials.py` to
   link its materials to the palette, then let Godot import again.

## Tooling

[gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) lints and formats GDScript:

```sh
pipx install "gdtoolkit==4.*"
gdlint . && gdformat --check .   # drop --check to apply formatting
```

`tools/godot.sh` runs Godot from the command line, passing on all its arguments. On 64-bit
x86 Linux it downloads Godot 4.7.2 the first time, verifies it against the official SHA-512
checksums and caches it in `~/.cache/dhull-garden`. Elsewhere, or to use your own copy, set
`GODOT` to the path of a Godot binary. `.claude/settings.json` lets Claude Code run this
script without asking.

`tools/blender.sh` does the same for Blender 5.2.3 LTS, the version models are made with
(SHA-256 checked; set `BLENDER` to use your own copy). For example,
`tools/blender.sh --background --python script.py` runs a Blender script without the interface.

Tests live in `tests/unit/`: any `test_*.gd` file extending `TestCase`, with `test_*`
methods. Run them all with:

```sh
tools/godot.sh --headless --path . res://tests/test_runner.tscn
```

or open `tests/test_runner.tscn` and press F6. A test fails on a failed assertion or on any
error logged while it runs. The exit code is 1 if anything failed.
