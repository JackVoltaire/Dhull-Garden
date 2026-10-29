class_name Ground
extends RefCounted
## Where the ground is, for things that stand on it: level geometry on the "world" physics layer.

## The "world" physics layer.
const LAYERS := 1


## The ground under [param point], looking [param reach] above and below it, or [param point]
## itself where there's none. Ask it during a physics frame, when the physics world can answer.
static func below(node: Node3D, point: Vector3, reach := 1.0) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(
		point + Vector3.UP * reach, point + Vector3.DOWN * reach, LAYERS
	)
	var hit := node.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if hit else point
