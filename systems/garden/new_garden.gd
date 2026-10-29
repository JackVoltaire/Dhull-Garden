class_name NewGarden
extends Resource
## Who lives in the garden when a new game starts. The design starts every garden with a single
## egg; until eggs can hatch, a new garden starts with these grown and young Dhulls instead.

## The area they live in, as the level's DhullSpawner names it.
@export var home_area := &"dream_island"
@export_range(0, 20) var adults := 3
@export_range(0, 20) var young := 2
@export var coloring: DhullColoring
