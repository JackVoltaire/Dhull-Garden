extends Node
## Global game state that outlives any single scene. Registered as the [code]Game[/code] autoload.
##
## Owns pausing so it works in every scene, even ones run on their own with F6.
## UI such as the pause menu reacts to [signal paused_changed] rather than pausing the tree itself.

signal paused_changed(is_paused: bool)

var _mouse_mode_before_pause := Input.MOUSE_MODE_VISIBLE


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
	if paused:
		_mouse_mode_before_pause = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = _mouse_mode_before_pause
	paused_changed.emit(paused)


func quit() -> void:
	# Closing the window sends this notification but quit() doesn't, so send it ourselves to
	# give autoloads such as Saves the same chance to save.
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
