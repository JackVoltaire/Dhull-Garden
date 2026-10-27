extends Level
## A stage with a Dhull for every activity and mood, to check their animations side by side: a row
## per activity, a column per mood. Open it from the F3 menu.

const DHULL_SCENE := preload("res://scenes/dhulls/dhull.tscn")

## Meters between columns (moods) and rows (activities).
@export var spacing := Vector2(1.1, 1.6)

@onready var _dhulls: Node3D = $Dhulls


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	# The same Dhulls every time, so a change in an animation is easy to spot.
	rng.seed = 1
	var moods := DhullState.Mood.values()
	var activities := DhullState.Activity.values()
	var left := -spacing.x * (moods.size() - 1) / 2.0
	for row in activities.size():
		var z := -spacing.y * row
		_add_label(DhullState.Activity.keys()[row].capitalize(), Vector3(left - spacing.x, 0.4, z))
		for column in moods.size():
			var dhull: Dhull = DHULL_SCENE.instantiate()
			dhull.genome = DhullGenome.random(rng)
			dhull.activity = activities[row]
			dhull.mood = moods[column]
			dhull.position = Vector3(left + spacing.x * column, 0.0, z)
			_dhulls.add_child(dhull)
	for column in moods.size():
		_add_label(
			DhullState.Mood.keys()[column].capitalize(),
			Vector3(left + spacing.x * column, 1.1, 0.6)
		)
	super()


func _add_label(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.004
	label.outline_size = 12
	_dhulls.add_child(label)
