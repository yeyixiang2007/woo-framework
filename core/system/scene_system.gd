class_name SceneSystem
extends RefCounted

signal transition_started(scene_path: String, payload)
signal transition_finished(scene_path: String, scene: Node, payload)
signal scene_preloaded(scene_path: String)
signal scene_cache_cleared()

var app
var enable_logging := false
var cached_scenes: Dictionary = {}
var before_change_hooks: Array = []
var after_change_hooks: Array = []


func _init(owner_app = null) -> void:
	app = owner_app


func preload_scene(scene_path: String, cache := true) -> PackedScene:
	var normalized := _normalize_path(scene_path)
	if normalized == "":
		push_error("SceneSystem: scene path cannot be empty.")
		return null

	if cached_scenes.has(normalized):
		return cached_scenes[normalized]

	var packed := load(normalized) as PackedScene
	if packed == null:
		push_error("SceneSystem: failed to preload scene at '%s'." % normalized)
		return null

	if cache:
		cached_scenes[normalized] = packed

	if enable_logging:
		print("SceneSystem preloaded: ", normalized)
	scene_preloaded.emit(normalized)
	return packed


func has_cached_scene(scene_path: String) -> bool:
	return cached_scenes.has(_normalize_path(scene_path))


func get_cached_scene(scene_path: String) -> PackedScene:
	var normalized := _normalize_path(scene_path)
	if cached_scenes.has(normalized):
		return cached_scenes[normalized]
	return null


func clear_cache() -> void:
	cached_scenes.clear()
	scene_cache_cleared.emit()


func add_before_change_hook(hook: Callable) -> void:
	if hook == null or not hook.is_valid():
		return
	if not before_change_hooks.has(hook):
		before_change_hooks.append(hook)


func remove_before_change_hook(hook: Callable) -> void:
	before_change_hooks.erase(hook)


func add_after_change_hook(hook: Callable) -> void:
	if hook == null or not hook.is_valid():
		return
	if not after_change_hooks.has(hook):
		after_change_hooks.append(hook)


func remove_after_change_hook(hook: Callable) -> void:
	after_change_hooks.erase(hook)


func change_scene(scene_path: String, payload = null, options: Dictionary = {}) -> Node:
	var normalized := _normalize_path(scene_path)
	if normalized == "":
		push_error("SceneSystem: scene path cannot be empty.")
		return null

	var resolved_app := _ensure_app()
	if resolved_app == null:
		push_error("SceneSystem: cannot change scene without WooApp.")
		return null

	var packed: PackedScene = null
	var use_cache := bool(options.get("use_cache", true))
	if use_cache and cached_scenes.has(normalized):
		packed = cached_scenes[normalized]

	if packed == null:
		packed = load(normalized) as PackedScene
		if packed == null:
			push_error("SceneSystem: failed to load scene at '%s'." % normalized)
			return null

	if bool(options.get("cache", false)):
		cached_scenes[normalized] = packed

	var previous_scene: Node = null
	if resolved_app != null:
		previous_scene = resolved_app.root_scene

	var context := {
		"app": resolved_app,
		"scene_path": normalized,
		"payload": payload,
		"previous_scene": previous_scene,
		"options": options.duplicate(true),
	}

	_call_hooks(before_change_hooks, context)
	transition_started.emit(normalized, payload)

	var instance := packed.instantiate()
	context["next_scene"] = instance
	resolved_app.mount_root_scene(instance)

	if enable_logging:
		print("SceneSystem changed: ", normalized)

	_call_hooks(after_change_hooks, context)
	transition_finished.emit(normalized, instance, payload)
	return instance


func change_scene_packed(scene: PackedScene, scene_path: String = "", payload = null, options: Dictionary = {}) -> Node:
	if scene == null:
		push_error("SceneSystem: cannot change to a null PackedScene.")
		return null

	var normalized := _normalize_path(scene_path)
	if normalized == "":
		normalized = "<packed>"

	var previous_scene: Node = null
	var resolved_app := _ensure_app()
	if resolved_app != null:
		previous_scene = resolved_app.root_scene

	var context := {
		"app": resolved_app,
		"scene_path": normalized,
		"payload": payload,
		"previous_scene": previous_scene,
		"options": options.duplicate(true),
	}

	_call_hooks(before_change_hooks, context)
	transition_started.emit(normalized, payload)

	var instance := scene.instantiate()
	context["next_scene"] = instance
	if resolved_app != null:
		resolved_app.mount_root_scene(instance)
	else:
		push_error("SceneSystem: cannot mount scene without WooApp.")
		return null

	if enable_logging:
		print("SceneSystem changed: ", normalized)

	_call_hooks(after_change_hooks, context)
	transition_finished.emit(normalized, instance, payload)
	return instance


func _call_hooks(hooks: Array, context: Dictionary) -> void:
	for hook in hooks:
		if hook is Callable and hook.is_valid():
			hook.call(context)


func _normalize_path(path_value: Variant) -> String:
	return String(path_value).strip_edges()


func _ensure_app() -> WooApp:
	if app == null:
		app = WooApp.get_instance()
	return app
