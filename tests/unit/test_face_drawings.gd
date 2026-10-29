extends TestCase
## The face drawings and the materials that paint them with dhull_face.gdshader: the Dhulls' and
## the dreamer's. Each material must have a frame per eye drawing its owner picks from, the eye
## layers alike, and a row of irises per eye color, or faces show the wrong drawing.

## Width over height of one frame of each strip, whatever size the drawings are imported at.
const EYE_FRAME_ASPECT := 1.6
const MOUTH_FRAME_ASPECT := 2.0
const DHULL_FACE_PATH := "res://scenes/dhulls/face/dhull_face.tres"
const DREAMER_FACE_PATH := "res://assets/materials/face_dreamer.tres"


func test_dhull_faces_have_a_drawing_per_shape() -> void:
	var material: ShaderMaterial = load(DHULL_FACE_PATH)
	_check_eyes(material, DhullFace.Eyes.size(), DhullGenome.EyeColor.size())
	assert_eq(material.get_shader_parameter("mouth_frames"), DhullFace.Mouth.size())
	var mouths: Texture2D = material.get_shader_parameter("mouths")
	assert_eq(
		mouths.get_width(),
		roundi(mouths.get_height() * MOUTH_FRAME_ASPECT) * DhullFace.Mouth.size()
	)


## The dreamer has eyes of their own, in one color.
func test_the_dreamer_has_a_drawing_per_eye() -> void:
	_check_eyes(load(DREAMER_FACE_PATH), DreamerModel.Eyes.size(), 1)


func _check_eyes(material: ShaderMaterial, frames: int, colors: int) -> void:
	var path := material.resource_path
	assert_eq(material.get_shader_parameter("eye_frames"), frames, path + " frames")
	assert_eq(material.get_shader_parameter("eye_colors"), colors, path + " colors")
	var whites: Texture2D = material.get_shader_parameter("eye_whites")
	var lines: Texture2D = material.get_shader_parameter("eye_lines")
	var irises: Texture2D = material.get_shader_parameter("irises")
	var frame_width := roundi(whites.get_height() * EYE_FRAME_ASPECT)
	assert_eq(whites.get_width(), frame_width * frames, path + " whites have a frame each")
	assert_eq(lines.get_size(), whites.get_size(), path + " lines match the whites")
	assert_eq(irises.get_size(), whites.get_size() * Vector2(1, colors), path + " iris rows")
	_check_irises_keep_clear(irises.get_image(), frames, path)


## The shader keeps each iris to its own half of its frame and smears the half's edge pixels
## when it slides an iris far, so no iris may touch the edges or the middle of its frame.
func _check_irises_keep_clear(irises: Image, frames: int, path: String) -> void:
	irises.decompress()
	var frame_width := irises.get_width() / frames
	var half := frame_width / 2
	for frame in frames:
		for column in [0, half - 1, half, frame_width - 1]:
			var x: int = frame * frame_width + column
			for y in irises.get_height():
				var clear := irises.get_pixel(x, y).a == 0.0
				assert_true(clear, "%s frame %d keeps clear of column %d" % [path, frame, column])
				if not clear:
					return
