extends Node
## Runs every test in res://tests/unit/. From the project folder:
##     godot --headless --path . res://tests/test_runner.tscn
## or open test_runner.tscn in the editor and press F6. Exits with code 1 if any test fails.
## Autoloads run as usual, so tests can use Clock, Saves and the other systems.

const TEST_DIR := "res://tests/unit/"

var _errors := ErrorCollector.new()


func _ready() -> void:
	OS.add_logger(_errors)
	var passed := 0
	var failed := 0
	for file in _test_files():
		var script: GDScript = load(TEST_DIR.path_join(file))
		for method in script.get_script_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_"):
				continue
			var problems := _run_test(script, test_name)
			if problems.is_empty():
				passed += 1
				continue
			failed += 1
			for problem in problems:
				printerr("FAIL %s %s: %s" % [file, test_name, problem])
	OS.remove_logger(_errors)
	print("%d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


func _test_files() -> PackedStringArray:
	var files := PackedStringArray()
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(file)
	files.sort()
	return files


func _run_test(script: GDScript, test_name: String) -> PackedStringArray:
	_errors.take()
	var test: TestCase = script.new()
	test.before_each()
	test.call(test_name)
	test.after_each()
	var problems := test.failures
	problems.append_array(_errors.take())
	if problems.is_empty() and test.assertion_count == 0:
		problems.append("made no assertions")
	return problems


## Records errors logged while a test runs, so a script error fails the test instead of only
## printing. Loggers can be called from any thread, hence the mutex.
class ErrorCollector:
	extends Logger

	var _mutex := Mutex.new()
	var _errors := PackedStringArray()

	func _log_error(
		_function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array[ScriptBacktrace]
	) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_errors.append("%s (%s:%d)" % [rationale if rationale else code, file, line])
		_mutex.unlock()

	## Returns the errors logged since the last call and forgets them.
	func take() -> PackedStringArray:
		_mutex.lock()
		var errors := _errors
		_errors = PackedStringArray()
		_mutex.unlock()
		return errors
