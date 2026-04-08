class_name WooCancellationToken
extends RefCounted

signal canceled(reason: String)

var _is_canceled := false
var _reason := ""


func is_canceled() -> bool:
	return _is_canceled


func get_reason(default_value := "") -> String:
	if _is_canceled:
		return _reason
	return default_value


func _cancel(reason := "") -> bool:
	if _is_canceled:
		return false

	_is_canceled = true
	_reason = reason
	canceled.emit(reason)
	return true
