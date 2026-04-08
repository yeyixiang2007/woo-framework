class_name SystemRegistry
extends RefCounted

signal system_registered(system_id: StringName)
signal system_built(system_id: StringName, instance: Object)
signal system_replaced(system_id: StringName, instance: Object)

var app
var definitions: Dictionary = {}
var instances: Dictionary = {}


func _init(owner_app = null) -> void:
	app = owner_app


func register_definition(id: StringName, script_ref: Variant, owner_module_id: StringName = &"") -> bool:
	var normalized_id := _normalize_id(id)
	if normalized_id == &"":
		push_error("SystemRegistry: system ID cannot be empty.")
		return false

	if definitions.has(normalized_id):
		push_error("SystemRegistry: duplicate system ID '%s'." % String(normalized_id))
		return false

	var script := _resolve_script(script_ref)
	if script == null:
		push_error("SystemRegistry: invalid system script for '%s'." % String(normalized_id))
		return false

	definitions[normalized_id] = {
		"id": normalized_id,
		"script": script,
		"script_path": script.resource_path,
		"module_id": owner_module_id,
	}

	system_registered.emit(normalized_id)
	return true


func has_system(id: StringName) -> bool:
	return definitions.has(_normalize_id(id))


func get_system(id: StringName) -> Object:
	var normalized_id := _normalize_id(id)
	if instances.has(normalized_id):
		return instances[normalized_id]

	if not definitions.has(normalized_id):
		push_error("SystemRegistry: unknown system ID '%s'." % String(normalized_id))
		return null

	var definition: Dictionary = definitions[normalized_id]
	var instance = definition["script"].new()
	_bind_app_if_supported(instance)
	instances[normalized_id] = instance
	system_built.emit(normalized_id, instance)
	return instance


func set_system(id: StringName, instance: Object) -> bool:
	var normalized_id := _normalize_id(id)
	if instance == null:
		push_error("SystemRegistry: cannot set a null system instance for '%s'." % String(normalized_id))
		return false

	_bind_app_if_supported(instance)
	instances[normalized_id] = instance
	system_replaced.emit(normalized_id, instance)
	return true


func clear() -> void:
	definitions.clear()
	instances.clear()


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


func _normalize_id(value: Variant) -> StringName:
	var string_value := String(value).strip_edges()
	if string_value.is_empty():
		return &""
	return StringName(string_value)


func _bind_app_if_supported(instance: Object) -> void:
	if instance == null or app == null:
		return
	if instance.has_method("set_app"):
		instance.call("set_app", app)
		return
	# Fallback for lightweight systems that expose a writable `app` property.
	for property_info in instance.get_property_list():
		if String(property_info.get("name", "")) == "app":
			instance.set("app", app)
			return
