extends TestCase
## The dreamer's look: picking it, saving it, and the model and colors that show it.

const DREAMER_PATH := "res://systems/dreamer/dreamer.gd"
const COLORS_PATH := "res://data/dreamer/colors.tres"
const MODEL_PATH := "res://assets/models/dreamer/dreamer.glb"
const ANIMATIONS_PATH := "res://scenes/player/dreamer_animations.tres"

## A Dreamer of its own, apart from the autoload, so no test touches the game's.
var _dreamer: Node


func before_each() -> void:
	_dreamer = load(DREAMER_PATH).new()


func after_each() -> void:
	_dreamer.free()


func test_a_new_game_asks_for_a_look() -> void:
	_dreamer.apply_save_data({})
	assert_false(_dreamer.chosen, "not picked yet")
	assert_true(_dreamer.look.equals(DreamerLook.new()), "the default look")


func test_a_look_is_saved_and_loaded() -> void:
	var look := DreamerLook.new()
	look.hair_length = DreamerLook.HairLength.LONG
	look.hair_color = DreamerLook.HairColor.TEAL
	_dreamer.choose(look)
	var loaded: Node = load(DREAMER_PATH).new()
	loaded.apply_save_data(_dreamer.get_save_data())
	assert_true(loaded.chosen, "still picked")
	assert_true(loaded.look.equals(look), "the same look")
	loaded.free()


func test_looks_are_saved_by_name() -> void:
	var data := DreamerLook.new().to_dict()
	assert_eq(data.hair_length, "MEDIUM")
	assert_eq(data.hair_color, "BLACK")


func test_choices_no_longer_offered_load_as_the_default() -> void:
	var look := DreamerLook.from_dict({"hair_length": "MOHAWK", "hair_color": 3})
	assert_true(look.equals(DreamerLook.new()))


func test_picking_a_look_wears_it_once() -> void:
	var changes := [0]
	_dreamer.look_changed.connect(func() -> void: changes[0] += 1)
	var look := DreamerLook.new()
	look.hair_color = DreamerLook.HairColor.PINK
	_dreamer.choose(look)
	_dreamer.choose(look)
	assert_eq(changes[0], 1, "only a new look changes it")
	look.hair_color = DreamerLook.HairColor.RED
	assert_eq(_dreamer.look.hair_color, DreamerLook.HairColor.PINK, "a copy is worn")


func test_keeping_the_default_look_counts_as_picking_it() -> void:
	_dreamer.apply_save_data({})
	_dreamer.choose(DreamerLook.new())
	assert_true(_dreamer.chosen)


func test_every_hair_color_has_a_color() -> void:
	var colors: DreamerColors = load(COLORS_PATH)
	for hair_color: DreamerLook.HairColor in DreamerLook.HairColor.values():
		assert_true(colors.hair.has(hair_color), "%s has a color" % hair_color)


## DreamerModel finds the parts it colors and the hair it shows by name in the model.
func test_the_model_has_every_part_the_dreamer_shows() -> void:
	var model: Node3D = load(MODEL_PATH).instantiate()
	var parts: Array[NodePath] = []
	parts.append_array(DreamerModel.HAIRS.values())
	for group in [
		DreamerModel.SKIN, DreamerModel.HOODIE, DreamerModel.TROUSERS, DreamerModel.SHOES
	]:
		parts.append_array(group)
	for part in parts:
		assert_true(model.get_node_or_null(part) is MeshInstance3D, "%s is in the model" % part)
	model.free()


## Every animation must key every part, or blending into it leaves parts where the last one put
## them.
func test_every_animation_keys_every_part_and_loops() -> void:
	var library: AnimationLibrary = load(ANIMATIONS_PATH)
	for animation_name in [&"idle", &"walk"]:
		var animation := library.get_animation(animation_name)
		assert_eq(animation.loop_mode, Animation.LOOP_LINEAR, "%s loops" % animation_name)
		for track in DreamerModel.ANIMATED_TRACKS:
			var keyed := animation.find_track(track, Animation.TYPE_VALUE) >= 0
			assert_true(keyed, "%s keys %s" % [animation_name, track])
