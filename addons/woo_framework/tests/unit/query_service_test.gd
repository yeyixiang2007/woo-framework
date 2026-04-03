extends RefCounted

const COUNTER_MODEL_SCRIPT := preload(
	"res://addons/woo_framework/examples/modules/counter/models/counter_model.gd"
)
const COUNTER_MODEL_RESOURCE := preload(
	"res://addons/woo_framework/examples/modules/counter/models/default_counter_model.tres"
)


class QueryHandler:
	extends RefCounted

	func execute_counter_state(context, _payload):
		var model = context.get_model(&"counter")
		if model == null:
			return {
				"count": 0,
			}
		return {
			"count": int(model.get("count")),
		}


class QueryFailSpy:
	extends RefCounted

	var failed_count := 0

	func on_failed(_query_id: StringName, _payload, _reason: String) -> void:
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
	var model = app.models.get_model(&"counter")
	if model != null:
		model.set("count", 8)

	var handler := QueryHandler.new()
	runner.expect_true(
		app.queries.register_definition(&"counter_state", Callable(handler, "execute_counter_state"), &"unit_test"),
		"QueryService should register callable handlers."
	)

	var result = app.queries.query(&"counter_state")
	runner.expect_true(result is Dictionary, "QueryService should return query payload dictionary.")
	if result is Dictionary:
		runner.expect_equal(int(result.get("count", 0)), 8, "Query should read latest model value.")

	var fail_spy := QueryFailSpy.new()
	app.queries.query_failed.connect(Callable(fail_spy, "on_failed"))
	var unknown_result = app.queries.query(&"unknown_query")
	runner.expect_true(unknown_result == null, "Unknown query should return null.")
	runner.expect_equal(fail_spy.failed_count, 1, "Unknown query should trigger query_failed signal.")

	app.shutdown()
	host.free()
