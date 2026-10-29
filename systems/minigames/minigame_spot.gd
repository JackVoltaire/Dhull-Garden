class_name MinigameSpot
extends Interactable
## A place in the world that starts a minigame when the player interacts with it, like a shiny
## spot on a rock that opens the mining minigame. When the minigame ends, the player is back
## where they were standing. A spot used once a day hides until the next day.

@export var minigame: MinigameDefinition
## Passed to the minigame as [member Minigames.context], e.g. {"ore": "copper"} to say what this
## spot yields.
@export var context: Dictionary = {}
## Whether it can be used only once each real-world day.
@export var once_a_day := false
## Stable id of this spot, for remembering that it was used today. Never rename it.
@export var spot_id: StringName


func _ready() -> void:
	Clock.day_changed.connect(_refresh)
	_refresh()


func interact(player: Player) -> void:
	super(player)
	if minigame == null:
		push_warning("%s has no minigame set." % get_path())
		return
	if once_a_day:
		Minigames.mark_used(spot_id)
	Minigames.launch(minigame, context, {"player": player.get_state()})


func _refresh() -> void:
	enabled = not (once_a_day and Minigames.used_today(spot_id))
	visible = enabled
