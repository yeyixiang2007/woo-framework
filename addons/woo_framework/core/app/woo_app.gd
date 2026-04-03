class_name WooApp
extends Node

signal bootstrapped(app: WooApp)
signal root_scene_changed(root_scene: Node)
signal state_changed(key: StringName, value: Variant)
signal shutting_down()

static var instance: WooApp

var app_name := "WooFramework"
var bootstrap: Node
var root_scene: Node
var boot_timestamp_unix := 0

var modules: ModuleRegistry
var models: ModelStore
var events: EventBus
var commands: CommandBus
var queries: QueryService
var systems: SystemRegistry
var runtime_state: Dictionary = {}


func _enter_tree() -> void:
	instance = self
	Woo.set_app(self)


func _exit_tree() -> void:
	if instance == self:
		instance = null
	if Woo.get_app() == self:
		Woo.clear_app()


static func get_instance() -> WooApp:
	return instance


func boot(owner: Node) -> void:
	if bootstrap != null:
		return

	bootstrap = owner
	_reset_runtime_registries()
	boot_timestamp_unix = Time.get_unix_time_from_system()
	set_state_value(&"app_name", app_name)
	set_state_value(&"boot_timestamp_unix", boot_timestamp_unix)
	set_state_value(&"status", "booted")
	bootstrapped.emit(self)


func mount_root_scene(scene: Node) -> void:
	if bootstrap == null:
		push_error("WooApp must be booted before mounting a root scene.")
		return

	if root_scene != null and is_instance_valid(root_scene):
		root_scene.queue_free()

	root_scene = scene
	root_scene.name = "RuntimeRoot"
	bootstrap.add_child(root_scene)
	set_state_value(&"status", "running")
	root_scene_changed.emit(root_scene)


func shutdown() -> void:
	set_state_value(&"status", "shutting_down")
	shutting_down.emit()

	if modules != null:
		modules.shutdown_modules()

	if root_scene != null and is_instance_valid(root_scene):
		root_scene.queue_free()
		root_scene = null


func has_started() -> bool:
	return bootstrap != null


func set_state_value(key: StringName, value: Variant) -> void:
	runtime_state[key] = value
	state_changed.emit(key, value)


func get_state_value(key: StringName, default_value: Variant = null) -> Variant:
	return runtime_state.get(key, default_value)


func get_runtime_snapshot() -> Dictionary:
	return {
		"app_name": app_name,
		"boot_timestamp_unix": boot_timestamp_unix,
		"has_root_scene": root_scene != null and is_instance_valid(root_scene),
		"status": get_state_value(&"status", "created"),
		"module_count": 0 if modules == null else modules.get_module_ids().size(),
		"module_ids": [] if modules == null else modules.get_module_ids(),
		"runtime_state": runtime_state.duplicate(true),
	}


func _reset_runtime_registries() -> void:
	modules = ModuleRegistry.new(self)
	models = ModelStore.new(self)
	events = _resolve_event_bus()
	commands = CommandBus.new(self)
	queries = QueryService.new(self)
	systems = SystemRegistry.new(self)


func _resolve_event_bus() -> EventBus:
	if get_tree() != null:
		var candidate := get_tree().root.get_node_or_null("WooEventBus") as EventBus
		if candidate != null:
			candidate.app = self
			return candidate

	var created := EventBus.new()
	created.app = self
	return created
