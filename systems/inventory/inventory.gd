extends Node
## The player's pockets and money, registered as the [code]Inventory[/code] autoload. Items are
## counted by id; what each one is comes from its ItemDefinition in data/items/.

## What the player holds, or their money, changed.
signal changed

const SAVE_ID := &"inventory"
const ITEMS_DIR := "res://data/items"

var money := 0
## Every item there is, by id.
var definitions: Dictionary[StringName, ItemDefinition] = {}

var _counts: Dictionary[StringName, int] = {}


func _init() -> void:
	for item: ItemDefinition in ResourceDir.load_all(ITEMS_DIR):
		definitions[item.id] = item


func _ready() -> void:
	Saves.register(SAVE_ID, self)


func count(id: StringName) -> int:
	return _counts.get(id, 0)


func add(id: StringName, amount := 1) -> void:
	assert(definitions.has(id), "No item '%s' in %s." % [id, ITEMS_DIR])
	_counts[id] = count(id) + amount
	changed.emit()


## Takes [param amount] of an item out of the pockets. Takes nothing and returns false if there
## aren't that many.
func take(id: StringName, amount := 1) -> bool:
	if count(id) < amount:
		return false
	_counts[id] = count(id) - amount
	if _counts[id] == 0:
		_counts.erase(id)
	changed.emit()
	return true


## The items the player holds at least one of, in the order of [enum ItemDefinition.Kind], then
## by id.
func held() -> Array[ItemDefinition]:
	var holding: Array[ItemDefinition] = []
	for id in _counts:
		holding.append(definitions[id])
	holding.sort_custom(
		func(a: ItemDefinition, b: ItemDefinition) -> bool:
			return a.kind < b.kind if a.kind != b.kind else String(a.id) < String(b.id)
	)
	return holding


func earn(amount: int) -> void:
	money += amount
	changed.emit()


## Pays [param amount]. Pays nothing and returns false if the player can't afford it.
func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	changed.emit()
	return true


func get_save_data() -> Dictionary:
	var counts := {}
	for id in _counts:
		counts[String(id)] = _counts[id]
	return {"money": money, "items": counts}


## Items the game no longer has are dropped from the pockets.
func apply_save_data(data: Dictionary) -> void:
	money = int(data.get("money", 0))
	_counts.clear()
	var counts: Variant = data.get("items", {})
	if counts is Dictionary:
		for id: Variant in counts:
			if definitions.has(StringName(id)) and int(counts[id]) > 0:
				_counts[StringName(id)] = int(counts[id])
	changed.emit()
