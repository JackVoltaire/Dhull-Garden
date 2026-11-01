class_name HeadTurn
extends Resource
## How a character's head is drawn with its face flattened, turned towards the camera and
## flattened along its line of sight, as anime-style 3D games draw heads, so a face keeps the
## shape it was drawn with from every side (see head_turn.gdshaderinc). Only the drawing changes:
## the head stays where it is.

## How far the head turns, at most, towards a camera at its side.
@export_range(0.0, 90.0, 1.0, "suffix:°") var most_sideways := 30.0
## How far the face tips, at most, towards a camera above or below it in front.
@export_range(0.0, 45.0, 1.0, "suffix:°") var most_upward := 15.0
## How deep the head is drawn along the camera's line of sight: 1 as modeled, less is flatter.
@export_range(0.1, 1.0, 0.05) var depth := 0.7
## How deep the front of the head is drawn, from its middle to its face: 1 as modeled, less
## flattens the face, as a flattice does, so it doesn't wrap round the head at an angle.
@export_range(0.1, 1.0, 0.05) var face_depth := 0.5
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
		part.set_instance_shader_parameter(&"head_face_depth", face_depth)
