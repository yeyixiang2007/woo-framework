class_name ModuleRegistrar
extends RefCounted

var app
var registry
var module_id: StringName = &""


func _init(owner_app = null, owner_registry = null, owner_module_id: StringName = &"") -> void:
	app = owner_app
	registry = owner_registry
	module_id = owner_module_id


func register_model(id: StringName, script_ref: Variant, default_resource: Variant = null) -> bool:
	if registry == null:
		return false
	return registry.register_model_definition(module_id, id, script_ref, default_resource)


func register_command(id: StringName, script_ref: Variant) -> bool:
	if registry == null:
		return false
	return registry.register_command_definition(module_id, id, script_ref)


func register_query(id: StringName, script_ref: Variant) -> bool:
	if registry == null:
		return false
	return registry.register_query_definition(module_id, id, script_ref)


func register_system(id: StringName, script_ref: Variant) -> bool:
	if registry == null:
		return false
	return registry.register_system_definition(module_id, id, script_ref)


func register_metadata(key: StringName, value: Variant) -> bool:
	if registry == null:
		return false
	return registry.register_module_metadata(module_id, key, value)
