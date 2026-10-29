class_name NamePrompt
extends PanelContainer
## Asks the dreamer to name a newly hatched Dhull: the one thing they ever type in the game.

var _player: Player
var _dhull: Dhull

@onready var _name: LineEdit = %Name
@onready var _ok: Button = %Ok


func _ready() -> void:
	hide()
	_ok.pressed.connect(_accept)
	_name.text_submitted.connect(_accept.unbind(1))
	_name.text_changed.connect(_on_text_changed)


func open(dhull: Dhull, player: Player) -> void:
	_dhull = dhull
	_player = player
	_player.busy = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_name.clear()
	_ok.disabled = true
	show()
	_name.grab_focus()


func _on_text_changed(text: String) -> void:
	_ok.disabled = text.strip_edges().is_empty()


func _accept() -> void:
	var chosen := _name.text.strip_edges()
	if chosen.is_empty():
		return
	_dhull.record.name = chosen
	hide()
	_player.busy = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
