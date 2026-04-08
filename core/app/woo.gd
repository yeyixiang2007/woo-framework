class_name Woo
extends Node

static func set_app(instance: WooApp) -> void:
	WooApp.set_instance(instance)


static func clear_app() -> void:
	WooApp.clear_instance()


static func get_app() -> WooApp:
	return WooApp.get_instance()
