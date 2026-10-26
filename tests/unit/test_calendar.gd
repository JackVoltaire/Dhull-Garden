extends TestCase


func test_single_day_range() -> void:
	var halloween := _event({"start_month": 10, "start_day": 31, "end_month": 10, "end_day": 31})
	assert_true(halloween.occurs_on(2026, 10, 31))
	assert_false(halloween.occurs_on(2026, 10, 30))
	assert_false(halloween.occurs_on(2026, 11, 1))


func test_range_spanning_new_year() -> void:
	var new_year := _event({"start_month": 12, "start_day": 31, "end_month": 1, "end_day": 1})
	assert_true(new_year.occurs_on(2026, 12, 31))
	assert_true(new_year.occurs_on(2027, 1, 1))
	assert_false(new_year.occurs_on(2026, 12, 30))
	assert_false(new_year.occurs_on(2027, 1, 2))


func test_hours() -> void:
	var evening := _event(
		{"start_month": 10, "start_day": 31, "end_month": 10, "end_day": 31, "start_hour": 17}
	)
	assert_false(evening.is_active_at(_at(2026, 10, 31, 16)))
	assert_true(evening.is_active_at(_at(2026, 10, 31, 17)))
	assert_true(evening.is_active_at(_at(2026, 10, 31, 23)))
	assert_false(evening.is_active_at(_at(2026, 11, 1, 17)))


func test_nth_weekday() -> void:
	var harvest := _event(
		{
			"recurrence": CalendarEvent.Recurrence.NTH_WEEKDAY,
			"weekday": Time.WEEKDAY_THURSDAY,
			"weekday_month": 11,
			"nth": 4,
		}
	)
	assert_true(harvest.occurs_on(2026, 11, 26))
	assert_false(harvest.occurs_on(2026, 11, 19))
	assert_true(harvest.occurs_on(2027, 11, 25))
	assert_false(harvest.occurs_on(2026, 10, 22), "same weekday, wrong month")


func test_weekly() -> void:
	var market := _event(
		{"recurrence": CalendarEvent.Recurrence.WEEKLY, "weekday": Time.WEEKDAY_SATURDAY}
	)
	assert_true(market.occurs_on(2026, 10, 31))
	assert_true(market.occurs_on(2026, 11, 7))
	assert_false(market.occurs_on(2026, 11, 1))


func test_seasons() -> void:
	assert_eq(Calendar.season_for_month(1, false), Calendar.Season.WINTER)
	assert_eq(Calendar.season_for_month(4, false), Calendar.Season.SPRING)
	assert_eq(Calendar.season_for_month(7, false), Calendar.Season.SUMMER)
	assert_eq(Calendar.season_for_month(10, false), Calendar.Season.AUTUMN)
	assert_eq(Calendar.season_for_month(12, false), Calendar.Season.WINTER)


func test_seasons_in_southern_hemisphere() -> void:
	assert_eq(Calendar.season_for_month(1, true), Calendar.Season.SUMMER)
	assert_eq(Calendar.season_for_month(4, true), Calendar.Season.AUTUMN)
	assert_eq(Calendar.season_for_month(7, true), Calendar.Season.WINTER)
	assert_eq(Calendar.season_for_month(10, true), Calendar.Season.SPRING)


func test_event_files_load_with_unique_ids() -> void:
	var ids := {}
	for event in Calendar.events:
		assert_false(ids.has(event.id), "duplicate id %s" % event.id)
		ids[event.id] = true
	assert_true(Calendar.get_event(&"new_year") != null)


func _event(properties: Dictionary) -> CalendarEvent:
	var event := CalendarEvent.new()
	for property: String in properties:
		event.set(property, properties[property])
	return event


func _at(year: int, month: int, day: int, hour: int) -> Dictionary:
	return {"year": year, "month": month, "day": day, "hour": hour}
