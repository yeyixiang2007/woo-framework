class_name ModuleContext
extends RefCounted

var app
var registry
var module: ModuleDefinition
var module_id: StringName = &""
var phase := "created"


func _init(owner_app = null, owner_registry = null, owner_module: ModuleDefinition = null) -> void:
	app = owner_app
	registry = owner_registry
	module = owner_module
	if module != null:
		module_id = module.get_module_id()


func set_phase(value: String) -> void:
	phase = value


func set_state(key: StringName, value: Variant) -> void:
	if app == null:
		return
	app.set_state_value(key, value)


func get_state(key: StringName, default_value: Variant = null) -> Variant:
	if app == null:
		return default_value
	return app.get_state_value(key, default_value)


func get_registered_entries() -> Dictionary:
	if registry == null:
		return {}
	return registry.get_registrations_for_module(module_id)


func get_dependency_ids() -> PackedStringArray:
	if module == null:
		return PackedStringArray()
	return module.get_dependencies()
