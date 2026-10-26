class_name ResourceDir
extends RefCounted
## Loads every resource in a folder. Data such as events and minigames is added by dropping a
## new .tres file into its folder instead of editing a list in code.


## Loads all resources directly inside [param dir], sorted by file name. Works in exported
## builds, where ResourceLoader.list_directory() still reports the original file names.
static func load_all(dir: String) -> Array[Resource]:
	var files := ResourceLoader.list_directory(dir)
	files.sort()
	var resources: Array[Resource] = []
	for file in files:
		if file.ends_with("/"):
			continue
		var resource := load(dir.path_join(file))
		if resource:
			resources.append(resource)
		else:
			push_error("Couldn't load resource '%s'." % dir.path_join(file))
	return resources
