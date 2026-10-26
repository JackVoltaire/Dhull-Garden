extends Node
## Placeholder minigame, shared by the 2D and 3D samples to show the minigame flow end to end:
## press Jump as often as you can before time runs out. Replace with real minigames.

const DURATION := 10.0

var _score := 0
var _time_left := DURATION
var _bounce: Tween

@onready var _toy: Node = %Toy
@onready var _label: Label = %Label
# The toy is a Node2D or a Node3D, so this is a Vector2 or a Vector3.
@onready var _toy_scale: Variant = _toy.scale


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		set_process(false)
		set_process_unhandled_input(false)
		Minigames.finish({"score": _score})
		return
	_label.text = tr("MINIGAME_SAMPLE_HUD") % [_score, ceili(_time_left)]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_score += 1
		if _bounce:
			_bounce.kill()
		_bounce = create_tween()
		_bounce.tween_property(_toy, "scale", _toy_scale * 1.3, 0.05)
		_bounce.tween_property(_toy, "scale", _toy_scale, 0.15)
