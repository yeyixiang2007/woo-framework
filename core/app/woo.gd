extends Node

static var app: WooApp


static func set_app(instance: WooApp) -> void:
	app = instance


static func clear_app() -> void:
	app = null


static func get_app() -> WooApp:
	return app
