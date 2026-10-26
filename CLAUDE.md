# Dhull Garden

Godot 4.7 creature-raising garden game in GDScript (Chao Garden successor with real-world
time, Animal Crossing-style events, and 2D/3D minigames). See README.md for layout, systems and
code conventions.

## Workflow

- When a branch's work is done, open a pull request and merge it into `main` yourself.
  Don't wait for a review.
- This project has no CI. Don't add GitHub Actions workflows. Before merging, run
  `gdlint . && gdformat --check .` locally instead, plus the tests:
  `tools/godot.sh --headless --path . res://tests/test_runner.tscn`.
- Run Godot only through `tools/godot.sh`. It downloads and verifies the right version, and
  it's the command `.claude/settings.json` allows.
