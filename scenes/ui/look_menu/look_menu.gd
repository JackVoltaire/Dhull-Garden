class_name LookMenu
extends PanelContainer
## Where the dreamer picks their look, the length and color of their hair, seeing it on
## themselves as they pick. A new game opens it before the first dream, and the pause menu opens
## it again any time.

## The hair colors to offer, as swatches.
@export var colors: DreamerColors

var _player: Player
var _length_buttons: Dictionary[DreamerLook.HairLength, Button] = {}
var _color_buttons: Dictionary[DreamerLook.HairColor, Button] = {}

@onready var _lengths: HBoxContainer = %Lengths
@onready var _swatches: GridContainer = %Swatches
@onready var _done: Button = %Done


func _ready() -> void:
	hide()
	# The choices are made from the look's options and the palette, so offering another length
	# or color needs no change here.
	var lengths := ButtonGroup.new()
	for length: DreamerLook.HairLength in DreamerLook.HairLength.values():
		var button := Button.new()
		button.text = "UI_HAIR_" + DreamerLook.HairLength.keys()[length]
		button.toggle_mode = true
		button.button_group = lengths
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_pick_length.bind(length))
		_lengths.add_child(button)
		_length_buttons[length] = button
	var swatches := ButtonGroup.new()
	for hair_color: DreamerLook.HairColor in DreamerLook.HairColor.values():
		var button := _swatch(colors.hair[hair_color])
		button.tooltip_text = "UI_HAIR_" + DreamerLook.HairColor.keys()[hair_color]
		button.button_group = swatches
		button.pressed.connect(_pick_color.bind(hair_color))
		_swatches.add_child(button)
		_color_buttons[hair_color] = button
	_done.pressed.connect(_close)


func open(player: Player) -> void:
	_player = player
	_player.busy = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_length_buttons[Dreamer.look.hair_length].set_pressed_no_signal(true)
	_color_buttons[Dreamer.look.hair_color].set_pressed_no_signal(true)
	show()
	_length_buttons[Dreamer.look.hair_length].grab_focus()


func _pick_length(length: DreamerLook.HairLength) -> void:
	var look := Dreamer.look.copy()
	look.hair_length = length
	Dreamer.choose(look)


func _pick_color(hair_color: DreamerLook.HairColor) -> void:
	var look := Dreamer.look.copy()
	look.hair_color = hair_color
	Dreamer.choose(look)


func _close() -> void:
	# Keeping the look they started with still counts as picking it.
	Dreamer.choose(Dreamer.look)
	hide()
	_player.busy = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


static func _swatch(color: Color) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(40, 40)
	var fill := ColorRect.new()
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(fill)
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	return button
