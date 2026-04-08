class_name ConfigSystem
extends RefCounted

signal config_registered(config_id: StringName)
signal config_loaded(config_id: StringName, resource: Resource)
signal config_cleared(config_id: StringName)

var app
var enable_logging := false
var configs: Dictionary = {}
var config_paths: Dictionary = {}


func _init(owner_app = null) -> void:
	app = owner_app


func set_app(owner_app) -> void:
	app = owner_app


func register_config(config_id: StringName, config_ref: Variant) -> bool:
	var normalized := _normalize_id(config_id)
	if normalized == &"":
		push_error("ConfigSystem: config ID cannot be empty.")
		return false

	if config_ref == null:
		push_error("ConfigSystem: config reference is null for '%s'." % String(normalized))
		return false

	if config_ref is Resource:
		configs[normalized] = config_ref
		config_paths.erase(normalized)
		config_registered.emit(normalized)
		if enable_logging:
			print("ConfigSystem registered: ", normalized)
		return true

	if config_ref is String:
		var path := String(config_ref)
		config_paths[normalized] = path
		config_registered.emit(normalized)
		if enable_logging:
			print("ConfigSystem registered: ", normalized)
		return true

	if config_ref is Script:
		var instance = config_ref.new()
		if instance is Resource:
			configs[normalized] = instance
			config_paths.erase(normalized)
			config_registered.emit(normalized)
			if enable_logging:
				print("ConfigSystem registered: ", normalized)
			return true

	push_error("ConfigSystem: unsupported config reference for '%s'." % String(normalized))
	return false


func preload_config(config_id: StringName, config_path: String) -> Resource:
	register_config(config_id, config_path)
	return get_config(config_id)


func get_config(config_id: StringName) -> Resource:
	var normalized := _normalize_id(config_id)
	if normalized == &"":
		return null
	if configs.has(normalized):
		return configs[normalized]

	if config_paths.has(normalized):
		var path := String(config_paths[normalized])
		if path != "":
			var loaded := load(path)
			if loaded is Resource:
				configs[normalized] = loaded
				config_loaded.emit(normalized, loaded)
				if enable_logging:
					print("ConfigSystem loaded: ", normalized)
				return loaded
			push_error("ConfigSystem: failed to load config '%s'." % String(normalized))
	return null


func has_config(config_id: StringName) -> bool:
	return configs.has(_normalize_id(config_id)) or config_paths.has(_normalize_id(config_id))


func clear_config(config_id: StringName) -> void:
	var normalized := _normalize_id(config_id)
	if normalized == &"":
		return
	configs.erase(normalized)
	config_paths.erase(normalized)
	config_cleared.emit(normalized)


func clear_all() -> void:
	for key in configs.keys():
		config_cleared.emit(key)
	configs.clear()
	config_paths.clear()


func _normalize_id(value: Variant) -> StringName:
	var string_value := String(value).strip_edges()
	if string_value.is_empty():
		return &""
	return StringName(string_value)
