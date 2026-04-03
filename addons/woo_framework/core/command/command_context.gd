class_name CommandContext
extends RefCounted

var app
var models: ModelStore
var events: EventBus
var queries: QueryService
var command_id: StringName = &""
var payload
var metadata: Dictionary = {}


func _init(
	owner_app = null,
	owner_models: ModelStore = null,
	owner_events: EventBus = null,
	owner_queries: QueryService = null,
	owner_command_id: StringName = &"",
	command_payload = null
) -> void:
	app = owner_app
	models = owner_models
	events = owner_events
	queries = owner_queries
	command_id = owner_command_id
	payload = command_payload


func get_model(id: StringName) -> Resource:
	if models == null:
		return null
	return models.get_model(id)


func set_state(key: StringName, value: Variant) -> void:
	if app == null:
		return
	app.set_state_value(key, value)


func get_state(key: StringName, default_value: Variant = null) -> Variant:
	if app == null:
		return default_value
	return app.get_state_value(key, default_value)


func emit_event(event_id: StringName, args: Array = []) -> void:
	if events == null:
		return
	events.emit_event(event_id, args)
