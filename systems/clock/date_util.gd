class_name DateUtil
extends RefCounted
## Calendar math on plain year/month/day values. Weekdays follow [enum Time.Weekday]:
## 0 is Sunday and 6 is Saturday.

const SECONDS_PER_DAY := 86400


static func is_leap_year(year: int) -> bool:
	return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


static func days_in_month(year: int, month: int) -> int:
	if month == 2:
		return 29 if is_leap_year(year) else 28
	return 30 if month in [4, 6, 9, 11] else 31


## Days since 1970-01-01. Subtract two of these to count the days between dates.
static func day_number(year: int, month: int, day: int) -> int:
	var unix_time := Time.get_unix_time_from_datetime_dict(
		{"year": year, "month": month, "day": day}
	)
	return floori(unix_time / float(SECONDS_PER_DAY))


static func weekday(year: int, month: int, day: int) -> int:
	# 1970-01-01 was a Thursday.
	return posmod(day_number(year, month, day) + Time.WEEKDAY_THURSDAY, 7)


## Day of the month of the [param n]th [param weekday_index] in a month, e.g. n = 2 and Sunday
## for the second Sunday of May. An [param n] of -1 means the last one in the month.
## Returns -1 if the month has no such day, like a fifth Monday in most months.
static func nth_weekday(year: int, month: int, weekday_index: int, n: int) -> int:
	var month_length := days_in_month(year, month)
	if n == -1:
		return month_length - posmod(weekday(year, month, month_length) - weekday_index, 7)
	if n < 1:
		return -1
	var first := 1 + posmod(weekday_index - weekday(year, month, 1), 7)
	var day := first + (n - 1) * 7
	return day if day <= month_length else -1
