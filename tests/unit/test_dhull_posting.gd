extends TestCase
## What Dhulls post about, and how each takes the player's reactions.

const FEED_TUNING_PATH := "res://data/feed/feed.tres"
const FEED_SCRIPT := preload("res://systems/feed/feed.gd")

var _tuning: FeedTuning
var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_tuning = load(FEED_TUNING_PATH)
	_rng.seed = 5


func test_bold_dhulls_want_a_rise_and_friendly_ones_sympathy() -> void:
	var bold := _adult(90, 90)
	assert_eq(DhullPosting.wants(bold, _tuning), DhullPosting.Wants.A_RISE)
	var friendly := _adult(20, 90)
	assert_eq(DhullPosting.wants(friendly, _tuning), DhullPosting.Wants.SYMPATHY)
	var neither := _adult(20, 20)
	assert_eq(DhullPosting.wants(neither, _tuning), DhullPosting.Wants.MATCHING_VIBE)


func test_a_dhull_wanting_sympathy_loves_comfort_and_hates_scorn() -> void:
	var sad := DhullState.Mood.SAD
	var wants := DhullPosting.Wants.SYMPATHY
	assert_eq(_response(wants, sad, FeedPost.Reaction.HEART), DhullPosting.Response.LOVED)
	assert_eq(_response(wants, sad, FeedPost.Reaction.SAD), DhullPosting.Response.LOVED)
	assert_eq(_response(wants, sad, FeedPost.Reaction.LIKE), DhullPosting.Response.MEH)
	assert_eq(_response(wants, sad, FeedPost.Reaction.ANGRY), DhullPosting.Response.STUNG)
	var happy := DhullState.Mood.HAPPY
	assert_eq(_response(wants, happy, FeedPost.Reaction.LIKE), DhullPosting.Response.LOVED)
	assert_eq(_response(wants, happy, FeedPost.Reaction.ANGRY), DhullPosting.Response.STUNG)


func test_a_dhull_wanting_its_vibe_matched_wants_exactly_that() -> void:
	var wants := DhullPosting.Wants.MATCHING_VIBE
	var sad := DhullState.Mood.SAD
	assert_eq(_response(wants, sad, FeedPost.Reaction.SAD), DhullPosting.Response.LOVED)
	assert_eq(_response(wants, sad, FeedPost.Reaction.HEART), DhullPosting.Response.MEH)
	assert_eq(_response(wants, sad, FeedPost.Reaction.LIKE), DhullPosting.Response.STUNG)
	var grumpy := DhullState.Mood.GRUMPY
	assert_eq(_response(wants, grumpy, FeedPost.Reaction.ANGRY), DhullPosting.Response.LOVED)


func test_a_petty_dhull_enjoys_an_angry_face_under_its_success() -> void:
	var wants := DhullPosting.Wants.A_RISE
	var happy := DhullState.Mood.HAPPY
	assert_eq(_response(wants, happy, FeedPost.Reaction.ANGRY), DhullPosting.Response.LOVED)
	assert_eq(_response(wants, happy, FeedPost.Reaction.LIKE), DhullPosting.Response.MEH)


func test_reactions_move_mood_and_bond() -> void:
	var friendly := _adult(20, 90)
	var post := FeedPost.new()
	post.mood = DhullState.Mood.SAD
	var happiness := friendly.happiness
	DhullPosting.take_reaction(friendly, post, FeedPost.Reaction.HEART, _tuning)
	assert_true(friendly.happiness > happiness, "cheered up")
	assert_true(friendly.bond > 0.0, "closer to you")
	var stung := _adult(20, 90)
	stung.bond = 0.5
	DhullPosting.take_reaction(stung, post, FeedPost.Reaction.ANGRY, _tuning)
	assert_true(stung.bond < 0.5, "hurt")


func test_mood_swings_worth_posting_about() -> void:
	var up := DhullPosting.topics_for_mood_change(DhullState.Mood.CONTENT, DhullState.Mood.HAPPY)
	assert_eq(up, [FeedPost.Topic.CHEERED_UP] as Array[FeedPost.Topic])
	var down := DhullPosting.topics_for_mood_change(DhullState.Mood.CONTENT, DhullState.Mood.SAD)
	assert_eq(down, [FeedPost.Topic.UPSET] as Array[FeedPost.Topic])
	var same := DhullPosting.topics_for_mood_change(DhullState.Mood.HAPPY, DhullState.Mood.PLAYFUL)
	assert_true(same.is_empty(), "still cheerful")


func test_every_topic_has_words_for_every_wording() -> void:
	for topic: FeedPost.Topic in FeedPost.Topic.values():
		for wording in DhullPosting.WORDINGS:
			var key := DhullPosting.text_key(topic, wording)
			assert_true(TranslationServer.translate(key) != key, key)


func test_only_grown_dhulls_post_and_never_too_often() -> void:
	var feed: Node = FEED_SCRIPT.new()
	var kid := _adult(50, 50)
	kid.life_stage = DhullRecord.LifeStage.YOUNG
	assert_true(feed.post_about(kid, FeedPost.Topic.MORNING) == null, "kids don't post")
	var adult := _adult(50, 50)
	assert_true(feed.post_about(adult, FeedPost.Topic.MORNING) != null, "adults do")
	assert_true(feed.post_about(adult, FeedPost.Topic.ATE) == null, "not again so soon")
	assert_eq(feed.posts.size(), 1)
	feed.free()


func test_the_feed_survives_saving() -> void:
	var feed: Node = FEED_SCRIPT.new()
	var post: FeedPost = feed.post_about(_adult(50, 50), FeedPost.Topic.ATE, &"chips")
	post.reaction = FeedPost.Reaction.HEART
	var saved: Dictionary = JSON.to_native(JSON.from_native(feed.get_save_data()))
	var loaded: Node = FEED_SCRIPT.new()
	loaded.apply_save_data(saved)
	assert_eq(loaded.posts.size(), 1)
	var copy: FeedPost = loaded.posts[0]
	assert_eq(copy.id, post.id)
	assert_eq(copy.topic, FeedPost.Topic.ATE)
	assert_eq(copy.subject, &"chips")
	assert_eq(copy.reaction, FeedPost.Reaction.HEART)
	assert_eq(copy.text_key, post.text_key)
	feed.free()
	loaded.free()


func _response(
	wants: DhullPosting.Wants, mood: DhullState.Mood, reaction: FeedPost.Reaction
) -> DhullPosting.Response:
	return DhullPosting.response(wants, mood, reaction)


func _adult(boldness: int, friendliness: int) -> DhullRecord:
	var record := DhullRecord.new()
	record.id = StringName("dhull_%d" % _rng.randi())
	record.genome = DhullGenome.random(_rng)
	record.genome.alleles[DhullGenome.Gene.BOLDNESS] = Vector2i(boldness, boldness)
	record.genome.alleles[DhullGenome.Gene.FRIENDLINESS] = Vector2i(friendliness, friendliness)
	return record


func test_every_selfie_gets_a_face_that_fits() -> void:
	var post := FeedPost.new()
	for topic: FeedPost.Topic in FeedPost.Topic.values():
		post.topic = topic
		post.mood = DhullState.Mood.CONTENT
		assert_true(DhullPosting.selfie_face(post) in DhullFace.Emotion.values(), "a face")
	post.topic = FeedPost.Topic.ATE
	assert_eq(DhullPosting.selfie_face(post), DhullFace.Emotion.HAPPY)
	post.topic = FeedPost.Topic.UPSET
	post.mood = DhullState.Mood.GRUMPY
	assert_eq(DhullPosting.selfie_face(post), DhullFace.Emotion.ANGRY)
	post.mood = DhullState.Mood.SAD
	assert_eq(DhullPosting.selfie_face(post), DhullFace.Emotion.SAD)
