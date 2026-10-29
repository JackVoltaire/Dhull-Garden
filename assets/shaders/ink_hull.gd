class_name InkHull
extends RefCounted
## The script side of ink_hull.gdshader, the ink outline round each part of a character.


## Tells each of [param parts]' outlines where the part's middle is, to grow it out from there.
static func center_outlines(parts: Array[Node]) -> void:
	for part: MeshInstance3D in parts:
		part.set_instance_shader_parameter(&"outline_center", part.mesh.get_aabb().get_center())
