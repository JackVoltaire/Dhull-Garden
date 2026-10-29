class_name DhullRecord
extends RefCounted
## One Dhull's life as the garden keeps and saves it: who it is, how far it has grown, how its
## needs stand and where it was last. An egg is a Dhull too, at its first life stage. The Garden
## autoload holds every record; a Dhull in a level only shows its record.

enum LifeStage { EGG, YOUNG, ADULT }

## Stable and unique in a garden; saves refer to the Dhull by it.
var id: StringName
## What the player named it when it hatched. Empty until then.
var name := ""
var genome: DhullGenome
var coloring: DhullColoring
var life_stage := LifeStage.ADULT
## Real hours since it was laid; it hatches and grows up as these go by.
var age_hours := 0.0
## The area it lives in. Dhulls stay home unless the player carries them elsewhere.
var home_area: StringName
## From 0 (full) to 1 (starving).
var hunger := 0.0
## From 0 (rested) to 1 (exhausted).
var tiredness := 0.0
## From 0 (miserable) to 1 (overjoyed).
var happiness := 0.5
var napping := false
## How close it has grown to the player, from 0 (a stranger) to 1.
var bond := 0.0
## How much the player has fussed over it lately, in pets. It wears off over the hours.
var fussed_over := 0.0
## Where it was last seen in its home area, and which way it faced, as a turn about the up axis
## in radians. Unplaced Dhulls haven't been put anywhere yet.
var position := Vector3.ZERO
var facing := 0.0
var placed := false


func is_egg() -> bool:
	return life_stage == LifeStage.EGG


func is_young() -> bool:
	return life_stage == LifeStage.YOUNG


func is_adult() -> bool:
	return life_stage == LifeStage.ADULT


## The record as saved. Enums are saved by name, so reordering them never breaks a save.
func to_dict() -> Dictionary:
	var data := {
		"id": String(id),
		"name": name,
		"genes": genome.to_dict(),
		"coloring": String(coloring.id),
		"life_stage": LifeStage.keys()[life_stage],
		"age_hours": age_hours,
		"home_area": String(home_area),
		"hunger": hunger,
		"tiredness": tiredness,
		"happiness": happiness,
		"napping": napping,
		"bond": bond,
		"fussed_over": fussed_over,
	}
	if placed:
		data["position"] = position
		data["facing"] = facing
	return data


## A record from [method to_dict]. [param colorings] maps coloring ids to colorings; an unknown
## coloring falls back to [param default_coloring], and missing needs to a fresh Dhull's.
static func from_dict(
	data: Dictionary,
	colorings: Dictionary[StringName, DhullColoring],
	default_coloring: DhullColoring,
	rng: RandomNumberGenerator
) -> DhullRecord:
	var record := DhullRecord.new()
	record.id = StringName(data.get("id", ""))
	record.name = str(data.get("name", ""))
	record.genome = DhullGenome.from_dict(data.get("genes", {}), rng)
	record.coloring = colorings.get(StringName(data.get("coloring", "")), default_coloring)
	record.life_stage = LifeStage.get(data.get("life_stage", ""), LifeStage.ADULT)
	record.age_hours = maxf(float(data.get("age_hours", 0.0)), 0.0)
	record.home_area = StringName(data.get("home_area", ""))
	record.hunger = clampf(float(data.get("hunger", record.hunger)), 0.0, 1.0)
	record.tiredness = clampf(float(data.get("tiredness", record.tiredness)), 0.0, 1.0)
	record.happiness = clampf(float(data.get("happiness", record.happiness)), 0.0, 1.0)
	record.napping = data.get("napping", false) == true
	record.bond = clampf(float(data.get("bond", 0.0)), 0.0, 1.0)
	record.fussed_over = maxf(float(data.get("fussed_over", 0.0)), 0.0)
	var saved_position: Variant = data.get("position")
	if saved_position is Vector3:
		record.position = saved_position
		record.facing = float(data.get("facing", 0.0))
		record.placed = true
	return record
