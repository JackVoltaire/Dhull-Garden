class_name Lookable
extends Marker3D
## Something that catches a Dhull's eye, placed where the eyes should land: the dreamer's face, a
## character's, another Dhull's, a mess on the ground. Dhulls look at the most interesting one
## they can see nearby (see DhullGaze).

const GROUP := &"lookables"

## How much it catches the eye, from 0 to 1. Nearer things catch it more.
@export_range(0.0, 1.0, 0.05) var interest := 0.5


func _ready() -> void:
	add_to_group(GROUP)
