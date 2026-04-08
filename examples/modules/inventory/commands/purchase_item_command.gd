class_name PurchaseItemCommand
extends RefCounted

const DEFAULT_COST := 5


func execute(context: CommandContext, payload):
	if context == null:
		return false

	var inventory: InventoryModel = context.get_model(&"inventory") as InventoryModel
	var currency: CurrencyModel = context.get_model(&"currency") as CurrencyModel
	if inventory == null or currency == null:
		return false

	var item_id := _read_string(payload, "item_id", "potion")
	var amount: int = maxi(_read_int(payload, "amount", 1), 1)
	var cost: int = _read_int(payload, "cost", DEFAULT_COST)
	var total_cost: int = cost * amount

	if not currency.spend_coins(total_cost):
		context.emit_event(&"purchase_failed", [item_id, total_cost, currency.coins])
		return false

	inventory.add_item(item_id, amount)
	context.emit_event(&"item_purchased", [item_id, amount, total_cost, currency.coins])
	return true


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
