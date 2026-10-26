# Dhull Garden

A 3D game built with [Godot](https://godotengine.org).

## Getting started

1. Install **Godot 4.7** (the standard build; the project uses GDScript, not C#).
2. In the Project Manager choose **Import**, then select this folder's `project.godot`.
3. Press **F5** to run. You start in the sandbox level with a third-person character.

The first time the editor opens the project it generates `*.uid` files next to scripts and
`*.import` files next to assets. Commit both: Godot uses them to keep references intact when
files move.

## Controls

| Action  | Keyboard and mouse | Gamepad      |
| ------- | ------------------ | ------------ |
| Move    | WASD / arrow keys  | Left stick   |
| Look    | Mouse              | Right stick  |
| Jump    | Space              | A / Cross    |
| Sprint  | Shift (hold)       | L3 (hold)    |
| Pause   | Esc                | Start        |

Bindings live in **Project > Project Settings > Input Map**. Code refers to actions by name
(`move_forward`, `jump`, …), never to physical keys.

## Project layout

```
autoloads/          Global singletons, registered in Project Settings > Globals
  game.gd           `Game`: pause state and quitting
scenes/
  main/             Entry scene (run/main_scene): the current level plus UI layers
  levels/sandbox/   Greybox test level for trying out movement and mechanics
  player/           Player scene and its controller script
  ui/pause_menu/    Pause overlay
assets/             Shared imported resources, by type
  audio/ fonts/ materials/ models/ textures/
```

Scenes are grouped **by feature**: a scene, its script and any resources only it uses sit
together in one folder. `assets/` is for things shared across features.

## Conventions

- **Naming:** `snake_case` for files and folders, `PascalCase` for node names and
  `class_name`s, `snake_case` for functions and variables, `_leading_underscore` for private
  members. These follow the
  [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- **Static typing:** type every variable, parameter and return value (`:=` where the type is
  obvious). It catches errors in the editor and makes scripts faster.
- **Signals up, calls down:** a node may call methods on its children, but reports to its
  parent or siblings with signals. Cross-scene communication goes through an autoload.
- **Pausing:** call `Game.set_paused()` and listen for `Game.paused_changed`; don't set
  `get_tree().paused` directly. Nodes that must keep running while paused (menus) set
  **Process > Mode** to *Always* or *When Paused*.
- **Physics layers** (named in Project Settings > Layer Names > 3D Physics):

  | Layer | Name   | Used by                                      |
  | ----- | ------ | -------------------------------------------- |
  | 1     | world  | Level geometry. The camera spring arm only collides with this layer. |
  | 2     | player | The player body, so the camera doesn't collide with it. |

- **Greyboxing:** block out levels with CSG nodes (see `sandbox.tscn`) and replace them with
  real meshes once a layout feels right.

## Tooling

[gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) lints and formats GDScript:

```sh
pipx install "gdtoolkit==4.*"
gdlint . && gdformat --check .   # drop --check to apply formatting
```
