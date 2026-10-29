class_name DigFind
extends Resource
## Something that can lie buried in a mining wall: which item it gives, the shape of cells it
## takes up in the wall, and how often it turns up. One .tres per find in data/mining/finds/.

@export var item: ItemDefinition
## The cells it covers, from its top-left corner.
@export var shape: Array[Vector2i] = [Vector2i.ZERO]
## How often it's buried compared with the other finds. Need not add up to anything.
@export_range(0.0, 10.0, 0.05) var commonness := 1.0
## The color it's drawn in once uncovered, until it has a drawing of its own.
@export var color := Color(0.7, 0.7, 0.75)


## How many cells across and down it takes up.
func extent() -> Vector2i:
	var corner := Vector2i.ZERO
	for cell in shape:
		corner = Vector2i(maxi(corner.x, cell.x), maxi(corner.y, cell.y))
	return corner + Vector2i.ONE
