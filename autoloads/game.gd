extends Node
## Global game state that outlives any single scene. Registered as the [code]Game[/code] autoload.
##
## Owns pausing so it works in every scene, even ones run on their own with F6.
## UI such as the pause menu reacts to [signal paused_changed] rather than pausing the tree itself.

signal paused_changed(is_paused: bool)


func _ready() -> void:
	# Keep receiving input while the tree is paused so the pause action can also unpause.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func set_paused(paused: bool) -> void:
	if get_tree().paused == paused:
		return
	get_tree().paused = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	paused_changed.emit(paused)


func quit() -> void:
	get_tree().quit()
