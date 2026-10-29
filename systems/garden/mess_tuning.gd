class_name MessTuning
extends Resource
## How fast young Dhulls left without an adult make a mess of the garden. The game's tuning is
## data/garden/mess.tres.

## Hours a young Dhull with no adult around takes to leave one bit of mess. Several young
## Dhulls left alone together make a mess that much faster.
@export_range(0.1, 48.0, 0.1, "suffix:h") var hours_per_mess := 3.0
## Mess stops piling up in an area past this many bits.
@export_range(1, 100) var most_per_area := 12
## How far from the young Dhull a bit of mess lands.
@export_range(0.0, 10.0, 0.1, "suffix:m") var spread := 1.5
