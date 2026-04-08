class_name WooTestRunner
extends RefCounted

var total := 0
var passed := 0
var failed := 0
var current_suite := "General"
var failures: PackedStringArray = PackedStringArray()


func start_suite(name: String) -> void:
	current_suite = name
	print("\n== Suite: ", name, " ==")


func start_case(name: String) -> void:
	print("-- Case: ", name)


func expect_true(condition: bool, message: String) -> void:
	total += 1
	if condition:
		passed += 1
		return
	_fail("%s (expected true)" % message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	total += 1
	if actual == expected:
		passed += 1
		return
	_fail("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])


func expect_not_null(value: Variant, message: String) -> void:
	total += 1
	if value != null:
		passed += 1
		return
	_fail("%s (expected non-null)" % message)


func get_summary() -> Dictionary:
	return {
		"total": total,
		"passed": passed,
		"failed": failed,
		"failures": failures.duplicate(),
	}


func print_summary() -> void:
	print("\n== Test Summary ==")
	print("Total: ", total, " Passed: ", passed, " Failed: ", failed)
	if failures.is_empty():
		print("All tests passed.")
		return
	print("Failures:")
	for failure in failures:
		print(" - ", failure)


func _fail(message: String) -> void:
	failed += 1
	var full_message := "[%s] %s" % [current_suite, message]
	failures.append(full_message)
	push_error("Test failure: %s" % full_message)
