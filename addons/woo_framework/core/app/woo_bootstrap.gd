class_name WooBootstrap
extends Node

signal startup_scene_loaded(scene: Node)
signal modules_booted(module_ids)

const DEFAULT_STARTUP_SCENE_PATH := "res://addons/woo_framework/examples/modules/counter/scenes/counter_scene.tscn"
const DEFAULT_MODULE_ROOTS := [
	"res://addons/woo_framework/examples/modules",
]
const DEFAULT_DEBUG_PANEL_SCRIPT_PATH := "res://addons/woo_framework/core/debug/woo_debug_panel.gd"

@export_file("*.tscn") var startup_scene_path: String = DEFAULT_STARTUP_SCENE_PATH
@export var auto_boot_modules := true
@export var module_root_paths: PackedStringArray = PackedStringArray(DEFAULT_MODULE_ROOTS)
@export var enable_debug_panel := true
@export_file("*.gd") var debug_panel_script_path: String = DEFAULT_DEBUG_PANEL_SCRIPT_PATH

var app: WooApp
var debug_panel: CanvasLayer


func _ready() -> void:
	app = _ensure_app()
	app.boot(self)
	if auto_boot_modules and not _boot_modules():
		return
	_mount_startup_scene()
	_mount_debug_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and app != null and is_instance_valid(app):
		app.shutdown()


func _ensure_app() -> WooApp:
	var existing := get_node_or_null("WooApp")
	if existing is WooApp:
		return existing

	var created := WooApp.new()
	created.name = "WooApp"
	add_child(created)
	return created


func _mount_startup_scene() -> void:
	var startup_scene := load(startup_scene_path) as PackedScene
	if startup_scene == null:
		push_error("WooBootstrap could not load startup scene: %s" % startup_scene_path)
		return

	var instantiated_scene := startup_scene.instantiate()
	app.mount_root_scene(instantiated_scene)
	startup_scene_loaded.emit(instantiated_scene)


func _boot_modules() -> bool:
	if app.modules == null:
		push_error("WooBootstrap could not access ModuleRegistry.")
		return false

	var did_boot := app.modules.boot_from_roots(module_root_paths)
	if not did_boot:
		push_error("WooBootstrap failed to boot modules: %s" % app.modules.get_boot_error())
		return false

	modules_booted.emit(app.modules.get_module_ids())
	return true


func _mount_debug_panel() -> void:
	if not enable_debug_panel:
		return
	if debug_panel != null and is_instance_valid(debug_panel):
		return

	var script = load(debug_panel_script_path)
	if script == null:
		push_error("WooBootstrap could not load debug panel script: %s" % debug_panel_script_path)
		return

	var instance = script.new()
	if not (instance is CanvasLayer):
		push_error("WooBootstrap debug panel script must create a CanvasLayer.")
		return

	debug_panel = instance
	debug_panel.name = "WooDebugPanel"
	add_child(debug_panel)
	if debug_panel.has_method("attach_app"):
		debug_panel.call("attach_app", app)
