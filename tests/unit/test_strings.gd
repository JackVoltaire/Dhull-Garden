extends TestCase
## The game's text in localization/strings.csv.

const STRINGS_PATH := "res://localization/strings.csv"


func test_every_key_is_written_once() -> void:
	var seen := {}
	for key in _keys():
		assert_false(seen.has(key), "%s is written once" % key)
		seen[key] = true


## The look menu names its choices by key, from the look's options.
func test_every_hair_choice_has_a_name() -> void:
	var keys := _keys()
	for length: String in DreamerLook.HairLength.keys():
		assert_true(keys.has("UI_HAIR_" + length), "UI_HAIR_%s is written" % length)
	for hair_color: String in DreamerLook.HairColor.keys():
		assert_true(keys.has("UI_HAIR_" + hair_color), "UI_HAIR_%s is written" % hair_color)


func _keys() -> PackedStringArray:
	var keys := PackedStringArray()
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	# The first line names the columns.
	file.get_csv_line()
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line[0].is_empty():
			keys.append(line[0])
	return keys
