class_name HeadTurn
extends Resource
## How a character's head is drawn turned towards the camera, so a face keeps the shape it was
## drawn with from every side, as in anime-style 3D games, and squashed towards it, as the
## Flattice add-on for Blender squashes it, so it's seen without perspective, like a drawing (see
## head_turn.gdshaderinc). Only the drawing changes: the head stays where it is.

## How far the head turns, at most, towards a camera at its side.
@export_range(0.0, 90.0, 1.0, "suffix:°") var most_sideways := 30.0
## How far the face tips, at most, towards a camera above or below it in front.
@export_range(0.0, 45.0, 1.0, "suffix:°") var most_upward := 15.0
## How deep the head is drawn along the line of sight, the flattice: 1 as modeled, 0 flat. The
## flatter, the less perspective swells the near side of the face, which shows up close.
@export_range(0.0, 1.0, 0.05) var depth := 0.1
## How far the head is shaded like a ball rather than by its own facets, for big, simple shapes
## of light and shade.
@export_range(0.0, 1.0, 0.05) var roundness := 0.5


## Turns [param head] and every part on it, like hair and a face, the same way, so they stay
## together.
func apply(head: GeometryInstance3D) -> void:
	var turn := Vector2(deg_to_rad(most_sideways), deg_to_rad(most_upward))
	var parts: Array[Node] = [head]
	parts.append_array(head.find_children("*", "GeometryInstance3D", true, false))
	for part: GeometryInstance3D in parts:
		part.set_instance_shader_parameter(&"head_turn", turn)
		part.set_instance_shader_parameter(&"head_depth", depth)
		part.set_instance_shader_parameter(&"head_roundness", roundness)
