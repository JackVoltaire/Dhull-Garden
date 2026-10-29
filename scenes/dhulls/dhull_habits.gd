class_name DhullHabits
extends Resource
## A Dhull's habit for each mood (see DhullHabit), and the plain rules for picking where it goes.
## The game's habits are in data/dhulls/habits.tres. Exactly where a stroll ends is left to
## chance, but what a Dhull does never is: its mood decides.

@export var content: DhullHabit
@export var happy: DhullHabit
@export var playful: DhullHabit
@export var sleepy: DhullHabit
@export var hungry: DhullHabit
@export var sad: DhullHabit
@export var grumpy: DhullHabit


func habit_for(mood: DhullState.Mood) -> DhullHabit:
	var by_mood: Dictionary[DhullState.Mood, DhullHabit] = {
		DhullState.Mood.CONTENT: content,
		DhullState.Mood.HAPPY: happy,
		DhullState.Mood.PLAYFUL: playful,
		DhullState.Mood.SLEEPY: sleepy,
		DhullState.Mood.HUNGRY: hungry,
		DhullState.Mood.SAD: sad,
		DhullState.Mood.GRUMPY: grumpy,
	}
	return by_mood[mood]


## Of [param spots], the one farthest from its nearest neighbour in [param others]: the best
## corner to be alone in. The first spot when there's nobody else around.
static func loneliest(spots: PackedVector3Array, others: PackedVector3Array) -> Vector3:
	var best := spots[0]
	var best_distance := -1.0
	for spot in spots:
		var distance := _distance_to_nearest(spot, others)
		if distance > best_distance:
			best = spot
			best_distance = distance
	return best


## Of [param others], which must not be empty, the one closest to [param from].
static func nearest(from: Vector3, others: PackedVector3Array) -> Vector3:
	var closest := others[0]
	for other in others:
		if from.distance_squared_to(other) < from.distance_squared_to(closest):
			closest = other
	return closest


## Where to stop when walking from [param from] up to [param to]: [param gap] short of it, or
## where it already is if it's closer than that.
static func beside(from: Vector3, to: Vector3, gap: float) -> Vector3:
	if from.distance_to(to) <= gap:
		return from
	return to + (from - to).normalized() * gap


static func _distance_to_nearest(spot: Vector3, others: PackedVector3Array) -> float:
	var nearest_distance := INF
	for other in others:
		nearest_distance = minf(nearest_distance, spot.distance_to(other))
	return nearest_distance
