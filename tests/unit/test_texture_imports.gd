extends TestCase
## The drawings are line art and pixel art, which VRAM compression blurs and smears. Godot
## switches a texture to VRAM compression by itself the first time it sees it used in 3D, unless
## its import settings say not to, so every drawing must be imported lossless with that switch
## turned off (Import dock: Compress > Mode "Lossless", Detect 3D > Compress To "Disabled").

const DRAWING_DIRS: Array[String] = ["res://scenes", "res://assets"]
const LOSSLESS := 0
const DETECT_3D_DISABLED := 0


func test_drawings_stay_lossless() -> void:
	for import_path in _texture_import_paths():
		var import_settings := ConfigFile.new()
		assert_eq(import_settings.load(import_path), OK, import_path + " loads")
		assert_eq(
			import_settings.get_value("params", "compress/mode"),
			LOSSLESS,
			import_path + " is lossless"
		)
		assert_eq(
			import_settings.get_value("params", "detect_3d/compress_to"),
			DETECT_3D_DISABLED,
			import_path + " never switches to VRAM compression"
		)


func _texture_import_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	for folder in DRAWING_DIRS:
		_collect_texture_imports(folder, paths)
	return paths


func _collect_texture_imports(folder: String, paths: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".svg.import") or file.ends_with(".png.import"):
			paths.append(folder.path_join(file))
	for subfolder in DirAccess.get_directories_at(folder):
		_collect_texture_imports(folder.path_join(subfolder), paths)
