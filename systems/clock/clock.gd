extends Node
## Real-world time source, registered as the [code]Clock[/code] autoload. Time-based features
## (day and night, events, aging) read the time from here instead of from [Time] directly, so
## the debug menu can move the clock for testing.
##
## Signals fire on the minute, hour and day boundaries of local time. A jump in
## [member offset_seconds] fires them once for the new time, plus [signal time_shifted].

signal minute_changed
signal hour_changed(hour: int)
signal phase_changed(phase: Phase)
signal day_changed
## The clock jumped because [member offset_seconds] changed, rather than ticking forward.
signal time_shifted

enum Phase { NIGHT, DAWN, DAY, DUSK }

## Local hours at which each [enum Phase] begins.
const DAWN_HOUR := 5
const DAY_HOUR := 7
const DUSK_HOUR := 18
const NIGHT_HOUR := 20

## Seconds added to the system time. The debug menu changes this to time travel.
var offset_seconds := 0:
	set(value):
		offset_seconds = value
		_check_for_changes()
		time_shifted.emit()

var _last_local: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_local = now_local()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_check_for_changes)
	add_child(timer)
	timer.start()


## Current Unix time in seconds (UTC), including [member offset_seconds].
func now_unix() -> int:
	return int(Time.get_unix_time_from_system()) + offset_seconds


## Current local date and time with the keys year, month, day, weekday, hour, minute and second.
func now_local() -> Dictionary:
	return to_local(now_unix())


## Converts a Unix time to a local date and time using the system's current UTC offset.
func to_local(unix_time: int) -> Dictionary:
	var bias_minutes: int = Time.get_time_zone_from_system().get("bias", 0)
	return Time.get_datetime_dict_from_unix_time(unix_time + bias_minutes * 60)


func phase() -> Phase:
	return phase_at_hour(now_local().hour)


## How far through the local day it is, from 0.0 at midnight towards 1.0.
func day_fraction() -> float:
	var local := now_local()
	var seconds: int = local.hour * 3600 + local.minute * 60 + local.second
	return seconds / float(DateUtil.SECONDS_PER_DAY)


static func phase_at_hour(hour: int) -> Phase:
	if hour < DAWN_HOUR or hour >= NIGHT_HOUR:
		return Phase.NIGHT
	if hour < DAY_HOUR:
		return Phase.DAWN
	if hour < DUSK_HOUR:
		return Phase.DAY
	return Phase.DUSK


func _check_for_changes() -> void:
	var local := now_local()
	var last := _last_local
	var day_differs: bool = (
		local.year != last.year or local.month != last.month or local.day != last.day
	)
	var hour_differs: bool = day_differs or local.hour != last.hour
	if not hour_differs and local.minute == last.minute:
		return

	_last_local = local
	minute_changed.emit()
	if hour_differs:
		hour_changed.emit(local.hour)
		if phase_at_hour(local.hour) != phase_at_hour(last.hour):
			phase_changed.emit(phase_at_hour(local.hour))
	if day_differs:
		day_changed.emit()
