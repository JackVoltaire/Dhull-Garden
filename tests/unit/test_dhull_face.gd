extends TestCase

## Width over height of one frame of each strip, whatever size the drawings are imported at.
const EYE_FRAME_ASPECT := 1.6
const MOUTH_FRAME_ASPECT := 2.0
const FACE_MATERIAL_PATH := "res://scenes/dhulls/face/dhull_face.tres"


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


## The face images and the face material must have one frame per eye and mouth shape, the eye
## layers alike, and a row of irises per eye color, or faces show the wrong drawing.
func test_face_images_match_the_shapes() -> void:
	var material: ShaderMaterial = load(FACE_MATERIAL_PATH)
	var eye_colors := DhullGenome.EyeColor.size()
	assert_eq(material.get_shader_parameter("eye_frames"), DhullFace.Eyes.size())
	assert_eq(material.get_shader_parameter("eye_colors"), eye_colors)
	assert_eq(material.get_shader_parameter("mouth_frames"), DhullFace.Mouth.size())
	var whites: Texture2D = material.get_shader_parameter("eye_whites")
	var lines: Texture2D = material.get_shader_parameter("eye_lines")
	var irises: Texture2D = material.get_shader_parameter("irises")
	var mouths: Texture2D = material.get_shader_parameter("mouths")
	assert_eq(
		whites.get_width(), roundi(whites.get_height() * EYE_FRAME_ASPECT) * DhullFace.Eyes.size()
	)
	assert_eq(lines.get_size(), whites.get_size(), "lines match the whites")
	assert_eq(irises.get_size(), whites.get_size() * Vector2(1, eye_colors), "a row per eye color")
	assert_eq(
		mouths.get_width(),
		roundi(mouths.get_height() * MOUTH_FRAME_ASPECT) * DhullFace.Mouth.size()
	)


## The shader keeps each iris to its own half of its frame and smears the half's edge pixels
## when it slides an iris far, so no iris may touch the edges or the middle of its frame.
func test_irises_keep_clear_of_their_frames_edges() -> void:
	var material: ShaderMaterial = load(FACE_MATERIAL_PATH)
	var irises: Image = (material.get_shader_parameter("irises") as Texture2D).get_image()
	irises.decompress()
	var frame_width := irises.get_width() / DhullFace.Eyes.size()
	var half := frame_width / 2
	for frame in DhullFace.Eyes.size():
		for column in [0, half - 1, half, frame_width - 1]:
			var x: int = frame * frame_width + column
			for y in irises.get_height():
				var clear := irises.get_pixel(x, y).a == 0.0
				assert_true(clear, "frame %d keeps clear of column %d" % [frame, column])
				if not clear:
					return
