class_name MinigameSpot
extends Interactable
## A place in the world that starts a minigame when the player interacts with it, like a shiny
## spot on a rock that opens the mining minigame. When the minigame ends, the player is back
## where they were standing.

@export var minigame: MinigameDefinition
## Passed to the minigame as [member Minigames.context], e.g. {"ore": "copper"} to say what this
## spot yields.
@export var context: Dictionary = {}


func interact(player: Player) -> void:
	super(player)
	if minigame == null:
		push_warning("%s has no minigame set." % get_path())
		return
	Minigames.launch(minigame, context, {"player": player.get_state()})
