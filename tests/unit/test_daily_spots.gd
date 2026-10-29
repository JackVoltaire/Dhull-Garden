extends TestCase
## Spots that can be used once a day, like shiny spots. These tests use a Minigames of their own,
## not the autoload, and move the clock back afterwards.

const MINIGAMES_SCRIPT := preload("res://systems/minigames/minigames.gd")

var _minigames: Node
var _offset_before := 0


func before_each() -> void:
	_minigames = MINIGAMES_SCRIPT.new()
	_offset_before = Clock.offset_seconds


func after_each() -> void:
	Clock.offset_seconds = _offset_before
	_minigames.free()


func test_a_spot_used_today_comes_back_tomorrow() -> void:
	assert_false(_minigames.used_today(&"rock"), "fresh")
	_minigames.mark_used(&"rock")
	assert_true(_minigames.used_today(&"rock"), "used")
	assert_false(_minigames.used_today(&"other_rock"), "only that spot")
	Clock.offset_seconds += DateUtil.SECONDS_PER_DAY
	assert_false(_minigames.used_today(&"rock"), "back the next day")


func test_used_spots_survive_saving() -> void:
	_minigames.mark_used(&"rock")
	var saved: Dictionary = JSON.to_native(JSON.from_native(_minigames.get_save_data()))
	var loaded: Node = MINIGAMES_SCRIPT.new()
	loaded.apply_save_data(saved)
	assert_true(loaded.used_today(&"rock"), "still used today")
	loaded.free()
