class_name CareMenu
extends PanelContainer
## The menu for caring for a Dhull in person: pet it, feed it something from your pockets, or
## pick it up. There's nothing to say to it here; words only go through the feed. An egg can only
## be picked up.

var _dhull: Dhull
var _player: Player

@onready var _actions: Container = %Actions
@onready var _foods: Container = %Foods
@onready var _pet: Button = %Pet
@onready var _feed: Button = %Feed
@onready var _pick_up: Button = %PickUp


func _ready() -> void:
	hide()
	_pet.pressed.connect(_on_pet)
	_feed.pressed.connect(_show_foods)
	_pick_up.pressed.connect(_on_pick_up)
	%Leave.pressed.connect(close)


func open(dhull: Dhull, player: Player) -> void:
	_dhull = dhull
	_player = player
	_player.busy = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_actions()
	show()


func close() -> void:
	hide()
	_player.busy = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_dhull = null


# _input rather than _unhandled_input, so cancelling closes this menu before the pause menu
# opens on the same key.
func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _show_actions() -> void:
	var egg := _dhull.record.is_egg()
	_pet.visible = not egg
	_feed.visible = not egg
	_foods.hide()
	_actions.show()
	(_pick_up if egg else _pet).grab_focus()


func _show_foods() -> void:
	for child in _foods.get_children():
		child.queue_free()
	var edible := Inventory.held().filter(
		func(item: ItemDefinition) -> bool: return item.is_edible()
	)
	if edible.is_empty():
		var nothing := Label.new()
		nothing.text = tr("UI_NOTHING_TO_EAT")
		_foods.add_child(nothing)
	for item: ItemDefinition in edible:
		var food := Button.new()
		food.text = tr("UI_ITEM_COUNT") % [tr(item.display_name), Inventory.count(item.id)]
		food.pressed.connect(_on_food_chosen.bind(item))
		_foods.add_child(food)
	var back := Button.new()
	back.text = tr("UI_BACK")
	back.pressed.connect(_show_actions)
	_foods.add_child(back)
	_actions.hide()
	_foods.show()
	_foods.get_child(0).grab_focus.call_deferred()


func _on_pet() -> void:
	_dhull.pet()
	close()


func _on_food_chosen(item: ItemDefinition) -> void:
	if _dhull.feed(item):
		Inventory.take(item.id)
	close()


func _on_pick_up() -> void:
	_player.pick_up(_dhull)
	close()
