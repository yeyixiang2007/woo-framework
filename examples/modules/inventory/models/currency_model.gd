class_name CurrencyModel
extends Resource

signal coins_changed(value: int)

var _coins := 0

@export var coins: int:
	set(value):
		if _coins == value:
			return
		_coins = value
		coins_changed.emit(_coins)
	get:
		return _coins


func add_coins(amount: int) -> int:
	if amount <= 0:
		return _coins
	coins = _coins + amount
	return _coins


func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if _coins < amount:
		return false
	coins = _coins - amount
	return true
