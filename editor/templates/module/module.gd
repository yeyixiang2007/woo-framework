class_name TemplateModule
extends ModuleDefinition

# TODO: Rename class_name, MODULE_ID, and resource paths after copying.
const MODULE_ID := &"template_module"
const MODULE_NAME := "Template Module"
const MODULE_VERSION := "0.1.0"
const MODULE_DESCRIPTION := "Template module for new features."
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
		&"template",
		preload("res://addons/woo_framework/editor/templates/module/models/template_model.gd"),
		preload("res://addons/woo_framework/editor/templates/module/models/default_template_model.tres")
	)
	registrar.register_command(
		&"template_command",
		preload("res://addons/woo_framework/editor/templates/module/commands/template_command.gd")
	)
	registrar.register_query(
		&"template_state",
		preload("res://addons/woo_framework/editor/templates/module/queries/template_state_query.gd")
	)
	registrar.register_metadata(&"category", "template")
