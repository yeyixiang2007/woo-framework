@tool
extends EditorPlugin

const ICON_PATH := "res://addons/woo_framework/plugin_icon.svg"
const AUTOLOADS := {
	"WooEventBus": "res://addons/woo_framework/core/bus/event_bus.gd",
}
const LEGACY_AUTOLOADS := {
	"Woo": "res://addons/woo_framework/core/app/woo.gd",
}
const CUSTOM_TYPES := [
	{
		"name": "WooBootstrap",
		"base": "Node",
		"script": preload("res://addons/woo_framework/core/app/woo_bootstrap.gd"),
	},
	{
		"name": "UiPanelBuilder",
		"base": "Node",
		"script": preload("res://addons/woo_framework/editor/builders/ui_panel_builder.gd"),
	},
]

var _icon: Texture2D


func _enter_tree() -> void:
	_icon = load(ICON_PATH) as Texture2D
	_register_custom_types()
	_remove_legacy_autoloads()
	_ensure_autoloads()


func _exit_tree() -> void:
	_unregister_custom_types()


func _enable_plugin() -> void:
	_remove_legacy_autoloads()
	_ensure_autoloads()


func _disable_plugin() -> void:
	_remove_managed_autoloads()
	_remove_legacy_autoloads()


func _register_custom_types() -> void:
	for item in CUSTOM_TYPES:
		add_custom_type(item["name"], item["base"], item["script"], _icon)


func _unregister_custom_types() -> void:
	for index in range(CUSTOM_TYPES.size() - 1, -1, -1):
		remove_custom_type(CUSTOM_TYPES[index]["name"])


func _ensure_autoloads() -> void:
	var changed := false
	for autoload_name in AUTOLOADS.keys():
		if _ensure_autoload(autoload_name, AUTOLOADS[autoload_name]):
			changed = true
	if changed:
		ProjectSettings.save()


func _remove_managed_autoloads() -> void:
	var changed := false
	for autoload_name in AUTOLOADS.keys():
		if _remove_autoload_if_managed(autoload_name, AUTOLOADS[autoload_name]):
			changed = true
	if changed:
		ProjectSettings.save()


func _remove_legacy_autoloads() -> void:
	var changed := false
	for autoload_name in LEGACY_AUTOLOADS.keys():
		if _remove_autoload_if_managed(autoload_name, LEGACY_AUTOLOADS[autoload_name]):
			changed = true
	if changed:
		ProjectSettings.save()


func _ensure_autoload(autoload_name: String, path: String) -> bool:
	var key := "autoload/%s" % autoload_name
	if ProjectSettings.has_setting(key):
		var existing := String(ProjectSettings.get_setting(key))
		if existing == path or existing == "*" + path:
			return false
		push_warning(
			"WooFramework: autoload '%s' already exists at '%s'. Existing value is kept." % [
				autoload_name,
				existing,
			]
		)
		return false

	add_autoload_singleton(autoload_name, path)
	return true


func _remove_autoload_if_managed(autoload_name: String, managed_path: String) -> bool:
	var key := "autoload/%s" % autoload_name
	if not ProjectSettings.has_setting(key):
		return false

	var existing := String(ProjectSettings.get_setting(key))
	if existing != managed_path and existing != "*" + managed_path:
		push_warning(
			"WooFramework: autoload '%s' points to '%s', so it was not removed automatically." % [
				autoload_name,
				existing,
			]
		)
		return false

	remove_autoload_singleton(autoload_name)
	return true
