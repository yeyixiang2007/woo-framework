class_name WooLogicTestRunner
extends Node

signal case_started(case_summary: Dictionary)
signal step_started(case_id: StringName, step_index: int, step_summary: Dictionary)
signal step_completed(case_id: StringName, step_index: int, step_report: Dictionary)
signal log_emitted(case_id: StringName, message: String)
signal case_completed(case_id: StringName, case_report: Dictionary)

var is_running := false
var _stop_requested := false


func stop_run() -> void:
	_stop_requested = true


func run_case(test_case: WooLogicTestCase, app: WooApp) -> Dictionary:
	if is_running:
		return {
			"ok": false,
			"reason": "runner_busy",
		}
	if test_case == null or not test_case.is_valid_case():
		return {
			"ok": false,
			"reason": "invalid_test_case",
		}
	if app == null or not app.has_started():
		return {
			"ok": false,
			"reason": "invalid_runtime_app",
		}

	is_running = true
	_stop_requested = false

	var context: Dictionary = {
		"app": app,
		"case": test_case,
		"variables": {},
		"last_result": null,
		"log_lines": PackedStringArray(),
	}

	var started_at_msec: int = Time.get_ticks_msec()
	var case_report: Dictionary = {
		"ok": true,
		"case_id": test_case.case_id,
		"suite_id": test_case.suite_id,
		"title": test_case.get_display_name(),
		"description": test_case.description,
		"step_count": test_case.steps.size(),
		"passed_step_count": 0,
		"failed_step_index": -1,
		"steps": [],
		"variables": {},
		"duration_msec": 0,
		"log_lines": PackedStringArray(),
	}

	case_started.emit(test_case.to_summary())
	_emit_log(context, "Running case %s" % String(test_case.case_id))

	for step_index: int in range(test_case.steps.size()):
		if _stop_requested:
			case_report["ok"] = false
			case_report["failed_step_index"] = step_index
			case_report["steps"].append(
				{
					"ok": false,
					"type": &"stop",
					"step_index": step_index,
					"message": "Execution stopped by request.",
				}
			)
			break

		var step_variant: Variant = test_case.steps[step_index]
		var step_dictionary: Dictionary = {}
		if step_variant is Dictionary:
			step_dictionary = (step_variant as Dictionary).duplicate(true)

		step_started.emit(test_case.case_id, step_index, _build_step_summary(step_dictionary))
		var step_report: Dictionary = await _execute_step(context, step_dictionary, step_index)
		case_report["steps"].append(step_report)
		step_completed.emit(test_case.case_id, step_index, step_report)

		if bool(step_report.get("ok", false)):
			case_report["passed_step_count"] = int(case_report.get("passed_step_count", 0)) + 1
			continue

		case_report["ok"] = false
		case_report["failed_step_index"] = step_index
		break

	case_report["duration_msec"] = max(0, Time.get_ticks_msec() - started_at_msec)
	case_report["variables"] = _duplicate_dictionary(context.get("variables", {}))
	case_report["last_result"] = _copy_value(context.get("last_result"))
	case_report["log_lines"] = _extract_string_array(context.get("log_lines", PackedStringArray()))
	is_running = false

	case_completed.emit(test_case.case_id, case_report)
	return case_report


func _execute_step(context: Dictionary, step: Dictionary, step_index: int) -> Dictionary:
	var step_type: StringName = StringName(String(step.get("type", "")).strip_edges())
	match step_type:
		&"command":
			return _execute_command_step(context, step, step_index)
		&"query":
			return _execute_query_step(context, step, step_index)
		&"assert":
			return _execute_assert_step(context, step, step_index)
		&"capture":
			return _execute_capture_step(context, step, step_index)
		&"wait_frames":
			return await _execute_wait_step(context, step, step_index)
		&"log":
			return _execute_log_step(context, step, step_index)
		_:
			return {
				"ok": false,
				"type": step_type,
				"step_index": step_index,
				"message": "Unsupported step type: %s" % String(step_type),
			}


func _execute_command_step(context: Dictionary, step: Dictionary, step_index: int) -> Dictionary:
	var app: WooApp = context.get("app") as WooApp
	if app == null or app.commands == null:
		return _build_failed_step_report(step, step_index, "CommandBus is not available.")

	var command_id: StringName = StringName(String(step.get("id", "")).strip_edges())
	if command_id == &"":
		return _build_failed_step_report(step, step_index, "Command step requires a non-empty id.")

	var payload: Variant = _resolve_value(step.get("payload", {}), context)
	var result = app.commands.execute(command_id, payload)
	context["last_result"] = _copy_value(result)
	_store_named_result(context, String(step.get("store_as", "")), result)

	var assertion_reports: Array[Dictionary] = _run_assertions(step, context, result)
	var is_ok: bool = result != null and _are_assertions_successful(assertion_reports)
	var message: String = "Command %s executed." % String(command_id)
	if result == null:
		message = "Command %s returned null." % String(command_id)
	elif not is_ok:
		message = "Command %s assertion failed: %s" % [String(command_id), _get_first_failed_assertion_message(assertion_reports)]

	_emit_log(context, message)

	return {
		"ok": is_ok,
		"type": &"command",
		"step_index": step_index,
		"id": command_id,
		"payload": _copy_value(payload),
		"result": _copy_value(result),
		"assertions": assertion_reports,
		"message": message,
	}


func _execute_query_step(context: Dictionary, step: Dictionary, step_index: int) -> Dictionary:
	var app: WooApp = context.get("app") as WooApp
	if app == null or app.queries == null:
		return _build_failed_step_report(step, step_index, "QueryService is not available.")

	var query_id: StringName = StringName(String(step.get("id", "")).strip_edges())
	if query_id == &"":
		return _build_failed_step_report(step, step_index, "Query step requires a non-empty id.")

	var payload: Variant = _resolve_value(step.get("payload", {}), context)
	var result = app.queries.query(query_id, payload)
	context["last_result"] = _copy_value(result)
	_store_named_result(context, String(step.get("store_as", "")), result)

	var assertion_reports: Array[Dictionary] = _run_assertions(step, context, result)
	var is_ok: bool = result != null and _are_assertions_successful(assertion_reports)
	var message: String = "Query %s executed." % String(query_id)
	if result == null:
		message = "Query %s returned null." % String(query_id)
	elif not is_ok:
		message = "Query %s assertion failed: %s" % [String(query_id), _get_first_failed_assertion_message(assertion_reports)]

	_emit_log(context, message)

	return {
		"ok": is_ok,
		"type": &"query",
		"step_index": step_index,
		"id": query_id,
		"payload": _copy_value(payload),
		"result": _copy_value(result),
		"assertions": assertion_reports,
		"message": message,
	}


func _execute_assert_step(context: Dictionary, step: Dictionary, step_index: int) -> Dictionary:
	var assertion_report: Dictionary = _run_single_assertion(step, context, null)
	var message: String = String(assertion_report.get("message", "Assertion failed."))
	_emit_log(context, message)

	return {
		"ok": bool(assertion_report.get("ok", false)),
		"type": &"assert",
		"step_index": step_index,
		"assertions": [assertion_report],
		"message": message,
	}


func _execute_capture_step(context: Dictionary, step: Dictionary, step_index: int) -> Dictionary:
	var store_as: String = String(step.get("store_as", "")).strip_edges()
	var ref: String = String(step.get("ref", "")).strip_edges()
	if store_as.is_empty() or ref.is_empty():
		return _build_failed_step_report(step, step_index, "Capture step requires ref and store_as.")

	var resolved_value = _resolve_reference(ref, context, null)
	_store_named_result(context, store_as, resolved_value)
	var message: String = "Captured %s from %s." % [store_as, ref]
	_emit_log(context, message)

	return {
		"ok": true,
		"type": &"capture",
		"step_index": step_index,
		"store_as": store_as,
		"ref": ref,
		"value": _copy_value(resolved_value),
		"message": message,
	}


func _execute_wait_step(context: Dictionary, step: Dictionary, step_index: int) -> Dictionary:
	var frame_count: int = max(1, int(step.get("frames", 1)))
	for _frame_index: int in range(frame_count):
		if _stop_requested:
			return _build_failed_step_report(step, step_index, "Wait interrupted by stop request.")
		await get_tree().process_frame

	var message: String = "Waited %d frame(s)." % frame_count
	_emit_log(context, message)
	return {
		"ok": true,
		"type": &"wait_frames",
		"step_index": step_index,
		"frames": frame_count,
		"message": message,
	}


func _execute_log_step(context: Dictionary, step: Dictionary, step_index: int) -> Dictionary:
	var message: String = String(_resolve_value(step.get("message", ""), context))
	_emit_log(context, message)
	return {
		"ok": true,
		"type": &"log",
		"step_index": step_index,
		"message": message,
	}


func _run_assertions(step: Dictionary, context: Dictionary, local_subject) -> Array[Dictionary]:
	var reports: Array[Dictionary] = []
	var raw_assertions: Variant = step.get("asserts", [])
	if not (raw_assertions is Array):
		return reports

	for raw_assertion: Variant in raw_assertions:
		if raw_assertion is Dictionary:
			reports.append(_run_single_assertion(raw_assertion as Dictionary, context, local_subject))
	return reports


func _run_single_assertion(assertion: Dictionary, context: Dictionary, local_subject) -> Dictionary:
	var ref_text: String = String(assertion.get("ref", "")).strip_edges()
	var path_text: String = String(assertion.get("path", "")).strip_edges()
	var value = null
	if not ref_text.is_empty():
		value = _resolve_reference(ref_text, context, local_subject)
	elif not path_text.is_empty():
		value = _resolve_path(local_subject, path_text)
	else:
		value = local_subject

	var report: Dictionary = {
		"ok": true,
		"ref": ref_text,
		"path": path_text,
		"actual": _copy_value(value),
		"message": "Assertion passed.",
	}

	if assertion.has("exists"):
		var expected_exists: bool = bool(_resolve_value(assertion.get("exists", true), context))
		var actual_exists: bool = value != null
		if actual_exists != expected_exists:
			return _fail_assertion(report, "Expected exists=%s but got %s." % [str(expected_exists), str(actual_exists)])

	if assertion.has("equals"):
		var expected_value = _resolve_value(assertion.get("equals"), context)
		if value != expected_value:
			return _fail_assertion(report, "Expected %s but got %s." % [_stringify_value(expected_value), _stringify_value(value)])

	if assertion.has("not_equals"):
		var expected_not_value = _resolve_value(assertion.get("not_equals"), context)
		if value == expected_not_value:
			return _fail_assertion(report, "Value unexpectedly equals %s." % _stringify_value(expected_not_value))

	if assertion.has("greater_or_equal"):
		var min_value = _resolve_value(assertion.get("greater_or_equal"), context)
		if _to_float(value) < _to_float(min_value):
			return _fail_assertion(report, "Expected >= %s but got %s." % [_stringify_value(min_value), _stringify_value(value)])

	if assertion.has("greater_than"):
		var gt_value = _resolve_value(assertion.get("greater_than"), context)
		if _to_float(value) <= _to_float(gt_value):
			return _fail_assertion(report, "Expected > %s but got %s." % [_stringify_value(gt_value), _stringify_value(value)])

	if assertion.has("size_equals"):
		var expected_size = int(_resolve_value(assertion.get("size_equals"), context))
		if _get_size(value) != expected_size:
			return _fail_assertion(report, "Expected size %d but got %d." % [expected_size, _get_size(value)])

	if assertion.has("size_greater_or_equal"):
		var min_size = int(_resolve_value(assertion.get("size_greater_or_equal"), context))
		if _get_size(value) < min_size:
			return _fail_assertion(report, "Expected size >= %d but got %d." % [min_size, _get_size(value)])

	if assertion.has("contains"):
		var contains_value = _resolve_value(assertion.get("contains"), context)
		if not _contains_value(value, contains_value):
			return _fail_assertion(report, "Expected collection to contain %s." % _stringify_value(contains_value))

	if assertion.has("not_contains"):
		var not_contains_value = _resolve_value(assertion.get("not_contains"), context)
		if _contains_value(value, not_contains_value):
			return _fail_assertion(report, "Expected collection not to contain %s." % _stringify_value(not_contains_value))

	return report


func _resolve_value(value, context: Dictionary):
	if value is Dictionary:
		var dictionary_value: Dictionary = value
		if dictionary_value.size() == 1 and dictionary_value.has("$ref"):
			return _resolve_reference(String(dictionary_value.get("$ref", "")), context, null)
		var result_dictionary: Dictionary = {}
		for key in dictionary_value.keys():
			result_dictionary[key] = _resolve_value(dictionary_value[key], context)
		return result_dictionary

	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(_resolve_value(item, context))
		return result_array

	return value


func _resolve_reference(ref: String, context: Dictionary, local_subject):
	var normalized_ref: String = ref.strip_edges()
	if normalized_ref.is_empty():
		return null

	if normalized_ref == "last_result":
		return context.get("last_result")
	if normalized_ref.begins_with("last_result."):
		return _resolve_path(context.get("last_result"), normalized_ref.trim_prefix("last_result."))
	if normalized_ref.begins_with("vars."):
		return _resolve_path(context.get("variables", {}), normalized_ref.trim_prefix("vars."))
	if normalized_ref.begins_with("app_state."):
		var app: WooApp = context.get("app") as WooApp
		var runtime_state: Dictionary = {}
		if app != null:
			runtime_state = app.runtime_state
		return _resolve_path(runtime_state, normalized_ref.trim_prefix("app_state."))
	if normalized_ref.begins_with("model:"):
		var model_ref: String = normalized_ref.trim_prefix("model:")
		var separator_index: int = model_ref.find("|")
		var model_id: String = model_ref
		var path_text: String = ""
		if separator_index >= 0:
			model_id = model_ref.substr(0, separator_index)
			path_text = model_ref.substr(separator_index + 1)
		var app: WooApp = context.get("app") as WooApp
		var model = null
		if app != null and app.models != null:
			model = app.models.get_model(StringName(model_id))
		return _resolve_path(model, path_text)
	if normalized_ref.begins_with("case."):
		var test_case: WooLogicTestCase = context.get("case") as WooLogicTestCase
		return _resolve_path(test_case, normalized_ref.trim_prefix("case."))

	return _resolve_path(local_subject, normalized_ref)


func _resolve_path(source, path_text: String):
	var normalized_path: String = path_text.strip_edges()
	if normalized_path.is_empty():
		return source

	var current = source
	for token: String in normalized_path.split(".", false):
		if current == null:
			return null
		current = _read_token(current, token)
	return current


func _read_token(source, token: String):
	if token == "size":
		return _get_size(source)

	if source is Dictionary:
		return (source as Dictionary).get(token)

	if source is Array:
		var array_source: Array = source
		if token.is_valid_int():
			var index: int = int(token)
			if index >= 0 and index < array_source.size():
				return array_source[index]
		return null

	if source is PackedStringArray:
		var packed_string_array: PackedStringArray = source
		if token.is_valid_int():
			var string_index: int = int(token)
			if string_index >= 0 and string_index < packed_string_array.size():
				return packed_string_array[string_index]
		return null

	if source is PackedInt32Array:
		var packed_int_array: PackedInt32Array = source
		if token.is_valid_int():
			var int_index: int = int(token)
			if int_index >= 0 and int_index < packed_int_array.size():
				return packed_int_array[int_index]
		return null

	if source is PackedFloat32Array:
		var packed_float_array: PackedFloat32Array = source
		if token.is_valid_int():
			var float_index: int = int(token)
			if float_index >= 0 and float_index < packed_float_array.size():
				return packed_float_array[float_index]
		return null

	if source is Object:
		var object_source: Object = source
		for property_info in object_source.get_property_list():
			if String(property_info.get("name", "")) == token:
				return object_source.get(token)
		return null

	return null


func _store_named_result(context: Dictionary, store_as: String, value) -> void:
	var normalized_key: String = store_as.strip_edges()
	if normalized_key.is_empty():
		return

	var variables: Dictionary = context.get("variables", {})
	variables[normalized_key] = _copy_value(value)
	context["variables"] = variables


func _emit_log(context: Dictionary, message: String) -> void:
	var normalized_message: String = message.strip_edges()
	if normalized_message.is_empty():
		return

	var log_lines: PackedStringArray = _extract_string_array(context.get("log_lines", PackedStringArray()))
	log_lines.append(normalized_message)
	context["log_lines"] = log_lines

	var test_case: WooLogicTestCase = context.get("case") as WooLogicTestCase
	var case_id: StringName = &""
	if test_case != null:
		case_id = test_case.case_id
	log_emitted.emit(case_id, normalized_message)


func _build_failed_step_report(step: Dictionary, step_index: int, message: String) -> Dictionary:
	return {
		"ok": false,
		"type": StringName(String(step.get("type", "")).strip_edges()),
		"step_index": step_index,
		"message": message,
	}


func _build_step_summary(step: Dictionary) -> Dictionary:
	return {
		"type": step.get("type", ""),
		"id": step.get("id", ""),
		"description": step.get("description", ""),
	}


func _are_assertions_successful(assertion_reports: Array[Dictionary]) -> bool:
	for assertion_report: Dictionary in assertion_reports:
		if not bool(assertion_report.get("ok", false)):
			return false
	return true


func _get_first_failed_assertion_message(assertion_reports: Array[Dictionary]) -> String:
	for assertion_report: Dictionary in assertion_reports:
		if not bool(assertion_report.get("ok", false)):
			return String(assertion_report.get("message", "Assertion failed."))
	return "Assertion failed."


func _fail_assertion(report: Dictionary, message: String) -> Dictionary:
	report["ok"] = false
	report["message"] = message
	return report


func _contains_value(container, expected_value) -> bool:
	if container == null:
		return false

	if container is Dictionary:
		var dictionary_container: Dictionary = container
		return dictionary_container.values().has(expected_value) or dictionary_container.has(expected_value)
	if container is Array:
		return (container as Array).has(expected_value)
	if container is PackedStringArray:
		return (container as PackedStringArray).has(String(expected_value))
	if container is String:
		return String(container).contains(String(expected_value))
	return false


func _get_size(value) -> int:
	if value == null:
		return 0
	if value is Dictionary:
		return (value as Dictionary).size()
	if value is Array:
		return (value as Array).size()
	if value is PackedStringArray:
		return (value as PackedStringArray).size()
	if value is PackedInt32Array:
		return (value as PackedInt32Array).size()
	if value is PackedFloat32Array:
		return (value as PackedFloat32Array).size()
	if value is String:
		return String(value).length()
	return 0


func _copy_value(value):
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()
	if value is PackedInt32Array:
		return (value as PackedInt32Array).duplicate()
	if value is PackedFloat32Array:
		return (value as PackedFloat32Array).duplicate()
	return value


func _duplicate_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _extract_string_array(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()

	var result: PackedStringArray = PackedStringArray()
	if value is Array:
		for item in value:
			var normalized_item: String = String(item).strip_edges()
			if not normalized_item.is_empty():
				result.append(normalized_item)
	return result


func _stringify_value(value) -> String:
	if value is Dictionary or value is Array:
		return JSON.stringify(value)
	return str(value)


func _to_float(value: Variant) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	if value is String:
		return String(value).to_float()
	return 0.0
