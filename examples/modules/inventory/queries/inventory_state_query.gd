class_name InventoryStateQuery
extends RefCounted


func execute(context: QueryContext, _payload):
	if context == null:
		return {}

	var inventory: InventoryModel = context.get_model(&"inventory") as InventoryModel
	var currency: CurrencyModel = context.get_model(&"currency") as CurrencyModel
	var items_payload: Dictionary = {}
	var coins_value := 0

	if inventory != null:
		items_payload = inventory.items.duplicate(true)
	if currency != null:
		coins_value = currency.coins

	return {
		"items": items_payload,
		"coins": coins_value,
	}
