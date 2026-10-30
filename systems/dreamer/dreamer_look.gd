class_name DreamerLook
extends RefCounted
## How the dreamer looks: for now, only the length and color of their hair. The colors each
## HairColor stands for are in data/dreamer/colors.tres (see DreamerColors).

enum HairLength { SHORT, MEDIUM, LONG }
enum HairColor { BLACK, WHITE, SILVER, BROWN, BLOND, RED, PINK, VIOLET, TEAL, GREEN }

var hair_length := HairLength.MEDIUM
var hair_color := HairColor.BLACK


func copy() -> DreamerLook:
	var look := DreamerLook.new()
	look.hair_length = hair_length
	look.hair_color = hair_color
	return look


func equals(other: DreamerLook) -> bool:
	return hair_length == other.hair_length and hair_color == other.hair_color


## Saved by name, so reordering or adding choices keeps old saves right.
func to_dict() -> Dictionary:
	return {
		"hair_length": HairLength.keys()[hair_length],
		"hair_color": HairColor.keys()[hair_color],
	}


## A look from [method to_dict]'s data. Anything missing or no longer offered is the default.
static func from_dict(data: Dictionary) -> DreamerLook:
	var look := DreamerLook.new()
	look.hair_length = HairLength.get(data.get("hair_length", ""), look.hair_length)
	look.hair_color = HairColor.get(data.get("hair_color", ""), look.hair_color)
	return look
