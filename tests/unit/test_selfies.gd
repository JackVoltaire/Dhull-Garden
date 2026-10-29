extends TestCase
## Keeping the selfies Dhulls take for their posts. These tests use a feed of their own and point
## Saves at a test folder, so the player's own saves and selfies are never touched.

const TEST_DIR := "user://test_selfies"
const FEED_SCRIPT := preload("res://systems/feed/feed.gd")

var _feed: Node
var _original_dir := ""
var _original_slot := -1
var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_original_dir = Saves.save_dir
	_original_slot = Saves.current_slot
	Saves.save_dir = TEST_DIR
	Saves.current_slot = 0
	_feed = FEED_SCRIPT.new()
	_feed.apply_save_data({})


func after_each() -> void:
	_feed.apply_save_data({})
	_feed.free()
	DirAccess.remove_absolute(TEST_DIR.path_join("slot_0_selfies"))
	DirAccess.remove_absolute(TEST_DIR)
	Saves.save_dir = _original_dir
	Saves.current_slot = _original_slot


func test_a_post_waits_for_its_selfie_until_one_is_kept() -> void:
	var dhull := _adult()
	var post: FeedPost = _feed.post_about(dhull, FeedPost.Topic.MORNING)
	assert_eq(_feed.waiting_for_selfies(dhull.id), [post] as Array[FeedPost])
	assert_true(_feed.selfie(post) == null, "no picture yet")
	_feed.keep_selfie(post, _picture())
	assert_true(_feed.has_selfie(post), "kept")
	assert_true(_feed.waiting_for_selfies(dhull.id).is_empty(), "nothing waiting")
	assert_true(_feed.selfie(post) != null, "there's a picture")


func test_selfies_load_back_from_disk() -> void:
	var post: FeedPost = _feed.post_about(_adult(), FeedPost.Topic.MORNING)
	_feed.keep_selfie(post, _picture())
	var saved: Dictionary = JSON.to_native(JSON.from_native(_feed.get_save_data()))
	var loaded: Node = FEED_SCRIPT.new()
	loaded.apply_save_data(saved)
	var picture: Texture2D = loaded.selfie(loaded.posts[0])
	assert_true(picture != null, "loaded")
	assert_eq(picture.get_size(), Vector2(8, 6))
	loaded.free()


func test_a_new_game_starts_without_old_selfies() -> void:
	var post: FeedPost = _feed.post_about(_adult(), FeedPost.Topic.MORNING)
	_feed.keep_selfie(post, _picture())
	_feed.apply_save_data({})
	assert_false(_feed.has_selfie(post), "forgotten")


func test_old_posts_take_their_selfies_with_them() -> void:
	var first: FeedPost = _feed.post_about(_adult(), FeedPost.Topic.MORNING)
	_feed.keep_selfie(first, _picture())
	for _post in _feed.tuning.most_posts_kept:
		_feed.post_about(_adult(), FeedPost.Topic.MORNING)
	assert_false(first in _feed.posts, "the oldest post went")
	assert_false(_feed.has_selfie(first), "and its selfie")


func _adult() -> DhullRecord:
	var record := DhullRecord.new()
	record.id = StringName("dhull_%d" % _rng.randi())
	record.genome = DhullGenome.random(_rng)
	return record


func _picture() -> Image:
	return Image.create(8, 6, false, Image.FORMAT_RGBA8)
