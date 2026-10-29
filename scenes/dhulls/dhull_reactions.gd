class_name DhullReactions
extends Node3D
## Reaction symbols that pop up beside a Dhull's head, as in Animal Crossing (see DhullReaction).
## Each symbol is a child drawing; one pops up at a time, stays a moment and shrinks away.

## How long a symbol stays up.
@export_range(0.1, 5.0, 0.05, "suffix:s") var show_seconds := 1.6
## How long it takes to pop up, and to shrink away.
@export_range(0.05, 1.0, 0.01, "suffix:s") var pop_seconds := 0.18

var _popping: Tween

@onready var _symbols: Dictionary[DhullReaction.Symbol, Node3D] = {
	DhullReaction.Symbol.EYE: $Eye,
	DhullReaction.Symbol.STAR: $Star,
	DhullReaction.Symbol.SPIRAL: $Spiral,
}


func _ready() -> void:
	_show_only(DhullReaction.Symbol.NONE)


## Pops up [param symbol], cutting short any symbol already up.
func pop(symbol: DhullReaction.Symbol) -> void:
	if _popping:
		_popping.kill()
	_show_only(symbol)
	scale = Vector3.ONE * 0.01
	_popping = create_tween()
	_popping.tween_property(self, ^"scale", Vector3.ONE * 1.25, pop_seconds * 0.6).set_trans(
		Tween.TRANS_BACK
	)
	_popping.tween_property(self, ^"scale", Vector3.ONE, pop_seconds * 0.4)
	_popping.tween_interval(show_seconds)
	_popping.tween_property(self, ^"scale", Vector3.ONE * 0.01, pop_seconds)
	_popping.tween_callback(_show_only.bind(DhullReaction.Symbol.NONE))


## How long a symbol is up for, from popping up to gone.
func duration() -> float:
	return pop_seconds * 2.0 + show_seconds


func _show_only(symbol: DhullReaction.Symbol) -> void:
	for kind in _symbols:
		_symbols[kind].visible = kind == symbol
