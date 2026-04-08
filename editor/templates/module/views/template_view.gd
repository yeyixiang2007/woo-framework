class_name TemplateView
extends "res://addons/woo_framework/core/presentation/view_base.gd"

@onready var value_label: Label = $Panel/VBox/ValueLabel
@onready var increment_button: Button = $Panel/VBox/Buttons/IncrementButton


func on_view_ready() -> void:
	if increment_button != null:
		increment_button.pressed.connect(_on_increment_pressed)
	_refresh()


func _on_increment_pressed() -> void:
	if app == null:
		return
	app.commands.execute(&"template_command", {"amount": 1})
	_refresh()


func _refresh() -> void:
	if app == null:
		return
	var result = app.queries.query(&"template_state")
	if result is Dictionary and value_label != null:
		value_label.text = "Value: %d" % int(result.get("value", 0))
