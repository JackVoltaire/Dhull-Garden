@tool
class_name FloatingIsland
extends CSGCombiner3D
## A floating island: a flat grassy top over a faceted rock underside that tapers to a point.
## The top surface is at this node's origin. Add CSG shapes as children to put hills and rocks
## on it; they merge into the island and share its collision.

## Radius of the top surface, in meters.
@export_range(1.0, 100.0, 0.5, "suffix:m") var radius := 12.0:
	set(value):
		radius = value
		_update()
## How far the rock underside hangs below the top.
@export_range(1.0, 100.0, 0.5, "suffix:m") var depth := 10.0:
	set(value):
		depth = value
		_update()
@export var top_material: Material:
	set(value):
		top_material = value
		_update()
@export var rock_material: Material:
	set(value):
		rock_material = value
		_update()


func _ready() -> void:
	_update()


func _update() -> void:
	if not is_node_ready():
		return
	var top: CSGCylinder3D = $Top
	top.radius = radius
	top.material = top_material
	var underside: CSGCylinder3D = $Underside
	underside.radius = radius * 0.96
	underside.height = depth
	underside.position.y = -top.height - depth / 2.0
	underside.material = rock_material
	var lump: CSGCylinder3D = $Lump
	lump.radius = radius * 0.5
	lump.height = depth * 0.7
	lump.position = Vector3(radius * 0.35, -top.height - depth * 0.35, -radius * 0.2)
	lump.material = rock_material
