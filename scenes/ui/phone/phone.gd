class_name Phone
extends PanelContainer
## The dreamer's phone, opened with the phone button: the feed, newest posts first. It's the only
## way Dhulls talk to the dreamer; the dreamer answers only with reactions.

const POST_CARD := preload("res://scenes/ui/phone/post_card.tscn")

var _player: Player

@onready var _posts: Container = %Posts


func _ready() -> void:
	hide()


func open(player: Player) -> void:
	_player = player
	_player.busy = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_posts()
	show()


func close() -> void:
	hide()
	_player.busy = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# _input rather than _unhandled_input, so cancelling closes the phone before the pause menu opens
# on the same key.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var closing := event.is_action_pressed("phone") or event.is_action_pressed("ui_cancel")
	if closing or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _show_posts() -> void:
	for child in _posts.get_children():
		child.queue_free()
	var newest := Feed.newest_first()
	if newest.is_empty():
		var nothing := Label.new()
		nothing.text = tr("UI_FEED_EMPTY")
		_posts.add_child(nothing)
	for post in newest:
		var card: PostCard = POST_CARD.instantiate()
		_posts.add_child(card)
		card.show_post(post)
