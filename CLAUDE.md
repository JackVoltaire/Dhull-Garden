# Dhull Garden

Godot 4.7 game in GDScript about raising Dhulls in a garden (Chao Garden successor with
real-world time, Animal Crossing-style events, and 2D/3D minigames). See README.md for layout,
systems and code conventions.

## Naming

- The creatures are **Dhulls**, singular **Dhull**. Use that name in code, data and game text,
  e.g. a `Dhull` class, `data/dhulls/`, `dhull_id`, not "creature" or "pet".
- "Chao" is Sega's name. Keep it out of code, data and game text.

## Workflow

- When a branch's work is done, open a pull request and merge it into `main` yourself.
  Don't wait for a review.
- This project has no CI. Don't add GitHub Actions workflows. Before merging, run
  `gdlint . && gdformat --check .` locally instead, plus the tests:
  `tools/godot.sh --headless --path . res://tests/test_runner.tscn`.
- Run Godot only through `tools/godot.sh`. It downloads and verifies the right version, and
  it's the command `.claude/settings.json` allows.
