extends Node
## Every Dhull's life, registered as the [code]Garden[/code] autoload. Dhulls live here rather
## than in level scenes, which are freed whenever the player changes area or plays a minigame;
## a level's DhullSpawner shows the ones living there. Their needs move on with the real-world
## clock every minute, and after loading, the garden catches up on the time the player was away
## by the same rules (see DhullLife). Young Dhulls with no adult around make a mess of the
## garden as time goes by, which stays until the player cleans it up (see MessRecord).

## The Dhulls' needs moved on, or were changed by hand.
signal lives_changed
## A new game or a load replaced the whole garden, so the old records are gone.
signal garden_replaced
## A Dhull joined the garden, such as an egg Lulla handed over.
signal dhull_added(record: DhullRecord)
## Mess turned up in [param area], or was cleaned up there.
signal mess_changed(area: StringName)

const SAVE_ID := &"garden"
const COLORINGS_DIR := "res://data/dhulls/colorings"
## Needs move on in steps of this many seconds.
const STEP_SECONDS := 60
## The longest time away caught up on. Needs settle within a few days, so going on for months
## would only make loading slow.
const MAX_CATCH_UP_SECONDS := 14 * DateUtil.SECONDS_PER_DAY

var tuning: DhullLifeTuning = preload("res://data/dhulls/life.tres")
var new_garden: NewGarden = preload("res://data/garden/new_garden.tres")
var mess_tuning: MessTuning = preload("res://data/garden/mess.tres")
var dhulls: Array[DhullRecord] = []
var mess: Array[MessRecord] = []
## Whether Lulla has handed the dreamer their first egg yet.
var first_egg_given := false
## The local day the garden was started on, as a DateUtil day number.
var started_on_day := 0

var _colorings: Dictionary[StringName, DhullColoring] = {}
## Unix time up to which the Dhulls' lives have been worked out.
var _simulated_until := 0
## Numbers the next Dhull's id, so ids are never reused.
var _next_number := 1
var _next_mess_number := 1
## Per area, the hours its young have spent with no adult around since their last mess.
var _untended_hours: Dictionary[StringName, float] = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for coloring: DhullColoring in ResourceDir.load_all(COLORINGS_DIR):
		_colorings[coloring.id] = coloring
	_start_new_garden()
	Saves.register(SAVE_ID, self)
	Clock.minute_changed.connect(catch_up)
	Clock.time_shifted.connect(catch_up)


func dhulls_in(area: StringName) -> Array[DhullRecord]:
	var living_there: Array[DhullRecord] = []
	for record in dhulls:
		if record.home_area == area:
			living_there.append(record)
	return living_there


func mess_in(area: StringName) -> Array[MessRecord]:
	var lying_there: Array[MessRecord] = []
	for bit in mess:
		if bit.area == area:
			lying_there.append(bit)
	return lying_there


## Adds a Dhull at [param life_stage] to [param area], with random genes, as old as a Dhull that
## just reached that stage. If [param at] is given it's placed there; otherwise the area's
## spawner places it.
func add_dhull(
	life_stage: DhullRecord.LifeStage, area: StringName, at: Variant = null
) -> DhullRecord:
	var record := DhullRecord.new()
	record.id = StringName("dhull_%d" % _next_number)
	_next_number += 1
	record.genome = DhullGenome.random(_rng)
	record.coloring = new_garden.coloring
	record.life_stage = life_stage
	record.age_hours = _age_at(life_stage)
	record.home_area = area
	if at is Vector3:
		record.position = at
		record.placed = true
	dhulls.append(record)
	dhull_added.emit(record)
	return record


## Lulla hands over the dreamer's first egg, at [param at] in the first area.
func give_first_egg(at: Vector3) -> DhullRecord:
	first_egg_given = true
	return add_dhull(DhullRecord.LifeStage.EGG, new_garden.home_area, at)


## Leaves a bit of mess near a young Dhull, unless its area is already as messy as it gets.
func make_mess_near(young: DhullRecord) -> void:
	if mess_in(young.home_area).size() >= mess_tuning.most_per_area:
		return
	var bit := MessRecord.new()
	bit.id = StringName("mess_%d" % _next_mess_number)
	_next_mess_number += 1
	bit.kind = _rng.randi_range(0, MessRecord.Kind.size() - 1) as MessRecord.Kind
	bit.area = young.home_area
	var offset := Vector3(mess_tuning.spread * sqrt(_rng.randf()), 0.0, 0.0)
	bit.position = young.position + offset.rotated(Vector3.UP, _rng.randf() * TAU)
	mess.append(bit)
	mess_changed.emit(bit.area)


func clean_up(bit: MessRecord) -> void:
	mess.erase(bit)
	mess_changed.emit(bit.area)


## Which day of the garden it is in local time, counting the day it was started as 1.
func day_of_garden() -> int:
	return _today() - started_on_day + 1


## Moves every Dhull's life on to the clock's current time.
func catch_up() -> void:
	advance_to(Clock.now_unix())


## Moves every Dhull's life on to [param unix_time]. A time in the past moves nothing: when the
## clock is turned back, the Dhulls carry on from where they are.
func advance_to(unix_time: int) -> void:
	if unix_time < _simulated_until:
		_simulated_until = unix_time
		return
	_simulated_until = maxi(_simulated_until, unix_time - MAX_CATCH_UP_SECONDS)
	var steps := (unix_time - _simulated_until) / STEP_SECONDS
	if steps == 0:
		return
	var carers := _carers()
	var step_hours := STEP_SECONDS / 3600.0
	for _step in steps:
		var anyone_grew := false
		for record in dhulls:
			var life_stage := record.life_stage
			DhullLife.advance(record, step_hours, carers[record], tuning)
			anyone_grew = anyone_grew or record.life_stage != life_stage
			if record.is_young() and carers[record] == null:
				_leave_untended(record, step_hours)
		# Who looks after whom only changes when someone hatches or grows up.
		if anyone_grew:
			carers = _carers()
	_simulated_until += steps * STEP_SECONDS
	lives_changed.emit()


## Lets the Dhulls in levels show their records again after something changed them by hand,
## such as the debug menu.
func notify_changed() -> void:
	lives_changed.emit()


func get_save_data() -> Dictionary:
	var saved_dhulls: Array = []
	for record in dhulls:
		saved_dhulls.append(record.to_dict())
	var saved_mess: Array = []
	for bit in mess:
		saved_mess.append(bit.to_dict())
	var untended_hours := {}
	for area in _untended_hours:
		untended_hours[String(area)] = _untended_hours[area]
	return {
		"dhulls": saved_dhulls,
		"next_number": _next_number,
		"simulated_until": _simulated_until,
		"mess": saved_mess,
		"next_mess_number": _next_mess_number,
		"untended_hours": untended_hours,
		"first_egg_given": first_egg_given,
		"started_on_day": started_on_day,
	}


func apply_save_data(data: Dictionary) -> void:
	if data.is_empty():
		_start_new_garden()
	else:
		dhulls.clear()
		for dhull_data: Variant in data.get("dhulls", []):
			if dhull_data is Dictionary:
				dhulls.append(
					DhullRecord.from_dict(dhull_data, _colorings, new_garden.coloring, _rng)
				)
		_next_number = int(data.get("next_number", dhulls.size() + 1))
		# Gardens saved before Lulla handed out eggs already have their Dhulls.
		first_egg_given = data.get("first_egg_given", not dhulls.is_empty()) == true
		# Gardens saved before the day was counted are at least a day old.
		started_on_day = int(data.get("started_on_day", _today() - 1))
		_load_mess(data)
		_simulated_until = int(data.get("simulated_until", Clock.now_unix()))
		catch_up()
	garden_replaced.emit()


## A new garden starts with nobody in it, until Lulla hands over the first egg.
func _start_new_garden() -> void:
	dhulls.clear()
	_next_number = 1
	first_egg_given = false
	started_on_day = _today()
	mess.clear()
	_next_mess_number = 1
	_untended_hours.clear()
	_simulated_until = Clock.now_unix()


## Who looks after each Dhull: the most nurturing adult at home for the young, nobody for others.
func _carers() -> Dictionary[DhullRecord, DhullRecord]:
	var carers: Dictionary[DhullRecord, DhullRecord] = {}
	for record in dhulls:
		carers[record] = DhullLife.carer_for(record, dhulls)
	return carers


## How old a Dhull is when it has just reached [param life_stage].
func _age_at(life_stage: DhullRecord.LifeStage) -> float:
	match life_stage:
		DhullRecord.LifeStage.YOUNG:
			return tuning.hatch_after_hours
		DhullRecord.LifeStage.ADULT:
			return tuning.hatch_after_hours + tuning.kid_phase_hours
	return 0.0


func _load_mess(data: Dictionary) -> void:
	mess.clear()
	for bit_data: Variant in data.get("mess", []):
		if bit_data is Dictionary:
			mess.append(MessRecord.from_dict(bit_data))
	_next_mess_number = int(data.get("next_mess_number", mess.size() + 1))
	_untended_hours.clear()
	var untended_hours: Variant = data.get("untended_hours", {})
	if untended_hours is Dictionary:
		for area: Variant in untended_hours:
			_untended_hours[StringName(area)] = float(untended_hours[area])


## A young Dhull spends [param hours] with no adult around, and leaves a mess every so often.
func _leave_untended(young: DhullRecord, hours: float) -> void:
	var untended: float = _untended_hours.get(young.home_area, 0.0) + hours
	if untended >= mess_tuning.hours_per_mess:
		untended -= mess_tuning.hours_per_mess
		make_mess_near(young)
	_untended_hours[young.home_area] = untended


func _today() -> int:
	var now := Clock.now_local()
	return DateUtil.day_number(now.year, now.month, now.day)
