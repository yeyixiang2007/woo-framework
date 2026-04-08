class_name TemplateStateQuery
extends RefCounted


func execute(context: QueryContext, _payload):
	if context == null:
		return {}

	var model: TemplateModel = context.get_model(&"template") as TemplateModel
	if model == null:
		return {
			"value": 0,
		}

	return {
		"value": model.value,
	}
