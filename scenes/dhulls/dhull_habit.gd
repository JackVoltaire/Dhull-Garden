class_name DhullHabit
extends Resource
## What a Dhull does with itself while it's awake in one mood: where it heads, and whether it
## stands or sits once it's there. A sad Dhull goes off on its own and sits in a corner; a playful
## one keeps running up to the others.

enum Destination { STAY, NEARBY, AWAY_FROM_OTHERS, TO_ANOTHER_DHULL }

## Where it heads when the mood comes over it, and on each outing after that.
@export var heads_to := Destination.STAY
## What it does once it's there: stand or sit.
@export var rests_by := DhullState.Activity.STANDING
## How long it rests before heading out again, for a Dhull of average energy; energetic Dhulls
## go sooner. 0 means it stays put until its mood changes.
@export_range(0.0, 300.0, 1.0, "suffix:s") var outing_every_seconds := 0.0
