class_name PresenterTemplate
extends "res://addons/woo_framework/core/presentation/presenter_base.gd"

@export var view_path: NodePath
@onready var bound_view: Node = get_node_or_null(view_path)


func on_app_ready(_app: WooApp) -> void:
	if bound_view != null:
		set_view(bound_view)


func on_view_ready(_view: Node) -> void:
	pass


func bind() -> void:
	super()


func unbind() -> void:
	super()
