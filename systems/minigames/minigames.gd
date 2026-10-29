extends Node
## Runs minigames, registered as the [code]Minigames[/code] autoload.
##
## [method launch] switches to a minigame's scene. The minigame reads [member context] for its
## input (which Dhull is playing, difficulty, ...) and calls [method finish] with its result.
## The player then returns to the scene they launched it from, and [signal minigame_finished]
## carries the result to whoever hands out rewards.
##
## A minigame scene can also be run on its own with F6; finishing then restarts it.
##
## It also remembers which spots have been used today, for spots that refresh every day, like
## shiny spots: their ids are saved with the local date they were used on.

signal minigame_finished(minigame: MinigameDefinition, result: Dictionary)

const DATA_DIR := "res://data/minigames/"
const SAVE_ID := &"minigames"

var minigames: Array[MinigameDefinition] = []
## The minigame being played, or null.
var current: MinigameDefinition
## Input from whoever launched [member current]. Empty when running a minigame scene directly.
var context: Dictionary = {}

var _return_scene_path := ""
var _return_params: Dictionary = {}
## The spots used on [member _used_on], by id.
var _used_spots: Array[StringName] = []
## The local date the spots in [member _used_spots] were used on, as YYYY-MM-DD.
var _used_on := ""


func _ready() -> void:
	for resource in ResourceDir.load_all(DATA_DIR):
		if resource is MinigameDefinition:
			minigames.append(resource)
		else:
			push_error("%s is not a MinigameDefinition." % resource.resource_path)
	Saves.register(SAVE_ID, self)


func get_minigame(id: StringName) -> MinigameDefinition:
	for minigame in minigames:
		if minigame.id == id:
			return minigame
	return null


## Whether the spot [param spot_id] has been used today.
func used_today(spot_id: StringName) -> bool:
	return _used_on == _today() and spot_id in _used_spots


## Notes that the spot [param spot_id] has been used today.
func mark_used(spot_id: StringName) -> void:
	if _used_on != _today():
		_used_spots.clear()
		_used_on = _today()
	if not spot_id in _used_spots:
		_used_spots.append(spot_id)


func get_save_data() -> Dictionary:
	var used: Array = []
	for spot_id in _used_spots:
		used.append(String(spot_id))
	return {"used_spots": used, "used_on": _used_on}


func apply_save_data(data: Dictionary) -> void:
	_used_spots.clear()
	for spot_id: Variant in data.get("used_spots", []):
		_used_spots.append(StringName(spot_id))
	_used_on = str(data.get("used_on", ""))


## Starts [param minigame]. [param return_params] go to the scene the player returns to
## afterwards (see [method Scenes.change_scene]), e.g. where to put the player back.
func launch(minigame: MinigameDefinition, launch_context := {}, return_params := {}) -> void:
	if current or Scenes.is_changing:
		push_warning("Can't launch '%s' right now." % minigame.id)
		return
	current = minigame
	context = launch_context
	_return_scene_path = get_tree().current_scene.scene_file_path
	_return_params = return_params
	await Scenes.change_scene(minigame.scene_path)


## Ends the current minigame with [param result], e.g. [code]{"score": 120}[/code].
func finish(result := {}) -> void:
	if current == null:
		print("Minigame finished with ", result, ". Restarting it.")
		get_tree().reload_current_scene()
		return
	var finished := current
	current = null
	context = {}
	await Scenes.change_scene(_return_scene_path, _return_params)
	_return_params = {}
	minigame_finished.emit(finished, result)


func _today() -> String:
	var now := Clock.now_local()
	return "%04d-%02d-%02d" % [now.year, now.month, now.day]
