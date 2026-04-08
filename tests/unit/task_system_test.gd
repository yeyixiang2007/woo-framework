extends RefCounted


class FlagProbe:
	extends RefCounted

	var ready := false

	func mark_ready() -> void:
		ready = true

	func is_ready() -> bool:
		return ready


static func run(runner) -> void:
	var context := _create_booted_app()
	var app: WooApp = context.get("app")
	var task_system := TaskSystem.new(app)

	var completed_task := task_system.completed(7)
	runner.expect_true(completed_task.is_succeeded(), "Completed task should succeed immediately.")
	runner.expect_equal(int(completed_task.get_result(0)), 7, "Completed task should expose its result.")

	var failed_task := task_system.failed("boom")
	runner.expect_true(failed_task.is_failed(), "Failed task should transition into failed state.")
	runner.expect_equal(String(failed_task.get_error("")), "boom", "Failed task should expose its error.")

	var cancellation_source := task_system.create_cancellation_source()
	cancellation_source.cancel("manual cancel")
	runner.expect_true(
		cancellation_source.token.is_canceled(),
		"Cancellation source should mark its token as canceled."
	)

	var all_task := task_system.when_all([
		task_system.completed("alpha"),
		task_system.completed("beta"),
	])
	runner.expect_true(all_task.is_succeeded(), "when_all should resolve immediately for finished tasks.")
	var all_results: Array = all_task.get_result([])
	runner.expect_equal(all_results.size(), 2, "when_all should keep the result count.")
	if all_results.size() == 2:
		runner.expect_equal(String(all_results[0]), "alpha", "when_all should preserve task order.")
		runner.expect_equal(String(all_results[1]), "beta", "when_all should preserve task order.")

	var any_task := task_system.when_any([
		task_system.failed("first"),
		task_system.completed("second"),
	])
	runner.expect_true(any_task.is_succeeded(), "when_any should resolve with the first settled task payload.")
	var any_payload: Dictionary = any_task.get_result({})
	runner.expect_equal(int(any_payload.get("index", -1)), 0, "when_any should return the first finished task index.")
	runner.expect_equal(String(any_payload.get("status", "")), "failed", "when_any should report task status.")

	_dispose_booted_app(context)


static func run_async(runner) -> void:
	var context := _create_booted_app()
	var app: WooApp = context.get("app")
	var task_system := TaskSystem.new(app)

	var delay_task := task_system.delay(0.01)
	await delay_task.finished
	runner.expect_true(delay_task.is_succeeded(), "delay should complete after the timer fires.")

	var frame_task := task_system.next_frame()
	await frame_task.finished
	runner.expect_true(frame_task.is_succeeded(), "next_frame should complete on the next process frame.")

	var probe := FlagProbe.new()
	app.get_tree().create_timer(0.01).timeout.connect(Callable(probe, "mark_ready"), CONNECT_ONE_SHOT)
	var wait_task := task_system.wait_until(Callable(probe, "is_ready"), null, false, 0.25)
	await wait_task.finished
	runner.expect_true(wait_task.is_succeeded(), "wait_until should complete once the predicate becomes true.")

	var cancel_source := task_system.create_cancellation_source()
	var canceled_delay := task_system.delay(0.2, cancel_source.token)
	cancel_source.cancel("test cancel")
	await canceled_delay.finished
	runner.expect_true(canceled_delay.is_canceled(), "Cancellation token should cancel pending delays.")
	runner.expect_equal(
		canceled_delay.get_cancel_reason(""),
		"test cancel",
		"Canceled task should keep the cancellation reason."
	)

	_dispose_booted_app(context)


static func _create_booted_app() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var host := Node.new()
	tree.root.add_child(host)

	var app := WooApp.new()
	host.add_child(app)
	app.boot(host)
	return {
		"host": host,
		"app": app,
	}


static func _dispose_booted_app(context: Dictionary) -> void:
	var app: WooApp = context.get("app")
	if app != null:
		app.shutdown()

	var host: Node = context.get("host")
	if host != null and is_instance_valid(host):
		host.free()
