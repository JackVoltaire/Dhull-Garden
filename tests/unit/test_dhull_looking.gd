extends TestCase
## What catches a Dhull's eye, and how far its irises turn to look at it.

const REACH := 5.0
const FIELD := PI / 2.0
const TURN_LIMIT := PI / 4.0

## Eyes at the origin, looking along +Z.
var _eyes := Transform3D.IDENTITY


func test_nearer_things_catch_the_eye_more() -> void:
	var near := DhullLooking.appeal(_eyes, Vector3(0, 0, 1), 0.5, REACH, FIELD)
	var far := DhullLooking.appeal(_eyes, Vector3(0, 0, 4), 0.5, REACH, FIELD)
	assert_true(near > far, "nearer is more appealing")
	assert_true(far > 0.0, "still in reach")


func test_things_out_of_reach_or_out_of_sight_dont_catch_the_eye() -> void:
	assert_eq(DhullLooking.appeal(_eyes, Vector3(0, 0, 6), 1.0, REACH, FIELD), 0.0)
	assert_eq(DhullLooking.appeal(_eyes, Vector3(0, 0, -1), 1.0, REACH, FIELD), 0.0)
	assert_eq(DhullLooking.appeal(_eyes, Vector3.ZERO, 1.0, REACH, FIELD), 0.0)


func test_it_looks_at_what_catches_its_eye_most() -> void:
	var appeals := PackedFloat32Array([0.2, 0.7, 0.0])
	assert_eq(DhullLooking.pick(appeals, -1, 0.1), 1)
	assert_eq(DhullLooking.pick(PackedFloat32Array([0.0, 0.0]), -1, 0.1), -1)
	assert_eq(DhullLooking.pick(PackedFloat32Array(), -1, 0.1), -1)


func test_it_keeps_looking_unless_something_beats_it_clearly() -> void:
	var appeals := PackedFloat32Array([0.5, 0.55])
	assert_eq(DhullLooking.pick(appeals, 0, 0.1), 0, "a little more isn't enough")
	assert_eq(DhullLooking.pick(PackedFloat32Array([0.5, 0.7]), 0, 0.1), 1)
	assert_eq(DhullLooking.pick(PackedFloat32Array([0.0, 0.3]), 0, 0.1), 1, "it went out of sight")


func test_irises_turn_toward_what_it_looks_at() -> void:
	assert_eq(DhullLooking.look_toward(_eyes, Vector3(0, 0, 2), TURN_LIMIT), Vector2.ZERO)
	var right := DhullLooking.look_toward(_eyes, Vector3(1, 0, 2), TURN_LIMIT)
	assert_true(right.x > 0.0 and is_zero_approx(right.y), "right is right")
	var up := DhullLooking.look_toward(_eyes, Vector3(0, 1, 2), TURN_LIMIT)
	assert_true(up.y > 0.0 and is_zero_approx(up.x), "up is up")


func test_irises_go_only_as_far_as_they_reach() -> void:
	var behind := DhullLooking.look_toward(_eyes, Vector3(1, -3, -1), TURN_LIMIT)
	assert_eq(behind, Vector2(1, -1))
	var at_limit := DhullLooking.look_toward(_eyes, Vector3(1, 0, 1), TURN_LIMIT)
	assert_true(is_equal_approx(at_limit.x, 1.0), "at the limit")


func test_turning_and_scaling_the_head_turns_the_eyes_with_it() -> void:
	var turned := Transform3D(
		Basis(Vector3.UP, PI / 2.0).scaled(Vector3.ONE * 0.7), Vector3(1, 0, 0)
	)
	# Turned a quarter left, the head faces +X: something further along +X is straight ahead.
	var ahead := DhullLooking.look_toward(turned, Vector3(3, 0, 0), TURN_LIMIT)
	assert_true(ahead.is_zero_approx(), "straight ahead")
	assert_true(DhullLooking.appeal(turned, Vector3(3, 0, 0), 1.0, REACH, FIELD) > 0.0)
