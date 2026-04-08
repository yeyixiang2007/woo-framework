class_name ControllerBase
extends Node

var app: WooApp
var models: ModelStore
var events: EventBus
var commands: CommandBus
var queries: QueryService
var systems: SystemRegistry
var _bound := false


func _ready() -> void:
	_attach_app()
	if app == null:
		return
	on_app_ready(app)
	bind()


func _exit_tree() -> void:
	unbind()


func on_app_ready(_app: WooApp) -> void:
	pass


func bind() -> void:
	_bound = true


func unbind() -> void:
	if not _bound:
		return
	_bound = false


func execute_command(command_id: StringName, payload = null):
	if commands == null:
		return null
	return commands.execute(command_id, payload)


func query_state(query_id: StringName, payload = null):
	if queries == null:
		return null
	return queries.query(query_id, payload)


func emit_event(event_id: StringName, args: Array = []) -> void:
	if events == null:
		return
	events.emit_event(event_id, args)


func _attach_app() -> void:
	if app == null:
		app = WooApp.get_instance()
	if app == null:
		return
	models = app.models
	events = app.events
	commands = app.commands
	queries = app.queries
	systems = app.systems
