class_name PostCard
extends PanelContainer
## One post on the phone: who posted it and when, its selfie and words, and the four reactions
## the player can leave on it, once. A selfie still to be taken shows up as soon as it is.

var _post: FeedPost

@onready var _handle: Label = %Handle
@onready var _when: Label = %When
@onready var _selfie: TextureRect = %Selfie
@onready var _words: Label = %Words
@onready var _reactions: Dictionary[FeedPost.Reaction, Button] = {
	FeedPost.Reaction.LIKE: %Like,
	FeedPost.Reaction.HEART: %Heart,
	FeedPost.Reaction.SAD: %Sad,
	FeedPost.Reaction.ANGRY: %Angry,
}


func _ready() -> void:
	for reaction in _reactions:
		_reactions[reaction].pressed.connect(_on_reaction.bind(reaction))
	Feed.selfie_taken.connect(_on_selfie_taken)


func show_post(post: FeedPost) -> void:
	_post = post
	var record := Garden.find_dhull(post.dhull_id)
	var name_shown := record.name if record and not record.name.is_empty() else tr("UI_UNNAMED")
	_handle.text = name_shown
	_when.text = _time_ago(Clock.now_unix() - post.posted_unix)
	var words := tr(post.text_key)
	if words.contains("%s"):
		var subject: ItemDefinition = Inventory.definitions.get(post.subject)
		words = words % (tr(subject.display_name).to_lower() if subject else "")
	_words.text = words
	_show_reaction()
	_selfie.texture = Feed.selfie(post)


func _on_selfie_taken(post: FeedPost) -> void:
	if post == _post:
		_selfie.texture = Feed.selfie(post)


func _on_reaction(reaction: FeedPost.Reaction) -> void:
	Feed.react(_post, reaction)
	_show_reaction()


## Once the player has reacted, only their reaction stays lit.
func _show_reaction() -> void:
	var reacted := _post.reaction != FeedPost.Reaction.NONE
	for reaction in _reactions:
		var button := _reactions[reaction]
		button.disabled = reacted
		button.button_pressed = _post.reaction == reaction
		button.modulate.a = 0.35 if reacted and _post.reaction != reaction else 1.0


func _time_ago(seconds: int) -> String:
	if seconds < 60:
		return tr("UI_JUST_NOW")
	if seconds < 3600:
		return tr("UI_MINUTES_AGO") % (seconds / 60)
	if seconds < DateUtil.SECONDS_PER_DAY:
		return tr("UI_HOURS_AGO") % (seconds / 3600)
	return tr("UI_DAYS_AGO") % (seconds / DateUtil.SECONDS_PER_DAY)
