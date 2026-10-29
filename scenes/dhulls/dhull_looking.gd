class_name DhullLooking
extends RefCounted
## Where a Dhull looks, as plain rules: at whatever catches its eye most among the things it can
## see nearby, and how far its irises turn to look at a point.


## How much something [param interest]ing at [param at] catches the eye of a Dhull whose eyes are
## at [param eyes], facing their +Z: more the nearer it is, and not at all from beyond
## [param reach] or more than [param field] radians off to the side.
static func appeal(
	eyes: Transform3D, at: Vector3, interest: float, reach: float, field: float
) -> float:
	var to := at - eyes.origin
	var distance := to.length()
	if distance > reach or distance == 0.0:
		return 0.0
	if eyes.basis.z.angle_to(to) > field:
		return 0.0
	return interest * (1.0 - distance / reach)


## Which of [param appeals] the Dhull looks at: the one that catches its eye most, but it keeps
## looking at [param current] (an index, or -1 for nothing) unless another beats it by
## [param stickiness], so its eyes don't flit between two things. -1 when nothing catches its eye.
static func pick(appeals: PackedFloat32Array, current: int, stickiness: float) -> int:
	var best := -1
	for index in appeals.size():
		if appeals[index] > 0.0 and (best < 0 or appeals[index] > appeals[best]):
			best = index
	if current >= 0 and current < appeals.size() and appeals[current] > 0.0:
		if best < 0 or appeals[best] <= appeals[current] + stickiness:
			return current
	return best


## How far the irises of eyes at [param eyes], facing their +Z, turn to look at [param at]: from
## -1 to 1 right and up as the eyes see it, reaching 1 at [param turn_limit] radians.
static func look_toward(eyes: Transform3D, at: Vector3, turn_limit: float) -> Vector2:
	var local := eyes.basis.orthonormalized().inverse() * (at - eyes.origin)
	if local.is_zero_approx():
		return Vector2.ZERO
	var sideways := atan2(local.x, local.z)
	var upwards := atan2(local.y, Vector2(local.x, local.z).length())
	return (Vector2(sideways, upwards) / turn_limit).clamp(-Vector2.ONE, Vector2.ONE)
