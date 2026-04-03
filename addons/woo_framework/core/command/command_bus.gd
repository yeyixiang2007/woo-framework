class_name CommandBus
extends RefCounted

signal command_registered(command_id: StringName)
signal command_executed(command_id: StringName, payload, result)
signal command_failed(command_id: StringName, payload, reason: String)

var app
var definitions: Dictionary = {}
var enable_logging := false


func _init(owner_app = null) -> void:
	app = owner_app


func register_definition(id: StringName, handler_ref: Variant, owner_module_id: StringName = &"") -> bool:
	var normalized_id := _normalize_id(id)
	if normalized_id == &"":
		_fail(normalized_id, null, "Command ID cannot be empty.")
		return false

	if definitions.has(normalized_id):
		_fail(normalized_id, null, "Duplicate command ID '%s'." % String(normalized_id))
		return false

	var definition: Dictionary = _resolve_handler(handler_ref)
	if definition.is_empty():
		_fail(normalized_id, null, "Invalid handler for command '%s'." % String(normalized_id))
		return false

	definition["id"] = normalized_id
	definition["module_id"] = owner_module_id
	definitions[normalized_id] = definition
	command_registered.emit(normalized_id)
	return true


func execute(command_id: StringName, payload = null, context_override: CommandContext = null):
	var normalized_id := _normalize_id(command_id)
	if not definitions.has(normalized_id):
		_fail(normalized_id, payload, "Unknown command '%s'." % String(normalized_id))
		return null

	var definition: Dictionary = definitions[normalized_id]
	var context := context_override
	if context == null:
		context = CommandContext.new(app, app.models, app.events, app.queries, normalized_id, payload)

	var result = null
	match definition.get("type"):
		"callable":
			result = definition["handler"].callv([context, payload])
		"script":
			var instance = definition["handler"].new()
			if instance.has_method("execute"):
				result = instance.execute(context, payload)
			else:
				_fail(normalized_id, payload, "Command script missing execute(context, payload).")
				return null
		"object":
			var instance_obj = definition["handler"]
			if instance_obj != null and instance_obj.has_method("execute"):
				result = instance_obj.execute(context, payload)
			else:
				_fail(normalized_id, payload, "Command object missing execute(context, payload).")
				return null
		_:
			_fail(normalized_id, payload, "Unsupported command handler type.")
			return null

	if enable_logging:
		print("CommandBus executed: ", normalized_id)
	command_executed.emit(normalized_id, payload, result)
	return result


func has_command(id: StringName) -> bool:
	return definitions.has(_normalize_id(id))


func clear() -> void:
	definitions.clear()


func _resolve_handler(handler_ref: Variant) -> Dictionary:
	if handler_ref == null:
		return {}

	if handler_ref is Callable:
		return {
			"type": "callable",
			"handler": handler_ref,
		}

	if handler_ref is Script:
		return {
			"type": "script",
			"handler": handler_ref,
			"script_path": handler_ref.resource_path,
		}

	if handler_ref is String:
		var loaded := load(handler_ref)
		if loaded is Script:
			return {
				"type": "script",
				"handler": loaded,
				"script_path": loaded.resource_path,
			}

	if handler_ref is Object:
		return {
			"type": "object",
			"handler": handler_ref,
		}

	return {}


func _normalize_id(value: Variant) -> StringName:
	var string_value := String(value).strip_edges()
	if string_value.is_empty():
		return &""
	return StringName(string_value)


func _fail(command_id: StringName, payload, reason: String) -> void:
	push_error("CommandBus: %s" % reason)
	command_failed.emit(command_id, payload, reason)
