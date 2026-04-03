class_name IncrementCounterCommand
extends RefCounted


func execute(context: CommandContext, payload):
	if context == null:
		return null

	var amount := _read_int(payload, "amount", 1)
	var model: CounterModel = context.get_model(&"counter") as CounterModel
	if model == null:
		return null

	var result := model.increment(amount)
	context.emit_event(&"counter_changed", [result])
	return result


func _read_int(payload, key: String, default_value: int) -> int:
	if payload is Dictionary and payload.has(key):
		return int(payload[key])
	if payload is int:
		return int(payload)
	return default_value
