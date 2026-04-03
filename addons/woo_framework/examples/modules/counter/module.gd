class_name CounterModule
extends ModuleDefinition

const MODULE_ID := &"counter"
const MODULE_NAME := "Counter"
const MODULE_VERSION := "0.1.0"
const MODULE_DESCRIPTION := "Minimal counter example module."
const MODULE_DEPENDENCIES := []


func get_module_id() -> StringName:
	return MODULE_ID


func get_module_name() -> String:
	return MODULE_NAME


func get_module_version() -> String:
	return MODULE_VERSION


func get_description() -> String:
	return MODULE_DESCRIPTION


func get_dependencies() -> PackedStringArray:
	return PackedStringArray(MODULE_DEPENDENCIES)


func register(registrar) -> void:
	registrar.register_model(
		&"counter",
		preload("res://addons/woo_framework/examples/modules/counter/models/counter_model.gd"),
		preload("res://addons/woo_framework/examples/modules/counter/models/default_counter_model.tres")
	)
	registrar.register_command(
		&"increment_counter",
		preload("res://addons/woo_framework/examples/modules/counter/commands/increment_counter_command.gd")
	)
	registrar.register_command(
		&"reset_counter",
		preload("res://addons/woo_framework/examples/modules/counter/commands/reset_counter_command.gd")
	)
	registrar.register_query(
		&"counter_state",
		preload("res://addons/woo_framework/examples/modules/counter/queries/counter_state_query.gd")
	)
	registrar.register_metadata(&"category", "example")
	registrar.register_metadata(
		&"scene_path",
		"res://addons/woo_framework/examples/modules/counter/scenes/counter_scene.tscn"
	)
