class_name LullaModel
extends Node3D
## Lulla's model (assets/models/lulla/): colors her parts, paints her face on her sheep's head
## (see dhull_face.gdshader), and acts her out. She sways sleepily on her feet hugging her pillow,
## her head drooping until she jolts awake (idle); stays awake while she talks, her mouth moving
## (talk); nods off and dozes (doze); and wakes with a start (wake). The animations are in
## scenes/characters/lulla/lulla_animations.tres, and key her eyes too.

## Her face drawings, in the order of the frames in scenes/characters/lulla/face/.
enum Eyes { DROWSY, SHUT, STARTLED }
enum Mouth { CLOSED, OPEN }

## The sheep's head, its face painted on it.
const HEAD := ^"Body/Head"
## Her face, ears and hands.
const SKIN: Array[NodePath] = [
	HEAD,
	^"Body/Neck",
	^"Body/Head/EarLeft",
	^"Body/Head/EarRight",
	^"Body/SleeveLeft/HandLeft",
	^"Body/SleeveRight/HandRight",
]
const GOWN: Array[NodePath] = [^"Body", ^"Body/SleeveLeft", ^"Body/SleeveRight"]
const FRILLS: Array[NodePath] = [
	^"Body/HemFrill",
	^"Body/CollarFrill",
	^"Body/SleeveLeft/CuffFrillLeft",
	^"Body/SleeveRight/CuffFrillRight",
]
const WOOL := ^"Body/Head/Wool"
const HORNS: Array[NodePath] = [^"Body/Head/HornLeft", ^"Body/Head/HornRight"]
const MASK := ^"Body/Head/Mask"
const PILLOW := ^"Body/Pillow"
const HOOVES := ^"Body/Hooves"
## The parts and the face every animation keys.
const ANIMATED_TRACKS: Array[NodePath] = [
	^"Body:position",
	^"Body:rotation",
	^"Body/Head:rotation",
	^"Body/Head/EarLeft:rotation",
	^"Body/Head/EarRight:rotation",
	^"Body/Head:instance_shader_parameters/eye_frame",
]

## Paints her face on her head; see dhull_face.gdshader.
@export var face_material: Material
@export var head_turn: HeadTurn
@export_group("Colors")
## A soft cream sheep's face, as on Animal Crossing's pale-faced sheep, and her ears and hands.
@export var skin := Color(1.0, 0.95, 0.88)
## What the face turns to where it's shaded: round its edges and up under the wool.
@export var skin_shade := Color(0.86, 0.76, 0.78)
## Lilac wool, with yellow stars and moons in it, as on her pillow.
@export var wool := Color(0.72, 0.6, 0.9)
@export var stars_and_moons := Color(1.0, 0.86, 0.32)
## A Victorian black nightgown, its frills a shade lighter so they read.
@export var gown := Color(0.11, 0.09, 0.14)
@export var frills := Color(0.21, 0.18, 0.27)
@export var horns := Color(0.92, 0.86, 0.74)
@export var horn_tips := Color(0.5, 0.4, 0.34)
@export var mask := Color(0.88, 0.58, 0.74)
@export var pillow := Color(0.94, 0.91, 0.99)
@export var hooves := Color(0.25, 0.18, 0.17)
@export_group("Acting")
## Seconds her mouth keeps moving for each letter of a line, and at least.
@export_range(0.01, 0.2, 0.005, "suffix:s") var talk_seconds_per_letter := 0.045
@export_range(0.1, 3.0, 0.05, "suffix:s") var shortest_talk := 0.4
## Seconds between her mouth opening and closing as she talks.
@export_range(0.05, 0.5, 0.01, "suffix:s") var mouth_flap := 0.12
## Seconds she takes to blend from one animation into the next, and to nod off.
@export_range(0.0, 2.0, 0.05, "suffix:s") var blend_time := 0.3
@export_range(0.0, 3.0, 0.05, "suffix:s") var nodding_off_time := 1.2

var _nodding_off := false
var _mouth_open := false

@onready var _face: GeometryInstance3D = get_node(HEAD)
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _mouth_timer: Timer = $MouthTimer
@onready var _talk_timer: Timer = $TalkTimer


func _ready() -> void:
	_paint(SKIN, skin, skin_shade)
	_paint(GOWN, gown)
	_add_detail(GOWN, CharacterDetail.Kind.CLOTH_FOLDS)
	_paint(FRILLS, frills)
	_paint([WOOL], wool)
	_add_detail([WOOL], CharacterDetail.Kind.WOOL_CURLS)
	_paint(HORNS, horns, horn_tips)
	_paint([MASK], mask)
	_paint([PILLOW], pillow)
	_add_detail([PILLOW], CharacterDetail.Kind.CLOTH_FOLDS)
	for part in [WOOL, PILLOW]:
		var starry: GeometryInstance3D = get_node(part)
		starry.set_instance_shader_parameter(&"pattern", DhullColoring.Pattern.STARS_AND_MOONS)
		starry.set_instance_shader_parameter(&"pattern_color", stars_and_moons)
	_paint([HOOVES], hooves)
	_face.material_overlay = face_material
	head_turn.apply(_face)
	_face.set_instance_shader_parameter(&"mouth_frame", Mouth.CLOSED)
	_mouth_timer.timeout.connect(_flap_mouth)
	_talk_timer.timeout.connect(_stop_talking)
	_animation_player.play(&"idle")


## Says [param text]: she wakes up enough to talk, and her mouth moves for as long as the line
## takes to say.
func say(text: String) -> void:
	if _animation_player.current_animation == &"wake":
		_animation_player.clear_queue()
		_animation_player.queue(&"talk")
	else:
		_animation_player.play(&"talk", blend_time)
	_talk_timer.start(maxf(text.length() * talk_seconds_per_letter, shortest_talk))
	_mouth_timer.start(mouth_flap)
	_show_mouth(true)


## Nods off once she's done talking, and dozes until she's woken.
func nod_off() -> void:
	_nodding_off = true


## Wakes her with a start from a doze.
func wake() -> void:
	_nodding_off = false
	_animation_player.play(&"wake")
	_animation_player.queue(&"idle")


func _flap_mouth() -> void:
	_show_mouth(not _mouth_open)


func _stop_talking() -> void:
	_mouth_timer.stop()
	_show_mouth(false)
	if _nodding_off:
		_animation_player.play(&"doze", nodding_off_time)
	else:
		_animation_player.play(&"idle", blend_time)


func _show_mouth(open: bool) -> void:
	_mouth_open = open
	_face.set_instance_shader_parameter(&"mouth_frame", Mouth.OPEN if open else Mouth.CLOSED)


## Colors [param parts], NodePaths, turning towards [param shade] by their "Tip" vertex color;
## only the face and the horns have any.
func _paint(parts: Array, color: Color, shade := color) -> void:
	for path: NodePath in parts:
		var part: GeometryInstance3D = get_node(path)
		part.set_instance_shader_parameter(&"part_color", color)
		part.set_instance_shader_parameter(&"tip_color", shade)


## Paints [param kind] of detail over [param parts], which are NodePaths.
func _add_detail(parts: Array, kind: CharacterDetail.Kind) -> void:
	for path: NodePath in parts:
		(get_node(path) as GeometryInstance3D).set_instance_shader_parameter(&"detail", kind)
