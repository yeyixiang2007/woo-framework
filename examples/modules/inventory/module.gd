class_name InventoryModule
extends ModuleDefinition

const MODULE_ID := &"inventory"
const MODULE_NAME := "Inventory"
const MODULE_VERSION := "0.1.0"
const MODULE_DESCRIPTION := "Inventory example with multiple models and commands."
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
		&"inventory",
		preload("res://addons/woo_framework/examples/modules/inventory/models/inventory_model.gd"),
		preload("res://addons/woo_framework/examples/modules/inventory/models/default_inventory_model.tres")
	)
	registrar.register_model(
		&"currency",
		preload("res://addons/woo_framework/examples/modules/inventory/models/currency_model.gd"),
		preload("res://addons/woo_framework/examples/modules/inventory/models/default_currency_model.tres")
	)
	registrar.register_command(
		&"add_item",
		preload("res://addons/woo_framework/examples/modules/inventory/commands/add_item_command.gd")
	)
	registrar.register_command(
		&"remove_item",
		preload("res://addons/woo_framework/examples/modules/inventory/commands/remove_item_command.gd")
	)
	registrar.register_command(
		&"grant_coins",
		preload("res://addons/woo_framework/examples/modules/inventory/commands/grant_coins_command.gd")
	)
	registrar.register_command(
		&"purchase_item",
		preload("res://addons/woo_framework/examples/modules/inventory/commands/purchase_item_command.gd")
	)
	registrar.register_query(
		&"inventory_state",
		preload("res://addons/woo_framework/examples/modules/inventory/queries/inventory_state_query.gd")
	)
	registrar.register_metadata(&"category", "example")
	registrar.register_metadata(
		&"scene_path",
		"res://addons/woo_framework/examples/modules/inventory/scenes/inventory_scene.tscn"
	)
