#!/usr/bin/env python3
"""Links model materials to the shared toon palette.

For every .glb under assets/models/, any material named like a file in assets/materials/
(e.g. a Blender material called "toon_grass") is set to use that .tres file instead of the
material inside the .glb. This rewrites the "_subresources" line of each .glb.import file, so
run it after Godot has imported a new model, then let Godot import again:

    python3 tools/link_model_materials.py
    tools/godot.sh --headless --path . --import
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Outline materials are next passes of the palette, not materials of their own.
PALETTE = sorted(
    path.stem
    for path in (ROOT / "assets" / "materials").glob("*.tres")
    if not path.stem.endswith("_outline")
)


def subresources_line() -> str:
    entries = ",\n".join(
        f'"{name}": {{\n"use_external/enabled": true,\n'
        f'"use_external/path": "res://assets/materials/{name}.tres"\n}}'
        for name in PALETTE
    )
    return '_subresources={\n"materials": {\n' + entries + "\n}\n}"


def link(import_file: Path) -> None:
    lines = import_file.read_text().split("\n")
    start = next(i for i, line in enumerate(lines) if line.startswith("_subresources="))
    # The value runs until the next "key=" line; a dictionary spans several lines.
    end = start + 1
    while end < len(lines) and "=" not in lines[end].split('"')[0]:
        end += 1
    lines[start:end] = subresources_line().split("\n")
    import_file.write_text("\n".join(lines))
    print("linked", import_file.relative_to(ROOT))


if __name__ == "__main__":
    for path in sorted((ROOT / "assets" / "models").rglob("*.glb.import")):
        link(path)
