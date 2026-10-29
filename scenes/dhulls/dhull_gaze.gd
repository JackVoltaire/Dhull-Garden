class_name DhullGaze
extends Node
## Moves a Dhull's irises to look at things. Every so often it glances about for whatever catches
## its eye most among the Lookables nearby (see DhullLooking), and its irises follow that as it or
## the thing moves. What the Dhull is busy with can hold its eyes instead, like its phone as it
## scrolls.

## Its own face, left out when it glances about.
@export var own_lookable: Lookable
## How far off things still catch its eye.
@export_range(0.5, 30.0, 0.5, "suffix:m") var reach := 5.0
## How far off to the side it notices things, either way from straight ahead.
@export_range(0.0, 180.0, 1.0, "suffix:°") var field_degrees := 80.0
## How far it turns its eyes before its irises are as far over as they go.
@export_range(5.0, 90.0, 1.0, "suffix:°") var turn_limit_degrees := 45.0
## Seconds between glances about, picked at random between x and y.
@export var glance_interval := Vector2(1.0, 3.5)
## How much more something else has to catch its eye before it looks away from what it's
## looking at, from 0 to 1.
@export_range(0.0, 1.0, 0.05) var stickiness := 0.15
## How fast its irises move, in their full reach per second.
@export_range(0.5, 40.0, 0.5) var eye_speed := 10.0

## The head its face is drawn on. The Dhull sets it whenever it builds its head.
var face: GeometryInstance3D:
	set(value):
		face = value
		if face:
			face.set_instance_shader_parameter(&"look", _look)
## What holds its eyes, whatever else is about, or null to look about.
var held_by: Node3D

var _looking_at: Lookable
var _look := Vector2.ZERO
var _rng := RandomNumberGenerator.new()

@onready var _glance_timer: Timer = $GlanceTimer


func _ready() -> void:
	_rng.randomize()
	_glance_timer.timeout.connect(_glance)
	_glance()


func _process(delta: float) -> void:
	if face == null:
		return
	var target: Node3D = held_by if held_by else _looking_at
	var wanted := Vector2.ZERO
	if is_instance_valid(target):
		var turn_limit := deg_to_rad(turn_limit_degrees)
		wanted = DhullLooking.look_toward(face.global_transform, target.global_position, turn_limit)
	if wanted == _look:
		return
	_look = _look.move_toward(wanted, eye_speed * delta)
	face.set_instance_shader_parameter(&"look", _look)


func _glance() -> void:
	_glance_timer.start(_rng.randf_range(glance_interval.x, glance_interval.y))
	if face == null:
		return
	var lookables: Array[Lookable] = []
	var appeals := PackedFloat32Array()
	var current := -1
	for lookable: Lookable in get_tree().get_nodes_in_group(Lookable.GROUP):
		if lookable == own_lookable:
			continue
		if lookable == _looking_at:
			current = lookables.size()
		lookables.append(lookable)
		appeals.append(
			DhullLooking.appeal(
				face.global_transform,
				lookable.global_position,
				lookable.interest,
				reach,
				deg_to_rad(field_degrees)
			)
		)
	var picked := DhullLooking.pick(appeals, current, stickiness)
	_looking_at = lookables[picked] if picked >= 0 else null
