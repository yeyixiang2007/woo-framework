class_name ControllerTemplate
extends "res://addons/woo_framework/core/presentation/controller_base.gd"

@export var scene_root_path: NodePath
@onready var scene_root: Node = get_node_or_null(scene_root_path)


func on_app_ready(_app: WooApp) -> void:
	pass


func bind() -> void:
	super()


func unbind() -> void:
	super()
