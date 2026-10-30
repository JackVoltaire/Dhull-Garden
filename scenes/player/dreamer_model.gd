class_name DreamerModel
extends Node3D
## The dreamer's model (assets/models/dreamer/): shows their look, the hair of the length they
## picked in the color they picked, colors the rest of them, paints their sleepy face on the flat
## sheet in front of their head and blinks, and stands idle or walks as they move.

## The dreamer's own face drawings, in the order of the frames in scenes/player/face/: tired and
## fed up, with heavy dark red lids.
enum Eyes { HALF_LIDDED, SHUT }
enum Mouth { GRITTED }

## The hair of each length; only the chosen one shows.
const HAIRS: Dictionary[DreamerLook.HairLength, NodePath] = {
	DreamerLook.HairLength.SHORT: ^"Body/Head/HairShort",
	DreamerLook.HairLength.MEDIUM: ^"Body/Head/HairMedium",
	DreamerLook.HairLength.LONG: ^"Body/Head/HairLong",
}
const SKIN: Array[NodePath] = [
	^"Body/Head", ^"Body/Neck", ^"Body/SleeveLeft/HandLeft", ^"Body/SleeveRight/HandRight"
]
const HOODIE: Array[NodePath] = [^"Body", ^"Body/SleeveLeft", ^"Body/SleeveRight"]
const SLEEVES: Array[NodePath] = [^"Body/SleeveLeft", ^"Body/SleeveRight"]
const TROUSERS: Array[NodePath] = [^"Body/LegLeft", ^"Body/LegRight"]
const SHOES: Array[NodePath] = [^"Body/LegLeft/ShoeLeft", ^"Body/LegRight/ShoeRight"]
## The flat sheet in front of the head the face is painted on, like glasses.
const FACE := ^"Body/Head/Face"
## The parts every animation moves.
const ANIMATED_TRACKS: Array[NodePath] = [
	^"Body:position",
	^"Body:rotation",
	^"Body/Head:rotation",
	^"Body/SleeveLeft:rotation",
	^"Body/SleeveRight:rotation",
	^"Body/LegLeft:rotation",
	^"Body/LegRight:rotation",
]

@export var colors: DreamerColors
## Where their irises rest, from -1 to 1 right and up: a little down, from under heavy lids.
@export var glance := Vector2(0.0, -0.3)
## Seconds between blinks, picked at random between x and y, and how long a blink lasts.
@export var blink_interval := Vector2(2.0, 5.0)
@export_range(0.05, 1.0, 0.01, "suffix:s") var blink_duration := 0.14
## How fast the dreamer goes when the walk's steps keep pace with the ground; faster or slower,
## the walk plays faster or slower to match.
@export_range(0.5, 10.0, 0.1, "suffix:m/s") var walk_animation_speed := 4.0
## How fast they have to go to walk rather than stand.
@export_range(0.0, 2.0, 0.05, "suffix:m/s") var walking_from := 0.3

var _blinking := false
var _rng := RandomNumberGenerator.new()

@onready var _face: MeshInstance3D = get_node(FACE)
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _blink_timer: Timer = $BlinkTimer


func _ready() -> void:
	_rng.randomize()
	_face.set_instance_shader_parameter(&"mouth_frame", Mouth.GRITTED)
	_face.set_instance_shader_parameter(&"look", glance)
	_paint(SKIN, colors.skin, colors.skin_shade)
	_paint(HOODIE, colors.hoodie)
	for sleeve in SLEEVES:
		var part: GeometryInstance3D = get_node(sleeve)
		part.set_instance_shader_parameter(&"pattern", DhullColoring.Pattern.STRIPES)
		part.set_instance_shader_parameter(&"pattern_color", colors.sleeve_stripes)
	_paint(TROUSERS, colors.trousers)
	_paint(SHOES, colors.shoes)
	_blink_timer.timeout.connect(_toggle_blink)
	_show_eyes()
	_blink_timer.start(_rng.randf_range(blink_interval.x, blink_interval.y))


## Shows [param look]: the hair of its length, in its color.
func show_look(look: DreamerLook) -> void:
	for length: DreamerLook.HairLength in HAIRS:
		var hair: MeshInstance3D = get_node(HAIRS[length])
		hair.visible = length == look.hair_length
		_paint_part(hair, colors.hair[look.hair_color])


## Walks, at a pace to match, while the dreamer goes at least [member walking_from] across the
## ground at [param ground_speed]; stands idle otherwise.
func show_motion(ground_speed: float) -> void:
	if ground_speed >= walking_from:
		_animation_player.play(&"walk")
		_animation_player.speed_scale = ground_speed / walk_animation_speed
	else:
		_animation_player.play(&"idle")
		_animation_player.speed_scale = 1.0


func _toggle_blink() -> void:
	_blinking = not _blinking
	_show_eyes()
	if _blinking:
		_blink_timer.start(blink_duration)
	else:
		_blink_timer.start(_rng.randf_range(blink_interval.x, blink_interval.y))


func _show_eyes() -> void:
	_face.set_instance_shader_parameter(&"eye_frame", Eyes.SHUT if _blinking else Eyes.HALF_LIDDED)


## The model shades parts towards their tip color by its "Tip" vertex color; only the skin has
## shading, so other parts' tip color is their own.
func _paint(parts: Array[NodePath], color: Color, shade := color) -> void:
	for part in parts:
		_paint_part(get_node(part), color, shade)


static func _paint_part(part: GeometryInstance3D, color: Color, shade := color) -> void:
	part.set_instance_shader_parameter(&"part_color", color)
	part.set_instance_shader_parameter(&"tip_color", shade)
