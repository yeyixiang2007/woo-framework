class_name ModuleDefinition
extends RefCounted

const DEFAULT_MODULE_VERSION := "0.1.0"


func get_module_id() -> StringName:
	push_error("ModuleDefinition.get_module_id() must be overridden.")
	return &""


func get_module_name() -> String:
	return String(get_module_id())


func get_module_version() -> String:
	return DEFAULT_MODULE_VERSION


func get_description() -> String:
	return ""


func get_dependencies() -> PackedStringArray:
	return PackedStringArray()


func is_enabled_by_default() -> bool:
	return true


func register(_registrar) -> void:
	pass


func initialize(_context) -> void:
	pass


func ready(_context) -> void:
	pass


func shutdown(_context) -> void:
	pass
