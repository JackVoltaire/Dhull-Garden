extends TestCase
## Every model should draw with the shared palette in assets/materials/, not the materials baked
## into its .glb, or it misses the toon shading, hatching and crayon look. A model that fails
## here usually needs tools/link_model_materials.py and another import.

const MODELS_DIR := "res://assets/models"
const PALETTE_DIR := "res://assets/materials/"


func test_models_use_the_palette() -> void:
	for model_path in _model_paths():
		var model: Node = load(model_path).instantiate()
		for mesh_instance: MeshInstance3D in model.find_children(
			"*", "MeshInstance3D", true, false
		):
			for surface in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.mesh.surface_get_material(surface)
				var where := "%s, %s, surface %d" % [model_path, mesh_instance.name, surface]
				assert_true(material != null, where + " has a material")
				if material:
					assert_true(material.resource_path.begins_with(PALETTE_DIR), where)
		model.free()


func _model_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	for folder in DirAccess.get_directories_at(MODELS_DIR):
		var path := "%s/%s/%s.glb" % [MODELS_DIR, folder, folder]
		if ResourceLoader.exists(path):
			paths.append(path)
	return paths
