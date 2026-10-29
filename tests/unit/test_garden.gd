extends TestCase
## The garden keeps every Dhull's life, moves it on with the clock and saves it. These tests use a
## garden of their own, not the Garden autoload, so the game's own Dhulls are never touched.

const GARDEN_SCRIPT := preload("res://systems/garden/garden.gd")

var _garden: Node


func before_each() -> void:
	_garden = GARDEN_SCRIPT.new()
	_garden.apply_save_data({})


func after_each() -> void:
	_garden.free()


func test_a_new_garden_has_its_starting_dhulls() -> void:
	var new_garden: NewGarden = _garden.new_garden
	assert_eq(_garden.dhulls.size(), new_garden.adults + new_garden.young)
	var ids := {}
	for record: DhullRecord in _garden.dhulls:
		ids[record.id] = true
		assert_eq(record.home_area, new_garden.home_area)
		assert_true(record.coloring == new_garden.coloring, "%s has the coloring" % record.id)
	assert_eq(ids.size(), _garden.dhulls.size(), "every id is unique")
	assert_eq(_garden.dhulls_in(new_garden.home_area).size(), _garden.dhulls.size())
	assert_true(_garden.dhulls_in(&"nowhere").is_empty(), "nobody lives nowhere")


func test_lives_move_on_with_the_clock() -> void:
	var record: DhullRecord = _garden.dhulls[0]
	_garden.advance_to(_simulated_until() + 2 * 3600)
	assert_true(record.hunger > 0.0, "got hungrier")
	assert_true(record.tiredness > 0.0, "got more tired")


func test_turning_the_clock_back_changes_nothing() -> void:
	var record: DhullRecord = _garden.dhulls[0]
	var before: Dictionary = record.to_dict()
	_garden.advance_to(_simulated_until() - 3600)
	assert_eq(record.to_dict(), before)


func test_catching_up_stops_after_two_weeks() -> void:
	var a_year_on: int = _simulated_until() + 365 * DateUtil.SECONDS_PER_DAY
	_garden.advance_to(a_year_on)
	assert_eq(_simulated_until(), a_year_on)


func test_the_garden_survives_saving() -> void:
	_garden.advance_to(_simulated_until() + 5 * 3600)
	# Saves keep exact types this way.
	var saved: Dictionary = JSON.to_native(JSON.from_native(_garden.get_save_data()))
	var loaded: Node = GARDEN_SCRIPT.new()
	loaded.apply_save_data(saved)
	assert_eq(loaded.dhulls.size(), _garden.dhulls.size())
	for index in _garden.dhulls.size():
		var original: DhullRecord = _garden.dhulls[index]
		var copy: DhullRecord = loaded.dhulls[index]
		assert_eq(copy.id, original.id)
		assert_eq(copy.life_stage, original.life_stage)
		assert_eq(copy.genome.alleles, original.genome.alleles)
	loaded.free()


func test_loading_replaces_the_dhulls() -> void:
	var replaced := [false]
	_garden.dhulls_replaced.connect(func() -> void: replaced[0] = true)
	_garden.apply_save_data({})
	assert_true(replaced[0], "told the levels")


func _simulated_until() -> int:
	return _garden.get_save_data().simulated_until
