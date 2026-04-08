class_name CounterModel
extends Resource

signal count_changed(value: int)

var _count := 0

@export var count: int:
	set(value):
		if _count == value:
			return
		_count = value
		count_changed.emit(_count)
	get:
		return _count


func reset() -> void:
	count = 0


func increment(amount: int = 1) -> int:
	count = _count + amount
	return _count
