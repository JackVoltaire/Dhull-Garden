extends TestCase
## Characters have no ink outlines, as House of Decay's have none. They mark themselves in the
## normal-roughness buffer, and the world's ink lines leave out whatever has that roughness.

const CHARACTER_SHADER := "res://assets/shaders/ps1_character.gdshader"
const INK_LINES_SHADER := "res://assets/shaders/ink_outlines.gdshader"
const CHARACTER_MATERIAL := "res://assets/materials/toon_character.tres"
## What the world's materials leave their roughness at.
const WORLD_ROUGHNESS := 1.0


func test_ink_lines_leave_out_the_roughness_characters_mark_themselves_with() -> void:
	var marked := _number_after((load(CHARACTER_SHADER) as Shader).code, "CHARACTER_ROUGHNESS = ")
	var left_out := _number_after(
		(load(INK_LINES_SHADER) as Shader).code, "uniform float character_roughness = "
	)
	assert_eq(left_out, marked)
	assert_true(absf(marked - WORLD_ROUGHNESS) > 0.2, "nothing in the world is left out")


func test_characters_draw_no_outline_of_their_own() -> void:
	var material: Material = load(CHARACTER_MATERIAL)
	assert_true(material.next_pass == null, "no outline pass")


## The number written in [param code] right after [param prefix].
static func _number_after(code: String, prefix: String) -> float:
	var start := code.find(prefix)
	if start < 0:
		return NAN
	var text := code.substr(start + prefix.length()).get_slice(";", 0)
	return text.strip_edges().to_float()
