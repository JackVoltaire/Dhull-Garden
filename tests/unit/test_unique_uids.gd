extends TestCase
## Godot finds a resource by the uid in its .import or .uid file, so two files with the same uid
## get mixed up, one loading in place of the other. That happens when an .import file is copied
## for a new texture rather than letting Godot write one.

const SKIPPED_DIRS: Array[String] = [".godot", ".git"]


func test_every_uid_is_unique() -> void:
	var owners := {}
	for path in _uid_files("res://"):
		var uid := _uid_in(path)
		if uid.is_empty():
			continue
		assert_false(owners.has(uid), "%s has the uid of %s" % [path, owners.get(uid, "")])
		owners[uid] = path


static func _uid_in(path: String) -> String:
	if path.ends_with(".uid"):
		return FileAccess.get_file_as_string(path).strip_edges()
	var import_settings := ConfigFile.new()
	import_settings.load(path)
	return import_settings.get_value("remap", "uid", "")


static func _uid_files(folder: String) -> PackedStringArray:
	var paths: PackedStringArray = []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".import") or file.ends_with(".uid"):
			paths.append(folder.path_join(file))
	for subfolder in DirAccess.get_directories_at(folder):
		if subfolder not in SKIPPED_DIRS:
			paths.append_array(_uid_files(folder.path_join(subfolder)))
	return paths
