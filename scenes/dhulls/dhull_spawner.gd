class_name DhullSpawner
extends Node3D
## Puts a Dhull in the level for each Dhull in the garden that lives in this area. Dhulls the
## garden hasn't placed yet appear at this node's Marker3D children, one after another.

const DHULL_SCENE := preload("res://scenes/dhulls/dhull.tscn")

## The area this level is, as Dhulls' home areas name it.
@export var area := &"dream_island"


func _ready() -> void:
	Garden.garden_replaced.connect(_respawn)
	Garden.dhull_added.connect(_on_dhull_added)
	_spawn()


func _on_dhull_added(record: DhullRecord) -> void:
	if record.home_area == area:
		_spawn_one(record, find_children("*", "Marker3D", false), 0)


func _respawn() -> void:
	for child in get_children():
		if child is Dhull:
			remove_child(child)
			child.queue_free()
	_spawn()


func _spawn() -> void:
	var spawn_points: Array[Node] = find_children("*", "Marker3D", false)
	var next_spawn_point := 0
	for record in Garden.dhulls_in(area):
		if not record.placed:
			next_spawn_point += 1
		_spawn_one(record, spawn_points, next_spawn_point - 1)


## Puts [param record]'s Dhull in the level. If it hasn't been placed yet, it goes to the spawn
## point numbered [param spawn_point], counting round.
func _spawn_one(record: DhullRecord, spawn_points: Array[Node], spawn_point: int) -> void:
	if not record.placed:
		var spot: Node3D = self
		if not spawn_points.is_empty():
			spot = spawn_points[spawn_point % spawn_points.size()]
		record.position = spot.global_position
		record.facing = spot.global_rotation.y
		record.placed = true
	var dhull: Dhull = DHULL_SCENE.instantiate()
	dhull.name = record.id
	dhull.record = record
	add_child(dhull)
	dhull.global_position = record.position
	dhull.global_rotation.y = record.facing
