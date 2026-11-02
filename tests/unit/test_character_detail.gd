extends TestCase
## The detail and patterns painted over characters' parts: cel_character.gdshader picks a kind
## of detail (CharacterDetail) by its number, its tile from character_detail.png, so the sheet
## must hold a square tile for each kind past NONE, as many as the shader is told there are; and
## it numbers its patterns as DhullColoring.Pattern does. Otherwise parts show the wrong ones.

const SHADER_PATH := "res://assets/shaders/cel_character.gdshader"
const TILES_PATH := "res://assets/textures/character_detail.png"


func test_there_is_a_tile_for_every_kind_of_detail() -> void:
	var tiles: Texture2D = load(TILES_PATH)
	var kinds := CharacterDetail.Kind.size() - 1
	assert_eq(tiles.get_height(), tiles.get_width() * kinds, "a square tile per kind")
	var code := (load(SHADER_PATH) as Shader).code
	assert_true(code.contains("uniform int detail_kinds = %d;" % kinds), "the shader counts them")


func test_the_shader_numbers_patterns_as_the_colorings_do() -> void:
	var code := (load(SHADER_PATH) as Shader).code
	for pattern: String in DhullColoring.Pattern.keys():
		if pattern == "NONE":
			continue
		var number: int = DhullColoring.Pattern[pattern]
		var constant := "const int PATTERN_%s = %d;" % [pattern, number]
		assert_true(code.contains(constant), constant)
