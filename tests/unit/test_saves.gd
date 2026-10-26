extends TestCase

const TEST_DIR := "user://test_saves"
const PARTICIPANT_ID := &"test_state"

var _state := FakeState.new()
var _original_dir := ""
var _original_slot := -1


class FakeState:
	var data: Dictionary = {}

	func get_save_data() -> Dictionary:
		return data

	func apply_save_data(new_data: Dictionary) -> void:
		data = new_data


func before_each() -> void:
	_original_dir = Saves.save_dir
	_original_slot = Saves.current_slot
	Saves.save_dir = TEST_DIR
	_delete_test_files()
	Saves.register(PARTICIPANT_ID, _state)


func after_each() -> void:
	Saves.unregister(PARTICIPANT_ID)
	_delete_test_files()
	Saves.save_dir = _original_dir
	Saves.current_slot = _original_slot
	Clock.offset_seconds = 0


func test_round_trip_keeps_types() -> void:
	Saves.new_game(0)
	_state.data = {"count": 3, "ratio": 0.5, "position": Vector3(1, 2, 3), "tags": [&"a", "b"]}
	assert_eq(Saves.save_game(), OK)
	_state.data = {}
	assert_eq(Saves.load_game(0), OK)
	assert_eq(_state.data.count, 3)
	assert_eq(_state.data.ratio, 0.5)
	assert_eq(_state.data.position, Vector3(1, 2, 3))
	assert_eq(_state.data.tags[0], &"a")
	assert_eq(_state.data.tags[1], "b")


func test_new_game_gives_participants_empty_data() -> void:
	_state.data = {"stale": true}
	Saves.new_game(0)
	assert_eq(_state.data, {})


func test_late_participant_gets_loaded_data() -> void:
	Saves.new_game(0)
	_state.data = {"value": 1}
	Saves.save_game()
	Saves.unregister(PARTICIPANT_ID)
	assert_eq(Saves.load_game(0), OK)
	var late := FakeState.new()
	Saves.register(PARTICIPANT_ID, late)
	assert_eq(late.data, {"value": 1})


func test_falls_back_to_backup_when_file_is_corrupt() -> void:
	Saves.new_game(0)
	_state.data = {"value": 1}
	Saves.save_game()
	_state.data = {"value": 2}
	Saves.save_game()
	_overwrite(Saves.slot_path(0), "not json")
	assert_eq(Saves.load_game(0), OK)
	assert_eq(_state.data, {"value": 1})


func test_rejects_saves_from_newer_versions() -> void:
	Saves.new_game(0)
	Saves.save_game()
	var file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Saves.slot_path(0)))
	file.version = Saves.VERSION + 1
	_overwrite(Saves.slot_path(0), JSON.stringify(file))
	assert_eq(Saves.load_game(0), ERR_FILE_UNRECOGNIZED)


func test_reports_time_away() -> void:
	Saves.new_game(0)
	Saves.save_game()
	Clock.offset_seconds = 3600
	var reported := []
	var on_loaded := func(_slot: int, seconds_away: int) -> void: reported.append(seconds_away)
	Saves.game_loaded.connect(on_loaded)
	Saves.load_game(0)
	Saves.game_loaded.disconnect(on_loaded)
	assert_eq(reported.size(), 1)
	assert_true(reported[0] >= 3600 and reported[0] <= 3601)


func test_slot_info_and_delete() -> void:
	assert_false(Saves.has_save(0))
	assert_eq(Saves.load_game(0), ERR_FILE_NOT_FOUND)
	Saves.new_game(0)
	Saves.save_game()
	assert_true(Saves.has_save(0))
	assert_eq(
		Saves.get_slot_info(0).game_version,
		ProjectSettings.get_setting("application/config/version")
	)
	Saves.delete_save(0)
	assert_false(Saves.has_save(0))
	assert_eq(Saves.get_slot_info(0), {})
	assert_eq(Saves.current_slot, -1)


func test_set_aside_keeps_files_but_frees_the_slot() -> void:
	Saves.new_game(0)
	Saves.save_game()
	Saves.set_aside(0)
	assert_false(Saves.has_save(0))
	assert_eq(DirAccess.get_files_at(TEST_DIR).size(), 1)


func _overwrite(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _delete_test_files() -> void:
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		return
	for file in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR.path_join(file))
