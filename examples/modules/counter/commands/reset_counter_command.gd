class_name ResetCounterCommand
extends RefCounted


func execute(context: CommandContext, _payload):
	if context == null:
		return null

	var model: CounterModel = context.get_model(&"counter") as CounterModel
	if model == null:
		return null

	model.reset()
	context.emit_event(&"counter_reset", [model.count])
	return model.count
