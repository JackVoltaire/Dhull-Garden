extends TestCase

const ANIMATIONS_PATH := "res://scenes/dhulls/dhull_animations.tres"

var _library: AnimationLibrary


func before_each() -> void:
	_library = load(ANIMATIONS_PATH)


func test_every_activity_and_mood_has_an_animation() -> void:
	for activity: DhullState.Activity in DhullState.Activity.values():
		for mood: DhullState.Mood in DhullState.Mood.values():
			var animation := DhullState.animation_for(activity, mood)
			assert_true(_library.has_animation(animation), "%s exists" % animation)


func test_every_animation_is_used() -> void:
	var used := {}
	for activity: DhullState.Activity in DhullState.Activity.values():
		for mood: DhullState.Mood in DhullState.Mood.values():
			used[DhullState.animation_for(activity, mood)] = true
	for animation in _library.get_animation_list():
		assert_true(used.has(animation), "%s is used" % animation)


## Every animation must key every part, or blending into it leaves parts where the last one put
## them.
func test_every_animation_keys_every_part_and_loops() -> void:
	for name in _library.get_animation_list():
		var animation := _library.get_animation(name)
		assert_eq(animation.loop_mode, Animation.LOOP_LINEAR, "%s loops" % name)
		for track in Dhull.ANIMATED_TRACKS:
			assert_true(
				animation.find_track(track, Animation.TYPE_VALUE) >= 0, "%s keys %s" % [name, track]
			)


func test_every_mood_has_a_face() -> void:
	for mood: DhullState.Mood in DhullState.Mood.values():
		assert_true(DhullState.FACES.has(mood), DhullState.Mood.keys()[mood])


func test_sleeping_dhulls_close_their_eyes() -> void:
	for mood: DhullState.Mood in DhullState.Mood.values():
		var emotion := DhullState.emotion_for(DhullState.Activity.SLEEPING, mood)
		assert_eq(emotion, DhullFace.Emotion.SLEEPY)


func test_energy_sets_the_speed() -> void:
	var rng := RandomNumberGenerator.new()
	var genome := DhullGenome.random(rng)
	genome.alleles[DhullGenome.Gene.ENERGY] = Vector2i(0, 0)
	assert_eq(DhullState.speed_scale(genome), DhullState.SPEED_RANGE.x)
	genome.alleles[DhullGenome.Gene.ENERGY] = Vector2i(DhullGenome.MAX_LEVEL, DhullGenome.MAX_LEVEL)
	assert_eq(DhullState.speed_scale(genome), DhullState.SPEED_RANGE.y)


func test_moods_show_as_weather_in_the_nebula() -> void:
	for mood: DhullState.Mood in DhullState.Mood.values():
		assert_true(DhullState.WEATHER.has(mood), DhullState.Mood.keys()[mood] + " has weather")
	assert_eq(DhullState.weather_for(DhullState.Mood.SAD), DhullState.Weather.RAIN)
	assert_eq(DhullState.weather_for(DhullState.Mood.GRUMPY), DhullState.Weather.STORM)
	assert_eq(DhullState.weather_for(DhullState.Mood.HAPPY), DhullState.Weather.SUN)
