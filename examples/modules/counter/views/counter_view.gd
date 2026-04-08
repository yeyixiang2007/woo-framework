class_name CounterView
extends Control

@onready var count_label: Label = $Panel/VBox/CountLabel
@onready var increment_button: Button = $Panel/VBox/Buttons/IncrementButton
@onready var reset_button: Button = $Panel/VBox/Buttons/ResetButton

var app: WooApp
var model: CounterModel


func _ready() -> void:
	app = WooApp.get_instance()
	if app == null:
		return

	increment_button.pressed.connect(_on_increment_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	model = app.models.get_model(&"counter") as CounterModel
	if model != null:
		model.count_changed.connect(_on_count_changed)

	_refresh()


func _on_increment_pressed() -> void:
	if app == null:
		return
	app.commands.execute(&"increment_counter", {"amount": 1})


func _on_reset_pressed() -> void:
	if app == null:
		return
	app.commands.execute(&"reset_counter")


func _on_count_changed(value: int) -> void:
	_update_label(value)


func _refresh() -> void:
	if app == null:
		return
	var result = app.queries.query(&"counter_state")
	if result is Dictionary:
		_update_label(int(result.get("count", 0)))
	elif model != null:
		_update_label(model.count)


func _update_label(value: int) -> void:
	if count_label == null:
		return
	count_label.text = "Count: %d" % value
