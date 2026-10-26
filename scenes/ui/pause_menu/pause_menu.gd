extends CanvasLayer
## Pause overlay. It only shows and hides; [code]Game[/code] owns the actual pause state.

@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(Game.set_paused.bind(false))
	_quit_button.pressed.connect(Game.quit)
	Game.paused_changed.connect(_on_paused_changed)


func _on_paused_changed(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		# Focus a button so the menu can be driven with a gamepad.
		_resume_button.grab_focus()
