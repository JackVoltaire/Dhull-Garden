extends TestCase
## Buying from and selling to Pebble. These tests use pockets of their own, not the Inventory
## autoload.

const INVENTORY_SCRIPT := preload("res://systems/inventory/inventory.gd")

var _pockets: Node


func before_each() -> void:
	_pockets = INVENTORY_SCRIPT.new()


func after_each() -> void:
	_pockets.free()


func test_buying_costs_its_price() -> void:
	var chips: ItemDefinition = _pockets.definitions[&"chips"]
	_pockets.earn(chips.buy_price + 1)
	assert_true(ShopTrade.buy(chips, _pockets), "bought")
	assert_eq(_pockets.count(&"chips"), 1)
	assert_eq(_pockets.money, 1)


func test_you_cant_buy_what_you_cant_afford() -> void:
	var chips: ItemDefinition = _pockets.definitions[&"chips"]
	_pockets.earn(chips.buy_price - 1)
	assert_false(ShopTrade.buy(chips, _pockets), "too expensive")
	assert_eq(_pockets.count(&"chips"), 0)
	assert_eq(_pockets.money, chips.buy_price - 1)


func test_pebble_only_sells_what_he_prices() -> void:
	var crystal: ItemDefinition = _pockets.definitions[&"crystal"]
	_pockets.earn(1000)
	assert_false(ShopTrade.buy(crystal, _pockets), "not for sale")
	var definitions: Array[ItemDefinition] = []
	definitions.assign(_pockets.definitions.values())
	var stock := ShopTrade.stock(definitions)
	assert_false(crystal in stock, "not in stock")
	for index in range(1, stock.size()):
		assert_true(stock[index - 1].buy_price <= stock[index].buy_price, "cheapest first")


func test_selling_pays_and_takes_one() -> void:
	var stone: ItemDefinition = _pockets.definitions[&"stone"]
	_pockets.add(&"stone", 2)
	assert_true(ShopTrade.sell(stone, _pockets), "sold")
	assert_eq(_pockets.count(&"stone"), 1)
	assert_eq(_pockets.money, stone.sell_price)
	_pockets.take(&"stone")
	assert_false(ShopTrade.sell(stone, _pockets), "nothing left to sell")
