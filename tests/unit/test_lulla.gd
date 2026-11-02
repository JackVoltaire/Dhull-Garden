extends TestCase
## Lulla: what she says and when she nods off (LullaTalk), and the model, animations and lines
## her scene relies on.

const SCENE_PATH := "res://scenes/characters/lulla/lulla.tscn"
const MODEL_PATH := "res://assets/models/lulla/lulla.glb"
const ANIMATIONS_PATH := "res://scenes/characters/lulla/lulla_animations.tres"
const STRINGS_PATH := "res://localization/strings.csv"
const LOOPED: Array[StringName] = [&"idle", &"talk", &"doze"]


func test_she_greets_a_new_dreamer_with_the_first_meeting() -> void:
	assert_eq(_talk().next_lines(false), PackedStringArray(["FIRST_1", "FIRST_2"]))


func test_she_mumbles_a_line_at_a_time_in_turn() -> void:
	var talk := _talk()
	assert_eq(talk.next_lines(true), PackedStringArray(["MUMBLE_1"]))
	assert_eq(talk.next_lines(true), PackedStringArray(["MUMBLE_2"]))
	assert_eq(talk.next_lines(true), PackedStringArray(["MUMBLE_1"]), "and starts over")


func test_she_nods_off_only_on_the_lines_she_nods_off_on() -> void:
	var talk := _talk()
	assert_false(talk.nods_off_on("MUMBLE_1"))
	assert_false(talk.dozing)
	assert_true(talk.nods_off_on("FIRST_2"))
	assert_true(talk.dozing)


func test_talking_to_her_while_she_dozes_wakes_her_with_a_waking_line() -> void:
	var talk := _talk()
	talk.nods_off_on("FIRST_2")
	assert_eq(talk.next_lines(true), PackedStringArray(["WAKE_1"]))
	assert_false(talk.dozing, "she's awake")
	assert_eq(talk.next_lines(true), PackedStringArray(["MUMBLE_1"]), "and mumbles again")


## LullaModel finds the parts it colors and the face it paints by name in the model.
func test_the_model_has_every_part_lulla_colors() -> void:
	var model: Node3D = load(MODEL_PATH).instantiate()
	var parts: Array[NodePath] = [
		LullaModel.HEAD, LullaModel.WOOL, LullaModel.MASK, LullaModel.PILLOW, LullaModel.HOOVES
	]
	for group in [LullaModel.SKIN, LullaModel.GOWN, LullaModel.FRILLS, LullaModel.HORNS]:
		parts.append_array(group)
	for part in parts:
		assert_true(model.get_node_or_null(part) is MeshInstance3D, "%s is in the model" % part)
	model.free()


## Every animation must key every part, her eyes included, or blending into it leaves them
## where the last one put them.
func test_every_animation_keys_every_part() -> void:
	var library: AnimationLibrary = load(ANIMATIONS_PATH)
	for animation_name in library.get_animation_list():
		var animation := library.get_animation(animation_name)
		for track in LullaModel.ANIMATED_TRACKS:
			assert_true(
				animation.find_track(track, Animation.TYPE_VALUE) >= 0,
				"%s keys %s" % [animation_name, track]
			)
		var looped := animation.loop_mode == Animation.LOOP_LINEAR
		assert_eq(looped, animation_name in LOOPED, "%s loops only if it should" % animation_name)


## Every line her scene gives her is written, the lines she nods off on among them.
func test_every_line_she_says_is_written() -> void:
	var lulla: Lulla = (load(SCENE_PATH) as PackedScene).instantiate()
	var written := _written_keys()
	var lines := PackedStringArray()
	for group in [lulla.first_meeting, lulla.mumbling, lulla.waking]:
		lines.append_array(group)
	for line in lines:
		assert_true(written.has(line), "%s is written" % line)
	for line in lulla.nodding_off:
		assert_true(lines.has(line), "%s is one of her lines" % line)
	lulla.free()


static func _talk() -> LullaTalk:
	return LullaTalk.new(
		PackedStringArray(["FIRST_1", "FIRST_2"]),
		PackedStringArray(["MUMBLE_1", "MUMBLE_2"]),
		PackedStringArray(["WAKE_1"]),
		PackedStringArray(["FIRST_2"])
	)


static func _written_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	# The first line names the columns.
	file.get_csv_line()
	while not file.eof_reached():
		keys.append(file.get_csv_line()[0])
	return keys
