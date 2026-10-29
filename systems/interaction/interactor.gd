class_name Interactor
extends Area3D
## The player's reach. Picks the nearest enabled [Interactable] inside its collision shape,
## shows that one's prompt, and uses it when the Interact button is pressed. While the player
## carries a Dhull, Interact puts it down instead, and while a menu is open it does nothing.

signal target_changed(target: Interactable)

## The interactable that Interact would use right now, or null.
var target: Interactable = null

@onready var _prompt: Label = %InteractionPrompt


func _init() -> void:
	collision_layer = 0
	collision_mask = Interactable.LAYER
	monitorable = false


func _ready() -> void:
	_prompt.hide()


func _physics_process(_delta: float) -> void:
	if _player().is_carrying():
		_set_target(null)
		_show_prompt(tr("PROMPT_PUT_DOWN"))
		return
	var nearest: Interactable = null
	var nearest_distance := INF
	for area in get_overlapping_areas():
		var interactable := area as Interactable
		if interactable == null or not interactable.enabled:
			continue
		var distance := global_position.distance_squared_to(interactable.global_position)
		if distance < nearest_distance:
			nearest = interactable
			nearest_distance = distance
	_set_target(nearest)
	_show_prompt(tr(target.prompt) if target and not _player().busy else "")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or _player().busy:
		return
	if _player().is_carrying():
		get_viewport().set_input_as_handled()
		_player().put_down()
	elif target:
		get_viewport().set_input_as_handled()
		target.interact(_player())


func _player() -> Player:
	return owner as Player


func _set_target(new_target: Interactable) -> void:
	if new_target != target:
		target = new_target
		target_changed.emit(target)


## Shows "[E] [param verb]", or nothing when [param verb] is empty.
func _show_prompt(verb: String) -> void:
	_prompt.visible = not verb.is_empty()
	if _prompt.visible:
		_prompt.text = tr("UI_INTERACT_PROMPT") % [_key_label("interact"), verb]


## The keyboard key bound to [param action], for showing in prompts.
static func _key_label(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.as_text_physical_keycode()
	return "?"
