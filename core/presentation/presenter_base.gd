class_name PresenterBase
extends Node

var app: WooApp
var models: ModelStore
var events: EventBus
var commands: CommandBus
var queries: QueryService
var systems: SystemRegistry
var view: Node
var _bound := false


func _ready() -> void:
	_attach_app()
	if app == null:
		return
	on_app_ready(app)
	if view != null:
		on_view_ready(view)
	bind()


func _exit_tree() -> void:
	unbind()


func set_view(view_node: Node) -> void:
	view = view_node
	if app == null:
		_attach_app()
	if app != null:
		on_view_ready(view)


func on_app_ready(_app: WooApp) -> void:
	pass


func on_view_ready(_view: Node) -> void:
	pass


func bind() -> void:
	_bound = true


func unbind() -> void:
	if not _bound:
		return
	_bound = false


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
