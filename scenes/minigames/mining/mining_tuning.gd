class_name MiningTuning
extends Resource
## The numbers behind the mining minigame: how big the wall is, how much rock covers it, how many
## things are buried in it and how much it can take before it caves in. The game's tuning is
## data/mining/mining.tres.

## Cells across and down.
@export var size := Vector2i(13, 10)
## The thinnest and thickest rock over any cell, in layers.
@export var depth_range := Vector2i(2, 5)
## Lumps of thicker rock spread over the wall, so it isn't evenly flat.
@export_range(0, 40) var lumps := 9
## How many things are buried, from the fewest to the most.
@export var finds_range := Vector2i(2, 4)
## How many strikes of the pick the wall takes before it caves in.
@export_range(1.0, 200.0, 1.0) var wall_strength := 40.0
## How much the hammer shakes the wall compared with the pick.
@export_range(1.0, 5.0, 0.1) var hammer_shake := 2.0
