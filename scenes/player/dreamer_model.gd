class_name DreamerModel
extends Node3D
## The dreamer's model (assets/models/dreamer/): shows their look, the hair of the length they
## picked in the color they picked, colors the rest of them, paints their sleepy face on and
## blinks, and stands idle or walks as they move.

## The hair of each length; only the chosen one shows.
const HAIRS: Dictionary[DreamerLook.HairLength, NodePath] = {
	DreamerLook.HairLength.SHORT: ^"Body/Head/HairShort",
	DreamerLook.HairLength.MEDIUM: ^"Body/Head/HairMedium",
	DreamerLook.HairLength.LONG: ^"Body/Head/HairLong",
}
const SKIN: Array[NodePath] = [
	^"Body/Head", ^"Body/SleeveLeft/HandLeft", ^"Body/SleeveRight/HandRight"
]
const HOODIE: Array[NodePath] = [^"Body", ^"Body/SleeveLeft", ^"Body/SleeveRight"]
const TROUSERS: Array[NodePath] = [^"Body/LegLeft", ^"Body/LegRight"]
const SHOES: Array[NodePath] = [^"Body/LegLeft/ShoeLeft", ^"Body/LegRight/ShoeRight"]
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
## Draws the face on the head; see dhull_face.gdshader.
@export var face_material: Material
## Their eyes: sleepy, under heavy lids.
@export var eye_style := DhullFace.EyeStyle.DROOPY
@export var eye_color := DhullGenome.EyeColor.SILVER
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

@onready var _head: MeshInstance3D = $Body/Head
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _blink_timer: Timer = $BlinkTimer


func _ready() -> void:
	_rng.randomize()
	_head.material_overlay = face_material
	# A shut mouth doesn't show.
	_head.set_instance_shader_parameter(&"mouth_frame", DhullFace.NO_MOUTH)
	_head.set_instance_shader_parameter(&"eye_color", eye_color)
	_paint(SKIN, colors.skin)
	_paint(HOODIE, colors.hoodie)
	_paint(TROUSERS, colors.trousers)
	_paint(SHOES, colors.shoes)
	InkHull.center_outlines(find_children("*", "MeshInstance3D", true, false))
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
	var eyes := DhullFace.eyes_for(DhullFace.Emotion.NEUTRAL, eye_style, _blinking)
	_head.set_instance_shader_parameter(&"eye_frame", eyes)


func _paint(parts: Array[NodePath], color: Color) -> void:
	for part in parts:
		_paint_part(get_node(part), color)


## The dreamer has no tips in another color, so the tip color is the part's own.
static func _paint_part(part: GeometryInstance3D, color: Color) -> void:
	part.set_instance_shader_parameter(&"part_color", color)
	part.set_instance_shader_parameter(&"tip_color", color)
