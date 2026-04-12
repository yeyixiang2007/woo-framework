class_name TweenSystem
extends RefCounted

signal playback_started(playback: WooTweenPlayback)
signal playback_finished(playback: WooTweenPlayback)

var app
var enable_logging := false
var active_playbacks: Array[WooTweenPlayback] = []
var _task_system: TaskSystem = null


func _init(owner_app = null) -> void:
	app = owner_app


func set_app(owner_app) -> void:
	app = owner_app


func sequence() -> WooTweenSequence:
	var value := WooTweenSequence.new()
	value.attach_system(self)
	return value


func to(target: Object, property_path, target_value, duration: float) -> WooTweenStep:
	return WooTweenStep.make_property(target, property_path, target_value, duration)


func value(target_callable: Callable, from_value, to_value, duration: float) -> WooTweenStep:
	return WooTweenStep.make_method(target_callable, from_value, to_value, duration)


func callback(target_callable: Callable) -> WooTweenStep:
	return WooTweenStep.make_callback(target_callable)


func interval(duration: float) -> WooTweenStep:
	return WooTweenStep.make_interval(duration)


func play(sequence_or_step) -> WooTweenPlayback:
	if sequence_or_step is WooTweenSequence:
		return _play_sequence(sequence_or_step)
	if sequence_or_step is WooTweenStep:
		return _play_sequence(sequence().append(sequence_or_step))

	var playback := _create_playback()
	_track_playback(playback)
	playback.fail("TweenSystem: play expects a WooTweenSequence or WooTweenStep.")
	return playback


func get_task_system() -> TaskSystem:
	if _task_system != null:
		return _task_system

	var resolved_app := _ensure_app()
	if resolved_app != null and resolved_app.systems != null and resolved_app.systems.has_system(&"task"):
		var candidate = resolved_app.systems.get_system(&"task")
		if candidate is TaskSystem:
			_task_system = candidate
			return _task_system

	_task_system = TaskSystem.new(resolved_app)
	return _task_system


func get_active_playbacks() -> Array:
	_cleanup_playbacks()
	return active_playbacks.duplicate()


func kill_all() -> void:
	for playback in get_active_playbacks():
		if playback is WooTweenPlayback:
			(playback as WooTweenPlayback).kill()


func _play_sequence(sequence_value: WooTweenSequence) -> WooTweenPlayback:
	var playback := _create_playback()
	_track_playback(playback)
	if sequence_value == null:
		playback.fail("TweenSystem: sequence cannot be null.")
		return playback

	var resolved_app := _ensure_app()
	if resolved_app == null or resolved_app.get_tree() == null:
		playback.fail("TweenSystem: WooApp must be inside the SceneTree before playing tweens.")
		return playback

	if sequence_value.is_empty():
		playback.complete_immediately(sequence_value, self)
		return playback

	var tree := resolved_app.get_tree()
	var tween := tree.create_tween()
	var bound_node := sequence_value.get_bound_node()
	if bound_node != null and is_instance_valid(bound_node):
		tween.bind_node(bound_node)

	tween.set_parallel(true)
	if sequence_value.get_process_mode() >= 0:
		tween.set_process_mode(sequence_value.get_process_mode())
	if sequence_value.get_pause_mode() >= 0:
		tween.set_pause_mode(sequence_value.get_pause_mode())
	tween.set_speed_scale(sequence_value.get_speed_scale())
	tween.set_ignore_time_scale(sequence_value.get_ignore_time_scale())

	var loops := sequence_value.get_loop_count()
	if loops < 0:
		tween.set_loops()
	elif loops > 1:
		tween.set_loops(loops)

	var compiled_count := 0
	for entry in sequence_value._get_sorted_entries():
		var step: WooTweenStep = entry.get("step")
		if _append_step_tweener(tween, float(entry.get("start", 0.0)), step):
			compiled_count += 1

	if compiled_count <= 0:
		tween.kill()
		playback.fail("TweenSystem: sequence did not produce any valid tweeners.")
		return playback

	playback.start(tween, sequence_value, self)
	if enable_logging:
		print("TweenSystem started playback with ", compiled_count, " tweeners.")
	return playback


func _append_step_tweener(tween: Tween, start_time: float, step: WooTweenStep) -> bool:
	if tween == null or step == null:
		return false

	var delay := max(start_time + step.delay, 0.0)
	match step.kind:
		WooTweenStep.Kind.PROPERTY:
			if step.target == null or not is_instance_valid(step.target):
				push_error("TweenSystem: property step target is invalid.")
				return false
			var property_tweener = tween.tween_property(
				step.target,
				step.property_path,
				step.final_value,
				step.duration
			)
			property_tweener.set_delay(delay)
			if step.has_from_value:
				property_tweener.from(step.from_value)
			elif step.use_from_current:
				property_tweener.from_current()
			if step.relative:
				property_tweener.as_relative()
			if step.trans >= 0:
				property_tweener.set_trans(step.trans)
			if step.ease >= 0:
				property_tweener.set_ease(step.ease)
			return true
		WooTweenStep.Kind.METHOD:
			if not step.method_callable.is_valid():
				push_error("TweenSystem: method step callable is invalid.")
				return false
			var method_tweener = tween.tween_method(
				step.method_callable,
				step.start_value,
				step.end_value,
				step.duration
			)
			method_tweener.set_delay(delay)
			if step.trans >= 0:
				method_tweener.set_trans(step.trans)
			if step.ease >= 0:
				method_tweener.set_ease(step.ease)
			return true
		WooTweenStep.Kind.CALLBACK:
			if not step.callback_callable.is_valid():
				push_error("TweenSystem: callback step callable is invalid.")
				return false
			var callback_tweener = tween.tween_callback(step.callback_callable)
			callback_tweener.set_delay(delay)
			return true
		WooTweenStep.Kind.INTERVAL:
			# IntervalTweener does not support set_delay(), so fold the scheduled
			# start offset into the interval duration to preserve the timeline span.
			tween.tween_interval(delay + step.duration)
			return true
		_:
			push_error("TweenSystem: unsupported tween step kind.")
			return false


func _create_playback() -> WooTweenPlayback:
	var task_system := get_task_system()
	if task_system == null:
		return WooTweenPlayback.new()
	return WooTweenPlayback.new(task_system.create_source())


func _track_playback(playback: WooTweenPlayback) -> void:
	if playback == null:
		return
	active_playbacks.append(playback)
	playback.started.connect(_on_playback_started, CONNECT_ONE_SHOT)
	playback.finished.connect(_on_playback_finished, CONNECT_ONE_SHOT)


func _on_playback_started(playback: WooTweenPlayback) -> void:
	playback_started.emit(playback)


func _on_playback_finished(playback: WooTweenPlayback) -> void:
	_cleanup_playbacks()
	if enable_logging:
		print("TweenSystem finished playback.")
	playback_finished.emit(playback)


func _cleanup_playbacks() -> void:
	var remaining: Array[WooTweenPlayback] = []
	for playback in active_playbacks:
		if playback == null:
			continue
		if playback.is_finished():
			continue
		remaining.append(playback)
	active_playbacks = remaining


func _ensure_app() -> WooApp:
	if app == null:
		app = WooApp.get_instance()
	return app
