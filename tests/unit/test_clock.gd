extends TestCase


func after_each() -> void:
	Clock.offset_seconds = 0


func test_phase_boundaries() -> void:
	assert_eq(Clock.phase_at_hour(0), Clock.Phase.NIGHT)
	assert_eq(Clock.phase_at_hour(4), Clock.Phase.NIGHT)
	assert_eq(Clock.phase_at_hour(5), Clock.Phase.DAWN)
	assert_eq(Clock.phase_at_hour(6), Clock.Phase.DAWN)
	assert_eq(Clock.phase_at_hour(7), Clock.Phase.DAY)
	assert_eq(Clock.phase_at_hour(17), Clock.Phase.DAY)
	assert_eq(Clock.phase_at_hour(18), Clock.Phase.DUSK)
	assert_eq(Clock.phase_at_hour(19), Clock.Phase.DUSK)
	assert_eq(Clock.phase_at_hour(20), Clock.Phase.NIGHT)
	assert_eq(Clock.phase_at_hour(23), Clock.Phase.NIGHT)


func test_offset_moves_the_clock() -> void:
	var before := Clock.now_unix()
	Clock.offset_seconds = DateUtil.SECONDS_PER_DAY
	var jump := Clock.now_unix() - before
	assert_true(jump >= DateUtil.SECONDS_PER_DAY and jump <= DateUtil.SECONDS_PER_DAY + 1)


func test_offset_change_emits_day_changed() -> void:
	var emitted := []
	var on_day_changed := func() -> void: emitted.append(true)
	Clock.day_changed.connect(on_day_changed)
	Clock.offset_seconds = DateUtil.SECONDS_PER_DAY
	Clock.day_changed.disconnect(on_day_changed)
	assert_eq(emitted.size(), 1)


func test_local_time_matches_the_system() -> void:
	var system := Time.get_datetime_dict_from_system()
	var local := Clock.to_local(int(Time.get_unix_time_from_system()))
	assert_eq(local.day, system.day)
	assert_eq(local.hour, system.hour)
