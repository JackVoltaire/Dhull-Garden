class_name Player
extends CharacterBody3D
## Third-person character: camera-relative movement, sprinting and jumping,
## with an orbiting camera driven by the mouse or the right stick.
##
## The body itself never rotates. [code]Model[/code] turns to face the movement direction
## and [code]CameraPivot[/code] turns with the camera, so the two stay independent.
##
## The player cares for Dhulls in person through the care menu, and can carry one in front of
## them and put it down again.

@export_group("Movement")
@export var walk_speed := 5.0
@export var sprint_speed := 8.0
## How quickly the character reaches its target speed, in m/s².
@export var acceleration := 40.0
## Fraction of [member acceleration] available while airborne.
@export_range(0.0, 1.0) var air_control := 0.3
@export var jump_velocity := 4.5
## How quickly [code]Model[/code] turns to face the movement direction.
@export var turn_speed := 12.0

@export_group("Camera")
## Radians per pixel of mouse movement, before the player's sensitivity setting is applied.
@export var mouse_sensitivity := 0.003
## Gamepad look speed in radians per second at full stick deflection.
@export var stick_sensitivity := 3.0
@export_range(-89.0, 0.0) var min_pitch_degrees := -70.0
@export_range(0.0, 89.0) var max_pitch_degrees := 30.0

@export_group("Carrying")
## How far in front of the player a carried Dhull is put down.
@export_range(0.2, 3.0, 0.05, "suffix:m") var put_down_distance := 0.9

## While a menu is open the player stands still and the camera stays put.
var busy := false

var _carried: Dhull
var _carried_from: Node

@onready var _model: Node3D = $Model
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _carry_point: Marker3D = $Model/CarryPoint
@onready var _care_menu: CareMenu = %CareMenu


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if busy:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# screen_relative ignores window stretching, so sensitivity doesn't change with window size.
		var setting: float = Settings.get_value("controls/mouse_sensitivity")
		_rotate_camera(-event.screen_relative * mouse_sensitivity * setting)
	elif event is InputEventMouseButton and event.pressed:
		# Recapture the cursor after it was released, e.g. by alt-tabbing.
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var look_input := Vector2.ZERO
	var move_input := Vector2.ZERO
	if not busy:
		look_input = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_rotate_camera(-look_input * stick_sensitivity * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta
	elif not busy and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Rotate the input by the camera's yaw so "forward" always points away from the camera.
	var direction := Vector3(move_input.x, 0.0, move_input.y).rotated(
		Vector3.UP, _camera_pivot.rotation.y
	)
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var accel := acceleration if is_on_floor() else acceleration * air_control
	var horizontal_velocity := Vector2(velocity.x, velocity.z).move_toward(
		Vector2(direction.x, direction.z) * speed, accel * delta
	)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y

	move_and_slide()

	if not direction.is_zero_approx():
		# Model faces -Z, Godot's forward axis.
		var target_yaw := atan2(-direction.x, -direction.z)
		var turn_weight := 1.0 - exp(-turn_speed * delta)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_weight)


## Opens the care menu for [param dhull].
func care_for(dhull: Dhull) -> void:
	_care_menu.open(dhull, self)


func is_carrying() -> bool:
	return _carried != null


## Picks [param dhull] up and carries it on the player's shoulders, looking where they go.
func pick_up(dhull: Dhull) -> void:
	_carried = dhull
	_carried_from = dhull.get_parent()
	dhull.carried = true
	dhull.reparent(_carry_point, false)
	dhull.position = Vector3.ZERO
	dhull.rotation = Vector3.ZERO


## Puts the carried Dhull down on the ground in front, facing the player.
func put_down() -> void:
	var dhull := _carried
	_carried = null
	var spot := Ground.below(self, _model.to_global(Vector3(0.0, 0.0, -put_down_distance)))
	dhull.reparent(_carried_from, false)
	dhull.global_position = spot
	dhull.global_rotation = Vector3(0.0, _model.global_rotation.y, 0.0)
	dhull.record.position = spot
	dhull.record.facing = dhull.global_rotation.y
	dhull.carried = false


## Where the player stands and which way they and the camera face, so a scene can put them back
## after a minigame with [method apply_state].
func get_state() -> Dictionary:
	return {
		"transform": global_transform,
		"model_yaw": _model.rotation.y,
		"camera_yaw": _camera_pivot.rotation.y,
		"camera_pitch": _spring_arm.rotation.x,
	}


func apply_state(state: Dictionary) -> void:
	global_transform = state.get("transform", global_transform)
	_model.rotation.y = state.get("model_yaw", _model.rotation.y)
	_camera_pivot.rotation.y = state.get("camera_yaw", _camera_pivot.rotation.y)
	_spring_arm.rotation.x = state.get("camera_pitch", _spring_arm.rotation.x)


func _rotate_camera(amount: Vector2) -> void:
	if Settings.get_value("controls/invert_y"):
		amount.y = -amount.y
	_camera_pivot.rotation.y += amount.x
	_spring_arm.rotation.x = clampf(
		_spring_arm.rotation.x + amount.y,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)
