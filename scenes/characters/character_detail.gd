class_name CharacterDetail
extends RefCounted
## The detail painted over a character's part, as House of Decay paints its textures: strands
## through hair, folds in cloth. cel_character.gdshader paints it from
## assets/textures/character_detail.png, wrapped round the part, over the part's own color.

## Numbered as in cel_character.gdshader; past NONE, in the order of the tiles in
## character_detail.png, top to bottom.
enum Kind { NONE, HAIR_STRANDS, CLOTH_FOLDS }
