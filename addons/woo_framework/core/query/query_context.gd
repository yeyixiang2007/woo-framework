class_name QueryContext
extends RefCounted

var app
var models: ModelStore
var query_id: StringName = &""
var payload


func _init(owner_app = null, owner_models: ModelStore = null, owner_query_id: StringName = &"", query_payload = null) -> void:
	app = owner_app
	models = owner_models
	query_id = owner_query_id
	payload = query_payload


func get_model(id: StringName) -> Resource:
	if models == null:
		return null
	return models.get_model(id)


func get_state(key: StringName, default_value: Variant = null) -> Variant:
	if app == null:
		return default_value
	return app.get_state_value(key, default_value)
