class_name WooLogicTestConsole
extends CanvasLayer

const RUNTIME_APP_NODE_NAME: String = "WooLogicTestApp"

@export var start_visible := true
@export var module_root_paths: PackedStringArray = PackedStringArray(["res://game/modules"])
@export var case_directories: PackedStringArray = PackedStringArray(["res://game/tests/logic"])
@export var toggle_keycode: Key = KEY_F8
@export var title_text: String = "Woo Logic Test Console"

var _registry: WooLogicTestRegistry = WooLogicTestRegistry.new()
var _runner: WooLogicTestRunner = null
var _runtime_app: WooApp = null
var _cases: Array[WooLogicTestCase] = []
var _selected_case_index := -1
var _log_lines: PackedStringArray = PackedStringArray()
var _suite_stop_requested := false
var _last_suite_reports: Array[Dictionary] = []

var _root_panel: PanelContainer = null
var _status_label: Label = null
var _case_list: ItemList = null
var _case_detail: RichTextLabel = null
var _log_output: RichTextLabel = null
var _manual_kind_option: OptionButton = null
var _manual_id_input: LineEdit = null
var _manual_payload_input: TextEdit = null
var _reload_button: Button = null
var _reset_runtime_button: Button = null
var _run_selected_button: Button = null
var _run_all_button: Button = null
var _stop_button: Button = null
var _copy_log_button: Button = null
var _manual_execute_button: Button = null


func _ready() -> void:
	layer = 110
	_runner = WooLogicTestRunner.new()
	_runner.name = "WooLogicTestRunner"
	add_child(_runner)
	_connect_runner_signals()
	_build_ui()
	visible = start_visible
	set_process_unhandled_input(true)
	_load_cases()
	_update_status("Ready")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == toggle_keycode:
			visible = not visible
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_root_panel = PanelContainer.new()
	_root_panel.anchor_left = 0.0
	_root_panel.anchor_top = 0.0
	_root_panel.anchor_right = 1.0
	_root_panel.anchor_bottom = 1.0
	_root_panel.offset_left = 24.0
	_root_panel.offset_top = 24.0
	_root_panel.offset_right = -24.0
	_root_panel.offset_bottom = -24.0
	_root_panel.set("theme_override_styles/panel", _build_panel_style(Color(0.10, 0.11, 0.14, 0.97), Color(0.25, 0.42, 0.61, 1.0)))
	add_child(_root_panel)

	var root_margin: MarginContainer = MarginContainer.new()
	root_margin.set("theme_override_constants/margin_left", 14)
	root_margin.set("theme_override_constants/margin_top", 14)
	root_margin.set("theme_override_constants/margin_right", 14)
	root_margin.set("theme_override_constants/margin_bottom", 14)
	_root_panel.add_child(root_margin)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.set("theme_override_constants/separation", 10)
	root_margin.add_child(root_vbox)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.set("theme_override_constants/separation", 8)
	root_vbox.add_child(header_row)

	var title_label: Label = Label.new()
	title_label.text = "%s  (F8 Toggle)" % title_text
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 24)
	header_row.add_child(title_label)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(_status_label)

	_reload_button = _build_action_button("Reload Cases", _on_reload_cases_pressed)
	header_row.add_child(_reload_button)

	_reset_runtime_button = _build_action_button("Reset Runtime", _on_reset_runtime_pressed)
	header_row.add_child(_reset_runtime_button)

	_run_selected_button = _build_action_button("Run Selected", _on_run_selected_pressed)
	header_row.add_child(_run_selected_button)

	_run_all_button = _build_action_button("Run All", _on_run_all_pressed)
	header_row.add_child(_run_all_button)

	_stop_button = _build_action_button("Stop", _on_stop_pressed)
	_stop_button.disabled = true
	header_row.add_child(_stop_button)

	_copy_log_button = _build_action_button("Copy Log", _on_copy_log_pressed)
	header_row.add_child(_copy_log_button)

	var body_split: HSplitContainer = HSplitContainer.new()
	body_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_split.split_offset = 340
	root_vbox.add_child(body_split)

	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.set("theme_override_styles/panel", _build_panel_style(Color(0.14, 0.16, 0.20, 0.96), Color(0.23, 0.28, 0.36, 1.0)))
	body_split.add_child(left_panel)

	var left_margin: MarginContainer = MarginContainer.new()
	left_margin.set("theme_override_constants/margin_left", 10)
	left_margin.set("theme_override_constants/margin_top", 10)
	left_margin.set("theme_override_constants/margin_right", 10)
	left_margin.set("theme_override_constants/margin_bottom", 10)
	left_panel.add_child(left_margin)

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.set("theme_override_constants/separation", 8)
	left_margin.add_child(left_vbox)

	var case_label: Label = Label.new()
	case_label.text = "Logic Cases"
	case_label.add_theme_font_size_override("font_size", 18)
	left_vbox.add_child(case_label)

	_case_list = ItemList.new()
	_case_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_case_list.select_mode = ItemList.SELECT_SINGLE
	_case_list.custom_minimum_size = Vector2(0.0, 320.0)
	_case_list.item_selected.connect(_on_case_selected)
	left_vbox.add_child(_case_list)

	var detail_label: Label = Label.new()
	detail_label.text = "Selected Case"
	detail_label.add_theme_font_size_override("font_size", 18)
	left_vbox.add_child(detail_label)

	_case_detail = RichTextLabel.new()
	_case_detail.bbcode_enabled = false
	_case_detail.fit_content = false
	_case_detail.scroll_active = true
	_case_detail.custom_minimum_size = Vector2(0.0, 260.0)
	_case_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(_case_detail)

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.set("theme_override_styles/panel", _build_panel_style(Color(0.12, 0.13, 0.17, 0.96), Color(0.23, 0.28, 0.36, 1.0)))
	body_split.add_child(right_panel)

	var right_margin: MarginContainer = MarginContainer.new()
	right_margin.set("theme_override_constants/margin_left", 10)
	right_margin.set("theme_override_constants/margin_top", 10)
	right_margin.set("theme_override_constants/margin_right", 10)
	right_margin.set("theme_override_constants/margin_bottom", 10)
	right_panel.add_child(right_margin)

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.set("theme_override_constants/separation", 8)
	right_margin.add_child(right_vbox)

	var manual_label: Label = Label.new()
	manual_label.text = "Manual Command / Query"
	manual_label.add_theme_font_size_override("font_size", 18)
	right_vbox.add_child(manual_label)

	var manual_row: HBoxContainer = HBoxContainer.new()
	manual_row.set("theme_override_constants/separation", 8)
	right_vbox.add_child(manual_row)

	_manual_kind_option = OptionButton.new()
	_manual_kind_option.add_item("Command")
	_manual_kind_option.add_item("Query")
	_manual_kind_option.custom_minimum_size = Vector2(140.0, 0.0)
	manual_row.add_child(_manual_kind_option)

	_manual_id_input = LineEdit.new()
	_manual_id_input.placeholder_text = "game.start_run / game.get_hud_state"
	_manual_id_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manual_row.add_child(_manual_id_input)

	_manual_execute_button = _build_action_button("Execute", _on_manual_execute_pressed)
	manual_row.add_child(_manual_execute_button)

	_manual_payload_input = TextEdit.new()
	_manual_payload_input.custom_minimum_size = Vector2(0.0, 132.0)
	_manual_payload_input.text = "{\n  \n}"
	right_vbox.add_child(_manual_payload_input)

	var output_label: Label = Label.new()
	output_label.text = "Run Output"
	output_label.add_theme_font_size_override("font_size", 18)
	right_vbox.add_child(output_label)

	_log_output = RichTextLabel.new()
	_log_output.bbcode_enabled = false
	_log_output.fit_content = false
	_log_output.scroll_active = true
	_log_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(_log_output)


func _build_action_button(text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110.0, 38.0)
	button.pressed.connect(callback)
	return button


func _build_panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	return style


func _connect_runner_signals() -> void:
	if _runner == null:
		return
	if not _runner.case_started.is_connected(_on_runner_case_started):
		_runner.case_started.connect(_on_runner_case_started)
	if not _runner.step_started.is_connected(_on_runner_step_started):
		_runner.step_started.connect(_on_runner_step_started)
	if not _runner.step_completed.is_connected(_on_runner_step_completed):
		_runner.step_completed.connect(_on_runner_step_completed)
	if not _runner.log_emitted.is_connected(_on_runner_log_emitted):
		_runner.log_emitted.connect(_on_runner_log_emitted)
	if not _runner.case_completed.is_connected(_on_runner_case_completed):
		_runner.case_completed.connect(_on_runner_case_completed)


func _load_cases() -> void:
	_cases = _registry.load_cases_from_directories(case_directories)
	_case_list.clear()
	for test_case: WooLogicTestCase in _cases:
		if test_case == null:
			continue
		_case_list.add_item("[%s] %s" % [String(test_case.suite_id), test_case.get_display_name()])

	if not _registry.last_errors.is_empty():
		for error_line: String in _registry.last_errors:
			_append_log("Registry: %s" % error_line)

	if not _cases.is_empty():
		_selected_case_index = 0
		_case_list.select(0)
		_render_case_detail(_cases[0])
	else:
		_selected_case_index = -1
		_case_detail.clear()
		_case_detail.append_text("No logic test cases were discovered.")


func _render_case_detail(test_case: WooLogicTestCase) -> void:
	if _case_detail == null:
		return
	if test_case == null:
		_case_detail.clear()
		return

	var lines: Array[String] = []
	lines.append("Case ID: %s" % String(test_case.case_id))
	lines.append("Suite: %s" % String(test_case.suite_id))
	lines.append("Title: %s" % test_case.get_display_name())
	lines.append("Reset Runtime: %s" % ("Yes" if test_case.reset_runtime_before_run else "No"))
	if not test_case.tags.is_empty():
		lines.append("Tags: %s" % ", ".join(test_case.tags))
	if not test_case.description.strip_edges().is_empty():
		lines.append("")
		lines.append(test_case.description.strip_edges())
	lines.append("")
	lines.append("Steps:")
	for step_index: int in range(test_case.steps.size()):
		var step_variant: Variant = test_case.steps[step_index]
		var step_dictionary: Dictionary = {}
		if step_variant is Dictionary:
			step_dictionary = step_variant
		var step_type: String = String(step_dictionary.get("type", ""))
		var step_id: String = String(step_dictionary.get("id", ""))
		var step_description: String = String(step_dictionary.get("description", "")).strip_edges()
		var descriptor: String = step_description
		if descriptor.is_empty():
			descriptor = step_id
		if descriptor.is_empty():
			descriptor = step_type
		lines.append("%d. [%s] %s" % [step_index + 1, step_type, descriptor])

	_case_detail.clear()
	_case_detail.append_text("\n".join(lines))


func _append_log(message: String) -> void:
	var normalized_message: String = message.strip_edges()
	if normalized_message.is_empty():
		return
	_log_lines.append(normalized_message)
	if _log_lines.size() > 300:
		_log_lines.remove_at(0)
	_refresh_log_output()


func _refresh_log_output() -> void:
	if _log_output == null:
		return
	_log_output.clear()
	_log_output.append_text("\n".join(_log_lines))


func _update_status(text: String) -> void:
	if _status_label == null:
		return
	var runtime_text: String = "runtime=offline"
	if _runtime_app != null and _runtime_app.modules != null and _runtime_app.modules.is_bootstrapped:
		runtime_text = "runtime=ready modules=%d" % _runtime_app.modules.get_module_ids().size()
	_status_label.text = "%s | %s | cases=%d" % [text, runtime_text, _cases.size()]


func _set_controls_enabled(enabled: bool) -> void:
	_reload_button.disabled = not enabled
	_reset_runtime_button.disabled = not enabled
	_run_selected_button.disabled = not enabled
	_run_all_button.disabled = not enabled
	_copy_log_button.disabled = not enabled
	_manual_execute_button.disabled = not enabled
	_stop_button.disabled = enabled


func _ensure_runtime_app(forced_module_roots: PackedStringArray = PackedStringArray()) -> bool:
	var effective_roots: PackedStringArray = module_root_paths
	if not forced_module_roots.is_empty():
		effective_roots = forced_module_roots
	if _runtime_app == null or not is_instance_valid(_runtime_app):
		var tree: SceneTree = get_tree()
		if tree == null or tree.root == null:
			_append_log("Runtime bootstrap failed: SceneTree root unavailable.")
			return false

		_runtime_app = tree.root.get_node_or_null(RUNTIME_APP_NODE_NAME) as WooApp
		if _runtime_app == null:
			_runtime_app = WooApp.new()
			_runtime_app.name = RUNTIME_APP_NODE_NAME
			tree.root.add_child(_runtime_app)

	if not _runtime_app.has_started():
		_runtime_app.boot(get_tree().root)

	if _runtime_app.modules == null:
		_append_log("Runtime bootstrap failed: module registry unavailable.")
		return false

	if not _runtime_app.modules.is_bootstrapped:
		var boot_ok: bool = _runtime_app.modules.boot_from_roots(effective_roots)
		if not boot_ok:
			_append_log("Runtime module boot failed: %s" % _runtime_app.modules.get_boot_error())
			return false

	return true


func _rebuild_runtime_app(forced_module_roots: PackedStringArray = PackedStringArray()) -> bool:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		_append_log("Runtime rebuild failed: SceneTree root unavailable.")
		return false

	var existing_app: WooApp = tree.root.get_node_or_null(RUNTIME_APP_NODE_NAME) as WooApp
	if existing_app != null:
		existing_app.queue_free()
		await get_tree().process_frame

	_runtime_app = null
	return _ensure_runtime_app(forced_module_roots)


func _get_selected_case() -> WooLogicTestCase:
	if _selected_case_index < 0 or _selected_case_index >= _cases.size():
		return null
	return _cases[_selected_case_index]


func _on_case_selected(index: int) -> void:
	_selected_case_index = index
	_render_case_detail(_get_selected_case())


func _on_reload_cases_pressed() -> void:
	_append_log("Reloading logic cases.")
	_load_cases()
	_update_status("Cases reloaded")


func _on_reset_runtime_pressed() -> void:
	_append_log("Rebuilding runtime app.")
	await _rebuild_runtime_app()
	_update_status("Runtime rebuilt")


func _on_run_selected_pressed() -> void:
	var test_case: WooLogicTestCase = _get_selected_case()
	if test_case == null:
		_append_log("No test case selected.")
		return

	_set_controls_enabled(false)
	_suite_stop_requested = false
	_log_lines = PackedStringArray()
	_append_log("Preparing selected case %s." % String(test_case.case_id))

	var runtime_ready: bool = await _prepare_runtime_for_case(test_case)
	if runtime_ready:
		var report: Dictionary = await _runner.run_case(test_case, _runtime_app)
		_last_suite_reports = [report]
	_append_log("Selected case finished.")
	_set_controls_enabled(true)
	_update_status("Selected case run complete")


func _on_run_all_pressed() -> void:
	if _cases.is_empty():
		_append_log("No logic cases available.")
		return

	_set_controls_enabled(false)
	_suite_stop_requested = false
	_log_lines = PackedStringArray()
	_last_suite_reports = []
	_append_log("Running all logic cases.")

	var passed_count := 0
	for test_case: WooLogicTestCase in _cases:
		if _suite_stop_requested:
			_append_log("Suite execution stopped before case %s." % String(test_case.case_id))
			break

		var runtime_ready: bool = await _prepare_runtime_for_case(test_case)
		if not runtime_ready:
			_last_suite_reports.append(
				{
					"ok": false,
					"case_id": test_case.case_id,
					"title": test_case.get_display_name(),
					"message": "Runtime bootstrap failed.",
				}
			)
			continue

		var case_report: Dictionary = await _runner.run_case(test_case, _runtime_app)
		_last_suite_reports.append(case_report)
		if bool(case_report.get("ok", false)):
			passed_count += 1

	_append_log("Suite summary: %d/%d case(s) passed." % [passed_count, _last_suite_reports.size()])
	_set_controls_enabled(true)
	_update_status("Suite run complete")


func _prepare_runtime_for_case(test_case: WooLogicTestCase) -> bool:
	if test_case == null:
		return false

	var effective_roots: PackedStringArray = module_root_paths
	if not test_case.module_root_paths.is_empty():
		effective_roots = test_case.module_root_paths
	if test_case.reset_runtime_before_run:
		return await _rebuild_runtime_app(effective_roots)
	return _ensure_runtime_app(effective_roots)


func _on_stop_pressed() -> void:
	_suite_stop_requested = true
	if _runner != null:
		_runner.stop_run()
	_append_log("Stop requested.")


func _on_copy_log_pressed() -> void:
	DisplayServer.clipboard_set("\n".join(_log_lines))
	_append_log("Copied log output to clipboard.")


func _on_manual_execute_pressed() -> void:
	if not _ensure_runtime_app():
		return

	var payload_text: String = _manual_payload_input.text.strip_edges()
	var payload: Variant = {}
	if not payload_text.is_empty():
		payload = JSON.parse_string(payload_text)
		if payload == null and payload_text != "null":
			_append_log("Manual execution aborted: invalid JSON payload.")
			return

	var action_id: StringName = StringName(_manual_id_input.text.strip_edges())
	if action_id == &"":
		_append_log("Manual execution aborted: missing command/query id.")
		return

	var result = null
	if _manual_kind_option.selected == 0:
		result = _runtime_app.commands.execute(action_id, payload)
		_append_log("Manual command %s => %s" % [String(action_id), _stringify_value(result)])
	else:
		result = _runtime_app.queries.query(action_id, payload)
		_append_log("Manual query %s => %s" % [String(action_id), _stringify_value(result)])

	_update_status("Manual execution complete")


func _on_runner_case_started(case_summary: Dictionary) -> void:
	_append_log("Case start: %s" % String(case_summary.get("case_id", "")))
	_update_status("Running %s" % String(case_summary.get("case_id", "")))


func _on_runner_step_started(_case_id: StringName, step_index: int, step_summary: Dictionary) -> void:
	_append_log("Step %d [%s] %s" % [
		step_index + 1,
		String(step_summary.get("type", "")),
		String(step_summary.get("id", step_summary.get("description", ""))),
	])


func _on_runner_step_completed(_case_id: StringName, _step_index: int, step_report: Dictionary) -> void:
	var outcome_text: String = "OK" if bool(step_report.get("ok", false)) else "FAIL"
	_append_log("%s: %s" % [outcome_text, String(step_report.get("message", ""))])


func _on_runner_log_emitted(_case_id: StringName, message: String) -> void:
	_append_log(message)


func _on_runner_case_completed(case_id: StringName, case_report: Dictionary) -> void:
	var passed_steps: int = int(case_report.get("passed_step_count", 0))
	var total_steps: int = int(case_report.get("step_count", 0))
	var duration_msec: int = int(case_report.get("duration_msec", 0))
	_append_log(
		"Case complete: %s => %s (%d/%d steps, %d ms)" % [
			String(case_id),
			"PASS" if bool(case_report.get("ok", false)) else "FAIL",
			passed_steps,
			total_steps,
			duration_msec,
		]
	)


func _stringify_value(value) -> String:
	if value is Dictionary or value is Array:
		return JSON.stringify(value, "  ")
	return str(value)
