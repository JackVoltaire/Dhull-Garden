class_name CutoutRing
extends MultiMeshInstance3D
## Copies of a drawn cutout scattered in a ring, built when the game starts: the sea of clouds
## under the island, clouds in the sky, floating eyes, sky doodles. Change [member random_seed]
## for a different arrangement.

## A QuadMesh with the cardboard cutout material, sized 1 m wide.
@export var cutout_mesh: Mesh
@export_range(1, 2000) var count := 220
@export_range(1.0, 500.0, 1.0, "suffix:m") var outer_radius := 140.0
## Keeps the middle clear, e.g. so the island's underside stays visible.
@export_range(0.0, 500.0, 1.0, "suffix:m") var inner_radius := 0.0
@export_range(0.0, 50.0, 0.5, "suffix:m") var height_variation := 3.0
## Cutout widths, in meters.
@export var size_range := Vector2(4.0, 11.0)
@export var random_seed := 7


func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = cutout_mesh
	multimesh.instance_count = count

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	for i in count:
		# sqrt spreads cutouts evenly over the ring's area instead of bunching them at the center.
		var distance := sqrt(rng.randf_range(inner_radius ** 2, outer_radius ** 2))
		var direction := Vector2.from_angle(rng.randf() * TAU)
		var size := rng.randf_range(size_range.x, size_range.y)
		var origin := Vector3(
			direction.x * distance,
			rng.randf_range(-height_variation, height_variation),
			direction.y * distance
		)
		var cutout_basis := Basis.from_scale(Vector3(size, size * rng.randf_range(0.8, 1.1), size))
		multimesh.set_instance_transform(i, Transform3D(cutout_basis, origin))
