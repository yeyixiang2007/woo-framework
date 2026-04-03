class_name AddItemCommand
extends RefCounted


func execute(context: CommandContext, payload):
	if context == null:
		return null

	var model: InventoryModel = context.get_model(&"inventory") as InventoryModel
	if model == null:
		return null

	var item_id := _read_string(payload, "item_id", "potion")
	var amount := _read_int(payload, "amount", 1)
	var success := model.add_item(item_id, amount)
	if success:
		context.emit_event(&"inventory_item_added", [item_id, amount])
	return model.items.duplicate(true)


func _read_string(payload, key: String, default_value: String) -> String:
	if payload is Dictionary and payload.has(key):
		return String(payload[key])
	if payload is String:
		return payload
	return default_value


func _read_int(payload, key: String, default_value: int) -> int:
	if payload is Dictionary and payload.has(key):
		return int(payload[key])
	if payload is int:
		return int(payload)
	return default_value
