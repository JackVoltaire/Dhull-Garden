extends TestCase
## What Dhulls do in each mood, and how they pick where to go.

const HABITS_PATH := "res://data/dhulls/habits.tres"

var _habits: DhullHabits


func before_each() -> void:
	_habits = load(HABITS_PATH)


func test_every_mood_has_a_habit_that_stands_or_sits() -> void:
	var resting := [DhullState.Activity.STANDING, DhullState.Activity.SITTING]
	for mood: DhullState.Mood in DhullState.Mood.values():
		var habit := _habits.habit_for(mood)
		var mood_name: String = DhullState.Mood.keys()[mood]
		assert_true(habit != null, mood_name + " has a habit")
		if habit:
			assert_true(habit.rests_by in resting, mood_name + " stands or sits")


func test_each_mood_has_its_own_habit() -> void:
	var seen := {}
	for mood: DhullState.Mood in DhullState.Mood.values():
		seen[_habits.habit_for(mood)] = true
	assert_eq(seen.size(), DhullState.Mood.size())


func test_sad_dhulls_sit_in_a_corner() -> void:
	var sad := _habits.habit_for(DhullState.Mood.SAD)
	assert_eq(sad.heads_to, DhullHabit.Destination.AWAY_FROM_OTHERS)
	assert_eq(sad.rests_by, DhullState.Activity.SITTING)
	assert_eq(sad.outing_every_seconds, 0.0)


func test_playful_dhulls_run_up_to_the_others() -> void:
	var playful := _habits.habit_for(DhullState.Mood.PLAYFUL)
	assert_eq(playful.heads_to, DhullHabit.Destination.TO_ANOTHER_DHULL)
	assert_true(playful.outing_every_seconds > 0.0, "and keep at it")


func test_the_loneliest_spot_is_farthest_from_everyone() -> void:
	var spots := PackedVector3Array([Vector3(1, 0, 0), Vector3(10, 0, 0), Vector3(-8, 0, 0)])
	var others := PackedVector3Array([Vector3(0, 0, 0), Vector3(9, 0, 0)])
	assert_eq(DhullHabits.loneliest(spots, others), Vector3(-8, 0, 0))
	assert_eq(DhullHabits.loneliest(spots, PackedVector3Array()), Vector3(1, 0, 0))


func test_dhulls_walk_up_to_the_nearest_other_and_stop_short() -> void:
	var from := Vector3(0, 0, 0)
	var others := PackedVector3Array([Vector3(0, 0, 9), Vector3(4, 0, 0)])
	var nearest := DhullHabits.nearest(from, others)
	assert_eq(nearest, Vector3(4, 0, 0))
	assert_eq(DhullHabits.beside(from, nearest, 1.0), Vector3(3, 0, 0))
	assert_eq(DhullHabits.beside(Vector3(3.5, 0, 0), nearest, 1.0), Vector3(3.5, 0, 0))
