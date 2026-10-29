class_name ShopTrade
extends RefCounted
## Buying from and selling to a shop like Pebble's, one item at a time. [param pockets] is an
## Inventory: the autoload in the game, or one of its own in tests.


## What the shop sells: every item it asks a price for, cheapest first.
static func stock(definitions: Array[ItemDefinition]) -> Array[ItemDefinition]:
	var for_sale: Array[ItemDefinition] = []
	for item in definitions:
		if item.buy_price > 0:
			for_sale.append(item)
	for_sale.sort_custom(
		func(a: ItemDefinition, b: ItemDefinition) -> bool: return a.buy_price < b.buy_price
	)
	return for_sale


## Buys one [param item]. Returns false, buying nothing, if the shop doesn't sell it or the
## player can't afford it.
static func buy(item: ItemDefinition, pockets: Node) -> bool:
	if item.buy_price <= 0 or not pockets.spend(item.buy_price):
		return false
	pockets.add(item.id)
	return true


## Sells one [param item]. Returns false, selling nothing, if the player has none.
static func sell(item: ItemDefinition, pockets: Node) -> bool:
	if not pockets.take(item.id):
		return false
	pockets.earn(item.sell_price)
	return true
