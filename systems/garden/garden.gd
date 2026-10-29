extends Node
## Every Dhull's life, registered as the [code]Garden[/code] autoload. Dhulls live here rather
## than in level scenes, which are freed whenever the player changes area or plays a minigame;
## a level's DhullSpawner shows the ones living there. Their needs move on with the real-world
## clock every minute, and after loading, the garden catches up on the time the player was away
## by the same rules (see DhullLife).

## The Dhulls' needs moved on, or were changed by hand.
signal lives_changed
## A new game or a load replaced every Dhull, so their old records are gone.
signal dhulls_replaced

const SAVE_ID := &"garden"
const COLORINGS_DIR := "res://data/dhulls/colorings"
## Needs move on in steps of this many seconds.
const STEP_SECONDS := 60
## The longest time away caught up on. Needs settle within a few days, so going on for months
## would only make loading slow.
const MAX_CATCH_UP_SECONDS := 14 * DateUtil.SECONDS_PER_DAY

var tuning: DhullLifeTuning = preload("res://data/dhulls/life.tres")
var new_garden: NewGarden = preload("res://data/garden/new_garden.tres")
var dhulls: Array[DhullRecord] = []

var _colorings: Dictionary[StringName, DhullColoring] = {}
## Unix time up to which the Dhulls' lives have been worked out.
var _simulated_until := 0
## Numbers the next Dhull's id, so ids are never reused.
var _next_number := 1
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for coloring: DhullColoring in ResourceDir.load_all(COLORINGS_DIR):
		_colorings[coloring.id] = coloring
	# A level run on its own, without a game started, still has Dhulls to show.
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
	# Who looks after whom only changes as Dhulls grow up or move, never within a catch-up.
	var carers: Dictionary[DhullRecord, DhullRecord] = {}
	for record in dhulls:
		carers[record] = DhullLife.carer_for(record, dhulls)
	var step_hours := STEP_SECONDS / 3600.0
	for _step in steps:
		for record in dhulls:
			DhullLife.advance(record, step_hours, carers[record], tuning)
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
	return {
		"dhulls": saved_dhulls,
		"next_number": _next_number,
		"simulated_until": _simulated_until,
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
		_simulated_until = int(data.get("simulated_until", Clock.now_unix()))
		catch_up()
	dhulls_replaced.emit()


func _start_new_garden() -> void:
	dhulls.clear()
	_next_number = 1
	for _adult in new_garden.adults:
		dhulls.append(_new_dhull(DhullRecord.LifeStage.ADULT))
	for _young in new_garden.young:
		dhulls.append(_new_dhull(DhullRecord.LifeStage.YOUNG))
	_simulated_until = Clock.now_unix()


func _new_dhull(life_stage: DhullRecord.LifeStage) -> DhullRecord:
	var record := DhullRecord.new()
	record.id = StringName("dhull_%d" % _next_number)
	_next_number += 1
	record.genome = DhullGenome.random(_rng)
	record.coloring = new_garden.coloring
	record.life_stage = life_stage
	record.home_area = new_garden.home_area
	return record
