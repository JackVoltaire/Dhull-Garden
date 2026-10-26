extends TestCase

const EYE_FRAME_WIDTH := 256
const MOUTH_FRAME_WIDTH := 128


func test_every_emotion_has_eyes_and_a_mouth() -> void:
	for emotion: DhullFace.Emotion in DhullFace.Emotion.values():
		assert_true(DhullFace.EYES_FOR.has(emotion), "eyes for %d" % emotion)
		assert_true(DhullFace.MOUTH_FOR.has(emotion), "mouth for %d" % emotion)


func test_blinking_shuts_open_eyes() -> void:
	assert_eq(DhullFace.eyes_for(DhullFace.Emotion.NEUTRAL, false), DhullFace.Eyes.OPEN)
	assert_eq(DhullFace.eyes_for(DhullFace.Emotion.NEUTRAL, true), DhullFace.Eyes.CLOSED)
	assert_eq(DhullFace.eyes_for(DhullFace.Emotion.ANGRY, true), DhullFace.Eyes.CLOSED)


func test_happy_eyes_stay_happy_when_blinking() -> void:
	assert_eq(DhullFace.eyes_for(DhullFace.Emotion.HAPPY, true), DhullFace.Eyes.HAPPY)


func test_mouth_ignores_blinking() -> void:
	assert_eq(DhullFace.mouth_for(DhullFace.Emotion.ANGRY), DhullFace.Mouth.GRIN)


## The face images and the face material must have one frame per eye and mouth shape, or
## faces show the wrong drawing.
func test_face_images_match_the_shapes() -> void:
	var material: ShaderMaterial = load("res://scenes/dhulls/face/dhull_face.tres")
	assert_eq(material.get_shader_parameter("eye_frames"), DhullFace.Eyes.size())
	assert_eq(material.get_shader_parameter("mouth_frames"), DhullFace.Mouth.size())
	var eyes: Texture2D = material.get_shader_parameter("eyes")
	var mouths: Texture2D = material.get_shader_parameter("mouths")
	assert_eq(eyes.get_width(), EYE_FRAME_WIDTH * DhullFace.Eyes.size())
	assert_eq(mouths.get_width(), MOUTH_FRAME_WIDTH * DhullFace.Mouth.size())
