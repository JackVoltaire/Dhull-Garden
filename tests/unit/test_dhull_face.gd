extends TestCase

## Width over height of one frame of each strip, whatever size the drawings are imported at.
const EYE_FRAME_ASPECT := 1.6
const MOUTH_FRAME_ASPECT := 2.0


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


## The face images and the face material must have one frame per eye and mouth shape, and a row
## of eyes per eye color, or faces show the wrong drawing.
func test_face_images_match_the_shapes() -> void:
	var material: ShaderMaterial = load("res://scenes/dhulls/face/dhull_face.tres")
	var eye_colors := DhullGenome.EyeColor.size()
	assert_eq(material.get_shader_parameter("eye_frames"), DhullFace.Eyes.size())
	assert_eq(material.get_shader_parameter("eye_colors"), eye_colors)
	assert_eq(material.get_shader_parameter("mouth_frames"), DhullFace.Mouth.size())
	var eyes: Texture2D = material.get_shader_parameter("eyes")
	var mouths: Texture2D = material.get_shader_parameter("mouths")
	assert_eq(eyes.get_height() % eye_colors, 0, "a row per eye color")
	var eye_frame_height := eyes.get_height() / eye_colors
	assert_eq(eyes.get_width(), roundi(eye_frame_height * EYE_FRAME_ASPECT) * DhullFace.Eyes.size())
	assert_eq(
		mouths.get_width(),
		roundi(mouths.get_height() * MOUTH_FRAME_ASPECT) * DhullFace.Mouth.size()
	)
