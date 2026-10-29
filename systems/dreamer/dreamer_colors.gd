class_name DreamerColors
extends Resource
## The dreamer's colors: their skin and clothes, which everyone shares for now, and the color of
## each hair color they can pick. The game's are data/dreamer/colors.tres.

@export var skin := Color(1, 0.88, 0.8)
## What the skin turns to where it's shaded: to the sides of the face, the jaw, under the fringe
## and the chin.
@export var skin_shade := Color(0.78, 0.62, 0.64)
@export var hoodie := Color(0.17, 0.15, 0.21)
## The stripes painted round the hoodie's sleeves.
@export var sleeve_stripes := Color(0.36, 0.33, 0.42)
@export var trousers := Color(0.11, 0.1, 0.14)
@export var shoes := Color(0.07, 0.06, 0.08)
@export var hair: Dictionary[DreamerLook.HairColor, Color] = {}
