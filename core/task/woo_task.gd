class_name WooTask
extends RefCounted

signal completed(result)
signal failed(error)
signal canceled(reason: String)
signal finished(task: WooTask)

enum Status {
	PENDING,
	SUCCEEDED,
	FAILED,
	CANCELED,
}

var metadata: Dictionary = {}
var _status := Status.PENDING
var _result = null
var _error = null
var _cancel_reason := ""


func get_status() -> int:
	return _status


func get_status_name() -> String:
	match _status:
		Status.SUCCEEDED:
			return "succeeded"
		Status.FAILED:
			return "failed"
		Status.CANCELED:
			return "canceled"
		_:
			return "pending"


func is_pending() -> bool:
	return _status == Status.PENDING


func is_succeeded() -> bool:
	return _status == Status.SUCCEEDED


func is_completed() -> bool:
	return is_succeeded()


func is_failed() -> bool:
	return _status == Status.FAILED


func is_canceled() -> bool:
	return _status == Status.CANCELED


func is_finished() -> bool:
	return _status != Status.PENDING


func get_result(default_value = null):
	if is_succeeded():
		return _result
	return default_value


func get_error(default_value = null):
	if is_failed():
		return _error
	return default_value


func get_cancel_reason(default_value := "") -> String:
	if is_canceled():
		return _cancel_reason
	return default_value


func resolve(result = null) -> bool:
	if not is_pending():
		return false

	_status = Status.SUCCEEDED
	_result = result
	completed.emit(result)
	finished.emit(self)
	return true


func fail(error = null) -> bool:
	if not is_pending():
		return false

	_status = Status.FAILED
	_error = error
	failed.emit(error)
	finished.emit(self)
	return true


func cancel(reason := "") -> bool:
	if not is_pending():
		return false

	_status = Status.CANCELED
	_cancel_reason = reason
	canceled.emit(reason)
	finished.emit(self)
	return true


func to_snapshot() -> Dictionary:
	return {
		"status": get_status_name(),
		"result": _result,
		"error": _error,
		"cancel_reason": _cancel_reason,
		"metadata": metadata.duplicate(true),
	}
