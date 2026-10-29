class_name DigBoard
extends Control
## Draws a DigSite and passes on where the player strikes it. Thicker rock is drawn lighter and
## jagged dug-out cells show what's under them; the cells the chosen tool would hit are outlined
## under the mouse. The colors are placeholders for drawn rock and finds.

signal struck(cell: Vector2i)

## How big a cell is on screen.
@export var cell_size := 48.0
## Rock colors from one layer thick to the thickest.
@export var rock_colors: PackedColorArray = [
	Color(0.24, 0.2, 0.32),
	Color(0.32, 0.27, 0.42),
	Color(0.41, 0.34, 0.52),
	Color(0.5, 0.42, 0.6),
	Color(0.6, 0.52, 0.7),
]
@export var dug_color := Color(0.09, 0.07, 0.12)
@export var ink_color := Color(0.08, 0.05, 0.11)
@export var aim_color := Color(1.0, 0.9, 0.55)

var site: DigSite:
	set(value):
		site = value
		custom_minimum_size = Vector2(site.size) * cell_size
		queue_redraw()
var tool := DigSite.Tool.PICK
## Once the dig is over, the wall takes no more strikes.
var locked := false

var _aimed_at := Vector2i(-1, -1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell := _cell_at(event.position)
		if cell != _aimed_at:
			_aimed_at = cell
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not locked:
			var cell := _cell_at(event.position)
			if site.has_cell(cell):
				struck.emit(cell)
				queue_redraw()


func _draw() -> void:
	if site == null:
		return
	for y in site.size.y:
		for x in site.size.x:
			_draw_cell(Vector2i(x, y))
	for placed in site.dug_out():
		for cell in placed.cells():
			draw_rect(_rect_of(cell).grow(-2.0), aim_color, false, 3.0)
	if not locked and site.has_cell(_aimed_at):
		var pattern := (
			DigSite.HAMMER_PATTERN if tool == DigSite.Tool.HAMMER else DigSite.PICK_PATTERN
		)
		for offset in pattern:
			if site.has_cell(_aimed_at + offset):
				draw_rect(_rect_of(_aimed_at + offset).grow(-4.0), aim_color, false, 2.0)


func _draw_cell(cell: Vector2i) -> void:
	var rect := _rect_of(cell)
	var rock := site.rock_at(cell)
	var color := dug_color
	if rock > 0:
		color = rock_colors[mini(rock, rock_colors.size()) - 1]
	else:
		var under := site.find_at(cell)
		if under:
			color = under.find.color
	draw_rect(rect, color)
	draw_rect(rect, ink_color, false, 2.0)


func _rect_of(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * cell_size, Vector2.ONE * cell_size)


func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i((point / cell_size).floor())
