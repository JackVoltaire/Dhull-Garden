class_name MessSpawner
extends Node3D
## Shows the mess lying in this area of the garden, and takes each bit away once it's cleaned up.

const MESS_SCENE := preload("res://scenes/props/mess/mess.tscn")

## The area this level is, as the garden names it.
@export var area := &"dream_island"


func _ready() -> void:
	Garden.mess_changed.connect(_on_mess_changed)
	Garden.garden_replaced.connect(_respawn)
	_respawn()


func _on_mess_changed(changed_area: StringName) -> void:
	if changed_area == area:
		_respawn()


func _respawn() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for bit in Garden.mess_in(area):
		var mess: Mess = MESS_SCENE.instantiate()
		mess.name = bit.id
		mess.record = bit
		add_child(mess)
		mess.global_position = bit.position
		# Each bit lies its own way round, always the same way.
		mess.rotation.y = fmod(float(hash(bit.id)), TAU)
