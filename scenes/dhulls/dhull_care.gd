class_name DhullCare
extends RefCounted
## What happens when the player cares for a Dhull in person: petting it and feeding it. Nothing is
## said, since words only go through the feed. Plain functions on DhullRecords, like DhullLife.

enum Response { WELCOMED, REFUSED }


## Pets the Dhull. Most love it, but not when it's asleep, grumpy, sad around someone it doesn't
## trust yet, or tired of being fussed over.
static func pet(record: DhullRecord, tuning: DhullLifeTuning) -> Response:
	var welcomed := _welcomes_petting(record, tuning)
	record.fussed_over += 1.0
	if welcomed:
		record.happiness = minf(record.happiness + tuning.pet_cheers, 1.0)
		record.bond = minf(record.bond + tuning.pet_bond, 1.0)
		return Response.WELCOMED
	record.happiness = maxf(record.happiness - tuning.annoyed_sadness, 0.0)
	return Response.REFUSED


## Feeds the Dhull [param item]. It turns down food when it's full, and the young turn down
## drinks like coffee that are only for adults.
static func feed(record: DhullRecord, item: ItemDefinition, tuning: DhullLifeTuning) -> Response:
	if item.is_for_adults_only() and record.is_young():
		return Response.REFUSED
	if not item.is_for_adults_only() and record.hunger <= tuning.full_below:
		return Response.REFUSED
	record.hunger = maxf(record.hunger - item.fills, 0.0)
	record.happiness = clampf(record.happiness + item.cheers, 0.0, 1.0)
	if item.wakes > 0.0:
		record.tiredness = maxf(record.tiredness - item.wakes, 0.0)
		record.napping = false
	return Response.WELCOMED


static func _welcomes_petting(record: DhullRecord, tuning: DhullLifeTuning) -> bool:
	if record.napping or record.fussed_over >= tuning.fussing_limit:
		return false
	match DhullLife.mood_for(record, tuning):
		DhullState.Mood.GRUMPY:
			return false
		DhullState.Mood.SAD:
			return record.bond >= tuning.trusted_from_bond
	return true
