extends Control
## The mining minigame, opened from a shiny spot: dig crafting materials out of a wall with the
## pick and the hammer before it caves in (see DigSite). Whatever is dug out completely goes into
## the player's pockets when they're done.

const FINDS_DIR := "res://data/mining/finds"

@export var tuning: MiningTuning

var _site: DigSite
var _rng := RandomNumberGenerator.new()

@onready var _board: DigBoard = %Board
@onready var _wall: ProgressBar = %Wall
@onready var _found: Label = %Found
@onready var _end: Control = %End
@onready var _end_message: Label = %EndMessage


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rng.randomize()
	var finds: Array[DigFind] = []
	for find: DigFind in ResourceDir.load_all(FINDS_DIR):
		finds.append(find)
	_site = DigSite.generate(tuning, finds, _rng)
	_board.site = _site
	_board.struck.connect(_on_struck)
	%Pick.pressed.connect(_choose_tool.bind(DigSite.Tool.PICK))
	%Hammer.pressed.connect(_choose_tool.bind(DigSite.Tool.HAMMER))
	%Leave.pressed.connect(_end_dig)
	%Done.pressed.connect(_finish)
	_wall.max_value = tuning.wall_strength
	_end.hide()
	_show_progress()


func _choose_tool(tool: DigSite.Tool) -> void:
	_board.tool = tool


func _on_struck(cell: Vector2i) -> void:
	_site.strike(cell, _board.tool)
	_show_progress()
	if _site.is_done():
		_end_dig()


func _show_progress() -> void:
	_wall.value = _site.wall_left
	var names := PackedStringArray()
	for placed in _site.dug_out():
		names.append(tr(placed.find.item.display_name))
	_found.text = tr("UI_FOUND") % (", ".join(names) if names else tr("UI_NOTHING_YET"))


func _end_dig() -> void:
	_board.locked = true
	_board.queue_redraw()
	if _site.has_caved_in():
		_end_message.text = tr("UI_WALL_CAVED_IN")
	elif _site.dug_out().size() == _site.buried.size():
		_end_message.text = tr("UI_DUG_OUT_EVERYTHING")
	else:
		_end_message.text = tr("UI_LEFT_THE_WALL")
	_end.show()
	%Done.grab_focus()


func _finish() -> void:
	var found: Array[String] = []
	for placed in _site.dug_out():
		Inventory.add(placed.find.item.id)
		found.append(String(placed.find.item.id))
	Minigames.finish({"found": found})
