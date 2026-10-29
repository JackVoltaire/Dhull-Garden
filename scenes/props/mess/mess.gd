class_name Mess
extends Node3D
## A bit of mess lying in the garden (see MessRecord): droppings, dirt, grime or clutter that young
## Dhulls left while no adult looked after them. It shows its kind's look, and the player walks up
## to it and cleans it up.

## The mess it shows. Set it before it enters the tree.
var record: MessRecord

@onready var _looks: Dictionary[MessRecord.Kind, Node3D] = {
	MessRecord.Kind.DROPPINGS: $Droppings,
	MessRecord.Kind.DIRT: $Dirt,
	MessRecord.Kind.GRIME: $Grime,
	MessRecord.Kind.CLUTTER: $Clutter,
}
@onready var _clean_up: Interactable = $CleanUp


func _ready() -> void:
	for kind in _looks:
		_looks[kind].visible = kind == record.kind
	_clean_up.interacted.connect(_on_clean_up)


func _physics_process(_delta: float) -> void:
	# Mess lands wherever the young Dhull was, so settle it onto the ground once physics can say
	# where that is.
	global_position = Ground.below(self, global_position)
	set_physics_process(false)


func _on_clean_up(_player: Player) -> void:
	Garden.clean_up(record)
