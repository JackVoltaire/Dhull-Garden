class_name Player
extends CharacterBody3D
## Third-person character: camera-relative movement, sprinting and jumping,
## with an orbiting camera driven by the mouse or the right stick.
##
## The body itself never rotates. [code]Model[/code] turns to face the movement direction
## and [code]CameraPivot[/code] turns with the camera, so the two stay independent.

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
@export var mouse_sensitivity := 0.003
## Gamepad look speed in radians per second at full stick deflection.
@export var stick_sensitivity := 3.0
@export_range(-89.0, 0.0) var min_pitch_degrees := -70.0
@export_range(0.0, 89.0) var max_pitch_degrees := 30.0

@onready var _model: Node3D = $Model
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# screen_relative ignores window stretching, so sensitivity doesn't change with window size.
		_rotate_camera(-event.screen_relative * mouse_sensitivity)
	elif event is InputEventMouseButton and event.pressed:
		# Recapture the cursor after it was released, e.g. by alt-tabbing.
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var look_input := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	_rotate_camera(-look_input * stick_sensitivity * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Rotate the input by the camera's yaw so "forward" always points away from the camera.
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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


func _rotate_camera(amount: Vector2) -> void:
	_camera_pivot.rotation.y += amount.x
	_spring_arm.rotation.x = clampf(
		_spring_arm.rotation.x + amount.y,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)
