class_name Interactor
extends Area3D
## The player's reach. Picks the nearest enabled [Interactable] inside its collision shape,
## shows that one's prompt, and uses it when the Interact button is pressed.

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
	if nearest != target:
		target = nearest
		_update_prompt()
		target_changed.emit(target)


func _unhandled_input(event: InputEvent) -> void:
	if target and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		target.interact(owner as Player)


func _update_prompt() -> void:
	_prompt.visible = target != null
	if target:
		_prompt.text = tr("UI_INTERACT_PROMPT") % [_key_label("interact"), tr(target.prompt)]


## The keyboard key bound to [param action], for showing in prompts.
static func _key_label(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.as_text_physical_keycode()
	return "?"
