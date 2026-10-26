@tool
class_name DreamTree
extends CSGCombiner3D
## Placeholder tree: a crooked trunk and branch under a puffy canopy. Set the materials per
## instance to vary the look.

@export var bark_material: Material:
	set(value):
		bark_material = value
		_apply_materials()
@export var leaves_material: Material:
	set(value):
		leaves_material = value
		_apply_materials()


func _ready() -> void:
	_apply_materials()


func _apply_materials() -> void:
	if not is_node_ready():
		return
	for shape in $Trunk.get_children():
		shape.set("material", bark_material)
	for shape in $Canopy.get_children():
		shape.set("material", leaves_material)
