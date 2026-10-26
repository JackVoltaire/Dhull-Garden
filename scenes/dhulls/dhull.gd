class_name Dhull
extends Node3D
## A Dhull: a smooth, clay-like body with its head floating close above it in a nebula mist. The
## face is drawn on the head from swappable eye and mouth images, like Wind Waker's, showing its
## [member emotion]. The head bobs gently and the eyes blink now and then. The arms, legs and tail
## are separate parts that swing from their joints; the AnimationPlayer plays an idle loop.

## The emotion its face shows.
@export var emotion := DhullFace.Emotion.NEUTRAL:
	set(value):
		emotion = value
		if is_node_ready():
			_show_face()
## Its everyday eyes, when no emotion swaps in eyes of its own.
@export var eye_style := DhullFace.EyeStyle.ROUND:
	set(value):
		eye_style = value
		if is_node_ready():
			_show_face()
## The colors of its clay; Sunny unless set. Without one, it keeps the clay shader's defaults.
@export var coloring: DhullColoring:
	set(value):
		coloring = value
		if is_node_ready():
			_apply_coloring()
## Draws the face on the head; see dhull_face.gdshader.
@export var face_material: Material
## How far the head bobs up and down, and how many times a second.
@export_range(0.0, 0.2, 0.005, "suffix:m") var head_bob_height := 0.02
@export_range(0.0, 3.0, 0.05) var head_bob_rate := 0.4
## Seconds between blinks, picked at random between x and y, and how long a blink lasts.
@export var blink_interval := Vector2(2.0, 5.0)
@export_range(0.05, 1.0, 0.01, "suffix:s") var blink_duration := 0.14

var _blinking := false
var _until_blink_change := 0.0
var _time := 0.0
var _rng := RandomNumberGenerator.new()

@onready var _head: MeshInstance3D = $Model/Head
@onready var _head_rest := _head.position
@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_rng.randomize()
	# Start each Dhull at its own point in its idle, bob and blinks, so a group isn't in step.
	_time = _rng.randf() * 10.0
	_until_blink_change = _rng.randf_range(blink_interval.x, blink_interval.y)
	_animation_player.seek(_rng.randf() * _animation_player.current_animation_length, true)
	_head.material_overlay = face_material
	_show_face()
	_apply_coloring()


func _process(delta: float) -> void:
	_time += delta
	_head.position = _head_rest + Vector3.UP * sin(_time * TAU * head_bob_rate) * head_bob_height
	_until_blink_change -= delta
	if _until_blink_change <= 0.0:
		_blinking = not _blinking
		if _blinking:
			_until_blink_change = blink_duration
		else:
			_until_blink_change = _rng.randf_range(blink_interval.x, blink_interval.y)
		_show_face()


func _show_face() -> void:
	_head.set_instance_shader_parameter(
		&"eye_frame", DhullFace.eyes_for(emotion, eye_style, _blinking)
	)
	_head.set_instance_shader_parameter(&"mouth_frame", DhullFace.mouth_for(emotion))


func _apply_coloring() -> void:
	if coloring == null:
		return
	_paint($Model/Body, coloring.body_color, coloring.body_pattern)
	_paint($Model/Body/Tail, coloring.body_color)
	_paint(_head, coloring.head_color)
	_paint($Model/Body/ArmLeft, coloring.limb_color)
	_paint($Model/Body/LegRight, coloring.limb_color)
	_paint($Model/Body/ArmRight, coloring.other_limb_color)
	_paint($Model/Body/LegLeft, coloring.other_limb_color)


func _paint(part: GeometryInstance3D, color: Color, pattern := DhullColoring.Pattern.NONE) -> void:
	part.set_instance_shader_parameter(&"part_color", color)
	part.set_instance_shader_parameter(&"tip_color", coloring.tip_color)
	part.set_instance_shader_parameter(&"pattern", pattern)
	part.set_instance_shader_parameter(&"pattern_color", coloring.pattern_color)
