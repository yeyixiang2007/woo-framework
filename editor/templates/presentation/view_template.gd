class_name ViewTemplate
extends "res://addons/woo_framework/core/presentation/view_base.gd"

@export var presenter_path: NodePath
@onready var bound_presenter: Node = get_node_or_null(presenter_path)


func on_view_ready() -> void:
	if bound_presenter != null:
		set_presenter(bound_presenter)
