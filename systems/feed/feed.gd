extends Node
## The feed on the dreamer's phone, registered as the [code]Feed[/code] autoload: the only way they
## hear from Dhulls. Grown Dhulls post when their mood swings, when they doze off and wake up, when
## they eat, late at night and in the morning, and never more often than every so many minutes.
## The player reads the posts and reacts, once each, and the Dhull takes it its own way (see
## DhullPosting).

signal posted(post: FeedPost)
signal reacted(post: FeedPost)

const SAVE_ID := &"feed"

var tuning: FeedTuning = preload("res://data/feed/feed.tres")
## Every post kept, oldest first.
var posts: Array[FeedPost] = []

var _next_number := 1
## When each Dhull last posted, as Unix time, by id.
var _last_posted: Dictionary[StringName, int] = {}


func _ready() -> void:
	Saves.register(SAVE_ID, self)
	Garden.mood_changed.connect(_on_mood_changed)
	Garden.nap_changed.connect(_on_nap_changed)
	Clock.hour_changed.connect(_on_hour_changed)


## Has [param record] post about [param topic], unless it isn't grown or posted too recently.
## [param subject] is what the post is about, such as the id of the food it ate. Returns the post,
## or null if there wasn't one.
func post_about(record: DhullRecord, topic: FeedPost.Topic, subject := &"") -> FeedPost:
	var now := Clock.now_unix()
	var gap := tuning.minutes_between_posts * 60
	if not record.is_adult() or now - _last_posted.get(record.id, now - gap) < gap:
		return null
	var post := FeedPost.new()
	post.id = StringName("post_%d" % _next_number)
	post.dhull_id = record.id
	post.posted_unix = now
	post.topic = topic
	post.mood = DhullLife.mood_for(record, Garden.tuning)
	post.text_key = DhullPosting.text_key(topic, _next_number)
	post.subject = subject
	_next_number += 1
	_last_posted[record.id] = now
	posts.append(post)
	if posts.size() > tuning.most_posts_kept:
		posts.pop_front()
	posted.emit(post)
	return post


## The player reacts to [param post], once. The Dhull takes it its own way.
func react(post: FeedPost, reaction: FeedPost.Reaction) -> void:
	var record := Garden.find_dhull(post.dhull_id)
	if post.reaction != FeedPost.Reaction.NONE or record == null:
		return
	post.reaction = reaction
	DhullPosting.take_reaction(record, post, reaction, tuning)
	Garden.notify_changed()
	reacted.emit(post)


func newest_first() -> Array[FeedPost]:
	var newest := posts.duplicate()
	newest.reverse()
	return newest


func get_save_data() -> Dictionary:
	var saved_posts: Array = []
	for post in posts:
		saved_posts.append(post.to_dict())
	var last_posted := {}
	for dhull_id in _last_posted:
		last_posted[String(dhull_id)] = _last_posted[dhull_id]
	return {"posts": saved_posts, "next_number": _next_number, "last_posted": last_posted}


func apply_save_data(data: Dictionary) -> void:
	posts.clear()
	for post_data: Variant in data.get("posts", []):
		if post_data is Dictionary:
			posts.append(FeedPost.from_dict(post_data))
	_next_number = int(data.get("next_number", posts.size() + 1))
	_last_posted.clear()
	var last_posted: Variant = data.get("last_posted", {})
	if last_posted is Dictionary:
		for dhull_id: Variant in last_posted:
			_last_posted[StringName(dhull_id)] = int(last_posted[dhull_id])


func _on_mood_changed(record: DhullRecord, old_mood: DhullState.Mood) -> void:
	var new_mood := DhullLife.mood_for(record, Garden.tuning)
	for topic in DhullPosting.topics_for_mood_change(old_mood, new_mood):
		post_about(record, topic)


func _on_nap_changed(record: DhullRecord) -> void:
	post_about(record, FeedPost.Topic.NAPPING if record.napping else FeedPost.Topic.WOKE_UP)


func _on_hour_changed(hour: int) -> void:
	if hour != tuning.late_night_hour and hour != tuning.morning_hour:
		return
	var topic := (
		FeedPost.Topic.LATE_NIGHT if hour == tuning.late_night_hour else FeedPost.Topic.MORNING
	)
	for record in Garden.dhulls:
		if not record.napping:
			post_about(record, topic)
