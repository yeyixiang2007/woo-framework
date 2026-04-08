class_name InventoryView
extends Control

@onready var items_label: Label = $Panel/VBox/ItemsLabel
@onready var coins_label: Label = $Panel/VBox/CoinsLabel
@onready var add_button: Button = $Panel/VBox/Buttons/AddPotionButton
@onready var remove_button: Button = $Panel/VBox/Buttons/RemovePotionButton
@onready var grant_button: Button = $Panel/VBox/Buttons/GrantCoinsButton
@onready var purchase_button: Button = $Panel/VBox/Buttons/PurchasePotionButton

var app: WooApp
var inventory_model: InventoryModel
var currency_model: CurrencyModel


func _ready() -> void:
	app = WooApp.get_instance()
	if app == null:
		return

	add_button.pressed.connect(_on_add_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	grant_button.pressed.connect(_on_grant_pressed)
	purchase_button.pressed.connect(_on_purchase_pressed)

	inventory_model = app.models.get_model(&"inventory") as InventoryModel
	if inventory_model != null:
		inventory_model.items_changed.connect(_on_items_changed)

	currency_model = app.models.get_model(&"currency") as CurrencyModel
	if currency_model != null:
		currency_model.coins_changed.connect(_on_coins_changed)

	_refresh()


func _on_add_pressed() -> void:
	if app == null:
		return
	app.commands.execute(&"add_item", {"item_id": "potion", "amount": 1})


func _on_remove_pressed() -> void:
	if app == null:
		return
	app.commands.execute(&"remove_item", {"item_id": "potion", "amount": 1})


func _on_grant_pressed() -> void:
	if app == null:
		return
	app.commands.execute(&"grant_coins", {"amount": 10})


func _on_purchase_pressed() -> void:
	if app == null:
		return
	app.commands.execute(&"purchase_item", {"item_id": "potion", "amount": 1, "cost": 5})


func _on_items_changed(_items: Dictionary) -> void:
	_refresh_items()


func _on_coins_changed(value: int) -> void:
	_update_coins(value)


func _refresh() -> void:
	if app == null:
		return
	var result = app.queries.query(&"inventory_state")
	if result is Dictionary:
		_refresh_items_with(result.get("items", {}))
		_update_coins(int(result.get("coins", 0)))
	else:
		if inventory_model != null:
			_refresh_items_with(inventory_model.items)
		if currency_model != null:
			_update_coins(currency_model.coins)


func _refresh_items() -> void:
	if inventory_model == null:
		return
	_refresh_items_with(inventory_model.items)


func _refresh_items_with(items: Dictionary) -> void:
	items_label.text = _format_items(items)


func _update_coins(value: int) -> void:
	coins_label.text = "Coins: %d" % value


func _format_items(items: Dictionary) -> String:
	if items.is_empty():
		return "Items: (empty)"
	var lines: Array[String] = []
	for key in items.keys():
		lines.append("%s x%s" % [String(key), String(items[key])])
	lines.sort()
	return "Items: " + ", ".join(lines)
