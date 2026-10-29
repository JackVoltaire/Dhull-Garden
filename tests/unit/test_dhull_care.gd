extends TestCase
## Petting and feeding a Dhull in person.

const TUNING_PATH := "res://data/dhulls/life.tres"

var _tuning: DhullLifeTuning
var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_tuning = load(TUNING_PATH)
	_rng.seed = 11


func test_a_content_dhull_loves_being_petted() -> void:
	var dhull := _dhull()
	var happiness := dhull.happiness
	assert_eq(DhullCare.pet(dhull, _tuning), DhullCare.Response.WELCOMED)
	assert_true(dhull.happiness > happiness, "happier")
	assert_true(dhull.bond > 0.0, "a little closer to you")


func test_too_much_petting_gets_annoying_until_it_wears_off() -> void:
	var dhull := _dhull()
	for _pet in ceili(_tuning.fussing_limit):
		DhullCare.pet(dhull, _tuning)
	assert_eq(DhullCare.pet(dhull, _tuning), DhullCare.Response.REFUSED)
	for _minute in 24 * 60:
		DhullLife.advance(dhull, 1.0 / 60.0, null, _tuning)
	dhull.happiness = 0.5
	dhull.hunger = 0.0
	dhull.tiredness = 0.0
	dhull.napping = false
	assert_eq(DhullCare.pet(dhull, _tuning), DhullCare.Response.WELCOMED)


func test_grumpy_and_napping_dhulls_dont_want_petting() -> void:
	var grumpy := _dhull()
	grumpy.happiness = 0.0
	grumpy.genome.alleles[DhullGenome.Gene.BOLDNESS] = Vector2i(90, 90)
	assert_eq(DhullCare.pet(grumpy, _tuning), DhullCare.Response.REFUSED)
	var napping := _dhull()
	napping.napping = true
	assert_eq(DhullCare.pet(napping, _tuning), DhullCare.Response.REFUSED)


func test_a_sad_dhull_takes_comfort_only_from_someone_it_trusts() -> void:
	var sad := _dhull()
	sad.happiness = 0.0
	sad.genome.alleles[DhullGenome.Gene.BOLDNESS] = Vector2i(10, 10)
	assert_eq(DhullCare.pet(sad, _tuning), DhullCare.Response.REFUSED)
	sad.bond = _tuning.trusted_from_bond
	sad.fussed_over = 0.0
	assert_eq(DhullCare.pet(sad, _tuning), DhullCare.Response.WELCOMED)


func test_a_hungry_dhull_eats() -> void:
	var dhull := _dhull()
	dhull.hunger = 0.8
	var noodles: ItemDefinition = load("res://data/items/instant_noodles.tres")
	assert_eq(DhullCare.feed(dhull, noodles, _tuning), DhullCare.Response.WELCOMED)
	assert_true(is_equal_approx(dhull.hunger, 0.8 - noodles.fills), "less hungry")


func test_a_full_dhull_turns_food_down() -> void:
	var dhull := _dhull()
	dhull.hunger = 0.0
	var chips: ItemDefinition = load("res://data/items/chips.tres")
	assert_eq(DhullCare.feed(dhull, chips, _tuning), DhullCare.Response.REFUSED)


func test_coffee_wakes_adults_but_the_young_wont_drink_it() -> void:
	var coffee: ItemDefinition = load("res://data/items/coffee.tres")
	var adult := _dhull()
	adult.tiredness = 0.8
	adult.napping = true
	assert_eq(DhullCare.feed(adult, coffee, _tuning), DhullCare.Response.WELCOMED)
	assert_false(adult.napping, "awake")
	assert_true(adult.tiredness < 0.8, "less tired")
	var young := _dhull()
	young.life_stage = DhullRecord.LifeStage.YOUNG
	young.hunger = 0.8
	assert_eq(DhullCare.feed(young, coffee, _tuning), DhullCare.Response.REFUSED)


func _dhull() -> DhullRecord:
	var record := DhullRecord.new()
	record.id = &"dhull_test"
	record.genome = DhullGenome.random(_rng)
	record.genome.alleles[DhullGenome.Gene.BOLDNESS] = Vector2i(50, 50)
	return record
