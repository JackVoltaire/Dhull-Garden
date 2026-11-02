extends TestCase
## Heads drawn turned towards the camera (see head_turn.gdshaderinc). Every shader that draws a
## part of a head must turn it the same way, and every part on a head must be told how, or the
## face, the hair and the head slide apart.

const HEAD_SHADERS: Array[String] = [
	"res://assets/shaders/cel_character.gdshader", "res://assets/shaders/dhull_face.gdshader"
]
const HEAD_TURN_INCLUDE := "res://assets/shaders/head_turn.gdshaderinc"
## The scenes whose characters turn their heads, and the node in each that's told how.
const CHARACTERS := {
	"res://scenes/dhulls/dhull.tscn": ^".",
	"res://scenes/player/player.tscn": ^"./Model/Dreamer",
	"res://scenes/characters/lulla/lulla.tscn": ^"./Model/Lulla",
}


func test_every_part_on_a_head_turns_with_it() -> void:
	var head := MeshInstance3D.new()
	var hair := MeshInstance3D.new()
	var face := MeshInstance3D.new()
	head.add_child(hair)
	hair.add_child(face)
	var turn := HeadTurn.new()
	turn.most_sideways = 20.0
	turn.most_upward = 10.0
	turn.depth = 0.6
	turn.roundness = 0.4
	turn.apply(head)
	var expected_turn := Vector2(deg_to_rad(20.0), deg_to_rad(10.0))
	for part: MeshInstance3D in [head, hair, face]:
		assert_eq(part.get_instance_shader_parameter(&"head_turn"), expected_turn, part.name)
		assert_eq(part.get_instance_shader_parameter(&"head_depth"), 0.6, part.name)
		assert_eq(part.get_instance_shader_parameter(&"head_roundness"), 0.4, part.name)
	head.free()


func test_every_shader_that_draws_a_head_turns_it() -> void:
	for path in HEAD_SHADERS:
		var code := (load(path) as Shader).code
		assert_true(code.contains('#include "%s"' % HEAD_TURN_INCLUDE), path + " includes it")
		assert_true(code.contains("turn_head(VERTEX, NORMAL"), path + " turns its vertices")


## A head carries the character shader, the face shader and the head turn's instance uniforms
## at once, and instance uniforms on one node share their slots, so no two may use the same one.
func test_head_instance_uniforms_keep_to_their_own_slots() -> void:
	var codes: Array[String] = [(load(HEAD_TURN_INCLUDE) as ShaderInclude).code]
	for path in HEAD_SHADERS:
		codes.append((load(path) as Shader).code)
	var uniform := RegEx.create_from_string(
		"instance uniform \\w+ (\\w+)[^;]*instance_index\\((\\d+)\\)"
	)
	var owners := {}
	for code in codes:
		for found in uniform.search_all(code):
			var slot := found.get_string(2).to_int()
			var name := found.get_string(1)
			assert_true(
				owners.get(slot, name) == name,
				"%s and %s share slot %d" % [owners.get(slot, ""), name, slot]
			)
			owners[slot] = name


func test_every_character_is_told_how_to_turn_its_head() -> void:
	for path: String in CHARACTERS:
		var state := (load(path) as PackedScene).get_state()
		assert_true(_property(state, CHARACTERS[path], &"head_turn") is HeadTurn, path)


## The value [param property] is set to on the node at [param node_path] in a scene.
static func _property(state: SceneState, node_path: NodePath, property: StringName) -> Variant:
	for node in state.get_node_count():
		if state.get_node_path(node) != node_path:
			continue
		for index in state.get_node_property_count(node):
			if state.get_node_property_name(node, index) == property:
				return state.get_node_property_value(node, index)
	return null
