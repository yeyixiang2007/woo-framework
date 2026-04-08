class_name WooTaskCompletionSource
extends RefCounted

var task: WooTask = WooTask.new()


func resolve(result = null) -> bool:
	return task.resolve(result)


func fail(error = null) -> bool:
	return task.fail(error)


func cancel(reason := "") -> bool:
	return task.cancel(reason)
