extends TestCase
## Which drawings make a Dhull's face. The drawings themselves are checked in
## test_face_drawings.gd.


func test_every_eye_style_has_everyday_eyes() -> void:
	for style: DhullFace.EyeStyle in DhullFace.EyeStyle.values():
		assert_true(DhullFace.EVERYDAY_EYES.has(style), "eyes for style %d" % style)


func test_neutral_shows_the_everyday_eyes() -> void:
	var neutral := DhullFace.Emotion.NEUTRAL
	assert_eq(DhullFace.eyes_for(neutral, DhullFace.EyeStyle.ROUND, false), DhullFace.Eyes.ROUND)
	assert_eq(DhullFace.eyes_for(neutral, DhullFace.EyeStyle.DROOPY, false), DhullFace.Eyes.DROOPY)
	assert_eq(DhullFace.eyes_for(neutral, DhullFace.EyeStyle.DUMB, false), DhullFace.Eyes.DUMB)


func test_emotions_show_their_own_eyes_whatever_the_style() -> void:
	var angry := DhullFace.Emotion.ANGRY
	assert_eq(DhullFace.eyes_for(angry, DhullFace.EyeStyle.DUMB, false), DhullFace.Eyes.ANGRY)
	assert_eq(DhullFace.eyes_for(angry, DhullFace.EyeStyle.DROOPY, false), DhullFace.Eyes.ANGRY)


func test_blinking_shuts_open_eyes() -> void:
	var style := DhullFace.EyeStyle.INTENSE
	assert_eq(DhullFace.eyes_for(DhullFace.Emotion.NEUTRAL, style, true), DhullFace.Eyes.CLOSED)
	assert_eq(DhullFace.eyes_for(DhullFace.Emotion.ANGRY, style, true), DhullFace.Eyes.CLOSED)


func test_happy_eyes_stay_happy_when_blinking() -> void:
	var happy := DhullFace.Emotion.HAPPY
	assert_eq(DhullFace.eyes_for(happy, DhullFace.EyeStyle.ROUND, true), DhullFace.Eyes.HAPPY)


func test_open_mouths_show() -> void:
	assert_eq(DhullFace.mouth_for(DhullFace.Emotion.ANGRY), DhullFace.Mouth.GRIN)
	assert_eq(DhullFace.mouth_for(DhullFace.Emotion.HAPPY), DhullFace.Mouth.OPEN)


func test_shut_mouths_hide() -> void:
	assert_eq(DhullFace.mouth_for(DhullFace.Emotion.NEUTRAL), DhullFace.NO_MOUTH)
	assert_eq(DhullFace.mouth_for(DhullFace.Emotion.SAD), DhullFace.NO_MOUTH)
