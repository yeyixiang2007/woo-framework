extends RefCounted


class CallbackProbe:
	extends RefCounted

	var callback_count := 0

	func mark() -> void:
		callback_count += 1


static func run(runner) -> void:
	var context := _create_booted_app()
	var host: Node = context.get("host")
	var app: WooApp = context.get("app")
	var tween_system := TweenSystem.new(app)

	var target := Node2D.new()
	host.add_child(target)

	var probe := CallbackProbe.new()
	var sequence := tween_system.sequence()
	sequence.append_interval(0.1)
	sequence.append(tween_system.to(target, "position", Vector2(10, 0), 0.3))
	sequence.join(tween_system.to(target, "scale", Vector2(2, 2), 0.3))
	sequence.insert_callback(0.05, Callable(probe, "mark"))

	runner.expect_true(
		is_equal_approx(sequence.get_total_duration(), 0.4),
		"Sequence duration should account for append/join/insert timing."
	)

	var snapshot := sequence.get_timeline_snapshot()
	runner.expect_equal(snapshot.size(), 4, "Sequence snapshot should include all inserted steps.")
	if snapshot.size() == 4:
		runner.expect_equal(String(snapshot[0].get("kind", "")), "interval", "First snapshot entry should be the interval step.")
		runner.expect_equal(String(snapshot[1].get("kind", "")), "callback", "Inserted callback should be sorted by start time.")
		runner.expect_equal(String(snapshot[2].get("kind", "")), "property", "Property tween should appear in the snapshot.")
		runner.expect_equal(String(snapshot[3].get("kind", "")), "property", "Joined property tween should appear in the snapshot.")

	_dispose_booted_app(context)


static func run_async(runner) -> void:
	var context := _create_booted_app()
	var host: Node = context.get("host")
	var app: WooApp = context.get("app")
	var tween_system := TweenSystem.new(app)

	var target := Node2D.new()
	target.position = Vector2.ZERO
	target.scale = Vector2.ONE
	host.add_child(target)

	var probe := CallbackProbe.new()
	var sequence := tween_system.sequence()
	sequence.append_interval(0.01)
	sequence.append(
		tween_system
			.to(target, "position", Vector2(30, 0), 0.03)
			.set_trans(Tween.TRANS_LINEAR)
			.set_ease(Tween.EASE_IN_OUT)
	)
	sequence.join(tween_system.to(target, "scale", Vector2(2, 2), 0.03))
	sequence.insert_callback(0.0, Callable(probe, "mark"))

	var playback := sequence.play()
	await playback.finished

	runner.expect_true(playback.state == WooTweenPlayback.State.COMPLETED, "Playback should complete successfully.")
	runner.expect_true(playback.task.is_succeeded(), "Playback should resolve its task on completion.")
	runner.expect_true(is_equal_approx(target.position.x, 30.0), "Tween should move the target to the final position.")
	runner.expect_true(is_equal_approx(target.scale.x, 2.0), "Joined tween should update the final scale.")
	runner.expect_equal(probe.callback_count, 1, "Inserted callback should run exactly once.")
	runner.expect_equal(tween_system.get_active_playbacks().size(), 0, "Completed playback should be removed from the active list.")

	var kill_playback := tween_system.play(
		tween_system.sequence().append(tween_system.to(target, "position", Vector2(80, 0), 0.2))
	)
	kill_playback.kill("manual stop")
	await app.get_tree().process_frame
	runner.expect_true(kill_playback.state == WooTweenPlayback.State.KILLED, "kill should transition playback into killed state.")
	runner.expect_true(kill_playback.task.is_canceled(), "Killed playback should cancel its task.")

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
