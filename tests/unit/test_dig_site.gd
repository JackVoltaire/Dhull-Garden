extends TestCase
## Digging in the mining minigame's wall.

const TUNING_PATH := "res://data/mining/mining.tres"
const FINDS_DIR := "res://data/mining/finds"

var _tuning: MiningTuning
var _finds: Array[DigFind] = []
var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_tuning = load(TUNING_PATH)
	_finds.clear()
	for find: DigFind in ResourceDir.load_all(FINDS_DIR):
		_finds.append(find)
	_rng.seed = 3


func test_finds_are_buried_whole_inside_the_wall_without_overlapping() -> void:
	for wall in 50:
		var site := DigSite.generate(_tuning, _finds, _rng)
		var count := site.buried.size()
		assert_true(count >= _tuning.finds_range.x, "wall %d buries enough" % wall)
		assert_true(count <= _tuning.finds_range.y, "wall %d buries no more than it should" % wall)
		var covered := {}
		for placed in site.buried:
			for cell in placed.cells():
				assert_true(site.has_cell(cell), "inside the wall")
				assert_false(covered.has(cell), "no overlap")
				covered[cell] = true


func test_the_rock_is_as_thick_as_it_should_be() -> void:
	var site := DigSite.generate(_tuning, _finds, _rng)
	for y in site.size.y:
		for x in site.size.x:
			var rock := site.rock_at(Vector2i(x, y))
			assert_true(
				rock >= _tuning.depth_range.x and rock <= _tuning.depth_range.y, "%d, %d" % [x, y]
			)


func test_the_pick_hits_one_cell_hard_and_its_neighbours_lightly() -> void:
	var site := _flat_wall(4)
	site.strike(Vector2i(5, 5), DigSite.Tool.PICK)
	assert_eq(site.rock_at(Vector2i(5, 5)), 2)
	assert_eq(site.rock_at(Vector2i(6, 5)), 3)
	assert_eq(site.rock_at(Vector2i(5, 4)), 3)
	assert_eq(site.rock_at(Vector2i(6, 6)), 4, "corners untouched")
	assert_eq(site.wall_left, _tuning.wall_strength - 1.0)


func test_the_hammer_hits_a_whole_patch_and_shakes_the_wall_harder() -> void:
	var site := _flat_wall(4)
	site.strike(Vector2i(5, 5), DigSite.Tool.HAMMER)
	for offset in DigSite.HAMMER_PATTERN:
		assert_eq(site.rock_at(Vector2i(5, 5) + offset), 2)
	assert_eq(site.rock_at(Vector2i(7, 5)), 4, "outside the patch untouched")
	assert_eq(site.wall_left, _tuning.wall_strength - _tuning.hammer_shake)


func test_striking_the_edge_stays_inside_the_wall() -> void:
	var site := _flat_wall(4)
	site.strike(Vector2i.ZERO, DigSite.Tool.HAMMER)
	assert_eq(site.rock_at(Vector2i.ZERO), 2)


func test_a_find_counts_once_every_cell_is_dug_out() -> void:
	var site := _flat_wall(2)
	var stone := _find(&"stone")
	assert_true(site.bury(stone, Vector2i(3, 3)), "buried")
	assert_false(site.bury(stone, Vector2i(4, 4)), "no overlapping")
	assert_false(site.bury(stone, site.size - Vector2i.ONE), "can't stick out")
	site.strike(Vector2i(3, 3), DigSite.Tool.PICK)
	assert_true(site.dug_out().is_empty(), "not all of it yet")
	site.strike(Vector2i(4, 4), DigSite.Tool.PICK)
	site.strike(Vector2i(3, 4), DigSite.Tool.PICK)
	site.strike(Vector2i(4, 3), DigSite.Tool.PICK)
	assert_eq(site.dug_out().size(), 1)
	assert_true(site.is_done(), "nothing left to find")


func test_the_wall_caves_in_after_enough_strikes() -> void:
	var site := _flat_wall(9)
	for _strike in ceili(_tuning.wall_strength):
		site.strike(Vector2i(1, 1), DigSite.Tool.PICK)
	assert_true(site.has_caved_in(), "caved in")
	var rock := site.rock_at(Vector2i(8, 8))
	site.strike(Vector2i(8, 8), DigSite.Tool.PICK)
	assert_eq(site.rock_at(Vector2i(8, 8)), rock, "no more digging")


func _flat_wall(layers: int) -> DigSite:
	var site := DigSite.new(_tuning)
	for y in site.size.y:
		for x in site.size.x:
			site.set_rock(Vector2i(x, y), layers)
	return site


func _find(item_id: StringName) -> DigFind:
	for find in _finds:
		if find.item.id == item_id:
			return find
	return null
