#!/usr/bin/env python3
"""Links model materials to the shared toon palette.

For every .glb under assets/models/, any material named like a palette file in
assets/materials/, a toon_*.tres (e.g. a Blender material called "toon_grass"), is set to use
that .tres file instead of the material inside the .glb. Other materials there, like ink_hull,
are passes other materials use, not ones a model is painted with. This rewrites the "_subresources" line of each .glb.import file that
isn't linked yet, so run it after Godot has imported a new model or a new palette material has
been added, then let Godot import again:

    python3 tools/link_model_materials.py
    tools/godot.sh --headless --path . --import
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PALETTE = sorted(path.stem for path in (ROOT / "assets" / "materials").glob("toon_*.tres"))
IMPORTED = ROOT / ".godot" / "imported"


def subresources_line() -> str:
    entries = ",\n".join(
        f'"{name}": {{\n"use_external/enabled": true,\n'
        f'"use_external/path": "res://assets/materials/{name}.tres"\n}}'
        for name in PALETTE
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
    linked = subresources_line().split("\n")
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
