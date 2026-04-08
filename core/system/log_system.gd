class_name LogSystem
extends RefCounted

signal log_added(entry: Dictionary)
signal log_cleared()

var app
var enable_print := true
var max_entries := 200
var entries: Array = []
var _bound := false


func _init(owner_app = null) -> void:
	app = owner_app


func set_app(owner_app) -> void:
	app = owner_app


func bind() -> void:
	if _bound:
		return

	var resolved_app := _ensure_app()
	if resolved_app == null:
		return

	if resolved_app.events != null:
		resolved_app.events.event_emitted.connect(_on_event_emitted)

	if resolved_app.commands != null:
		resolved_app.commands.command_executed.connect(_on_command_executed)
		resolved_app.commands.command_failed.connect(_on_command_failed)

	_bound = true


func unbind() -> void:
	if not _bound:
		return
	if app != null:
		if app.events != null and app.events.event_emitted.is_connected(_on_event_emitted):
			app.events.event_emitted.disconnect(_on_event_emitted)
		if app.commands != null and app.commands.command_executed.is_connected(_on_command_executed):
			app.commands.command_executed.disconnect(_on_command_executed)
		if app.commands != null and app.commands.command_failed.is_connected(_on_command_failed):
			app.commands.command_failed.disconnect(_on_command_failed)
	_bound = false


func log_info(message: String, payload = null) -> void:
	_add_entry("info", {
		"message": message,
		"payload": payload,
	})


func log_error(message: String, payload = null) -> void:
	_add_entry("error", {
		"message": message,
		"payload": payload,
	})
	push_error("LogSystem: %s" % message)


func clear() -> void:
	entries.clear()
	log_cleared.emit()


func get_entries() -> Array:
	return entries.duplicate(true)


func _on_event_emitted(event_id: StringName, payload) -> void:
	_add_entry("event", {
		"event_id": String(event_id),
		"payload": payload,
	})


func _on_command_executed(command_id: StringName, payload, result) -> void:
	_add_entry("command", {
		"command_id": String(command_id),
		"payload": payload,
		"result": result,
	})


func _on_command_failed(command_id: StringName, payload, reason: String) -> void:
	_add_entry("command_error", {
		"command_id": String(command_id),
		"payload": payload,
		"reason": reason,
	})


func _add_entry(entry_type: String, payload: Dictionary) -> void:
	var entry := {
		"type": entry_type,
		"timestamp_unix": Time.get_unix_time_from_system(),
		"payload": payload,
	}
	entries.append(entry)
	if entries.size() > max_entries:
		entries.pop_front()

	if enable_print:
		print("LogSystem: ", entry_type, " ", payload)

	log_added.emit(entry)


func _ensure_app() -> WooApp:
	if app == null:
		app = WooApp.get_instance()
	return app
