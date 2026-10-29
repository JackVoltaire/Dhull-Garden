class_name DigSite
extends RefCounted
## A mining wall, like the fossil digging in Pokémon Diamond and Pearl: a grid of cells, each
## under a few layers of rock, with finds buried in it. The pick knocks two layers off a cell and
## one off its four neighbours; the hammer knocks two off a whole 3x3 patch but shakes the wall
## harder. Once the wall has taken all it can, it caves in, and only finds dug out completely by
## then are kept. Plain logic with no engine calls, so the minigame scene only draws it.

enum Tool { PICK, HAMMER }


## A find lying in the wall at [member origin], its top-left corner.
class Buried:
	extends RefCounted
	var find: DigFind
	var origin: Vector2i

	func _init(buried_find: DigFind, at: Vector2i) -> void:
		find = buried_find
		origin = at

	func cells() -> Array[Vector2i]:
		var covered: Array[Vector2i] = []
		for cell in find.shape:
			covered.append(origin + cell)
		return covered


const PICK_PATTERN: Dictionary[Vector2i, int] = {
	Vector2i(0, 0): 2,
	Vector2i(1, 0): 1,
	Vector2i(-1, 0): 1,
	Vector2i(0, 1): 1,
	Vector2i(0, -1): 1,
}
const HAMMER_PATTERN: Dictionary[Vector2i, int] = {
	Vector2i(-1, -1): 2,
	Vector2i(0, -1): 2,
	Vector2i(1, -1): 2,
	Vector2i(-1, 0): 2,
	Vector2i(0, 0): 2,
	Vector2i(1, 0): 2,
	Vector2i(-1, 1): 2,
	Vector2i(0, 1): 2,
	Vector2i(1, 1): 2,
}

var size := Vector2i.ZERO
var buried: Array[Buried] = []
## How many more strikes of the pick the wall can take.
var wall_left := 0.0

var _tuning: MiningTuning
## Rock layers left over each cell, row by row.
var _rock := PackedInt32Array()


func _init(tuning: MiningTuning) -> void:
	_tuning = tuning
	size = tuning.size
	wall_left = tuning.wall_strength
	_rock.resize(size.x * size.y)


## A fresh wall: rock of uneven thickness, with a few of [param finds] buried in it, the more
## common ones more often.
static func generate(
	tuning: MiningTuning, finds: Array[DigFind], rng: RandomNumberGenerator
) -> DigSite:
	var site := DigSite.new(tuning)
	site._pile_up_rock(rng)
	var weights := PackedFloat32Array()
	for find in finds:
		weights.append(find.commonness)
	var wanted := rng.randi_range(tuning.finds_range.x, tuning.finds_range.y)
	# Some tries miss for want of room; the wall is never so full that it needs many more.
	for _try in wanted * 20:
		if site.buried.size() >= wanted:
			break
		var find := finds[rng.rand_weighted(weights)]
		var room := tuning.size - find.extent()
		site.bury(find, Vector2i(rng.randi_range(0, room.x), rng.randi_range(0, room.y)))
	return site


## Buries [param find] at [param origin], unless it would stick out of the wall or overlap
## another find. Returns whether it was buried.
func bury(find: DigFind, origin: Vector2i) -> bool:
	var placed := Buried.new(find, origin)
	for cell in placed.cells():
		if not has_cell(cell) or find_at(cell) != null:
			return false
	buried.append(placed)
	return true


func has_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func rock_at(cell: Vector2i) -> int:
	return _rock[cell.y * size.x + cell.x]


func set_rock(cell: Vector2i, layers: int) -> void:
	_rock[cell.y * size.x + cell.x] = maxi(layers, 0)


## The find under [param cell], or null.
func find_at(cell: Vector2i) -> Buried:
	for placed in buried:
		if cell in placed.cells():
			return placed
	return null


## Strikes the wall at [param cell] with [param tool]. Does nothing once it has caved in.
func strike(cell: Vector2i, tool: Tool) -> void:
	if has_caved_in():
		return
	var pattern := HAMMER_PATTERN if tool == Tool.HAMMER else PICK_PATTERN
	for offset in pattern:
		var hit := cell + offset
		if has_cell(hit):
			set_rock(hit, rock_at(hit) - pattern[offset])
	wall_left = maxf(wall_left - (_tuning.hammer_shake if tool == Tool.HAMMER else 1.0), 0.0)


func has_caved_in() -> bool:
	return wall_left <= 0.0


func is_dug_out(placed: Buried) -> bool:
	for cell in placed.cells():
		if rock_at(cell) > 0:
			return false
	return true


## The finds dug out completely so far.
func dug_out() -> Array[Buried]:
	var out: Array[Buried] = []
	for placed in buried:
		if is_dug_out(placed):
			out.append(placed)
	return out


func is_done() -> bool:
	return has_caved_in() or dug_out().size() == buried.size()


## Covers the wall in its thinnest rock, then piles lumps of thicker rock here and there.
func _pile_up_rock(rng: RandomNumberGenerator) -> void:
	_rock.fill(_tuning.depth_range.x)
	for _lump in _tuning.lumps:
		var middle := Vector2i(rng.randi_range(0, size.x - 1), rng.randi_range(0, size.y - 1))
		var radius := rng.randf_range(1.0, 3.0)
		for y in size.y:
			for x in size.x:
				var cell := Vector2i(x, y)
				if Vector2(cell - middle).length() <= radius:
					set_rock(cell, mini(rock_at(cell) + 1, _tuning.depth_range.y))
