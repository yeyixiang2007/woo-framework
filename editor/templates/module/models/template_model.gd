class_name TemplateModel
extends Resource

signal value_changed(value: int)

var _value := 0

@export var value: int:
	set(new_value):
		if _value == new_value:
			return
		_value = new_value
		value_changed.emit(_value)
	get:
		return _value


func reset() -> void:
	value = 0


func increment(amount: int = 1) -> int:
	value = _value + amount
	return _value
