class_name InventoryModel
extends Resource

signal items_changed(items: Dictionary)

@export var capacity: int = 20
@export var items: Dictionary = {}


func add_item(item_id: StringName, amount: int = 1) -> bool:
	var key := _normalize_item_id(item_id)
	if key == "":
		return false
	if amount <= 0:
		return false

	var current := int(items.get(key, 0))
	items[key] = current + amount
	items_changed.emit(items)
	return true


func remove_item(item_id: StringName, amount: int = 1) -> bool:
	var key := _normalize_item_id(item_id)
	if key == "":
		return false
	if amount <= 0:
		return false
	if not items.has(key):
		return false

	var current := int(items.get(key, 0)) - amount
	if current <= 0:
		items.erase(key)
	else:
		items[key] = current
	items_changed.emit(items)
	return true


func clear_items() -> void:
	items.clear()
	items_changed.emit(items)


func _normalize_item_id(value: Variant) -> String:
	return String(value).strip_edges()
