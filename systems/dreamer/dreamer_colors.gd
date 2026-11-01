class_name DreamerColors
extends Resource
## The dreamer's colors: their skin and clothes, which everyone shares for now, and the color of
## each hair color they can pick. The game's are data/dreamer/colors.tres.

@export var skin := Color(1, 0.88, 0.8)
## What the skin turns to where it's shaded: to the sides of the face, the jaw, under the fringe
## and the chin.
@export var skin_shade := Color(0.78, 0.62, 0.64)
## Pastel goth: a pale lilac hoodie with near-black stripes round the sleeves, slate trousers and
## chunky off-white shoes, light enough to stand out from the dark ground.
@export var hoodie := Color(0.62, 0.56, 0.74)
## The stripes painted round the hoodie's sleeves.
@export var sleeve_stripes := Color(0.17, 0.15, 0.21)
@export var trousers := Color(0.25, 0.25, 0.34)
@export var shoes := Color(0.88, 0.85, 0.8)
@export var hair: Dictionary[DreamerLook.HairColor, Color] = {}
## How much darker the hair is in the creases between its locks, from 0 to 1, so each lock reads
## on its own.
@export_range(0.0, 1.0, 0.05) var hair_crease_darkening := 0.3


## The color the hair of [param hair_color] turns to in the creases between its locks.
func hair_crease(hair_color: DreamerLook.HairColor) -> Color:
	return hair[hair_color].darkened(hair_crease_darkening)
