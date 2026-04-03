extends RefCounted

const COUNTER_MODEL_SCRIPT := preload(
	"res://addons/woo_framework/examples/modules/counter/models/counter_model.gd"
)
const COUNTER_MODEL_RESOURCE := preload(
	"res://addons/woo_framework/examples/modules/counter/models/default_counter_model.tres"
)


static func run(runner) -> void:
	var host := Node.new()
	var app := WooApp.new()
	host.add_child(app)
	app.boot(host)

	runner.expect_true(
		app.models.register_definition(
			&"counter",
			COUNTER_MODEL_SCRIPT,
			COUNTER_MODEL_RESOURCE,
			&"unit_test"
		),
		"ModelStore should register model definition."
	)
	runner.expect_true(app.models.has_model(&"counter"), "ModelStore should report registered model.")

	var model = app.models.get_model(&"counter")
	runner.expect_not_null(model, "ModelStore should create model instance from definition.")
	if model != null:
		runner.expect_equal(int(model.get("count")), 0, "Counter model default count should be 0.")
		model.set("count", 4)

	var cached = app.models.get_model(&"counter")
	runner.expect_not_null(cached, "ModelStore should return cached model instance.")
	if cached != null:
		runner.expect_equal(int(cached.get("count")), 4, "Cached model should keep mutations.")

	var replacement = COUNTER_MODEL_SCRIPT.new()
	replacement.set("count", 9)
	runner.expect_true(
		app.models.set_model(&"counter", replacement),
		"ModelStore should accept model replacement."
	)

	var replaced = app.models.get_model(&"counter")
	runner.expect_not_null(replaced, "ModelStore should return replaced model instance.")
	if replaced != null:
		runner.expect_equal(int(replaced.get("count")), 9, "Replaced model should be returned by get_model.")

	app.shutdown()
	host.free()
