class_name DhullReaction
extends RefCounted
## The reaction symbols that pop up beside a Dhull, as in Animal Crossing: an eye when it notices
## the player, a star when it cheers up, a spiral when it gets upset. Its habits can show them now
## and then too (see DhullHabit).

enum Symbol { NONE, EYE, STAR, SPIRAL }

const CHEERFUL: Array[DhullState.Mood] = [DhullState.Mood.HAPPY, DhullState.Mood.PLAYFUL]
const UPSET: Array[DhullState.Mood] = [DhullState.Mood.SAD, DhullState.Mood.GRUMPY]


## The symbol a change of mood pops up: a star on cheering up, a spiral on getting upset, and
## nothing when it was already as cheerful or as upset before.
static func on_mood_change(old_mood: DhullState.Mood, new_mood: DhullState.Mood) -> Symbol:
	if new_mood in CHEERFUL and not old_mood in CHEERFUL:
		return Symbol.STAR
	if new_mood in UPSET and not old_mood in UPSET:
		return Symbol.SPIRAL
	return Symbol.NONE
