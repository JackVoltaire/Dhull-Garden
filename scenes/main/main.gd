extends Node
## Entry point. Continues the game in slot 0, or starts a new one there, then enters the garden.
## A title screen with slot selection will replace this.

const SLOT := 0
const FIRST_SCENE := "res://scenes/levels/dream_island/dream_island.tscn"


func _ready() -> void:
	if not Saves.has_save(SLOT):
		Saves.new_game(SLOT)
	else:
		var error := Saves.load_game(SLOT)
		if error != OK:
			push_error(
				(
					"Couldn't load save slot %d (%s). Setting it aside and starting a new game."
					% [SLOT, error_string(error)]
				)
			)
			Saves.set_aside(SLOT)
			Saves.new_game(SLOT)
	Scenes.change_scene(FIRST_SCENE)
