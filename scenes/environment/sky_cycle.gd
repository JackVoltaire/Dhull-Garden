@tool
class_name SkyCycle
extends Node
## Colors the sky, fog and sunlight by the local time of day, following [code]Clock[/code] in
## the game. In the editor it shows [member preview_hour] instead, to try out the look.
##
## Each gradient covers one day, from midnight at the left edge to midnight at the right.
## Needs a WorldEnvironment whose sky uses a ProceduralSkyMaterial.

@export var world_environment: WorldEnvironment
## Sunlight by day and moonlight by night.
@export var sun: DirectionalLight3D
@export var sky_top: Gradient
@export var sky_horizon: Gradient
## Below the horizon, behind the sea of clouds.
@export var ground: Gradient
@export var light_color: Gradient
@export var fog_color: Gradient
## Tints the shady side of everything. Blended half and half with light from the sky.
@export var shadow_tint: Gradient
@export_range(0.0, 2.0) var day_light_energy := 0.6
@export_range(0.0, 2.0) var night_light_energy := 0.3
## Hour shown in the editor, where the game clock isn't running.
@export_range(0.0, 24.0, 0.25) var preview_hour := 12.0:
	set(value):
		preview_hour = value
		_apply()


func _ready() -> void:
	if not Engine.is_editor_hint():
		Clock.minute_changed.connect(_apply)
		Clock.time_shifted.connect(_apply)
	_apply()


func _apply() -> void:
	if not is_node_ready() or world_environment == null or sun == null:
		return
	var day_fraction := preview_hour / 24.0
	if not Engine.is_editor_hint():
		day_fraction = Clock.day_fraction()
	var environment := world_environment.environment
	var sky := environment.sky.sky_material as ProceduralSkyMaterial
	if sky:
		sky.sky_top_color = _sample(sky_top, day_fraction, sky.sky_top_color)
		sky.sky_horizon_color = _sample(sky_horizon, day_fraction, sky.sky_horizon_color)
		sky.ground_horizon_color = _sample(ground, day_fraction, sky.ground_horizon_color)
		sky.ground_bottom_color = sky.ground_horizon_color
	environment.fog_light_color = _sample(fog_color, day_fraction, environment.fog_light_color)
	environment.ambient_light_color = _sample(
		shadow_tint, day_fraction, environment.ambient_light_color
	)

	# The sun rises at 6:00, peaks at noon and sets at 18:00. At night the same light plays the
	# moon, so it stays above the horizon and shadows never go flat.
	var angle := day_fraction * TAU
	var elevation := maxf(absf(-cos(angle)) * 70.0, 20.0)
	sun.rotation = Vector3(-deg_to_rad(elevation), angle, 0.0)
	var daylight := smoothstep(-0.15, 0.25, -cos(angle))
	sun.light_energy = lerpf(night_light_energy, day_light_energy, daylight)
	sun.light_color = _sample(light_color, day_fraction, sun.light_color)


static func _sample(gradient: Gradient, offset: float, fallback: Color) -> Color:
	return gradient.sample(offset) if gradient else fallback
