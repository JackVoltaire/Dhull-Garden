#!/usr/bin/env python3
"""Links model materials to the shared toon palette.

For every .glb under assets/models/, each material it uses that's named like a palette file in
assets/materials/ (e.g. a Blender material called "toon_grass") is set to use that .tres file
instead of the material inside the .glb. The palette is the toon_*.tres colors and the
face_*.tres faces; the other files there, like ink_hull, are passes other materials use. This
rewrites the "_subresources" line of each .glb.import file that isn't linked yet, so run it
after Godot has imported a new model or a model uses a new palette material, then let Godot
import again:

    python3 tools/link_model_materials.py
    tools/godot.sh --headless --path . --import
"""

import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MATERIALS = ROOT / "assets" / "materials"
PALETTE = sorted(path.stem for pattern in ("toon_*.tres", "face_*.tres") for path in MATERIALS.glob(pattern))
IMPORTED = ROOT / ".godot" / "imported"


def used_materials(model: Path) -> set[str]:
    """The names of the materials a .glb uses, from its JSON chunk."""
    data = model.read_bytes()
    # A 12-byte header, then the JSON chunk's length and type, then the JSON.
    (length,) = struct.unpack_from("<I", data, 12)
    document = json.loads(data[20:20 + length])
    return {material.get("name", "") for material in document.get("materials", [])}


def subresources_line(model: Path) -> str:
    # Only the model's own materials, so a new palette file doesn't touch every other model.
    used = used_materials(model)
    entries = ",\n".join(
        f'"{name}": {{\n"use_external/enabled": true,\n'
        f'"use_external/path": "res://assets/materials/{name}.tres"\n}}'
        for name in PALETTE
        if name in used
    )
    return '_subresources={\n"materials": {\n' + entries + "\n}\n}"


def without_fallbacks(lines: list[str]) -> list[str]:
    # Godot adds a fallback path to each linked material when it imports; it changes nothing.
    return [line for line in lines if "use_external/fallback_path" not in line]


def link(import_file: Path) -> bool:
    """Links one model's materials. Returns False if they were linked already."""
    lines = import_file.read_text().split("\n")
    start = next(i for i, line in enumerate(lines) if line.startswith("_subresources="))
    # The value runs until the next "key=" line; a dictionary spans several lines.
    end = start + 1
    while end < len(lines) and "=" not in lines[end].split('"')[0]:
        end += 1
    linked = subresources_line(import_file.with_suffix("")).split("\n")
    if without_fallbacks(lines[start:end]) == linked:
        return False
    lines[start:end] = linked
    # Godot writes these files with LF endings; Python on Windows would write CRLF.
    import_file.write_text("\n".join(lines), newline="\n")
    # Godot doesn't always notice an edited .import file and can keep the model's old import,
    # with the materials from inside the .glb. Dropping that import makes the next one redo it.
    model_name = import_file.name.removesuffix(".import")
    for cached in IMPORTED.glob(f"{model_name}-*"):
        cached.unlink()
    return True


if __name__ == "__main__":
    for path in sorted((ROOT / "assets" / "models").rglob("*.glb.import")):
        if link(path):
            print("linked", path.relative_to(ROOT))
