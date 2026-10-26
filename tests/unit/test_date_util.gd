extends TestCase


func test_leap_years() -> void:
	assert_true(DateUtil.is_leap_year(2024))
	assert_true(DateUtil.is_leap_year(2000))
	assert_false(DateUtil.is_leap_year(1900))
	assert_false(DateUtil.is_leap_year(2026))


func test_days_in_month() -> void:
	assert_eq(DateUtil.days_in_month(2026, 1), 31)
	assert_eq(DateUtil.days_in_month(2026, 2), 28)
	assert_eq(DateUtil.days_in_month(2024, 2), 29)
	assert_eq(DateUtil.days_in_month(2026, 4), 30)
	assert_eq(DateUtil.days_in_month(2026, 12), 31)


func test_day_number() -> void:
	assert_eq(DateUtil.day_number(1970, 1, 1), 0)
	assert_eq(DateUtil.day_number(1969, 12, 31), -1)
	assert_eq(DateUtil.day_number(2000, 2, 29), 11016)
	assert_eq(DateUtil.day_number(2026, 10, 26), 20752)


func test_weekday() -> void:
	assert_eq(DateUtil.weekday(1970, 1, 1), Time.WEEKDAY_THURSDAY)
	assert_eq(DateUtil.weekday(1969, 12, 31), Time.WEEKDAY_WEDNESDAY)
	assert_eq(DateUtil.weekday(2000, 2, 29), Time.WEEKDAY_TUESDAY)
	assert_eq(DateUtil.weekday(2026, 10, 26), Time.WEEKDAY_MONDAY)
	assert_eq(DateUtil.weekday(2026, 5, 31), Time.WEEKDAY_SUNDAY)


func test_nth_weekday() -> void:
	assert_eq(DateUtil.nth_weekday(2026, 5, Time.WEEKDAY_SUNDAY, 2), 10, "2nd Sunday of May")
	assert_eq(DateUtil.nth_weekday(2026, 11, Time.WEEKDAY_THURSDAY, 4), 26, "4th Thursday")
	assert_eq(DateUtil.nth_weekday(2026, 5, Time.WEEKDAY_FRIDAY, 1), 1, "month starts on it")


func test_last_weekday() -> void:
	assert_eq(DateUtil.nth_weekday(2026, 5, Time.WEEKDAY_MONDAY, -1), 25)
	assert_eq(DateUtil.nth_weekday(2024, 2, Time.WEEKDAY_SATURDAY, -1), 24, "leap February")


func test_missing_nth_weekday() -> void:
	assert_eq(DateUtil.nth_weekday(2026, 5, Time.WEEKDAY_MONDAY, 5), -1, "only four Mondays")
	assert_eq(DateUtil.nth_weekday(2026, 5, Time.WEEKDAY_MONDAY, 0), -1)
