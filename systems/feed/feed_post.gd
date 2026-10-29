class_name FeedPost
extends RefCounted
## One post on the feed: who posted it and when, what it's about, how the Dhull felt, and how the
## player reacted. The Feed autoload keeps and saves the posts.

enum Topic { CHEERED_UP, UPSET, HUNGRY, WOKE_UP, NAPPING, ATE, LATE_NIGHT, MORNING }
enum Reaction { NONE, LIKE, HEART, SAD, ANGRY }

var id: StringName
var dhull_id: StringName
var posted_unix := 0
var topic := Topic.CHEERED_UP
## The Dhull's mood when it posted, which its words and selfie show.
var mood := DhullState.Mood.CONTENT
## Translation key of its words.
var text_key := ""
## What the post is about, such as the food it ate, for its words and selfie. May be empty.
var subject: StringName
var reaction := Reaction.NONE


## The post as saved. Enums are saved by name, so reordering them never breaks a save.
func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"dhull_id": String(dhull_id),
		"posted_unix": posted_unix,
		"topic": Topic.keys()[topic],
		"mood": DhullState.Mood.keys()[mood],
		"text_key": text_key,
		"subject": String(subject),
		"reaction": Reaction.keys()[reaction],
	}


static func from_dict(data: Dictionary) -> FeedPost:
	var post := FeedPost.new()
	post.id = StringName(data.get("id", ""))
	post.dhull_id = StringName(data.get("dhull_id", ""))
	post.posted_unix = int(data.get("posted_unix", 0))
	post.topic = Topic.get(data.get("topic", ""), Topic.CHEERED_UP)
	post.mood = DhullState.Mood.get(data.get("mood", ""), DhullState.Mood.CONTENT)
	post.text_key = str(data.get("text_key", ""))
	post.subject = StringName(data.get("subject", ""))
	post.reaction = Reaction.get(data.get("reaction", ""), Reaction.NONE)
	return post
