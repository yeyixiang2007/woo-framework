class_name WooLogicTestRegistry
extends RefCounted

const SUPPORTED_EXTENSIONS: Array[String] = ["tres", "res"]

var last_errors: PackedStringArray = PackedStringArray()


func load_cases_from_directories(root_directories: PackedStringArray) -> Array[WooLogicTestCase]:
	last_errors = PackedStringArray()
	var loaded_cases: Array[WooLogicTestCase] = []
	var discovered_paths: Array[String] = []

	for root_directory: String in root_directories:
		_discover_case_paths(root_directory, discovered_paths)

	discovered_paths.sort()
	for case_path: String in discovered_paths:
		var loaded_resource: Resource = load(case_path) as Resource
		var test_case: WooLogicTestCase = loaded_resource as WooLogicTestCase
		if test_case == null:
			last_errors.append("Invalid test case resource: %s" % case_path)
			continue
		if not test_case.is_valid_case():
			last_errors.append("Incomplete test case resource: %s" % case_path)
			continue
		loaded_cases.append(test_case)

	loaded_cases.sort_custom(_sort_cases)
	return loaded_cases


func _discover_case_paths(directory_path: String, output: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		last_errors.append("Directory not found: %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while entry_name != "":
		if entry_name.begins_with("."):
			entry_name = directory.get_next()
			continue

		var full_path: String = directory_path.path_join(entry_name)
		if directory.current_is_dir():
			_discover_case_paths(full_path, output)
		else:
			var extension: String = entry_name.get_extension().to_lower()
			if SUPPORTED_EXTENSIONS.has(extension):
				output.append(full_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _sort_cases(a: WooLogicTestCase, b: WooLogicTestCase) -> bool:
	if a == null:
		return false
	if b == null:
		return true
	if a.suite_id == b.suite_id:
		return String(a.case_id) < String(b.case_id)
	return String(a.suite_id) < String(b.suite_id)
