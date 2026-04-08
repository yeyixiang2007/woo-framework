class_name ViewBase
extends Control

var app: WooApp
var presenter: Node


func _ready() -> void:
	_attach_app()
	on_view_ready()


func set_presenter(presenter_instance: Node) -> void:
	presenter = presenter_instance
	if presenter != null and presenter.has_method("set_view"):
		presenter.call("set_view", self)


func on_view_ready() -> void:
	pass


func _attach_app() -> void:
	if app == null:
		app = Woo.get_app()
	if app == null:
		app = WooApp.get_instance()
