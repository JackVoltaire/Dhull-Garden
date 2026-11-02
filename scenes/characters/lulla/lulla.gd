class_name Lulla
extends Node3D
## Lulla, the sleepy, cryptic sheep girl who carries her pillow everywhere. The first time the
## dreamer talks to her she hands over their first egg; after that she mumbles, a line at a time.
## She nods off in the middle of some lines and dozes until she's talked to again, then wakes
## with a start (see LullaTalk); her model acts it all out.

## Translation keys of what she says when the dreamer first meets her. She hands over the egg
## after the last line.
@export var first_meeting := PackedStringArray()
## Translation keys of her mumbling afterwards, one line each time, in turn.
@export var mumbling := PackedStringArray()
## Translation keys of what she says when woken from a doze, one line each time, in turn.
@export var waking := PackedStringArray()
## Translation keys of the lines she nods off on, mid-sentence.
@export var nodding_off := PackedStringArray()

var _talk: LullaTalk

@onready var _interactable: Interactable = $Talk
@onready var _model: LullaModel = $Model/Lulla


func _ready() -> void:
	_talk = LullaTalk.new(first_meeting, mumbling, waking, nodding_off)
	_interactable.interacted.connect(_on_talk)


func _on_talk(player: Player) -> void:
	if _talk.dozing:
		_model.wake()
	var met := Garden.first_egg_given
	var when_done := Callable() if met else _hand_over_egg.bind(player)
	player.listen(tr("CHARACTER_LULLA"), _talk.next_lines(met), when_done, _say)


## Acts out [param line] as it's shown: she says it, and nods off if it's one she nods off on.
func _say(line: String) -> void:
	_model.say(tr(line))
	if _talk.nods_off_on(line):
		_model.nod_off()


## Gives the dreamer their first egg, straight into their arms.
func _hand_over_egg(player: Player) -> void:
	var egg := Garden.give_first_egg(global_position + global_basis.z * 0.7)
	for dhull: Dhull in get_tree().get_nodes_in_group(Dhull.GROUP):
		if dhull.record == egg:
			player.pick_up(dhull)
