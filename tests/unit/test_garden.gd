extends TestCase
## The garden keeps every Dhull's life, moves it on with the clock and saves it. These tests use a
## garden of their own, not the Garden autoload, so the game's own Dhulls are never touched.

const GARDEN_SCRIPT := preload("res://systems/garden/garden.gd")

var _garden: Node


func before_each() -> void:
	_garden = GARDEN_SCRIPT.new()
	_garden.apply_save_data({})
	var home: StringName = _garden.new_garden.home_area
	for life_stage in [DhullRecord.LifeStage.ADULT, DhullRecord.LifeStage.YOUNG]:
		for _dhull in 2:
			_garden.add_dhull(life_stage, home)


func after_each() -> void:
	_garden.free()


func test_a_new_garden_starts_empty_until_lulla_hands_over_an_egg() -> void:
	var fresh: Node = GARDEN_SCRIPT.new()
	fresh.apply_save_data({})
	assert_true(fresh.dhulls.is_empty(), "nobody yet")
	assert_false(fresh.first_egg_given, "no egg yet")
	var added := []
	fresh.dhull_added.connect(func(record: DhullRecord) -> void: added.append(record))
	var egg: DhullRecord = fresh.give_first_egg(Vector3(1, 0, 2))
	assert_true(fresh.first_egg_given, "egg given")
	assert_eq(fresh.dhulls.size(), 1)
	assert_true(egg.is_egg(), "it's an egg")
	assert_true(egg.placed, "placed")
	assert_eq(egg.position, Vector3(1, 0, 2))
	assert_eq(egg.home_area, fresh.new_garden.home_area)
	assert_true(egg.coloring == fresh.new_garden.coloring, "has the garden's coloring")
	assert_eq(added.size(), 1, "told the levels")
	fresh.free()


func test_every_dhull_gets_its_own_id() -> void:
	var ids := {}
	for record: DhullRecord in _garden.dhulls:
		ids[record.id] = true
	assert_eq(ids.size(), _garden.dhulls.size())
	assert_true(_garden.dhulls_in(&"nowhere").is_empty(), "nobody lives nowhere")


func test_whether_the_first_egg_was_given_survives_saving() -> void:
	_garden.give_first_egg(Vector3.ZERO)
	var saved: Dictionary = JSON.to_native(JSON.from_native(_garden.get_save_data()))
	var loaded: Node = GARDEN_SCRIPT.new()
	loaded.apply_save_data(saved)
	assert_true(loaded.first_egg_given, "still given")
	loaded.free()


func test_gardens_saved_before_eggs_count_as_given_one() -> void:
	var saved: Dictionary = _garden.get_save_data()
	saved.erase("first_egg_given")
	var loaded: Node = GARDEN_SCRIPT.new()
	loaded.apply_save_data(saved)
	assert_true(loaded.first_egg_given, "it already has Dhulls")
	loaded.free()


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
	_garden.garden_replaced.connect(func() -> void: replaced[0] = true)
	_garden.apply_save_data({})
	assert_true(replaced[0], "told the levels")


func _simulated_until() -> int:
	return _garden.get_save_data().simulated_until


func test_young_left_without_an_adult_make_a_mess() -> void:
	var young := _only_young()
	var mess_changes := [0]
	_garden.mess_changed.connect(func(_area: StringName) -> void: mess_changes[0] += 1)
	var tuning: MessTuning = _garden.mess_tuning
	var hours := tuning.hours_per_mess * 2.5
	# A minute more, so many small steps adding up to just under a threshold don't miss one.
	_garden.advance_to(_simulated_until() + roundi(hours * 3600.0) + GARDEN_SCRIPT.STEP_SECONDS)
	var expected := floori(hours * young.size() / tuning.hours_per_mess)
	var mess: Array[MessRecord] = _garden.mess_in(young[0].home_area)
	assert_eq(mess.size(), mini(expected, tuning.most_per_area))
	assert_eq(mess_changes[0], mess.size(), "told the levels each time")
	for bit in mess:
		var nearest := INF
		for record in young:
			nearest = minf(nearest, bit.position.distance_to(record.position))
		assert_true(nearest <= tuning.spread + 0.001, "%s lands near the young" % bit.id)


func test_young_looked_after_by_an_adult_make_no_mess() -> void:
	_garden.advance_to(_simulated_until() + 48 * 3600)
	assert_true(_garden.mess.is_empty(), "no mess with an adult around")


func test_mess_stops_piling_up_past_a_point() -> void:
	_only_young()
	_garden.advance_to(_simulated_until() + 14 * DateUtil.SECONDS_PER_DAY)
	var tuning: MessTuning = _garden.mess_tuning
	assert_eq(_garden.mess.size(), tuning.most_per_area)


func test_cleaning_up_takes_the_mess_away() -> void:
	var young := _only_young()
	_garden.make_mess_near(young[0])
	var bit: MessRecord = _garden.mess[0]
	_garden.clean_up(bit)
	assert_true(_garden.mess.is_empty(), "cleaned up")


func test_mess_survives_saving() -> void:
	var young := _only_young()
	_garden.make_mess_near(young[0])
	var saved: Dictionary = JSON.to_native(JSON.from_native(_garden.get_save_data()))
	var loaded: Node = GARDEN_SCRIPT.new()
	loaded.apply_save_data(saved)
	assert_eq(loaded.mess.size(), 1)
	var original: MessRecord = _garden.mess[0]
	var copy: MessRecord = loaded.mess[0]
	assert_eq(copy.id, original.id)
	assert_eq(copy.kind, original.kind)
	assert_eq(copy.area, original.area)
	assert_eq(copy.position, original.position)
	loaded.free()


## Takes every adult out of the garden, leaving the young on their own, and returns the young.
func _only_young() -> Array[DhullRecord]:
	var young: Array[DhullRecord] = []
	for record: DhullRecord in _garden.dhulls:
		if record.is_young():
			young.append(record)
	_garden.dhulls.assign(young)
	return young
