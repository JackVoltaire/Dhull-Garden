extends TestCase
## Which reaction symbol a change of mood pops up.


func test_cheering_up_pops_a_star() -> void:
	var star := DhullReaction.on_mood_change(DhullState.Mood.CONTENT, DhullState.Mood.HAPPY)
	assert_eq(star, DhullReaction.Symbol.STAR)


func test_getting_upset_pops_a_spiral() -> void:
	var spiral := DhullReaction.on_mood_change(DhullState.Mood.HUNGRY, DhullState.Mood.SAD)
	assert_eq(spiral, DhullReaction.Symbol.SPIRAL)


func test_staying_as_cheerful_or_as_upset_pops_nothing() -> void:
	var playful := DhullReaction.on_mood_change(DhullState.Mood.HAPPY, DhullState.Mood.PLAYFUL)
	assert_eq(playful, DhullReaction.Symbol.NONE)
	var grumpy := DhullReaction.on_mood_change(DhullState.Mood.SAD, DhullState.Mood.GRUMPY)
	assert_eq(grumpy, DhullReaction.Symbol.NONE)
	var sleepy := DhullReaction.on_mood_change(DhullState.Mood.CONTENT, DhullState.Mood.SLEEPY)
	assert_eq(sleepy, DhullReaction.Symbol.NONE)
