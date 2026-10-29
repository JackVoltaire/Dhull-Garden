class_name MessRecord
extends RefCounted
## A bit of mess in the garden, left by young Dhulls while no adult looked after them, until the
## player cleans it up. The Garden autoload keeps and saves it; a level's MessSpawner shows it.

enum Kind { DROPPINGS, DIRT, GRIME, CLUTTER }

## Stable and unique in a garden.
var id: StringName
var kind := Kind.DIRT
var area: StringName
var position := Vector3.ZERO


## The mess as saved. The kind is saved by name, so reordering it never breaks a save.
func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"kind": Kind.keys()[kind],
		"area": String(area),
		"position": position,
	}


static func from_dict(data: Dictionary) -> MessRecord:
	var mess := MessRecord.new()
	mess.id = StringName(data.get("id", ""))
	mess.kind = Kind.get(data.get("kind", ""), Kind.DIRT)
	mess.area = StringName(data.get("area", ""))
	var saved_position: Variant = data.get("position")
	if saved_position is Vector3:
		mess.position = saved_position
	return mess
