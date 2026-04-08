class_name ModelStore
extends RefCounted

signal model_registered(id: StringName)
signal model_built(id: StringName, instance: Resource)
signal model_replaced(id: StringName, instance: Resource)

var app
var model_definitions: Dictionary = {}
var model_instances: Dictionary = {}


func _init(owner_app = null) -> void:
	app = owner_app


func register_definition(
	id: StringName,
	script_ref: Variant,
	default_resource: Variant = null,
	owner_module_id: StringName = &""
) -> bool:
	var normalized_id := _normalize_id(id)
	if normalized_id == &"":
		push_error("ModelStore: model ID cannot be empty.")
		return false

	var script := _resolve_script(script_ref)
	if script == null:
		push_error("ModelStore: model script is invalid for '%s'." % String(normalized_id))
		return false

	if model_definitions.has(normalized_id):
		push_error("ModelStore: duplicate model ID '%s'." % String(normalized_id))
		return false

	var default_instance := _resolve_resource(default_resource)
	model_definitions[normalized_id] = {
		"id": normalized_id,
		"script": script,
		"script_path": script.resource_path,
		"default_resource": default_instance,
		"default_resource_path": "" if default_instance == null else default_instance.resource_path,
		"module_id": owner_module_id,
	}

	model_registered.emit(normalized_id)
	return true


func has_model(id: StringName) -> bool:
	return model_definitions.has(_normalize_id(id))


func get_model_ids() -> Array:
	var ids: Array = model_definitions.keys()
	ids.sort_custom(func(a, b): return String(a) < String(b))
	return ids


func get_model(id: StringName) -> Resource:
	var normalized_id := _normalize_id(id)
	if model_instances.has(normalized_id):
		return model_instances[normalized_id]

	if not model_definitions.has(normalized_id):
		push_error("ModelStore: unknown model ID '%s'." % String(normalized_id))
		return null

	var definition: Dictionary = model_definitions[normalized_id]
	var instance = _build_instance(definition)
	if instance == null:
		push_error("ModelStore: failed to build model '%s'." % String(normalized_id))
		return null

	model_instances[normalized_id] = instance
	model_built.emit(normalized_id, instance)
	return instance


func set_model(id: StringName, instance: Resource) -> bool:
	var normalized_id := _normalize_id(id)
	if instance == null:
		push_error("ModelStore: cannot set a null model instance for '%s'." % String(normalized_id))
		return false

	model_instances[normalized_id] = instance
	model_replaced.emit(normalized_id, instance)
	return true


func get_definition(id: StringName) -> Dictionary:
	var normalized_id := _normalize_id(id)
	if not model_definitions.has(normalized_id):
		return {}
	return model_definitions[normalized_id].duplicate(true)


func clear() -> void:
	model_definitions.clear()
	model_instances.clear()


func _build_instance(definition: Dictionary) -> Resource:
	var default_instance: Resource = definition.get("default_resource")
	if default_instance != null:
		return default_instance.duplicate(true)

	var script: Script = definition.get("script")
	if script == null:
		return null

	var instance = script.new()
	if instance is Resource:
		return instance

	push_error("ModelStore: model script must create a Resource instance.")
	return null


func _resolve_script(script_ref: Variant) -> Script:
	if script_ref == null:
		return null
	if script_ref is Script:
		return script_ref
	if script_ref is String:
		var loaded := load(script_ref)
		if loaded is Script:
			return loaded
	return null


func _resolve_resource(resource_ref: Variant) -> Resource:
	if resource_ref == null:
		return null
	if resource_ref is Resource:
		return resource_ref
	if resource_ref is String:
		var loaded := load(resource_ref)
		if loaded is Resource:
			return loaded
	return null


func _normalize_id(value: Variant) -> StringName:
	var string_value := String(value).strip_edges()
	if string_value.is_empty():
		return &""
	return StringName(string_value)
