extends TestCase
## The face drawings and the materials that paint them with dhull_face.gdshader: the Dhulls' and
## the dreamer's. Each material must have a frame per drawing its owner picks from, the eye
## layers alike, and a row of irises per eye color, or faces show the wrong drawing; and each
## frame must be the shape the material shows it at, or it's stretched. Where the eyes are spread
## apart, the shader cuts each frame in two, so no eye may reach the middle of its frame.
const DHULL_FACE_PATH := "res://scenes/dhulls/face/dhull_face.tres"
const DREAMER_FACE_PATH := "res://assets/materials/face_dreamer.tres"


func test_dhull_faces_have_a_drawing_per_shape() -> void:
	var material: ShaderMaterial = load(DHULL_FACE_PATH)
	_check_eyes(material, DhullFace.Eyes.size(), DhullGenome.EyeColor.size())
	_check_mouths(material, DhullFace.Mouth.size())


## The dreamer has a face of their own, with eyes in one color.
func test_the_dreamer_has_a_drawing_per_eye_and_mouth() -> void:
	var material: ShaderMaterial = load(DREAMER_FACE_PATH)
	_check_eyes(material, DreamerModel.Eyes.size(), 1)
	_check_mouths(material, DreamerModel.Mouth.size())


func _check_eyes(material: ShaderMaterial, frames: int, colors: int) -> void:
	var path := material.resource_path
	assert_eq(material.get_shader_parameter("eye_frames"), frames, path + " frames")
	assert_eq(material.get_shader_parameter("eye_colors"), colors, path + " colors")
	var whites: Texture2D = material.get_shader_parameter("eye_whites")
	var lines: Texture2D = material.get_shader_parameter("eye_lines")
	var irises: Texture2D = material.get_shader_parameter("irises")
	var size: Vector2 = material.get_shader_parameter("eyes_size")
	var frame_width := roundi(whites.get_height() * size.x / size.y)
	assert_eq(whites.get_width(), frame_width * frames, path + " whites have a frame each")
	assert_eq(lines.get_size(), whites.get_size(), path + " lines match the whites")
	assert_eq(irises.get_size(), whites.get_size() * Vector2(1, colors), path + " iris rows")
	_check_irises_keep_clear(irises.get_image(), frames, path)
	if material.get_shader_parameter("eyes_apart") != null:
		for layer: Texture2D in [whites, lines]:
			_check_clear_of_middle(layer.get_image(), frames, layer.resource_path)


func _check_mouths(material: ShaderMaterial, frames: int) -> void:
	var path := material.resource_path
	assert_eq(material.get_shader_parameter("mouth_frames"), frames, path + " mouth frames")
	var mouths: Texture2D = material.get_shader_parameter("mouths")
	var size: Vector2 = material.get_shader_parameter("mouth_size")
	var frame_width := roundi(mouths.get_height() * size.x / size.y)
	assert_eq(mouths.get_width(), frame_width * frames, path + " mouths have a frame each")


## The shader shows each half of an eye frame on its own side of the face, moved out by
## eyes_apart, so anything drawn across the middle of the frame is cut in two.
func _check_clear_of_middle(layer: Image, frames: int, path: String) -> void:
	layer.decompress()
	var frame_width := layer.get_width() / frames
	var half := frame_width / 2
	for frame in frames:
		for column in [half - 1, half]:
			var x: int = frame * frame_width + column
			for y in layer.get_height():
				var clear := layer.get_pixel(x, y).a == 0.0
				assert_true(clear, "%s frame %d keeps clear of the middle" % [path, frame])
				if not clear:
					return


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
