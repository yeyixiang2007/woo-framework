extends RefCounted

const COUNTER_MODEL_SCRIPT := preload(
	"res://addons/woo_framework/examples/modules/counter/models/counter_model.gd"
)
const COUNTER_MODEL_RESOURCE := preload(
	"res://addons/woo_framework/examples/modules/counter/models/default_counter_model.tres"
)


class CommandHandler:
	extends RefCounted

	func execute_increment(context, payload):
		var model = context.get_model(&"counter")
		if model == null:
			return null
		var amount := 1
		if payload is Dictionary and payload.has("amount"):
			amount = int(payload["amount"])
		model.set("count", int(model.get("count")) + amount)
		context.emit_event(&"counter_changed", [model.get("count")])
		return int(model.get("count"))


class CommandFailSpy:
	extends RefCounted

	var failed_count := 0

	func on_failed(_command_id: StringName, _payload, _reason: String) -> void:
		failed_count += 1


static func run(runner) -> void:
	var host := Node.new()
	var app := WooApp.new()
	host.add_child(app)
	app.boot(host)

	app.models.register_definition(
		&"counter",
		COUNTER_MODEL_SCRIPT,
		COUNTER_MODEL_RESOURCE,
		&"unit_test"
	)

	var handler := CommandHandler.new()
	runner.expect_true(
		app.commands.register_definition(&"increment_counter", Callable(handler, "execute_increment"), &"unit_test"),
		"CommandBus should register callable handlers."
	)

	var result = app.commands.execute(&"increment_counter", {"amount": 3})
	runner.expect_equal(int(result), 3, "CommandBus should execute handler and return result.")
	var model = app.models.get_model(&"counter")
	runner.expect_not_null(model, "Command execution should use registered model.")
	if model != null:
		runner.expect_equal(int(model.get("count")), 3, "Command should mutate model state.")

	var fail_spy := CommandFailSpy.new()
	app.commands.command_failed.connect(Callable(fail_spy, "on_failed"))
	var unknown_result = app.commands.execute(&"unknown_command")
	runner.expect_true(unknown_result == null, "Unknown command should return null.")
	runner.expect_equal(fail_spy.failed_count, 1, "Unknown command should trigger command_failed signal.")

	app.shutdown()
	host.free()
