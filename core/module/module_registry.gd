class_name ModuleRegistry
extends RefCounted

signal discovery_completed(module_paths)
signal module_discovered(module_id: StringName, script_path: String)
signal modules_sorted(sorted_module_ids)
signal module_registered(module_id: StringName)
signal module_initialized(module_id: StringName)
signal module_readied(module_id: StringName)
signal module_shutdown(module_id: StringName)
signal boot_completed(sorted_module_ids)
signal boot_failed(reason: String)

var app
var discovered_module_paths := PackedStringArray()
var loaded_module_paths: Dictionary = {}
var modules_by_id: Dictionary = {}
var module_contexts: Dictionary = {}
var module_registrations: Dictionary = {}
var sorted_module_ids: Array = []
var boot_error := ""
var is_bootstrapped := false


func _init(owner_app = null) -> void:
	app = owner_app


func discover_module_paths(root_paths: PackedStringArray) -> PackedStringArray:
	var discovered: Array[String] = []
	for root_path in root_paths:
		_discover_modules_in_root(root_path, discovered)

	discovered.sort()

	var unique := PackedStringArray()
	var seen: Dictionary = {}
	for path in discovered:
		if seen.has(path):
			continue
		seen[path] = true
		unique.append(path)

	discovered_module_paths = unique
	discovery_completed.emit(discovered_module_paths)
	return discovered_module_paths


func boot_from_roots(root_paths: PackedStringArray) -> bool:
	var module_paths := discover_module_paths(root_paths)
	return boot_from_module_scripts(module_paths)


func boot_from_module_scripts(module_paths: PackedStringArray) -> bool:
	if app == null:
		return _fail("ModuleRegistry requires a valid WooApp instance.")

	if is_bootstrapped:
		return true

	_clear_registry_state()
	discovered_module_paths = module_paths

	if not _instantiate_modules(module_paths):
		return false

	if not _sort_modules_by_dependencies():
		return false

	if not _register_modules():
		return false

	if not _initialize_modules():
		return false

	if not _ready_modules():
		return false

	is_bootstrapped = true
	_sync_app_state()
	boot_completed.emit(sorted_module_ids.duplicate())
	return true


func shutdown_modules() -> void:
	if not is_bootstrapped:
		return

	for index in range(sorted_module_ids.size() - 1, -1, -1):
		var module_id: StringName = sorted_module_ids[index]
		var module = modules_by_id.get(module_id)
		var context = module_contexts.get(module_id)
		if module == null or context == null:
			continue

		context.set_phase("shutdown")
		module.shutdown(context)
		module_shutdown.emit(module_id)

	is_bootstrapped = false
	if app != null:
		app.set_state_value(&"module_registry_status", "shutdown")


func get_module(module_id: StringName) -> ModuleDefinition:
	return modules_by_id.get(module_id)


func get_module_ids() -> Array:
	return sorted_module_ids.duplicate()


func get_registrations_for_module(module_id: StringName) -> Dictionary:
	if not module_registrations.has(module_id):
		return {}
	return module_registrations[module_id].duplicate(true)


func get_boot_error() -> String:
	return boot_error


func register_model_definition(
	owner_module_id: StringName,
	id: StringName,
	script_ref: Variant,
	default_resource: Variant = null
) -> bool:
	if app == null or app.models == null:
		return _fail("ModelStore is not available on WooApp.")

	var registered: bool = app.models.register_definition(id, script_ref, default_resource, owner_module_id)
	if not registered:
		return _fail("Failed to register model '%s' from module '%s'." % [
			String(id),
			String(owner_module_id),
		])

	return _register_definition(
		"models",
		{},
		owner_module_id,
		id,
		{
			"script": script_ref,
			"script_path": _extract_resource_path(script_ref),
			"default_resource": default_resource,
			"default_resource_path": _extract_resource_path(default_resource),
		}
	)


func register_command_definition(owner_module_id: StringName, id: StringName, script_ref: Variant) -> bool:
	if app == null or app.commands == null:
		return _fail("CommandBus is not available on WooApp.")

	var registered: bool = app.commands.register_definition(id, script_ref, owner_module_id)
	if not registered:
		return _fail("Failed to register command '%s' from module '%s'." % [
			String(id),
			String(owner_module_id),
		])

	return _register_definition(
		"commands",
		{},
		owner_module_id,
		id,
		{
			"script": script_ref,
			"script_path": _extract_resource_path(script_ref),
		}
	)


func register_query_definition(owner_module_id: StringName, id: StringName, script_ref: Variant) -> bool:
	if app == null or app.queries == null:
		return _fail("QueryService is not available on WooApp.")

	var registered: bool = app.queries.register_definition(id, script_ref, owner_module_id)
	if not registered:
		return _fail("Failed to register query '%s' from module '%s'." % [
			String(id),
			String(owner_module_id),
		])

	return _register_definition(
		"queries",
		{},
		owner_module_id,
		id,
		{
			"script": script_ref,
			"script_path": _extract_resource_path(script_ref),
		}
	)


func register_system_definition(owner_module_id: StringName, id: StringName, script_ref: Variant) -> bool:
	if app == null or app.systems == null:
		return _fail("SystemRegistry is not available on WooApp.")

	var registered: bool = app.systems.register_definition(id, script_ref, owner_module_id)
	if not registered:
		return _fail("Failed to register system '%s' from module '%s'." % [
			String(id),
			String(owner_module_id),
		])

	return _register_definition(
		"systems",
		{},
		owner_module_id,
		id,
		{
			"script": script_ref,
			"script_path": _extract_resource_path(script_ref),
		}
	)


func register_module_metadata(owner_module_id: StringName, key: StringName, value: Variant) -> bool:
	var normalized_key := _normalize_id(key)
	if normalized_key == &"":
		return _fail("Module metadata key cannot be empty.")

	var bucket := _ensure_module_bucket(owner_module_id)
	bucket["metadata"][normalized_key] = value
	return true


func _discover_modules_in_root(root_path: String, discovered: Array[String]) -> void:
	var directory := DirAccess.open(root_path)
	if directory == null:
		return

	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while entry_name != "":
		if directory.current_is_dir() and not entry_name.begins_with("."):
			var module_path := root_path.path_join(entry_name).path_join("module.gd")
			if ResourceLoader.exists(module_path):
				discovered.append(module_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _instantiate_modules(module_paths: PackedStringArray) -> bool:
	for module_path in module_paths:
		var script_ref := load(module_path)
		if script_ref == null:
			return _fail("Failed to load module script: %s" % module_path)

		var module = script_ref.new()
		if not (module is ModuleDefinition):
			return _fail("Module script must extend ModuleDefinition: %s" % module_path)

		if not module.is_enabled_by_default():
			continue

		var module_id := _normalize_id(module.get_module_id())
		if module_id == &"":
			return _fail("Module ID cannot be empty: %s" % module_path)

		if modules_by_id.has(module_id):
			return _fail("Duplicate module ID detected: %s" % String(module_id))

		modules_by_id[module_id] = module
		loaded_module_paths[module_id] = module_path
		module_contexts[module_id] = ModuleContext.new(app, self, module)
		_ensure_module_bucket(module_id)
		module_discovered.emit(module_id, module_path)

	return true


func _sort_modules_by_dependencies() -> bool:
	var visited: Dictionary = {}
	var visiting: Dictionary = {}
	var module_ids: Array = modules_by_id.keys()
	module_ids.sort_custom(func(a, b): return String(a) < String(b))

	for module_id in module_ids:
		if not _visit_module(module_id, visited, visiting):
			return false

	modules_sorted.emit(sorted_module_ids.duplicate())
	return true


func _visit_module(module_id: StringName, visited: Dictionary, visiting: Dictionary) -> bool:
	if visited.has(module_id):
		return true

	if visiting.has(module_id):
		return _fail("Circular module dependency detected at: %s" % String(module_id))

	visiting[module_id] = true
	var module: ModuleDefinition = modules_by_id[module_id]
	var dependencies := module.get_dependencies()

	for dependency in dependencies:
		var dependency_id := _normalize_id(dependency)
		if not modules_by_id.has(dependency_id):
			return _fail(
				"Missing module dependency '%s' required by '%s'." % [
					String(dependency_id),
					String(module_id),
				]
			)
		if not _visit_module(dependency_id, visited, visiting):
			return false

	visiting.erase(module_id)
	visited[module_id] = true
	sorted_module_ids.append(module_id)
	return true


func _register_modules() -> bool:
	for module_id in sorted_module_ids:
		var module: ModuleDefinition = modules_by_id[module_id]
		var context: ModuleContext = module_contexts[module_id]
		var registrar := ModuleRegistrar.new(app, self, module_id)
		context.set_phase("register")
		module.register(registrar)
		if boot_error != "":
			return false
		module_registered.emit(module_id)
	return true


func _initialize_modules() -> bool:
	for module_id in sorted_module_ids:
		var module: ModuleDefinition = modules_by_id[module_id]
		var context: ModuleContext = module_contexts[module_id]
		context.set_phase("initialize")
		module.initialize(context)
		if boot_error != "":
			return false
		module_initialized.emit(module_id)
	return true


func _ready_modules() -> bool:
	for module_id in sorted_module_ids:
		var module: ModuleDefinition = modules_by_id[module_id]
		var context: ModuleContext = module_contexts[module_id]
		context.set_phase("ready")
		module.ready(context)
		if boot_error != "":
			return false
		module_readied.emit(module_id)
	return true


func _register_definition(
	kind: String,
	store: Dictionary,
	owner_module_id: StringName,
	id: StringName,
	payload: Dictionary
) -> bool:
	var normalized_id := _normalize_id(id)
	if normalized_id == &"":
		return _fail("%s entry ID cannot be empty." % kind.capitalize())

	if store.has(normalized_id):
		return _fail(
			"Duplicate %s ID '%s' declared by module '%s'." % [
				kind.trim_suffix("s"),
				String(normalized_id),
				String(owner_module_id),
			]
		)

	var entry_payload := payload.duplicate(true)
	entry_payload["id"] = normalized_id
	entry_payload["module_id"] = owner_module_id
	if store != null:
		store[normalized_id] = entry_payload
	var bucket := _ensure_module_bucket(owner_module_id)
	bucket[kind][normalized_id] = entry_payload
	return true


func _ensure_module_bucket(module_id: StringName) -> Dictionary:
	if not module_registrations.has(module_id):
		module_registrations[module_id] = {
			"models": {},
			"commands": {},
			"queries": {},
			"systems": {},
			"metadata": {},
		}
	return module_registrations[module_id]


func _sync_app_state() -> void:
	if app == null:
		return

	var loaded_ids := PackedStringArray()
	for module_id in sorted_module_ids:
		loaded_ids.append(String(module_id))

	app.set_state_value(&"module_registry_status", "ready")
	app.set_state_value(&"module_count", sorted_module_ids.size())
	app.set_state_value(&"module_ids", loaded_ids)
	app.set_state_value(&"module_paths", loaded_module_paths.duplicate(true))


func _clear_registry_state() -> void:
	boot_error = ""
	discovered_module_paths = PackedStringArray()
	loaded_module_paths = {}
	modules_by_id = {}
	module_contexts = {}
	module_registrations = {}
	sorted_module_ids = []
	is_bootstrapped = false
	if app != null:
		if app.models != null:
			app.models.clear()
		if app.commands != null:
			app.commands.clear()
		if app.queries != null:
			app.queries.clear()
		if app.systems != null:
			app.systems.clear()


func _normalize_id(value: Variant) -> StringName:
	var string_value := String(value).strip_edges()
	if string_value.is_empty():
		return &""
	return StringName(string_value)


func _extract_resource_path(value: Variant) -> String:
	if value == null:
		return ""
	if value is Resource:
		return value.resource_path
	if value is Script:
		return value.resource_path
	if value is String:
		return value
	return ""


func _fail(reason: String) -> bool:
	boot_error = reason
	push_error(reason)
	boot_failed.emit(reason)
	if app != null:
		app.set_state_value(&"module_registry_status", "error")
		app.set_state_value(&"module_registry_error", reason)
	return false
