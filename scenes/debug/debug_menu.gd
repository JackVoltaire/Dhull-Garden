extends CanvasLayer
## Developer tools, toggled with F3 (the debug_menu action): time travel, calendar state,
## saving and loading, switching levels, launching minigames and giving Dhulls new genes.
## Registered as the [code]DebugMenu[/code] autoload and removed in release builds.

const WEEKDAYS := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
const TIME_JUMPS := {"+1 hour": 3600, "+1 day": 86400, "+1 week": 604800, "+30 days": 2592000}
const LEVELS := {
	"Dream island": "res://scenes/levels/dream_island/dream_island.tscn",
	"Sandbox": "res://scenes/levels/sandbox/sandbox.tscn",
	"Dhull gallery": "res://scenes/levels/dhull_gallery/dhull_gallery.tscn",
}

var _mouse_mode_before_open := Input.MOUSE_MODE_VISIBLE
var _status: Label

@onready var _items: VBoxContainer = %Items


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	hide()
	_status = Label.new()
	_items.add_child(_status)

	var time_row := _add_row("Time")
	for label: String in TIME_JUMPS:
		_add_button(time_row, label, func() -> void: Clock.offset_seconds += TIME_JUMPS[label])
	_add_button(time_row, "Reset", func() -> void: Clock.offset_seconds = 0)

	var save_row := _add_row("Save")
	_add_button(save_row, "Save", Saves.save_game)
	_add_button(save_row, "Load", func() -> void: Saves.load_game(maxi(Saves.current_slot, 0)))
	_add_button(save_row, "Delete and start over", _restart_save)

	var level_row := _add_row("Levels")
	for level_name: String in LEVELS:
		_add_button(level_row, level_name, _change_level.bind(LEVELS[level_name]))

	var dhull_row := _add_row("Dhulls")
	_add_button(dhull_row, "New random genes", _reroll_dhulls)
	var activity_row := _add_row("Dhull activity")
	for activity: DhullState.Activity in DhullState.Activity.values():
		var activity_name: String = DhullState.Activity.keys()[activity].capitalize()
		_add_button(activity_row, activity_name, _set_dhulls.bind(&"activity", activity))
	var mood_row := _add_row("Dhull mood")
	for mood: DhullState.Mood in DhullState.Mood.values():
		var mood_name: String = DhullState.Mood.keys()[mood].capitalize()
		_add_button(mood_row, mood_name, _set_dhulls.bind(&"mood", mood))

	var minigame_row := _add_row("Minigames")
	for minigame in Minigames.minigames:
		_add_button(minigame_row, tr(minigame.title), _launch_minigame.bind(minigame))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		set_open(not visible)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible:
		_status.text = _status_text()


func set_open(open: bool) -> void:
	if open == visible:
		return
	visible = open
	if open:
		_mouse_mode_before_open = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = _mouse_mode_before_open


func _status_text() -> String:
	var now := Clock.now_local()
	var events := PackedStringArray(
		Calendar.get_active_events().map(
			func(event: CalendarEvent) -> String: return tr(event.display_name)
		)
	)
	var lines: PackedStringArray = [
		(
			"%s %04d-%02d-%02d %02d:%02d   %s   %s"
			% [
				WEEKDAYS[now.weekday],
				now.year,
				now.month,
				now.day,
				now.hour,
				now.minute,
				Clock.Phase.keys()[Clock.phase()].capitalize(),
				Calendar.Season.keys()[Calendar.season()].capitalize(),
			]
		),
		"Clock offset: %+.2f days" % (Clock.offset_seconds / float(DateUtil.SECONDS_PER_DAY)),
		"Events: %s" % (", ".join(events) if events else "none"),
		"Save slot: %d   FPS: %d" % [Saves.current_slot, Engine.get_frames_per_second()],
	]
	return "\n".join(lines)


func _restart_save() -> void:
	var slot := maxi(Saves.current_slot, 0)
	Saves.delete_save(slot)
	Saves.new_game(slot)


func _change_level(path: String) -> void:
	set_open(false)
	Scenes.change_scene(path)


func _reroll_dhulls() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for dhull: Dhull in get_tree().get_nodes_in_group(Dhull.GROUP):
		dhull.genome = DhullGenome.random(rng)


## Sets a property, such as activity or mood, on every Dhull in the level.
func _set_dhulls(property: StringName, value: int) -> void:
	for dhull: Dhull in get_tree().get_nodes_in_group(Dhull.GROUP):
		dhull.set(property, value)


func _launch_minigame(minigame: MinigameDefinition) -> void:
	set_open(false)
	Minigames.launch(minigame)


func _add_row(title: String) -> HBoxContainer:
	var label := Label.new()
	label.text = title
	_items.add_child(label)
	var row := HBoxContainer.new()
	_items.add_child(row)
	return row


func _add_button(row: HBoxContainer, text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(on_pressed)
	row.add_child(button)
