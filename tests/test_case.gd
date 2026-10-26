class_name TestCase
extends RefCounted
## Base class for tests in res://tests/unit/. Every method whose name starts with "test_" is a
## test. Each one runs on a fresh instance, between [method before_each] and [method after_each].
## A test fails if an assertion fails, if it logs an engine or script error, or if it makes no
## assertions at all (which usually means it crashed before reaching them).

var failures: PackedStringArray = []
var assertion_count := 0


func before_each() -> void:
	pass


func after_each() -> void:
	pass


## Passes if both values have the same type and are equal, so 1 and 1.0 count as different.
func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	assertion_count += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("expected %s, got %s" % [var_to_str(expected), var_to_str(actual)], message)


func assert_true(condition: bool, message := "") -> void:
	assertion_count += 1
	if not condition:
		_fail("expected true", message)


func assert_false(condition: bool, message := "") -> void:
	assertion_count += 1
	if condition:
		_fail("expected false", message)


func _fail(problem: String, message: String) -> void:
	failures.append(problem if message.is_empty() else "%s: %s" % [message, problem])
