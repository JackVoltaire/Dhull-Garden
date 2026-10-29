class_name DhullHabit
extends Resource
## What a Dhull does with itself while it's awake in one mood: where it heads, what it does once
## it's there, and what it shows now and then while it rests. A sad Dhull goes off on its own,
## sits in a corner and sighs, scrolling its phone if it's grown; a playful one keeps running up
## to the others.

enum Destination { STAY, NEARBY, AWAY_FROM_OTHERS, TO_ANOTHER_DHULL }

## Where it heads when the mood comes over it, and on each outing after that.
@export var heads_to := Destination.STAY
## What a young Dhull does once it's there: stand or sit.
@export var rests_by := DhullState.Activity.STANDING
## What an adult does there: stand or sit too, or hang out, scrolling its phone or sipping a drink.
@export var adults_rest_by := DhullState.Activity.STANDING
## How long it rests before heading out again, for a Dhull of average energy; energetic Dhulls
## go sooner. 0 means it stays put until its mood changes.
@export_range(0.0, 300.0, 1.0, "suffix:s") var outing_every_seconds := 0.0
## A reaction it shows now and then while it rests in this mood, like a sigh.
@export var idle_reaction := DhullReaction.Symbol.NONE
## About how often it shows it.
@export_range(1.0, 300.0, 1.0, "suffix:s") var idle_reaction_every_seconds := 20.0
## Whether gloomy blue lines come down over its face with the reaction, as in anime.
@export var gloomy := false


## What a Dhull does once it's there, grown up or young.
func rest_for(adult: bool) -> DhullState.Activity:
	return adults_rest_by if adult else rests_by
