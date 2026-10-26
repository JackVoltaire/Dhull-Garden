class_name Level
extends Node3D
## Root of an area the player walks around in. Expects the player as a child named Player.
## When the player comes back from a minigame, puts them back where they were standing.

var _player_state: Dictionary = {}

@onready var _player: Player = $Player


## Called by [code]Scenes[/code] before the level enters the tree. A "player" entry holds a
## [method Player.get_state] to restore.
func setup(params: Dictionary) -> void:
	_player_state = params.get("player", {})


func _ready() -> void:
	if not _player_state.is_empty():
		_player.apply_state(_player_state)
