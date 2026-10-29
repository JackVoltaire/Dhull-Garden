class_name Lulla
extends Node3D
## Lulla, the sleepy, cryptic goat girl who carries her pillow everywhere. The first time the
## dreamer talks to her she hands over their first egg; after that she mumbles, a line at a time.
## Her look is a placeholder.

## Translation keys of what she says when the dreamer first meets her. She hands over the egg
## after the last line.
@export var first_meeting := PackedStringArray()
## Translation keys of her mumbling afterwards, one line each time, in turn.
@export var mumbling := PackedStringArray()

var _next_mumble := 0

@onready var _talk: Interactable = $Talk


func _ready() -> void:
	_talk.interacted.connect(_on_talk)


func _on_talk(player: Player) -> void:
	if not Garden.first_egg_given:
		player.listen(tr("CHARACTER_LULLA"), first_meeting, _hand_over_egg.bind(player))
		return
	player.listen(tr("CHARACTER_LULLA"), PackedStringArray([mumbling[_next_mumble]]))
	_next_mumble = (_next_mumble + 1) % mumbling.size()


## Gives the dreamer their first egg, straight into their arms.
func _hand_over_egg(player: Player) -> void:
	var egg := Garden.give_first_egg(global_position + global_basis.z * 0.7)
	for dhull: Dhull in get_tree().get_nodes_in_group(Dhull.GROUP):
		if dhull.record == egg:
			player.pick_up(dhull)
