class_name GrantCoinsCommand
extends RefCounted


func execute(context: CommandContext, payload):
	if context == null:
		return null

	var model: CurrencyModel = context.get_model(&"currency") as CurrencyModel
	if model == null:
		return null

	var amount := _read_int(payload, "amount", 1)
	var result := model.add_coins(amount)
	context.emit_event(&"coins_granted", [amount, result])
	return result


func _read_int(payload, key: String, default_value: int) -> int:
	if payload is Dictionary and payload.has(key):
		return int(payload[key])
	if payload is int:
		return int(payload)
	return default_value
