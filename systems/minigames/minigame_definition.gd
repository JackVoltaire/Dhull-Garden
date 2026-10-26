class_name MinigameDefinition
extends Resource
## Describes a minigame so menus can list it and the [code]Minigames[/code] autoload can launch
## it. To add one, create a MinigameDefinition resource in res://data/minigames/.

## Stable identifier for code and save data. Don't rename it once players have saves.
@export var id: StringName
## Translation key of the name shown to players.
@export var title: String
## Translation key of a one-line description.
@export var description: String
## The minigame's scene. Its root can be 2D, 3D or UI.
@export_file("*.tscn") var scene_path: String
