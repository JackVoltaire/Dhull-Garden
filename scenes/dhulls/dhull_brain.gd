class_name DhullBrain
extends Node
## Carries out a Dhull's habits in a level. When it's given a mood, the Dhull heads where that
## mood takes it, walking along the level's navigation mesh, then rests there as the habit says,
## hanging out if it's grown, and now and then heads out again (see DhullHabit). It reports what
## the Dhull is doing through [signal activity_changed]; while the Dhull naps, the brain rests.

signal activity_changed(activity: DhullState.Activity)

@export var habits: DhullHabits
## The Dhull it moves.
@export var dhull: Dhull
@export var navigation_agent: NavigationAgent3D
## How fast an adult of average energy walks.
@export_range(0.1, 3.0, 0.05, "suffix:m/s") var walk_speed := 0.7
## How fast it turns to face where it's going.
@export_range(0.5, 20.0, 0.5, "suffix:rad/s") var turn_speed := 6.0
## How far it strolls when it goes somewhere nearby.
@export_range(0.5, 20.0, 0.5, "suffix:m") var nearby_distance := 4.0
## How far around it looks for a spot away from the others.
@export_range(1.0, 40.0, 0.5, "suffix:m") var solitude_distance := 10.0
## How many spots it weighs up when looking for one away from the others.
@export_range(1, 64) var solitude_spots := 12
## How close it walks up to another Dhull.
@export_range(0.2, 5.0, 0.1, "suffix:m") var company_gap := 0.9

var _habit: DhullHabit
var _awake := false
var _walking := false
var _outing_due := false
var _until_outing := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_physics_process(false)


## Takes up the habit of [param mood], heading off where it leads. Nothing changes if the Dhull
## is already awake in that mood.
func follow_mood(mood: DhullState.Mood) -> void:
	var habit := habits.habit_for(mood)
	if _awake and habit == _habit:
		return
	_awake = true
	_habit = habit
	_outing_due = true
	set_physics_process(true)


## Stops wherever the Dhull is, as when it dozes off.
func rest() -> void:
	_awake = false
	_walking = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _walking:
		_walk(delta)
		return
	if not _outing_due and _habit.outing_every_seconds > 0.0:
		_until_outing -= delta
		_outing_due = _until_outing <= 0.0
	if _outing_due and _map_knows_where_it_is():
		_outing_due = false
		_head_out()


func _head_out() -> void:
	var from := dhull.global_position
	var others := _other_dhulls()
	var destination: Vector3
	match _habit.heads_to:
		DhullHabit.Destination.STAY:
			_settle()
			return
		DhullHabit.Destination.AWAY_FROM_OTHERS:
			var spots := PackedVector3Array()
			for _spot in solitude_spots:
				spots.append(_on_map(from + _random_offset(solitude_distance)))
			destination = DhullHabits.loneliest(spots, others)
		DhullHabit.Destination.TO_ANOTHER_DHULL when not others.is_empty():
			var other := DhullHabits.nearest(from, others)
			destination = _on_map(DhullHabits.beside(from, other, company_gap))
		_:
			destination = _on_map(from + _random_offset(nearby_distance))
	navigation_agent.target_position = destination
	_walking = true
	activity_changed.emit(DhullState.Activity.WALKING)


func _settle() -> void:
	_walking = false
	_until_outing = _habit.outing_every_seconds / DhullState.speed_scale(dhull.genome)
	activity_changed.emit(_habit.rest_for(dhull.record.is_adult()))


func _walk(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		_settle()
		return
	var next := navigation_agent.get_next_path_position()
	var heading := next - dhull.global_position
	heading.y = 0.0
	if heading.length_squared() > 0.0001:
		var facing := atan2(heading.x, heading.z)
		dhull.global_rotation.y = rotate_toward(dhull.global_rotation.y, facing, turn_speed * delta)
	var speed := walk_speed * DhullState.speed_scale(dhull.genome) * dhull.size_scale()
	var step := dhull.global_position.move_toward(next, speed * delta)
	# The navigation mesh floats up to a cell above the ground; walking on it would hover.
	dhull.global_position = Ground.below(dhull, step)
	dhull.record.position = dhull.global_position
	dhull.record.facing = dhull.global_rotation.y


func _other_dhulls() -> PackedVector3Array:
	var positions := PackedVector3Array()
	for other: Dhull in get_tree().get_nodes_in_group(Dhull.GROUP):
		if other != dhull:
			positions.append(other.global_position)
	return positions


func _random_offset(distance: float) -> Vector3:
	return Vector3(distance * sqrt(_rng.randf()), 0.0, 0.0).rotated(Vector3.UP, _rng.randf() * TAU)


## Whether the navigation map has the level's navigation mesh around the Dhull yet. For the
## first frames after a level loads it doesn't: before its first update it can't be asked at
## all, and for a moment after that it answers every question with the origin.
func _map_knows_where_it_is() -> bool:
	if NavigationServer3D.map_get_iteration_id(_map()) == 0:
		return false
	var owner_region := NavigationServer3D.map_get_closest_point_owner(
		_map(), dhull.global_position
	)
	return owner_region.is_valid()


func _on_map(point: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(_map(), point)


func _map() -> RID:
	return navigation_agent.get_navigation_map()
