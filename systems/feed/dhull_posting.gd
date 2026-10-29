class_name DhullPosting
extends RefCounted
## What Dhulls post about, and how a Dhull takes the player's reaction to a post. Plain functions,
## like DhullLife. Which reaction is right depends on the Dhull: some want sympathy, some want
## the player to match their vibe, and some want to get a rise out of people, like a petty Dhull
## that enjoys an angry face under its own success.

enum Wants { SYMPATHY, MATCHING_VIBE, A_RISE }
enum Response { LOVED, MEH, STUNG }
## How a post feels: good, low, or angry.
enum Tone { UP, DOWN, ANGRY }

## How many ways there are to word each topic. Their translation keys end in 1, 2 and so on.
const WORDINGS := 2


## What a Dhull wants from reactions to its posts, from its personality: bold Dhulls want a rise,
## friendly ones sympathy, and the rest for you to match their vibe.
static func wants(record: DhullRecord, tuning: FeedTuning) -> Wants:
	if record.genome.level(DhullGenome.Gene.BOLDNESS) >= tuning.wants_a_rise_from_boldness:
		return Wants.A_RISE
	if (
		record.genome.level(DhullGenome.Gene.FRIENDLINESS)
		>= tuning.wants_sympathy_from_friendliness
	):
		return Wants.SYMPATHY
	return Wants.MATCHING_VIBE


static func tone_of(mood: DhullState.Mood) -> Tone:
	match mood:
		DhullState.Mood.GRUMPY:
			return Tone.ANGRY
		DhullState.Mood.SAD, DhullState.Mood.HUNGRY, DhullState.Mood.SLEEPY:
			return Tone.DOWN
	return Tone.UP


## How a Dhull that [param wants] something takes [param reaction] on a post made in
## [param mood].
static func response(wants: Wants, mood: DhullState.Mood, reaction: FeedPost.Reaction) -> Response:
	var tone := tone_of(mood)
	match wants:
		Wants.SYMPATHY:
			return _sympathetic_response(tone, reaction)
		Wants.A_RISE:
			if reaction in [FeedPost.Reaction.SAD, FeedPost.Reaction.ANGRY]:
				return Response.LOVED
			return Response.MEH
	var matching: Dictionary[Tone, FeedPost.Reaction] = {
		Tone.UP: FeedPost.Reaction.LIKE,
		Tone.DOWN: FeedPost.Reaction.SAD,
		Tone.ANGRY: FeedPost.Reaction.ANGRY,
	}
	if reaction == matching[tone]:
		return Response.LOVED
	return Response.MEH if reaction == FeedPost.Reaction.HEART else Response.STUNG


## Lets the Dhull take [param reaction] to its post, which moves its mood and its bond with you.
static func take_reaction(
	record: DhullRecord, post: FeedPost, reaction: FeedPost.Reaction, tuning: FeedTuning
) -> Response:
	var taken := response(wants(record, tuning), post.mood, reaction)
	var happiness: Dictionary[Response, float] = {
		Response.LOVED: tuning.loved_cheers,
		Response.MEH: 0.0,
		Response.STUNG: -tuning.stung_sadness
	}
	var bond: Dictionary[Response, float] = {
		Response.LOVED: tuning.loved_bond,
		Response.MEH: tuning.meh_bond,
		Response.STUNG: -tuning.stung_bond
	}
	record.happiness = clampf(record.happiness + happiness[taken], 0.0, 1.0)
	record.bond = clampf(record.bond + bond[taken], 0.0, 1.0)
	return taken


## Translation key of the words for a post on [param topic], worded the [param wording]th way.
static func text_key(topic: FeedPost.Topic, wording: int) -> String:
	return "POST_%s_%d" % [FeedPost.Topic.keys()[topic], wording % WORDINGS + 1]


## What a change from [param old_mood] to [param new_mood] gets posted about: one topic, or none
## when the change isn't worth a post.
static func topics_for_mood_change(
	old_mood: DhullState.Mood, new_mood: DhullState.Mood
) -> Array[FeedPost.Topic]:
	if new_mood == DhullState.Mood.HUNGRY and old_mood != new_mood:
		return [FeedPost.Topic.HUNGRY]
	if new_mood in DhullReaction.CHEERFUL and not old_mood in DhullReaction.CHEERFUL:
		return [FeedPost.Topic.CHEERED_UP]
	if new_mood in DhullReaction.UPSET and not old_mood in DhullReaction.UPSET:
		return [FeedPost.Topic.UPSET]
	return []


## A Dhull that wants sympathy loves you sharing its joy, its sadness or its anger, and is hurt
## by reactions that go against how it feels.
static func _sympathetic_response(tone: Tone, reaction: FeedPost.Reaction) -> Response:
	var comforting: Dictionary[Tone, Array] = {
		Tone.UP: [FeedPost.Reaction.LIKE, FeedPost.Reaction.HEART],
		Tone.DOWN: [FeedPost.Reaction.HEART, FeedPost.Reaction.SAD],
		Tone.ANGRY: [FeedPost.Reaction.HEART, FeedPost.Reaction.ANGRY],
	}
	var hurtful: Dictionary[Tone, Array] = {
		Tone.UP: [FeedPost.Reaction.SAD, FeedPost.Reaction.ANGRY],
		Tone.DOWN: [FeedPost.Reaction.ANGRY],
		Tone.ANGRY: [FeedPost.Reaction.LIKE],
	}
	if reaction in comforting[tone]:
		return Response.LOVED
	return Response.STUNG if reaction in hurtful[tone] else Response.MEH
