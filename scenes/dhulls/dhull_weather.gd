@tool
class_name DhullWeather
extends Node3D
## The weather in a Dhull's nebula, showing how it feels (see DhullState.WEATHER). Each kind of
## weather is a child drawing; only the current one shows.

@onready var _drawings: Dictionary[DhullState.Weather, Node3D] = {
	DhullState.Weather.RAIN: $Rain,
	DhullState.Weather.STORM: $Storm,
	DhullState.Weather.SUN: $Sun,
}


func show_weather(weather: DhullState.Weather) -> void:
	for kind in _drawings:
		_drawings[kind].visible = kind == weather
