extends Node
## Save slots on disk, registered as the [code]Saves[/code] autoload.
##
## Systems that own persistent state call [method register] once with an id and an object that
## has two methods: [code]get_save_data() -> Dictionary[/code] and
## [code]apply_save_data(data: Dictionary) -> void[/code]. A new game applies an empty Dictionary.
## Keep persistent state in such systems rather than in scene nodes, because scenes are freed
## whenever the player moves between the garden and minigames.
##
## Each slot is a JSON file: a readable header plus the game data encoded with
## [method JSON.from_native], which keeps exact types (int vs float, Vector3, ...) and never
## decodes objects, so shared save files can't run code. A write goes to a temporary file
## first, and the previous save is kept as a .bak backup that loading falls back to.

## Emitted after a new game starts or a save loads. [param seconds_away] is how long the game
## was closed since the last save (0 for a new game). It's negative if the system clock was
## turned back.
signal game_loaded(slot: int, seconds_away: int)
signal game_saved(slot: int)

## Version of the save data layout. When it changes, bump this and add a step to
## [method _migrate_step] that converts data from the previous version.
const VERSION := 1
const AUTOSAVE_SECONDS := 300.0

## Folder holding the slot files.
var save_dir := "user://saves"
## Slot of the game in progress, or -1 before a game is started or loaded.
var current_slot := -1

var _participants: Dictionary[StringName, Object] = {}
## Data of the current game per participant id. Keeps data for participants that haven't
## registered yet, so nothing is lost if they register late.
var _data: Dictionary = {}
var _created_unix := 0
var _play_time := 0.0


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_SECONDS
	timer.timeout.connect(_autosave)
	add_child(timer)
	timer.start()


func _process(delta: float) -> void:
	if current_slot >= 0:
		_play_time += delta


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_autosave()


func register(id: StringName, participant: Object) -> void:
	assert(
		participant.has_method("get_save_data") and participant.has_method("apply_save_data"),
		"Save participant '%s' needs get_save_data() and apply_save_data()." % id
	)
	_participants[id] = participant
	if current_slot >= 0:
		participant.apply_save_data(_data.get(id, {}))


func unregister(id: StringName) -> void:
	_participants.erase(id)


func new_game(slot: int) -> void:
	current_slot = slot
	_data = {}
	_created_unix = Clock.now_unix()
	_play_time = 0.0
	for id in _participants:
		_participants[id].apply_save_data({})
	game_loaded.emit(slot, 0)


func load_game(slot: int) -> Error:
	var file := _read_file(slot_path(slot))
	if file.is_empty():
		file = _read_file(_backup_path(slot))
		if file.is_empty():
			return ERR_FILE_CORRUPT if has_save(slot) else ERR_FILE_NOT_FOUND
		push_warning("Save slot %d was unreadable; loaded its backup instead." % slot)

	var version := int(file.version)
	if version > VERSION:
		push_warning("Save slot %d is from a newer version of the game." % slot)
		return ERR_FILE_UNRECOGNIZED
	var data: Variant = JSON.to_native(file.data)
	if not data is Dictionary:
		return ERR_FILE_CORRUPT

	current_slot = slot
	_data = migrate(data, version)
	_created_unix = int(file.get("created_unix", 0))
	_play_time = float(file.get("play_time_seconds", 0))
	for id in _participants:
		_participants[id].apply_save_data(_data.get(id, {}))
	game_loaded.emit(slot, Clock.now_unix() - int(file.get("saved_unix", 0)))
	return OK


func save_game() -> Error:
	if current_slot < 0:
		return ERR_UNCONFIGURED
	for id in _participants:
		_data[id] = _participants[id].get_save_data()
	var file := {
		"version": VERSION,
		"game_version": ProjectSettings.get_setting("application/config/version", ""),
		"created_unix": _created_unix,
		"saved_unix": Clock.now_unix(),
		"play_time_seconds": int(_play_time),
		"data": JSON.from_native(_data),
	}
	var error := _write_atomically(slot_path(current_slot), JSON.stringify(file, "\t"))
	if error == OK:
		game_saved.emit(current_slot)
	else:
		push_error("Couldn't save slot %d: %s" % [current_slot, error_string(error)])
	return error


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(_backup_path(slot))


## Header of a slot for showing it in a menu: created_unix, saved_unix, play_time_seconds and
## game_version. Empty if the slot has no readable save.
func get_slot_info(slot: int) -> Dictionary:
	var file := _read_file(slot_path(slot))
	if file.is_empty():
		file = _read_file(_backup_path(slot))
	if file.is_empty():
		return {}
	return {
		"created_unix": int(file.get("created_unix", 0)),
		"saved_unix": int(file.get("saved_unix", 0)),
		"play_time_seconds": int(file.get("play_time_seconds", 0)),
		"game_version": str(file.get("game_version", "")),
	}


func delete_save(slot: int) -> void:
	for path in [slot_path(slot), _backup_path(slot), slot_path(slot) + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if slot == current_slot:
		current_slot = -1


## Renames a slot's files out of the way, e.g. when they can't be loaded, so starting a new game
## in that slot doesn't overwrite them. They stay in [member save_dir] for manual recovery.
func set_aside(slot: int) -> void:
	var suffix := ".broken-%d" % Clock.now_unix()
	for path in [slot_path(slot), _backup_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.rename_absolute(path, path + suffix)


func slot_path(slot: int) -> String:
	return save_dir.path_join("slot_%d.json" % slot)


## Upgrades data saved by an older [constant VERSION] to the current layout.
static func migrate(data: Dictionary, from_version: int) -> Dictionary:
	var version := from_version
	while version < VERSION:
		data = _migrate_step(data, version)
		version += 1
	return data


## Converts data from [param version] to [param version] + 1. Add a branch per version, e.g.
## [code]1: data["garden"]["trees"] = []; return data[/code].
static func _migrate_step(data: Dictionary, version: int) -> Dictionary:
	match version:
		_:
			push_error("No save migration from version %d." % version)
			return data


func _backup_path(slot: int) -> String:
	return slot_path(slot) + ".bak"


func _autosave() -> void:
	if current_slot >= 0:
		save_game()


## Returns the parsed file, or an empty Dictionary if it's missing or malformed.
func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	# A JSON instance reports bad input through its return value; JSON.parse_string() would
	# also log an engine error.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = json.data
	if parsed is Dictionary and parsed.has("version") and parsed.has("data"):
		return parsed
	return {}


func _write_atomically(path: String, text: String) -> Error:
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return error
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var written := file.store_string(text)
	file.close()
	if not written:
		return ERR_FILE_CANT_WRITE

	if FileAccess.file_exists(path):
		var backup_path := path + ".bak"
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		error = DirAccess.rename_absolute(path, backup_path)
		if error != OK:
			return error
	return DirAccess.rename_absolute(temp_path, path)
