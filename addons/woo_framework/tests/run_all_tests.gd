extends SceneTree

const TEST_RUNNER := preload("res://addons/woo_framework/tests/framework/test_runner.gd")
const MODEL_STORE_TEST := preload("res://addons/woo_framework/tests/unit/model_store_test.gd")
const EVENT_BUS_TEST := preload("res://addons/woo_framework/tests/unit/event_bus_test.gd")
const COMMAND_BUS_TEST := preload("res://addons/woo_framework/tests/unit/command_bus_test.gd")
const QUERY_SERVICE_TEST := preload("res://addons/woo_framework/tests/unit/query_service_test.gd")
const INTEGRATION_SCENE := preload(
	"res://addons/woo_framework/tests/integration/scenes/example_modules_integration_test.tscn"
)


func _init() -> void:
	var runner = TEST_RUNNER.new()
	if runner == null:
		push_error("Test runner could not be created.")
		quit(1)
		return

	_run_unit_tests(runner)
	_run_integration_tests(runner)

	runner.print_summary()
	var summary: Dictionary = runner.get_summary()
	var failed_count := int(summary.get("failed", 0))
	quit(0 if failed_count == 0 else 1)


func _run_unit_tests(runner) -> void:
	runner.start_suite("Unit")

	runner.start_case("ModelStore")
	MODEL_STORE_TEST.run(runner)

	runner.start_case("EventBus")
	EVENT_BUS_TEST.run(runner)

	runner.start_case("CommandBus")
	COMMAND_BUS_TEST.run(runner)

	runner.start_case("QueryService")
	QUERY_SERVICE_TEST.run(runner)


func _run_integration_tests(runner) -> void:
	runner.start_suite("Integration")
	runner.start_case("Example Modules Startup + Interaction + Save")

	var test_scene := INTEGRATION_SCENE.instantiate()
	if test_scene == null:
		runner.expect_true(false, "Integration test scene should instantiate.")
		return

	if test_scene.has_method("run_case"):
		test_scene.call("run_case", runner)
	else:
		runner.expect_true(false, "Integration test scene should expose run_case(runner).")

	if test_scene is Node:
		(test_scene as Node).queue_free()
