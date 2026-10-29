class_name DhullColoring
extends Resource
## How a Dhull is colored: a color for each of its parts, the color its nubs turn towards at the
## tips, and an optional pattern on its body. A Dhull applies it to its parts through the clay
## shader's instance uniforms, so Dhulls can differ while sharing one material.

## Numbered as in clay.gdshader.
enum Pattern { NONE, DIAMONDS, SPOTS, STRIPES }

## Stable name that saves refer to it by. Never rename it.
@export var id: StringName
@export var body_color := Color(1.0, 0.83, 0.25)
@export var head_color := Color(1.0, 0.83, 0.25)
## The left arm and the right leg.
@export var limb_color := Color(1.0, 0.83, 0.25)
## The right arm and the left leg. A color unlike [member limb_color] crosses over like a
## harlequin's.
@export var other_limb_color := Color(1.0, 0.83, 0.25)
@export var tip_color := Color(1.0, 0.55, 0.25)
@export var body_pattern := Pattern.NONE
@export var pattern_color := Color(0.36, 0.24, 0.8)
