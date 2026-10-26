extends Node
## Tracks which [CalendarEvent]s are running and the current season, registered as the
## [code]Calendar[/code] autoload. Events are loaded from [constant EVENTS_DIR].
##
## The signals only report changes after startup. To know what's running when a scene starts,
## call [method get_active_events] and [method season].

signal event_started(event: CalendarEvent)
signal event_ended(event: CalendarEvent)
signal season_changed(season: Season)

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const EVENTS_DIR := "res://data/events/"
const SEASONS_FROM_WINTER: Array[Season] = [
	Season.WINTER, Season.SPRING, Season.SUMMER, Season.AUTUMN
]

var events: Array[CalendarEvent] = []

var _active: Array[CalendarEvent] = []
var _season := Season.SPRING


func _ready() -> void:
	for resource in ResourceDir.load_all(EVENTS_DIR):
		if resource is CalendarEvent:
			events.append(resource)
		else:
			push_error("%s is not a CalendarEvent." % resource.resource_path)
	_active = _find_active_events()
	_season = _current_season()
	Clock.hour_changed.connect(_refresh.unbind(1))
	Clock.time_shifted.connect(_refresh)
	Settings.changed.connect(_on_setting_changed)


func get_active_events() -> Array[CalendarEvent]:
	return _active.duplicate()


func is_event_active(id: StringName) -> bool:
	return _active.any(func(event: CalendarEvent) -> bool: return event.id == id)


func get_event(id: StringName) -> CalendarEvent:
	for event in events:
		if event.id == id:
			return event
	return null


func season() -> Season:
	return _season


## Meteorological season: in the north, winter is December to February, spring March to May,
## and so on. South of the equator the seasons are opposite.
static func season_for_month(month: int, southern_hemisphere: bool) -> Season:
	var index := floori((month % 12) / 3.0)
	if southern_hemisphere:
		index = (index + 2) % 4
	return SEASONS_FROM_WINTER[index]


func _refresh() -> void:
	var previous := _active
	_active = _find_active_events()
	for event in previous:
		if event not in _active:
			event_ended.emit(event)
	for event in _active:
		if event not in previous:
			event_started.emit(event)

	var new_season := _current_season()
	if new_season != _season:
		_season = new_season
		season_changed.emit(new_season)


func _find_active_events() -> Array[CalendarEvent]:
	var local := Clock.now_local()
	return events.filter(func(event: CalendarEvent) -> bool: return event.is_active_at(local))


func _current_season() -> Season:
	var southern: bool = Settings.get_value("game/southern_hemisphere")
	return season_for_month(Clock.now_local().month, southern)


func _on_setting_changed(setting: String, _value: Variant) -> void:
	if setting == "game/southern_hemisphere":
		_refresh()
