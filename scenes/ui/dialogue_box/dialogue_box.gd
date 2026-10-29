class_name DialogueBox
extends PanelContainer
## What a character says to the dreamer, one line at a time. The dreamer never answers; Interact
## moves on to the next line.

var _player: Player
var _lines := PackedStringArray()
var _next_line := 0
var _when_done := Callable()

@onready var _speaker: Label = %Speaker
@onready var _line: Label = %Line


func _ready() -> void:
	hide()


## Shows [param lines], translation keys, from [param speaker]. Calls [param when_done] after
## the last one.
func say(
	player: Player, speaker: String, lines: PackedStringArray, when_done := Callable()
) -> void:
	_player = player
	_player.busy = true
	_speaker.text = speaker
	_lines = lines
	_next_line = 0
	_when_done = when_done
	show()
	_show_next_line()


# _input rather than _unhandled_input, so the Interact press moves the dialogue on before the
# player's Interactor sees it.
func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		_show_next_line()


func _show_next_line() -> void:
	if _next_line >= _lines.size():
		hide()
		_player.busy = false
		if _when_done.is_valid():
			_when_done.call()
		return
	_line.text = tr(_lines[_next_line])
	_next_line += 1
