class_name SplashPuffs
extends Node3D
## Keeps spawning little cartoon clouds that pop up, drift upward and fade, like the jagged
## splash clouds at the foot of a waterfall.

@export var texture: Texture2D
@export_range(0.02, 5.0, 0.01, "suffix:s") var interval := 0.09
@export_range(0.1, 10.0, 0.1, "suffix:s") var lifetime := 1.4
## How far from this node puffs can appear on each axis.
@export var spread := Vector3(1.6, 0.4, 0.8)
## Smallest and largest puff width, in meters.
@export var size_range := Vector2(3.0, 5.5)
@export_range(0.0, 10.0, 0.1, "suffix:m") var rise := 1.6

var _rng := RandomNumberGenerator.new()
var _time_to_next := 0.0


func _process(delta: float) -> void:
	if texture == null:
		return
	_time_to_next -= delta
	while _time_to_next <= 0.0:
		_time_to_next += interval
		_spawn_puff()


func _spawn_puff() -> void:
	var puff := Sprite3D.new()
	puff.texture = texture
	puff.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	puff.shaded = true
	puff.pixel_size = _rng.randf_range(size_range.x, size_range.y) / texture.get_width()
	puff.position = Vector3(
		_rng.randf_range(-spread.x, spread.x),
		_rng.randf_range(-spread.y, spread.y),
		_rng.randf_range(-spread.z, spread.z)
	)
	puff.scale = Vector3.ONE * 0.3
	add_child(puff)

	var tween := puff.create_tween().set_parallel()
	tween.tween_property(puff, "scale", Vector3.ONE, lifetime * 0.35).set_trans(Tween.TRANS_BACK)
	tween.tween_property(puff, "position:y", puff.position.y + rise, lifetime)
	tween.tween_property(puff, "modulate:a", 0.0, lifetime * 0.5).set_delay(lifetime * 0.5)
	tween.chain().tween_callback(puff.queue_free)
