extends TestCase
## What Dhulls do in each mood, and how they pick where to go.

const HABITS_PATH := "res://data/dhulls/habits.tres"

var _habits: DhullHabits


func before_each() -> void:
	_habits = load(HABITS_PATH)


## The young have no phones and don't drink coffee: only adults hang out.
func test_every_mood_has_a_habit_to_rest_by_and_only_adults_hang_out() -> void:
	for mood: DhullState.Mood in DhullState.Mood.values():
		var habit := _habits.habit_for(mood)
		var mood_name: String = DhullState.Mood.keys()[mood]
		assert_true(habit != null, mood_name + " has a habit")
		if habit:
			var young := habit.rest_for(false)
			var adult := habit.rest_for(true)
			assert_true(young in DhullState.RESTING, mood_name + " young rest")
			assert_false(young in DhullState.HANGING_OUT, mood_name + " young don't hang out")
			assert_true(adult in DhullState.RESTING, mood_name + " adults rest")


func test_grown_dhulls_scroll_their_phones_or_sip_to_stay_awake() -> void:
	for mood: DhullState.Mood in [DhullState.Mood.CONTENT, DhullState.Mood.SAD]:
		var habit := _habits.habit_for(mood)
		assert_eq(habit.rest_for(true), DhullState.Activity.SCROLLING)
	var sleepy := _habits.habit_for(DhullState.Mood.SLEEPY)
	assert_eq(sleepy.rest_for(true), DhullState.Activity.SIPPING)
	assert_eq(sleepy.rest_for(false), DhullState.Activity.SITTING)


func test_energetic_dhulls_drink_energy_drinks_and_the_rest_coffee() -> void:
	var genome := DhullGenome.random(RandomNumberGenerator.new())
	genome.alleles[DhullGenome.Gene.ENERGY] = Vector2i(DhullGenome.MAX_LEVEL, DhullGenome.MAX_LEVEL)
	assert_eq(_habits.drink_for(genome).id, &"energy_drink")
	genome.alleles[DhullGenome.Gene.ENERGY] = Vector2i(0, 0)
	assert_eq(_habits.drink_for(genome).id, &"coffee")
	assert_true(_habits.coffee.prop != null, "coffee can be held")
	assert_true(_habits.energy_drink.prop != null, "energy drinks can be held")


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


func test_sad_and_grumpy_dhulls_sigh_gloomily_now_and_then() -> void:
	for mood: DhullState.Mood in [DhullState.Mood.SAD, DhullState.Mood.GRUMPY]:
		var habit := _habits.habit_for(mood)
		var mood_name: String = DhullState.Mood.keys()[mood]
		assert_eq(habit.idle_reaction, DhullReaction.Symbol.SPIRAL, mood_name + " sighs")
		assert_true(habit.gloomy, mood_name + " is gloomy about it")
