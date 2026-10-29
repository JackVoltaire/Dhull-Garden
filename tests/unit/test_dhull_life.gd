extends TestCase
## How Dhulls' needs change over time, how adults look after the young, and which moods show.

const TUNING_PATH := "res://data/dhulls/life.tres"
const HOME := &"test_area"

var _tuning: DhullLifeTuning
var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_tuning = load(TUNING_PATH)
	_rng.seed = 7


func test_adults_forage_so_they_never_starve() -> void:
	var adult := _dhull(DhullRecord.LifeStage.ADULT)
	_live(adult, 48.0)
	assert_eq(adult.hunger, _tuning.forage_hunger)
	assert_true(adult.happiness > _tuning.unhappy_at, "a foraging adult stays happy enough")


func test_young_left_alone_starve_and_grow_unhappy() -> void:
	var young := _dhull(DhullRecord.LifeStage.YOUNG)
	_live(young, 48.0)
	assert_eq(young.hunger, 1.0)
	assert_true(young.happiness <= _tuning.unhappy_at, "a young Dhull alone grows unhappy")


func test_the_least_nurturing_adult_feeds_the_young_the_bare_minimum() -> void:
	var young := _dhull(DhullRecord.LifeStage.YOUNG)
	var carer := _adult_with_friendliness(0)
	_live(young, 48.0, carer)
	assert_eq(young.hunger, _tuning.bare_minimum_hunger)
	assert_eq(DhullLife.mood_for(young, _tuning), DhullState.Mood.HUNGRY)


func test_a_nurturing_adult_keeps_the_young_fed_and_happy() -> void:
	var young := _dhull(DhullRecord.LifeStage.YOUNG)
	young.happiness = 0.0
	var carer := _adult_with_friendliness(DhullGenome.MAX_LEVEL)
	_live(young, 48.0, carer)
	assert_true(young.hunger <= _tuning.nurtured_hunger, "fed well")
	assert_true(young.happiness >= _tuning.nurtured_happiness, "kept happy")


func test_the_young_are_looked_after_by_the_most_nurturing_adult_at_home() -> void:
	var young := _dhull(DhullRecord.LifeStage.YOUNG)
	var kind := _adult_with_friendliness(80)
	var cold := _adult_with_friendliness(10)
	var kinder_but_away := _adult_with_friendliness(100)
	kinder_but_away.home_area = &"elsewhere"
	var garden: Array[DhullRecord] = [young, cold, kinder_but_away, kind]
	assert_true(DhullLife.carer_for(young, garden) == kind, "the kind adult at home")
	assert_true(DhullLife.carer_for(kind, garden) == null, "adults need no carer")
	var alone: Array[DhullRecord] = [young, kinder_but_away]
	assert_true(DhullLife.carer_for(young, alone) == null, "no adult at home")


func test_dhulls_nap_when_tired_and_wake_up_rested() -> void:
	var adult := _dhull(DhullRecord.LifeStage.ADULT)
	adult.tiredness = _tuning.nap_at - 0.001
	_live(adult, 1.0 / 60.0)
	assert_true(adult.napping, "dozes off")
	var napping_minutes := 0
	while adult.napping and napping_minutes < 24 * 60:
		_live(adult, 1.0 / 60.0)
		napping_minutes += 1
	assert_false(adult.napping, "wakes up")
	assert_true(adult.tiredness <= _tuning.wake_at, "rested")


func test_the_young_nap_more_than_adults() -> void:
	var young := _dhull(DhullRecord.LifeStage.YOUNG)
	var adult := _dhull(DhullRecord.LifeStage.ADULT)
	var carer := _adult_with_friendliness(50)
	var young_napping_minutes := 0
	var adult_napping_minutes := 0
	for _minute in 24 * 60:
		DhullLife.advance(young, 1.0 / 60.0, carer, _tuning)
		DhullLife.advance(adult, 1.0 / 60.0, null, _tuning)
		young_napping_minutes += int(young.napping)
		adult_napping_minutes += int(adult.napping)
	assert_true(adult_napping_minutes > 0, "adults nap too")
	assert_true(young_napping_minutes > adult_napping_minutes, "the young nap more")


func test_unhappy_dhulls_are_grumpy_if_bold_and_sad_if_timid() -> void:
	var dhull := _dhull(DhullRecord.LifeStage.ADULT)
	dhull.happiness = _tuning.unhappy_at
	dhull.hunger = 1.0
	dhull.genome.alleles[DhullGenome.Gene.BOLDNESS] = Vector2i(90, 90)
	assert_eq(DhullLife.mood_for(dhull, _tuning), DhullState.Mood.GRUMPY)
	dhull.genome.alleles[DhullGenome.Gene.BOLDNESS] = Vector2i(10, 10)
	assert_eq(DhullLife.mood_for(dhull, _tuning), DhullState.Mood.SAD)


func test_needs_running_high_show_as_hungry_or_sleepy() -> void:
	var dhull := _dhull(DhullRecord.LifeStage.ADULT)
	dhull.tiredness = _tuning.sleepy_at
	assert_eq(DhullLife.mood_for(dhull, _tuning), DhullState.Mood.SLEEPY)
	dhull.hunger = _tuning.hungry_at
	assert_eq(DhullLife.mood_for(dhull, _tuning), DhullState.Mood.HUNGRY)


func test_happy_dhulls_are_playful_when_rested() -> void:
	var dhull := _dhull(DhullRecord.LifeStage.ADULT)
	dhull.happiness = _tuning.happy_at
	dhull.tiredness = _tuning.playful_below_tiredness
	assert_eq(DhullLife.mood_for(dhull, _tuning), DhullState.Mood.PLAYFUL)
	dhull.tiredness = (_tuning.playful_below_tiredness + _tuning.sleepy_at) / 2.0
	assert_eq(DhullLife.mood_for(dhull, _tuning), DhullState.Mood.HAPPY)


func test_a_fresh_dhull_is_content() -> void:
	assert_eq(
		DhullLife.mood_for(_dhull(DhullRecord.LifeStage.ADULT), _tuning), DhullState.Mood.CONTENT
	)


func test_records_survive_saving() -> void:
	var coloring := DhullColoring.new()
	coloring.id = &"test_coloring"
	var record := _dhull(DhullRecord.LifeStage.YOUNG)
	record.coloring = coloring
	record.hunger = 0.25
	record.tiredness = 0.5
	record.happiness = 0.75
	record.napping = true
	record.position = Vector3(1.5, 0.25, -2.0)
	record.facing = 1.25
	record.placed = true
	# Saves keep exact types this way, so a Vector3 comes back a Vector3.
	var saved: Dictionary = JSON.to_native(JSON.from_native(record.to_dict()))
	var colorings: Dictionary[StringName, DhullColoring] = {coloring.id: coloring}
	var loaded := DhullRecord.from_dict(saved, colorings, null, _rng)
	assert_eq(loaded.id, record.id)
	assert_eq(loaded.genome.alleles, record.genome.alleles)
	assert_true(loaded.coloring == coloring, "same coloring")
	assert_eq(loaded.life_stage, DhullRecord.LifeStage.YOUNG)
	assert_eq(loaded.home_area, HOME)
	assert_eq(loaded.hunger, 0.25)
	assert_eq(loaded.tiredness, 0.5)
	assert_eq(loaded.happiness, 0.75)
	assert_true(loaded.napping, "still napping")
	assert_eq(loaded.position, record.position)
	assert_eq(loaded.facing, 1.25)
	assert_true(loaded.placed, "still placed")


func test_records_with_unknown_colorings_get_the_default() -> void:
	var default_coloring := DhullColoring.new()
	var data := {"id": "dhull_1", "coloring": "gone"}
	var no_colorings: Dictionary[StringName, DhullColoring] = {}
	var loaded := DhullRecord.from_dict(data, no_colorings, default_coloring, _rng)
	assert_true(loaded.coloring == default_coloring, "default coloring")
	assert_false(loaded.placed, "not placed")


func _dhull(life_stage: DhullRecord.LifeStage) -> DhullRecord:
	var record := DhullRecord.new()
	record.id = &"dhull_test"
	record.genome = DhullGenome.random(_rng)
	record.life_stage = life_stage
	record.home_area = HOME
	return record


func _adult_with_friendliness(friendliness: int) -> DhullRecord:
	var adult := _dhull(DhullRecord.LifeStage.ADULT)
	adult.genome.alleles[DhullGenome.Gene.FRIENDLINESS] = Vector2i(friendliness, friendliness)
	return adult


## Lives through [param hours] a minute at a time, as the Garden does.
func _live(record: DhullRecord, hours: float, carer: DhullRecord = null) -> void:
	for _minute in roundi(hours * 60.0):
		DhullLife.advance(record, 1.0 / 60.0, carer, _tuning)
