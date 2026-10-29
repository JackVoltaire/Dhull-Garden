class_name Pebble
extends Node3D
## Pebble, the nervous crow merchant who loves anything shiny. He buys the dreamer's finds and
## sells everyday things, from the garden's second day on; before that he isn't ready. His look
## is a placeholder.

## The day of the garden, counting its first as 1, from which his shop is open.
@export_range(1, 30) var opens_on_day := 2
## Translation keys of what he says while the shop isn't open yet, one line each time, in turn.
@export var not_open_yet := PackedStringArray()
## Translation keys of his greetings once it's open, one each time, in turn, before the shop.
@export var greetings := PackedStringArray()

var _next_line := 0

@onready var _talk: Interactable = $Talk


func _ready() -> void:
	_talk.interacted.connect(_on_talk)


func _on_talk(player: Player) -> void:
	var is_open := Garden.day_of_garden() >= opens_on_day
	var lines := greetings if is_open else not_open_yet
	var line := PackedStringArray([lines[_next_line % lines.size()]])
	_next_line += 1
	if is_open:
		player.listen(tr("CHARACTER_PEBBLE"), line, player.shop)
	else:
		player.listen(tr("CHARACTER_PEBBLE"), line)
