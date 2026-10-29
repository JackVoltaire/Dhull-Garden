class_name ItemDefinition
extends Resource
## One kind of item: something you can carry, sell, buy, feed to a Dhull or craft with. Items are
## data: one .tres per item in data/items/, found automatically.

enum Kind { MATERIAL, FOOD, DRINK }

## Stable name that saves refer to it by. Never rename it.
@export var id: StringName
## Translation key of its name.
@export var display_name := ""
@export var kind := Kind.MATERIAL
## What Pebble asks for it, or 0 if he doesn't sell it.
@export_range(0, 9999) var buy_price := 0
## What Pebble pays for it.
@export_range(0, 9999) var sell_price := 1

@export_group("Eating")
## How much hunger it takes away, from 0 to 1.
@export_range(0.0, 1.0, 0.01) var fills := 0.0
## How much happier it makes a Dhull.
@export_range(-1.0, 1.0, 0.01) var cheers := 0.0
## How much tiredness it takes away, as coffee does. Only adults take these.
@export_range(0.0, 1.0, 0.01) var wakes := 0.0

@export_group("Look")
## What a Dhull holds up when it posts about the item, like the cup of noodles it's eating.
@export var prop: Mesh


func is_edible() -> bool:
	return kind == Kind.FOOD or kind == Kind.DRINK


func is_for_adults_only() -> bool:
	return wakes > 0.0
