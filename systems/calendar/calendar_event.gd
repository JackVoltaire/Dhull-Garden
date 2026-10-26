class_name CalendarEvent
extends Resource
## A recurring real-world event, like a holiday or a weekly market. To add one, create a
## CalendarEvent resource in res://data/events/; the [code]Calendar[/code] autoload picks it up.

enum Recurrence {
	## Every year from start month/day to end month/day, inclusive. May span New Year.
	YEARLY_RANGE,
	## Every year on the nth weekday of a month, e.g. the second Sunday of May.
	NTH_WEEKDAY,
	## Every week on one weekday.
	WEEKLY,
}

## Stable identifier for code and save data. Don't rename it once players have saves.
@export var id: StringName
## Translation key of the name shown to players.
@export var display_name: String
@export var recurrence := Recurrence.YEARLY_RANGE

@export_group("Yearly Range")
@export_range(1, 12) var start_month := 1
@export_range(1, 31) var start_day := 1
@export_range(1, 12) var end_month := 1
@export_range(1, 31) var end_day := 1

@export_group("Weekday")
## Used by NTH_WEEKDAY and WEEKLY.
@export_enum("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
var weekday := 0
## Month for NTH_WEEKDAY.
@export_range(1, 12) var weekday_month := 1
## Which occurrence for NTH_WEEKDAY: 1 for the first in the month, 2 for the second, and so on.
## -1 for the last.
@export_range(-1, 5) var nth := 1

@export_group("Hours")
## Local hour the event starts on each day it runs.
@export_range(0, 23) var start_hour := 0
## Local hour the event ends, exclusive. 24 runs it until midnight.
@export_range(1, 24) var end_hour := 24


## Whether the event is running at [param local], a date and time like the ones from
## [code]Clock.now_local()[/code].
func is_active_at(local: Dictionary) -> bool:
	var hour: int = local.hour
	if hour < start_hour or hour >= end_hour:
		return false
	return occurs_on(local.year, local.month, local.day)


## Whether the event runs at some point on the given date.
func occurs_on(year: int, month: int, day: int) -> bool:
	match recurrence:
		Recurrence.YEARLY_RANGE:
			var date := month * 100 + day
			var start := start_month * 100 + start_day
			var end := end_month * 100 + end_day
			if start <= end:
				return date >= start and date <= end
			return date >= start or date <= end
		Recurrence.NTH_WEEKDAY:
			return month == weekday_month and day == DateUtil.nth_weekday(year, month, weekday, nth)
		Recurrence.WEEKLY:
			return DateUtil.weekday(year, month, day) == weekday
	return false
