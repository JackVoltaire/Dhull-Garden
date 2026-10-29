extends TestCase
## The player's pockets and money, and the items there are. These tests use pockets of their own,
## not the Inventory autoload, so the game's own are never touched.

const INVENTORY_SCRIPT := preload("res://systems/inventory/inventory.gd")

var _pockets: Node


func before_each() -> void:
	_pockets = INVENTORY_SCRIPT.new()


func after_each() -> void:
	_pockets.free()


func test_items_go_in_and_come_out() -> void:
	_pockets.add(&"chips", 2)
	assert_eq(_pockets.count(&"chips"), 2)
	assert_true(_pockets.take(&"chips"), "took one")
	assert_eq(_pockets.count(&"chips"), 1)
	assert_false(_pockets.take(&"chips", 5), "can't take more than there is")
	assert_eq(_pockets.count(&"chips"), 1)


func test_held_items_are_listed_materials_first() -> void:
	_pockets.add(&"coffee")
	_pockets.add(&"stone")
	_pockets.add(&"chips")
	var held: Array[ItemDefinition] = _pockets.held()
	var ids: Array[StringName] = []
	for item in held:
		ids.append(item.id)
	assert_eq(ids, [&"stone", &"chips", &"coffee"] as Array[StringName])


func test_money_is_earned_and_spent_but_never_overspent() -> void:
	_pockets.earn(30)
	assert_true(_pockets.spend(20), "paid")
	assert_false(_pockets.spend(20), "can't afford it")
	assert_eq(_pockets.money, 10)


func test_pockets_survive_saving() -> void:
	_pockets.earn(42)
	_pockets.add(&"crystal", 3)
	var saved: Dictionary = JSON.to_native(JSON.from_native(_pockets.get_save_data()))
	var loaded: Node = INVENTORY_SCRIPT.new()
	loaded.apply_save_data(saved)
	assert_eq(loaded.money, 42)
	assert_eq(loaded.count(&"crystal"), 3)
	loaded.free()


func test_items_the_game_no_longer_has_are_dropped() -> void:
	_pockets.apply_save_data({"money": 5, "items": {"crystal": 1, "gone_item": 4}})
	assert_eq(_pockets.count(&"crystal"), 1)
	assert_eq(_pockets.held().size(), 1)


func test_every_item_is_named_and_unique() -> void:
	var items: Array[Resource] = ResourceDir.load_all(INVENTORY_SCRIPT.ITEMS_DIR)
	assert_eq(_pockets.definitions.size(), items.size(), "no two items share an id")
	for item: ItemDefinition in items:
		assert_true(
			TranslationServer.translate(item.display_name) != item.display_name,
			"%s has a name" % item.id
		)


## Otherwise buying from Pebble and selling straight back would make money out of nothing.
func test_pebble_never_pays_more_than_he_asks() -> void:
	for item: ItemDefinition in _pockets.definitions.values():
		if item.buy_price > 0:
			assert_true(
				item.sell_price < item.buy_price, "%s sells for less than it costs" % item.id
			)
