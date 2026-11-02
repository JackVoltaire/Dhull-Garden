extends Node
## The `Dreamer` autoload: how the player's dreamer looks, saved with the game. A new game asks
## for a look before the first dream, and the pause menu can ask again any time; the player
## scene answers both by opening its look menu.

## The look changed, as it does while the dreamer tries looks on.
signal look_changed
## Something asked the dreamer to pick their look, like the pause menu.
signal look_wanted

const SAVE_ID := &"dreamer"

var look := DreamerLook.new()
## Whether the dreamer has picked their look yet in this game.
var chosen := false


func _ready() -> void:
	Saves.register(SAVE_ID, self)


## Wears [param new_look], and counts it as picked.
func choose(new_look: DreamerLook) -> void:
	chosen = true
	if new_look.equals(look):
		return
	look = new_look.copy()
	look_changed.emit()


## Asks for the dreamer to pick their look again.
func ask_for_look() -> void:
	look_wanted.emit()


func get_save_data() -> Dictionary:
	return {"look": look.to_dict(), "chosen": chosen}


## A new game, or a save from before the dreamer had a look, starts with the default look, not
## yet picked.
func apply_save_data(data: Dictionary) -> void:
	var saved_look: Variant = data.get("look", {})
	look = DreamerLook.from_dict(saved_look if saved_look is Dictionary else {})
	chosen = bool(data.get("chosen", false))
	look_changed.emit()
