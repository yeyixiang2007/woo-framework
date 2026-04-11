@tool
class_name WooLogicTestCase
extends Resource

@export var case_id: StringName = &""
@export var suite_id: StringName = &"general"
@export var title: String = ""
@export_multiline var description: String = ""
@export var tags: PackedStringArray = PackedStringArray()
@export var module_root_paths: PackedStringArray = PackedStringArray()
@export var reset_runtime_before_run := true
@export var steps: Array = []


func is_valid_case() -> bool:
	return case_id != &"" and not steps.is_empty()


func get_display_name() -> String:
	var normalized_title: String = title.strip_edges()
	if not normalized_title.is_empty():
		return normalized_title
	return String(case_id)


func to_summary() -> Dictionary:
	return {
		"case_id": case_id,
		"suite_id": suite_id,
		"title": get_display_name(),
		"description": description,
		"tags": tags.duplicate(),
		"module_root_paths": module_root_paths.duplicate(),
		"reset_runtime_before_run": reset_runtime_before_run,
		"step_count": steps.size(),
	}
