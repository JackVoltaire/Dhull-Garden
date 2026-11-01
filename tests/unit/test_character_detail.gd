extends TestCase
## The detail painted over characters' parts (see CharacterDetail): cel_character.gdshader picks
## a kind's tile from character_detail.png by its number, so the sheet must hold a square tile
## for each kind past NONE, as many as the shader is told there are, or parts show the wrong
## detail.

const SHADER_PATH := "res://assets/shaders/cel_character.gdshader"
const TILES_PATH := "res://assets/textures/character_detail.png"


func test_there_is_a_tile_for_every_kind_of_detail() -> void:
	var tiles: Texture2D = load(TILES_PATH)
	var kinds := CharacterDetail.Kind.size() - 1
	assert_eq(tiles.get_height(), tiles.get_width() * kinds, "a square tile per kind")
	var code := (load(SHADER_PATH) as Shader).code
	assert_true(code.contains("uniform int detail_kinds = %d;" % kinds), "the shader counts them")
