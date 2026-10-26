class_name Level
extends Node3D
## Root of an area the player walks around in. Expects the player as a child named Player.
## When the player comes back from a minigame, puts them back where they were standing, and
## when they fall off the world, puts them back where they started.

## Height below which the player has fallen off and goes back to where they started.
@export var fall_limit := -50.0

var _player_state: Dictionary = {}
var _spawn_transform := Transform3D.IDENTITY

@onready var _player: Player = $Player


## Called by [code]Scenes[/code] before the level enters the tree. A "player" entry holds a
## [method Player.get_state] to restore.
func setup(params: Dictionary) -> void:
	_player_state = params.get("player", {})


func _ready() -> void:
	_spawn_transform = _player.global_transform
	if not _player_state.is_empty():
		_player.apply_state(_player_state)


func _physics_process(_delta: float) -> void:
	if _player.global_position.y < fall_limit:
		_player.global_transform = _spawn_transform
		_player.velocity = Vector3.ZERO
