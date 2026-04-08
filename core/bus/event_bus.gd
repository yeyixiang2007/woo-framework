class_name EventBus
extends Node

signal event_declared(event_id: StringName)
signal listener_added(event_id: StringName)
signal listener_removed(event_id: StringName)
signal event_emitted(event_id: StringName, payload)

var app
var enable_logging := false
var declared_events: Dictionary = {}
var listeners: Dictionary = {}
var once_listeners: Dictionary = {}


func _init(owner_app = null) -> void:
	app = owner_app


func declare_event(event_id: StringName) -> void:
	var normalized := _normalize_id(event_id)
	if normalized == &"":
		return
	if declared_events.has(normalized):
		return
	declared_events[normalized] = true
	event_declared.emit(normalized)


func has_event(event_id: StringName) -> bool:
	return declared_events.has(_normalize_id(event_id))


func on(event_id: StringName, listener: Callable) -> void:
	if not _ensure_listener(event_id, listener, listeners):
		return
	listener_added.emit(_normalize_id(event_id))


func once(event_id: StringName, listener: Callable) -> void:
	if not _ensure_listener(event_id, listener, once_listeners):
		return
	listener_added.emit(_normalize_id(event_id))


func off(event_id: StringName, listener: Callable) -> void:
	var normalized := _normalize_id(event_id)
	_remove_listener(normalized, listener, listeners)
	_remove_listener(normalized, listener, once_listeners)
	listener_removed.emit(normalized)


func emit_event(event_id: StringName, args: Array = []) -> void:
	var normalized := _normalize_id(event_id)
	if normalized == &"":
		return

	if enable_logging:
		print("EventBus emit: ", normalized, " args=", args)

	_event_call(normalized, listeners, args)
	_event_call(normalized, once_listeners, args, true)
	event_emitted.emit(normalized, args)


func clear() -> void:
	declared_events.clear()
	listeners.clear()
	once_listeners.clear()


func _event_call(event_id: StringName, bucket: Dictionary, args: Array, consume := false) -> void:
	if not bucket.has(event_id):
		return

	var current_list: Array = bucket[event_id].duplicate()
	for listener in current_list:
		if not (listener is Callable) or not listener.is_valid():
			continue
		listener.callv(args)

	if consume:
		bucket.erase(event_id)


func _ensure_listener(event_id: StringName, listener: Callable, bucket: Dictionary) -> bool:
	var normalized := _normalize_id(event_id)
	if normalized == &"":
		return false
	if listener == null or not listener.is_valid():
		return false

	if not bucket.has(normalized):
		bucket[normalized] = []
	var list: Array = bucket[normalized]
	if not list.has(listener):
		list.append(listener)
	bucket[normalized] = list
	return true


func _remove_listener(event_id: StringName, listener: Callable, bucket: Dictionary) -> void:
	if not bucket.has(event_id):
		return
	var list: Array = bucket[event_id]
	list.erase(listener)
	if list.is_empty():
		bucket.erase(event_id)
	else:
		bucket[event_id] = list


func _normalize_id(value: Variant) -> StringName:
	var string_value := String(value).strip_edges()
	if string_value.is_empty():
		return &""
	return StringName(string_value)
