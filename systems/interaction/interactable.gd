class_name Interactable
extends Area3D
## Something the player can walk up to and use with the Interact button. Give it a
## CollisionShape3D child for how close the player must be, then connect [signal interacted]
## or extend this class and override [method interact].
##
## Interactables sit on the "interactable" physics layer, which only the player's
## [Interactor] looks at.

signal interacted(player: Player)

## Physics layer 3, named "interactable" in the project settings.
const LAYER := 1 << 2

## Translation key of the verb shown in the prompt, such as "PROMPT_DIG".
@export var prompt := "PROMPT_INTERACT"
## When false, the player can't see or use it, e.g. while it's used up for the day.
@export var enabled := true


func _init() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false


func interact(player: Player) -> void:
	interacted.emit(player)
