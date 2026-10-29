class_name DhullLife
extends RefCounted
## How a Dhull grows up and its needs change as real time passes, and which mood shows them. Plain
## functions on DhullRecords with no engine calls, so the Garden runs the same rules live and
## for the time the player was away.


## Moves a Dhull's life on by [param hours]: it ages, hatches or grows up when it's time, and its
## needs change. Run it in small steps (the Garden uses a minute): a Dhull dozes off, wakes up or
## grows only between steps. [param carer] is the adult looking after it if it's young (see
## [method carer_for]), or null when there's none. Eggs only age.
static func advance(
	record: DhullRecord, hours: float, carer: DhullRecord, tuning: DhullLifeTuning
) -> void:
	record.age_hours += hours
	_grow(record, tuning)
	if record.is_egg():
		return
	var rates := tuning.young_rates if record.is_young() else tuning.adult_rates
	_advance_hunger(record, hours, carer, rates, tuning)
	_advance_tiredness(record, hours, rates, tuning)
	_advance_happiness(record, hours, carer, tuning)
	record.fussed_over = maxf(record.fussed_over - tuning.fussing_fades_per_hour * hours, 0.0)


## The adult that looks after a young Dhull: the most nurturing one living in the same area.
## Null for adults, and for the young when no adult lives with them.
static func carer_for(record: DhullRecord, garden: Array[DhullRecord]) -> DhullRecord:
	if not record.is_young():
		return null
	var carer: DhullRecord = null
	for other in garden:
		if not other.is_adult() or other.home_area != record.home_area:
			continue
		if carer == null or nurturing(other) > nurturing(carer):
			carer = other
	return carer


## How nurturing an adult is, from 0 (feeds the young the bare minimum) to 1 (keeps them happy
## too). Friendly Dhulls are the most nurturing.
static func nurturing(adult: DhullRecord) -> float:
	return adult.genome.level(DhullGenome.Gene.FRIENDLINESS)


## The mood a Dhull's needs show. Unhappiness shows over everything else: bold Dhulls turn
## grumpy, timid ones sad.
static func mood_for(record: DhullRecord, tuning: DhullLifeTuning) -> DhullState.Mood:
	if record.happiness <= tuning.unhappy_at:
		var boldness := record.genome.level(DhullGenome.Gene.BOLDNESS)
		if boldness >= tuning.grumpy_from_boldness:
			return DhullState.Mood.GRUMPY
		return DhullState.Mood.SAD
	if record.hunger >= tuning.hungry_at:
		return DhullState.Mood.HUNGRY
	if record.tiredness >= tuning.sleepy_at:
		return DhullState.Mood.SLEEPY
	if record.happiness >= tuning.happy_at:
		if record.tiredness <= tuning.playful_below_tiredness:
			return DhullState.Mood.PLAYFUL
		return DhullState.Mood.HAPPY
	return DhullState.Mood.CONTENT


static func _grow(record: DhullRecord, tuning: DhullLifeTuning) -> void:
	if record.is_egg() and record.age_hours >= tuning.hatch_after_hours:
		record.life_stage = DhullRecord.LifeStage.YOUNG
	elif (
		record.is_young() and record.age_hours >= tuning.hatch_after_hours + tuning.kid_phase_hours
	):
		record.life_stage = DhullRecord.LifeStage.ADULT


static func _advance_hunger(
	record: DhullRecord,
	hours: float,
	carer: DhullRecord,
	rates: DhullNeedRates,
	tuning: DhullLifeTuning
) -> void:
	var hunger := minf(record.hunger + rates.hunger_per_hour * hours, 1.0)
	if record.is_adult():
		hunger = minf(hunger, tuning.forage_hunger)
	elif carer:
		var fed_to := lerpf(tuning.bare_minimum_hunger, tuning.nurtured_hunger, nurturing(carer))
		hunger = minf(hunger, fed_to)
	record.hunger = hunger


static func _advance_tiredness(
	record: DhullRecord, hours: float, rates: DhullNeedRates, tuning: DhullLifeTuning
) -> void:
	if record.napping:
		record.tiredness = maxf(record.tiredness - rates.resting_per_hour * hours, 0.0)
		record.napping = record.tiredness > tuning.wake_at
	else:
		record.tiredness = minf(record.tiredness + rates.tiring_per_hour * hours, 1.0)
		record.napping = record.tiredness >= tuning.nap_at


static func _advance_happiness(
	record: DhullRecord, hours: float, carer: DhullRecord, tuning: DhullLifeTuning
) -> void:
	var sadness := 0.0
	if record.hunger >= tuning.starving_at:
		sadness += tuning.starving_sadness_per_hour * hours
	if record.is_young() and carer == null:
		sadness += tuning.lonely_sadness_per_hour * hours
	var happiness := record.happiness - sadness
	if sadness == 0.0:
		happiness = move_toward(
			happiness, tuning.resting_happiness, tuning.settling_per_hour * hours
		)
	if record.is_young() and carer:
		happiness = maxf(happiness, tuning.nurtured_happiness * nurturing(carer))
	record.happiness = clampf(happiness, 0.0, 1.0)
