# Dhull Garden

Godot 4.7 game in GDScript about raising Dhulls in a garden (Chao Garden successor with
real-world time, Animal Crossing-style events, and 2D/3D minigames). See README.md for layout,
systems and code conventions.

## Design

- The design lives in the Claude Doc "Dhull — Design Notes":
  https://claude.ai/artifact/4HbX4xyVneZZ749Qy3PWDE. Read it with the docs tools before
  working on gameplay, the island or the Dhulls.
- Its "Idea bits" are brainstorm suggestions, not decisions. Don't build them unless asked.

## Naming

- The creatures are **Dhulls**, singular **Dhull**. Use that name in code, data and game text,
  e.g. a `Dhull` class, `data/dhulls/`, `dhull_id`, not "creature" or "pet".
- "Chao" is Sega's name. Keep it out of code, data and game text.

## Workflow

- Commit and push as you go, with a pull request open for the branch. Merge it into `main`
  yourself once a few commits have built up, not after every change. Don't wait for a review.
- This project has no CI. Don't add GitHub Actions workflows. Before merging, run
  `gdlint . && gdformat --check .` locally instead, plus the tests:
  `tools/godot.sh --headless --path . res://tests/test_runner.tscn`.
- Run Godot only through `tools/godot.sh`, and Blender only through `tools/blender.sh`. They
  download and verify the right versions, and they're the commands `.claude/settings.json`
  allows.
- Models: the `.blend` in `assets/models/<name>/` is the source. Change models by running Blender
  scripts on it (`tools/blender.sh --background <file>.blend --python <script>`), save it, and
  re-export the `.glb` next to it. See "Models (Blender)" in README.md.
