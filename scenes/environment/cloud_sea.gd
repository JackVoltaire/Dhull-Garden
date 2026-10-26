class_name CloudSea
extends MultiMeshInstance3D
## A sea of puffy clouds scattered in a ring, built when the game starts. Change
## [member random_seed] for a different arrangement.

@export var cloud_material: Material
@export_range(1, 2000) var count := 220
@export_range(1.0, 500.0, 1.0, "suffix:m") var outer_radius := 140.0
## Keeps the middle clear so the island's underside stays visible.
@export_range(0.0, 500.0, 1.0, "suffix:m") var inner_radius := 0.0
@export_range(0.0, 50.0, 0.5, "suffix:m") var height_variation := 3.0
@export var size_range := Vector2(4.0, 11.0)
@export var random_seed := 7


func _ready() -> void:
	var puff := SphereMesh.new()
	puff.radial_segments = 16
	puff.rings = 8
	puff.material = cloud_material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = puff
	multimesh.instance_count = count

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	for i in count:
		# sqrt spreads puffs evenly over the ring's area instead of bunching them at the center.
		var distance := sqrt(rng.randf_range(inner_radius ** 2, outer_radius ** 2))
		var direction := Vector2.from_angle(rng.randf() * TAU)
		var size := rng.randf_range(size_range.x, size_range.y)
		var puff_basis := Basis.from_scale(
			Vector3(size, size * 0.45, size * rng.randf_range(0.7, 1.0))
		)
		puff_basis = Basis(Vector3.UP, rng.randf() * TAU) * puff_basis
		var origin := Vector3(
			direction.x * distance,
			rng.randf_range(-height_variation, height_variation),
			direction.y * distance
		)
		multimesh.set_instance_transform(i, Transform3D(puff_basis, origin))
