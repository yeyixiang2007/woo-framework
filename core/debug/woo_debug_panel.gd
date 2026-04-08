class_name WooDebugPanel
extends CanvasLayer

@export var start_visible := false
@export_range(0.1, 3.0, 0.1) var refresh_interval := 0.5
@export_range(5, 200, 1) var max_entries := 30
@export_range(320.0, 900.0, 10.0) var panel_width := 520.0

var app
var _bound_app = null
var _refresh_elapsed := 0.0

var root_panel: PanelContainer
var header_label: Label
var content_label: RichTextLabel

var event_entries: Array[String] = []
var command_entries: Array[String] = []


func _ready() -> void:
	layer = 100
	_build_ui()
	visible = start_visible
	set_process(true)
	set_process_unhandled_input(true)
	_resolve_app()
	_refresh_content()


func _exit_tree() -> void:
	_disconnect_app_signals()


func attach_app(owner_app) -> void:
	app = owner_app
	_bind_app_signals()
	_refresh_content()


func _process(delta: float) -> void:
	if app == null:
		_resolve_app()
	if not visible:
		return
	_refresh_elapsed += delta
	if _refresh_elapsed >= refresh_interval:
		_refresh_elapsed = 0.0
		_refresh_content()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_F3:
			visible = not visible
			_refresh_content()
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	root_panel = PanelContainer.new()
	root_panel.name = "DebugPanel"
	root_panel.anchor_left = 1.0
	root_panel.anchor_top = 0.0
	root_panel.anchor_right = 1.0
	root_panel.anchor_bottom = 1.0
	root_panel.offset_left = -panel_width - 16.0
	root_panel.offset_top = 16.0
	root_panel.offset_right = -16.0
	root_panel.offset_bottom = -16.0
	add_child(root_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	root_panel.add_child(vbox)

	header_label = Label.new()
	header_label.name = "Header"
	header_label.text = "Woo Debug Panel  (F3 Toggle)"
	header_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header_label)

	content_label = RichTextLabel.new()
	content_label.name = "Content"
	content_label.bbcode_enabled = true
	content_label.scroll_following = false
	content_label.fit_content = true
	content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_label.custom_minimum_size = Vector2(0.0, 480.0)
	vbox.add_child(content_label)


func _resolve_app() -> void:
	if app == null:
		app = WooApp.get_instance()
	_bind_app_signals()


func _bind_app_signals() -> void:
	if app == null:
		return
	if _bound_app == app:
		return

	_disconnect_app_signals()
	_bound_app = app

	if app.events != null:
		if not app.events.event_emitted.is_connected(_on_event_emitted):
			app.events.event_emitted.connect(_on_event_emitted)

	if app.commands != null:
		if not app.commands.command_executed.is_connected(_on_command_executed):
			app.commands.command_executed.connect(_on_command_executed)
		if not app.commands.command_failed.is_connected(_on_command_failed):
			app.commands.command_failed.connect(_on_command_failed)


func _disconnect_app_signals() -> void:
	if _bound_app == null:
		return
	if _bound_app.events != null and _bound_app.events.event_emitted.is_connected(_on_event_emitted):
		_bound_app.events.event_emitted.disconnect(_on_event_emitted)
	if _bound_app.commands != null and _bound_app.commands.command_executed.is_connected(_on_command_executed):
		_bound_app.commands.command_executed.disconnect(_on_command_executed)
	if _bound_app.commands != null and _bound_app.commands.command_failed.is_connected(_on_command_failed):
		_bound_app.commands.command_failed.disconnect(_on_command_failed)
	_bound_app = null


func _on_event_emitted(event_id: StringName, payload) -> void:
	_push_entry(
		event_entries,
		"%s payload=%s" % [String(event_id), _compact_value(payload, 120)]
	)


func _on_command_executed(command_id: StringName, payload, result) -> void:
	_push_entry(
		command_entries,
		"OK %s payload=%s result=%s" % [
			String(command_id),
			_compact_value(payload, 80),
			_compact_value(result, 80),
		]
	)


func _on_command_failed(command_id: StringName, payload, reason: String) -> void:
	_push_entry(
		command_entries,
		"ERR %s reason=%s payload=%s" % [
			String(command_id),
			reason,
			_compact_value(payload, 80),
		]
	)


func _push_entry(bucket: Array[String], value: String) -> void:
	bucket.append(value)
	if bucket.size() > max_entries:
		bucket.pop_front()


func _refresh_content() -> void:
	if content_label == null:
		return

	var lines: Array[String] = []
	lines.append("[b]WooFramework Runtime Debug[/b]")
	lines.append("Press [b]F3[/b] to hide/show this panel.")
	lines.append("")
	lines.append_array(_build_module_status_lines())
	lines.append("")
	lines.append_array(_build_model_snapshot_lines())
	lines.append("")
	lines.append_array(_build_log_lines("Recent Commands", "ffd27d", command_entries, 10))
	lines.append("")
	lines.append_array(_build_log_lines("Recent Events", "8fd2ff", event_entries, 10))
	content_label.clear()
	content_label.append_text("\n".join(lines))


func _build_module_status_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("[color=#9ad89a]Module Status[/color]")
	if app == null:
		lines.append("app: <unavailable>")
		return lines

	var module_status: Variant = app.get_state_value(&"module_registry_status", "unknown")
	lines.append("registry_status: %s" % String(module_status))

	if app.modules == null:
		lines.append("modules: <registry unavailable>")
		return lines

	var ids: Array = app.modules.get_module_ids()
	var names: Array[String] = []
	for module_id in ids:
		names.append(String(module_id))
	lines.append("module_count: %d" % names.size())
	lines.append("module_ids: %s" % (", ".join(names) if not names.is_empty() else "<none>"))
	return lines


func _build_model_snapshot_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("[color=#9ad89a]Model Snapshots[/color]")
	if app == null or app.models == null:
		lines.append("models: <unavailable>")
		return lines

	var ids: Array = app.models.get_model_ids()
	if ids.is_empty():
		lines.append("<no models registered>")
		return lines

	for model_id in ids:
		var model = app.models.get_model(model_id)
		if model == null:
			lines.append("- %s: <null>" % String(model_id))
			continue
		lines.append("- %s: %s" % [String(model_id), _snapshot_model(model)])
	return lines


func _snapshot_model(model: Resource) -> String:
	var fields: Array[String] = []
	for info in model.get_property_list():
		var property_name := String(info.get("name", ""))
		if property_name.is_empty() or property_name.begins_with("_"):
			continue
		if property_name == "script":
			continue

		var usage := int(info.get("usage", 0))
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue

		var value = model.get(property_name)
		fields.append("%s=%s" % [property_name, _compact_value(value, 40)])

	if fields.is_empty():
		return "<no script fields>"
	return ", ".join(fields)


func _build_log_lines(title: String, color_code: String, bucket: Array[String], take: int) -> Array[String]:
	var lines: Array[String] = []
	lines.append("[color=#%s]%s[/color]" % [color_code, title])
	if bucket.is_empty():
		lines.append("<empty>")
		return lines

	var start_index := maxi(bucket.size() - take, 0)
	for index in range(bucket.size() - 1, start_index - 1, -1):
		lines.append("- %s" % bucket[index])
	return lines


func _compact_value(value: Variant, max_len: int) -> String:
	var text := ""
	if value is Array or value is Dictionary:
		text = JSON.stringify(value)
	else:
		text = str(value)
	if text.length() > max_len:
		return text.substr(0, max_len - 3) + "..."
	return text
