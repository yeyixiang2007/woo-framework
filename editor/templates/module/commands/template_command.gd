class_name TemplateCommand
extends RefCounted


func execute(context: CommandContext, payload):
	if context == null:
		return null

	var model: TemplateModel = context.get_model(&"template") as TemplateModel
	if model == null:
		return null

	var amount := _read_int(payload, "amount", 1)
	var result : int = model.increment(amount)
	context.emit_event(&"template_changed", [result])
	return result


func _read_int(payload, key: String, default_value: int) -> int:
	if payload is Dictionary and payload.has(key):
		return int(payload[key])
	if payload is int:
		return int(payload)
	return default_value
