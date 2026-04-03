class_name CounterStateQuery
extends RefCounted


func execute(context: QueryContext, _payload):
	if context == null:
		return {}
	var model: CounterModel = context.get_model(&"counter") as CounterModel
	if model == null:
		return {
			"count": 0,
		}
	return {
		"count": model.count,
	}
