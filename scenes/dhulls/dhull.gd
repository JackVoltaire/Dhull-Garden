@tool
class_name Dhull
extends Node3D
## A Dhull: a Chao-like body with its head floating close above it in a nebula mist. Its hidden
## [member genome] decides its head shape, body shape, eye style and eye color; the model is put
## together from those parts when it's ready, in the editor too. What it's doing and how it feels,
## its [member activity] and [member mood], pick its animation and face (see DhullState); its
## energy sets how fast it moves. The face is drawn on the head from swappable eye and mouth
## images, like Wind Waker's, and the eyes blink now and then. Its mood also shows as weather in
## its nebula, and reaction symbols pop up beside its head (see DhullReaction).
##
## An egg is a Dhull too: it shows only its shell until it hatches, and can only be carried.
##
## A Dhull in the garden shows its [member record], the life the Garden autoload keeps for it:
## its needs set its mood (see DhullLife), its Brain walks it about as that mood's habit says
## (see DhullBrain) unless it's napping, and the young are smaller. It reacts when its mood
## changes, when it notices the player, and now and then as it rests. The player can pet it, feed
## it and carry it about (see DhullCare and CareMenu). When it posts on the feed it takes a selfie
## right where it is: it holds its phone out on a selfie stick in one nub, since its nubs are far
## too short to frame a face, holds up what the post is about in the other, and pulls a face that
## fits (see DhullPosting.selfie_face); the shot is taken from the phone. Posts it made while its
## area wasn't loaded get their selfies the next time it is.
## Without a record, as in the Dhull gallery, it shows whatever activity and mood are set on it
## and stays where it is.

const BODY_MODELS: Dictionary[DhullGenome.BodyShape, PackedScene] = {
	DhullGenome.BodyShape.BELL: preload("res://assets/models/dhull_body_bell/dhull_body_bell.glb"),
	DhullGenome.BodyShape.BEAN: preload("res://assets/models/dhull_body_bean/dhull_body_bean.glb"),
}
const HEAD_MODELS: Dictionary[DhullGenome.HeadShape, PackedScene] = {
	DhullGenome.HeadShape.MOON: preload("res://assets/models/dhull_head_moon/dhull_head_moon.glb"),
	DhullGenome.HeadShape.MOONCAT:
	preload("res://assets/models/dhull_head_mooncat/dhull_head_mooncat.glb"),
	DhullGenome.HeadShape.BEAN: preload("res://assets/models/dhull_head_bean/dhull_head_bean.glb"),
}
## The parts every animation moves. The head is a holder that carries the head model and its mist.
const ANIMATED_TRACKS: Array[NodePath] = [
	^"Model:position",
	^"Model:rotation",
	^"Model/Body:scale",
	^"Model/Body/ArmLeft:rotation",
	^"Model/Body/ArmRight:rotation",
	^"Model/Body/LegLeft:rotation",
	^"Model/Body/LegRight:rotation",
	^"Model/Body/Tail:rotation",
	^"Model/Head:position",
	^"Model/Head:rotation",
]
## Seconds to blend from one animation into the next when the activity or mood changes.
const BLEND_TIME := 0.4
## Every Dhull in the game is in this group.
const GROUP := &"dhulls"

## Its genes. Without any, it gets random ones when the game runs, and the first variant of
## everything in the editor.
@export var genome: DhullGenome:
	set(value):
		genome = value
		if is_node_ready():
			_build_model()
## What it's doing.
@export var activity := DhullState.Activity.STANDING:
	set(value):
		activity = value
		if is_node_ready():
			_show_state()
## How it feels.
@export var mood := DhullState.Mood.CONTENT:
	set(value):
		mood = value
		if is_node_ready():
			_show_state()
## The colors of its clay; Sunny unless set. Without one, it keeps the clay shader's defaults.
@export var coloring: DhullColoring:
	set(value):
		coloring = value
		if is_node_ready():
			_apply_coloring()
## Draws the face on the head; see dhull_face.gdshader.
@export var face_material: Material
## How big a young Dhull is next to an adult.
@export_range(0.3, 1.0, 0.05) var young_scale := 0.7
## How close the player has to come before it notices them, for the least and the most curious
## Dhulls.
@export var notice_distance := Vector2(2.0, 6.0)
@export_group("Selfies")
## Where the right nub holds the selfie stick and the left nub holds the thing it's posting
## about, from their joints.
@export var stick_grip := Vector3(-0.15, -0.13, 0.0)
@export var held_thing_grip := Vector3(0.17, -0.15, 0.02)
## How long it takes to strike the pose before the shot, and how long it holds it after.
@export_range(0.0, 3.0, 0.05, "suffix:s") var selfie_pose_seconds := 0.6
@export_range(0.0, 3.0, 0.05, "suffix:s") var selfie_hold_seconds := 0.8
## Seconds between blinks, picked at random between x and y, and how long a blink lasts.
@export var blink_interval := Vector2(2.0, 5.0)
@export_range(0.05, 1.0, 0.01, "suffix:s") var blink_duration := 0.14

## Its life in the garden. Set it before the Dhull enters the tree.
var record: DhullRecord:
	set(value):
		record = value
		genome = value.genome
		coloring = value.coloring
## Whether the player is carrying it. A carried Dhull goes where it's taken.
var carried := false:
	set(value):
		carried = value
		if is_node_ready() and record:
			_show_life()

var _blinking := false
var _until_blink_change := 0.0
var _rng := RandomNumberGenerator.new()
var _head_shape: MeshInstance3D
## Whether its life has been shown yet. The first time isn't a change of mood to react to.
var _life_shown := false
## The life stage shown last, to notice it hatching or growing up.
var _shown_life_stage := DhullRecord.LifeStage.ADULT
## Posts it still has to take a selfie for, oldest first.
var _selfies_due: Array[FeedPost] = []
var _taking_selfies := false
## The face it pulls in the selfie it's taking.
var _selfie_face := DhullFace.Emotion.NEUTRAL

@onready var _model: Node3D = $Model
@onready var _head: Node3D = $Model/Head
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _brain: DhullBrain = $Brain
@onready var _weather: DhullWeather = $Model/Head/Weather
@onready var _reactions: DhullReactions = $Model/Head/Reactions
@onready var _notice: Area3D = $Notice
@onready var _notice_shape: CollisionShape3D = $Notice/Shape
@onready var _sigh_timer: Timer = $SighTimer
@onready var _care: Interactable = $Care
@onready var _egg: MeshInstance3D = $Egg
@onready var _selfie: SubViewport = $Selfie
@onready var _selfie_lens: Camera3D = $Selfie/Lens
@onready var _selfie_stick: Node3D = $Model/SelfieStick
@onready var _stick_phone: Node3D = $Model/SelfieStick/Phone
@onready var _held_thing: MeshInstance3D = $Model/HeldThing


func _ready() -> void:
	_rng.randomize()
	if genome == null and not Engine.is_editor_hint():
		genome = DhullGenome.random(_rng)
	_build_model()
	if Engine.is_editor_hint():
		return
	add_to_group(GROUP)
	_notice.monitoring = record != null
	_care.enabled = record != null
	if record:
		_care.interacted.connect(_on_care)
		var curiosity := genome.level(DhullGenome.Gene.CURIOSITY)
		(_notice_shape.shape as SphereShape3D).radius = lerpf(
			notice_distance.x, notice_distance.y, curiosity
		)
		_notice.body_entered.connect(_on_noticed)
		_sigh_timer.timeout.connect(_sigh)
		_brain.activity_changed.connect(_on_brain_activity_changed)
		Garden.lives_changed.connect(_show_life)
		Feed.posted.connect(_on_posted)
		_show_life()
		_selfies_due.assign(Feed.waiting_for_selfies(record.id))
		_take_selfies.call_deferred()
	_until_blink_change = _rng.randf_range(blink_interval.x, blink_interval.y)
	# Start each Dhull at its own point in its loop, so Dhulls doing the same thing aren't in step.
	_animation_player.seek(_rng.randf() * _animation_player.current_animation_length, true)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_until_blink_change -= delta
	if _until_blink_change <= 0.0:
		_blinking = not _blinking
		if _blinking:
			_until_blink_change = blink_duration
		else:
			_until_blink_change = _rng.randf_range(blink_interval.x, blink_interval.y)
		_show_face()


## How big it is next to a grown Dhull.
func size_scale() -> float:
	return young_scale if record and record.is_young() else 1.0


## Pops up [param symbol] beside its head, with gloomy lines down its face if [param gloomy].
func react(symbol: DhullReaction.Symbol, gloomy := false) -> void:
	if symbol == DhullReaction.Symbol.NONE:
		return
	_reactions.pop(symbol)
	if gloomy:
		_set_gloom(true)
		get_tree().create_timer(_reactions.duration()).timeout.connect(_set_gloom.bind(false))


## Pets it, and shows whether it liked that.
func pet() -> void:
	_respond(DhullCare.pet(record, Garden.tuning))


## Offers it [param item] to eat or drink. Returns whether it took it.
func feed(item: ItemDefinition) -> bool:
	var response := DhullCare.feed(record, item, Garden.tuning)
	_respond(response)
	if response == DhullCare.Response.WELCOMED:
		Feed.post_about(record, FeedPost.Topic.ATE, item.id)
	return response == DhullCare.Response.WELCOMED


func _on_posted(post: FeedPost) -> void:
	if post.dhull_id != record.id:
		return
	_selfies_due.append(post)
	_take_selfies()


## Takes a selfie for each post waiting for one, one after another.
func _take_selfies() -> void:
	if _taking_selfies:
		return
	_taking_selfies = true
	while not _selfies_due.is_empty():
		await _take_selfie(_selfies_due.front())
		_selfies_due.pop_front()
	_taking_selfies = false
	_show_life()


## Raises the phone, holds up what [param post] is about, pulls the face that fits and shoots,
## from the phone, so the face and the thing are both in the picture.
func _take_selfie(post: FeedPost) -> void:
	var subject: ItemDefinition = Inventory.definitions.get(post.subject)
	_held_thing.mesh = subject.prop if subject else null
	_held_thing.visible = _held_thing.mesh != null
	_selfie_stick.visible = true
	_selfie_face = DhullPosting.selfie_face(post)
	_brain.rest()
	_set_activity(DhullState.Activity.TAKING_SELFIE)
	await get_tree().create_timer(selfie_pose_seconds).timeout
	var focus := _head.global_position
	if _held_thing.visible:
		focus = focus.lerp(_held_thing.global_position, 0.5)
	var phone_at := Transform3D(Basis.IDENTITY, _stick_phone.global_position)
	_selfie_lens.global_transform = phone_at.looking_at(focus)
	_selfie.render_target_update_mode = SubViewport.UPDATE_ONCE
	# One frame to draw the picture, one for it to be ready to read back.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	Feed.keep_selfie(post, _selfie.get_texture().get_image())
	await get_tree().create_timer(selfie_hold_seconds).timeout
	_held_thing.visible = false
	_selfie_stick.visible = false


func _respond(response: DhullCare.Response) -> void:
	var welcomed := response == DhullCare.Response.WELCOMED
	react(DhullReaction.Symbol.STAR if welcomed else DhullReaction.Symbol.SPIRAL)
	Garden.notify_changed()


## A hatched Dhull is named the first time the dreamer cares for it.
func _on_care(player: Player) -> void:
	if record.name.is_empty() and not record.is_egg():
		player.name_dhull(self)
	else:
		player.care_for(self)


func _show_life() -> void:
	var new_mood := DhullLife.mood_for(record, Garden.tuning)
	var hatched := _life_shown and _shown_life_stage == DhullRecord.LifeStage.EGG
	hatched = hatched and not record.is_egg()
	# Setting a mood or activity blends into its animation again, so only change what changed.
	if new_mood != mood:
		if _life_shown and not record.is_egg():
			react(DhullReaction.on_mood_change(mood, new_mood))
		mood = new_mood
	if hatched:
		react(DhullReaction.Symbol.STAR)
	_life_shown = true
	_shown_life_stage = record.life_stage
	_care.enabled = not carried
	_model.visible = not record.is_egg()
	_egg.visible = record.is_egg()
	# A selfie holds its pose until the shot is done; it shows the rest of its life afterwards.
	if not _taking_selfies:
		_show_activity()
	_model.scale = Vector3.ONE * size_scale()
	_keep_sighing()


## What it's doing follows from its life: an egg sits still, a napping Dhull sleeps, a carried
## one sits on the player's shoulders, and otherwise its brain walks it about.
func _show_activity() -> void:
	if record.is_egg():
		_brain.rest()
		_set_activity(DhullState.Activity.STANDING)
	elif record.napping:
		_brain.rest()
		_set_activity(DhullState.Activity.SLEEPING)
	elif carried:
		_brain.rest()
		_set_activity(DhullState.Activity.SITTING)
	else:
		_brain.follow_mood(mood)


func _on_brain_activity_changed(new_activity: DhullState.Activity) -> void:
	if not record.napping and not carried and not _taking_selfies:
		_set_activity(new_activity)


func _set_activity(new_activity: DhullState.Activity) -> void:
	if new_activity != activity:
		activity = new_activity
		_keep_sighing()


func _on_noticed(_player: Node3D) -> void:
	if not record.napping and not record.is_egg():
		react(DhullReaction.Symbol.EYE)


## Keeps the sigh timer going while it rests in a mood that sighs now and then, and stops it
## otherwise.
func _keep_sighing() -> void:
	var habit := _brain.habits.habit_for(mood)
	var resting := activity in [DhullState.Activity.STANDING, DhullState.Activity.SITTING]
	if not resting or habit.idle_reaction == DhullReaction.Symbol.NONE:
		_sigh_timer.stop()
	elif _sigh_timer.is_stopped():
		var seconds := habit.idle_reaction_every_seconds * _rng.randf_range(0.6, 1.4)
		_sigh_timer.start(seconds / DhullState.speed_scale(genome))


func _sigh() -> void:
	var habit := _brain.habits.habit_for(mood)
	react(habit.idle_reaction, habit.gloomy)
	_keep_sighing()


func _set_gloom(gloomy: bool) -> void:
	_head_shape.set_instance_shader_parameter(&"gloom", 1.0 if gloomy else 0.0)


## Puts the model together from the body and head its genes call for.
func _build_model() -> void:
	var old_body := _model.get_node_or_null(^"Body")
	if not Engine.is_editor_hint():
		# Out of the old nubs before they go.
		_selfie_stick.reparent(_model, false)
		_held_thing.reparent(_model, false)
	if old_body:
		_model.remove_child(old_body)
		old_body.queue_free()
	if _head_shape:
		_head.remove_child(_head_shape)
		_head_shape.queue_free()
	var body_shape := genome.body_shape() if genome else DhullGenome.BodyShape.BELL
	var head_shape := genome.head_shape() if genome else DhullGenome.HeadShape.MOON
	var body := _take_part(BODY_MODELS[body_shape], &"Body")
	_model.add_child(body)
	if not Engine.is_editor_hint():
		_hold(_selfie_stick, body.get_node(^"ArmRight"), stick_grip)
		_hold(_held_thing, body.get_node(^"ArmLeft"), held_thing_grip)
	_head_shape = _take_part(HEAD_MODELS[head_shape], &"Head")
	_head_shape.name = &"Shape"
	_head_shape.material_overlay = face_material
	_head.add_child(_head_shape)
	# The animation player holds on to the parts it moved last; these are new ones.
	_animation_player.clear_caches()
	_apply_coloring()
	_show_state()


## Puts [param thing] in [param nub], at [param grip] from its joint, turned as it was.
static func _hold(thing: Node3D, nub: Node3D, grip: Vector3) -> void:
	thing.reparent(nub, false)
	thing.position = grip


## The named part of a model, with its children, taken out of the rest of the model.
static func _take_part(model: PackedScene, part_name: StringName) -> Node3D:
	var root := model.instantiate()
	var part: Node3D = root.get_node(NodePath(part_name))
	root.remove_child(part)
	root.free()
	return part


func _show_state() -> void:
	_show_face()
	_weather.show_weather(DhullState.weather_for(mood))
	# Animating in the editor would save the animated pose into the scene.
	if Engine.is_editor_hint():
		return
	if genome:
		_animation_player.speed_scale = DhullState.speed_scale(genome)
	_animation_player.play(DhullState.animation_for(activity, mood), BLEND_TIME)


func _show_face() -> void:
	var emotion := DhullState.emotion_for(activity, mood)
	if activity == DhullState.Activity.TAKING_SELFIE:
		emotion = _selfie_face
	var eye_style := genome.eye_style() if genome else DhullFace.EyeStyle.ROUND
	var eye_color := genome.eye_color() if genome else DhullGenome.EyeColor.TEAL
	_head_shape.set_instance_shader_parameter(&"eye_color", eye_color)
	_head_shape.set_instance_shader_parameter(
		&"eye_frame", DhullFace.eyes_for(emotion, eye_style, _blinking)
	)
	_head_shape.set_instance_shader_parameter(&"mouth_frame", DhullFace.mouth_for(emotion))


func _apply_coloring() -> void:
	if coloring == null:
		return
	_paint($Model/Body, coloring.body_color, coloring.body_pattern)
	_paint($Model/Body/Tail, coloring.body_color)
	_paint(_head_shape, coloring.head_color)
	_paint(_egg, coloring.head_color, DhullColoring.Pattern.SPOTS)
	_paint($Model/Body/ArmLeft, coloring.limb_color)
	_paint($Model/Body/LegRight, coloring.limb_color)
	_paint($Model/Body/ArmRight, coloring.other_limb_color)
	_paint($Model/Body/LegLeft, coloring.other_limb_color)


func _paint(part: GeometryInstance3D, color: Color, pattern := DhullColoring.Pattern.NONE) -> void:
	part.set_instance_shader_parameter(&"part_color", color)
	part.set_instance_shader_parameter(&"tip_color", coloring.tip_color)
	part.set_instance_shader_parameter(&"pattern", pattern)
	part.set_instance_shader_parameter(&"pattern_color", coloring.pattern_color)
