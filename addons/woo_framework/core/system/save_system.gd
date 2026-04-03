class_name SaveSystem
extends RefCounted

signal slot_saved(slot_id: StringName, metadata: Dictionary)
signal slot_loaded(slot_id: StringName, metadata: Dictionary)
signal slot_deleted(slot_id: StringName)
signal save_failed(slot_id: StringName, reason: String)
signal load_failed(slot_id: StringName, reason: String)

var app
var save_root := "user://saves"
var metadata_filename := "slot.json"
var model_subdir := "models"
var version := "0.1.0"
var enable_logging := false


func _init(owner_app = null) -> void:
	app = owner_app


func set_app(owner_app) -> void:
	app = owner_app


func list_slots() -> PackedStringArray:
	var result := PackedStringArray()
	var root := _normalize_path(save_root)
	if root == "":
		return result
	if not DirAccess.dir_exists_absolute(root):
		return result
	var dir := DirAccess.open(root)
	if dir == null:
		return result

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			result.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	return result


func slot_exists(slot_id: StringName) -> bool:
	var normalized := _normalize_id(slot_id)
	if normalized == &"":
		return false
	var path := _slot_dir(normalized)
	return DirAccess.dir_exists_absolute(path)


func save_slot(slot_id: StringName, options: Dictionary = {}) -> bool:
	var normalized := _normalize_id(slot_id)
	if normalized == &"":
		_emit_save_failed(normalized, "Slot ID cannot be empty.")
		return false

	var resolved_app := _ensure_app()
	if resolved_app == null or resolved_app.models == null:
		_emit_save_failed(normalized, "SaveSystem requires a valid WooApp and ModelStore.")
		return false

	var slot_dir := _slot_dir(normalized)
	var models_dir := slot_dir.path_join(model_subdir)
	if not _ensure_dir(models_dir):
		_emit_save_failed(normalized, "Failed to create save slot directory.")
		return false

	var model_ids: PackedStringArray = options.get("model_ids", PackedStringArray())
	if model_ids.is_empty():
		model_ids = _get_all_model_ids()

	var models_payload: Dictionary = {}
	for model_id_value in model_ids:
		var model_id := _normalize_id(model_id_value)
		if model_id == &"":
			continue
		var model_instance := resolved_app.models.get_model(model_id)
		if model_instance == null:
			_emit_save_failed(normalized, "Model '%s' could not be resolved." % String(model_id))
			return false

		var relative_path := model_subdir.path_join("%s.tres" % String(model_id))
		var target_path := slot_dir.path_join(relative_path)
		var save_error := ResourceSaver.save(
			model_instance,
			target_path,
			ResourceSaver.FLAG_CHANGE_PATH
		)
		if save_error != OK:
			_emit_save_failed(
				normalized,
				"Failed to save model '%s' (error %s)." % [String(model_id), str(save_error)]
			)
			return false

		models_payload[model_id] = {
			"path": relative_path,
		}

	var metadata: Dictionary = {
		"slot_id": String(normalized),
		"version": version,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"app_name": "" if resolved_app == null else resolved_app.app_name,
		"models": models_payload,
	}
	if options.has("metadata") and options["metadata"] is Dictionary:
		metadata.merge(options["metadata"], true)

	if not _write_metadata(slot_dir, metadata):
		_emit_save_failed(normalized, "Failed to write slot metadata.")
		return false

	if enable_logging:
		print("SaveSystem saved slot: ", normalized)
	slot_saved.emit(normalized, metadata)
	return true


func load_slot(slot_id: StringName, options: Dictionary = {}) -> bool:
	var normalized := _normalize_id(slot_id)
	if normalized == &"":
		_emit_load_failed(normalized, "Slot ID cannot be empty.")
		return false

	var resolved_app := _ensure_app()
	if resolved_app == null or resolved_app.models == null:
		_emit_load_failed(normalized, "SaveSystem requires a valid WooApp and ModelStore.")
		return false

	var slot_dir := _slot_dir(normalized)
	var metadata := _read_metadata(slot_dir)
	if metadata.is_empty():
		_emit_load_failed(normalized, "Slot metadata not found or invalid.")
		return false

	var models_payload: Dictionary = metadata.get("models", {})
	var model_ids: PackedStringArray = options.get("model_ids", PackedStringArray())
	var allow_missing := bool(options.get("allow_missing", false))
	if model_ids.is_empty():
		model_ids = PackedStringArray()
		for key in models_payload.keys():
			model_ids.append(String(key))

	for model_id_value in model_ids:
		var model_id := _normalize_id(model_id_value)
		if model_id == &"":
			continue
		if not models_payload.has(model_id):
			if allow_missing:
				continue
			_emit_load_failed(normalized, "Model '%s' not found in slot." % String(model_id))
			return false
		var entry: Dictionary = models_payload[model_id]
		var relative_path := String(entry.get("path", ""))
		if relative_path == "":
			_emit_load_failed(normalized, "Missing path for model '%s'." % String(model_id))
			return false
		var resource_path := slot_dir.path_join(relative_path)
		var loaded := load(resource_path)
		if loaded == null or not (loaded is Resource):
			_emit_load_failed(normalized, "Failed to load model '%s'." % String(model_id))
			return false
		if not resolved_app.models.set_model(model_id, loaded):
			_emit_load_failed(normalized, "Failed to apply model '%s'." % String(model_id))
			return false

	if enable_logging:
		print("SaveSystem loaded slot: ", normalized)
	slot_loaded.emit(normalized, metadata)
	return true


func delete_slot(slot_id: StringName) -> bool:
	var normalized := _normalize_id(slot_id)
	if normalized == &"":
		return false

	var slot_dir := _slot_dir(normalized)
	if not DirAccess.dir_exists_absolute(slot_dir):
		return false

	if not _remove_dir_recursive(slot_dir):
		return false

	if enable_logging:
		print("SaveSystem deleted slot: ", normalized)
	slot_deleted.emit(normalized)
	return true


func get_slot_metadata(slot_id: StringName) -> Dictionary:
	var normalized := _normalize_id(slot_id)
	if normalized == &"":
		return {}
	return _read_metadata(_slot_dir(normalized))


func _ensure_app() -> WooApp:
	if app == null:
		app = Woo.get_app()
	return app


func _write_metadata(slot_dir: String, metadata: Dictionary) -> bool:
	var metadata_path := slot_dir.path_join(metadata_filename)
	var file := FileAccess.open(metadata_path, FileAccess.WRITE)
	if file == null:
		return false
	var json_text := JSON.stringify(metadata, "\t")
	file.store_string(json_text)
	return true


func _read_metadata(slot_dir: String) -> Dictionary:
	var metadata_path := slot_dir.path_join(metadata_filename)
	if not FileAccess.file_exists(metadata_path):
		return {}
	var file := FileAccess.open(metadata_path, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	var json := JSON.new()
	var parse_error := json.parse(content)
	if parse_error != OK:
		return {}
	var data = json.data
	if data is Dictionary:
		return data
	return {}


func _get_all_model_ids() -> PackedStringArray:
	var result := PackedStringArray()
	if app == null or app.models == null:
		return result
	var ids: Array = app.models.get_model_ids()
	for model_id in ids:
		result.append(String(model_id))
	return result


func _slot_dir(slot_id: StringName) -> String:
	return _normalize_path(save_root).path_join(String(slot_id))


func _normalize_id(value: Variant) -> StringName:
	var string_value := String(value).strip_edges()
	if string_value.is_empty():
		return &""
	return StringName(string_value)


func _normalize_path(value: Variant) -> String:
	return String(value).strip_edges()


func _ensure_dir(path: String) -> bool:
	var normalized := _normalize_path(path)
	if normalized == "":
		return false
	if DirAccess.dir_exists_absolute(normalized):
		return true
	var error := DirAccess.make_dir_recursive_absolute(normalized)
	return error == OK


func _remove_dir_recursive(path: String) -> bool:
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		if dir.current_is_dir():
			if not _remove_dir_recursive(path.path_join(entry)):
				return false
		else:
			if dir.remove(entry) != OK:
				return false
		entry = dir.get_next()
	dir.list_dir_end()
	var parent_path := path.get_base_dir()
	var parent := DirAccess.open(parent_path)
	if parent == null:
		return false
	return parent.remove(path.get_file()) == OK


func _emit_save_failed(slot_id: StringName, reason: String) -> void:
	push_error("SaveSystem: %s" % reason)
	save_failed.emit(slot_id, reason)


func _emit_load_failed(slot_id: StringName, reason: String) -> void:
	push_error("SaveSystem: %s" % reason)
	load_failed.emit(slot_id, reason)
