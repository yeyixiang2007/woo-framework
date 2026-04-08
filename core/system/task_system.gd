class_name TaskSystem
extends RefCounted

signal task_created(task: WooTask)
signal task_finished(task: WooTask)


class _TaskSignalWatcher:
	extends RefCounted

	var owner
	var source: WooTaskCompletionSource
	var signal_ref
	var cancel_token: WooCancellationToken
	var capture_first_arg := false

	func start() -> void:
		if owner == null or source == null:
			return
		if cancel_token != null and cancel_token.is_canceled():
			source.cancel(cancel_token.get_reason())
			_cleanup()
			return
		if signal_ref == null:
			source.fail("TaskSystem: signal watcher requires a valid signal.")
			_cleanup()
			return

		signal_ref.connect(_on_signal, CONNECT_ONE_SHOT)
		if cancel_token != null:
			cancel_token.canceled.connect(_on_canceled, CONNECT_ONE_SHOT)

	func _on_signal(first_arg = null) -> void:
		if source != null:
			source.resolve(first_arg if capture_first_arg else null)
		_cleanup()

	func _on_canceled(reason := "") -> void:
		if source != null:
			source.cancel(reason)
		_cleanup()

	func _cleanup() -> void:
		if signal_ref != null and signal_ref.is_connected(_on_signal):
			signal_ref.disconnect(_on_signal)
		if cancel_token != null and cancel_token.canceled.is_connected(_on_canceled):
			cancel_token.canceled.disconnect(_on_canceled)
		if owner != null:
			owner._release_watcher(self)


class _TaskConditionWatcher:
	extends RefCounted

	var owner
	var source: WooTaskCompletionSource
	var predicate: Callable
	var cancel_token: WooCancellationToken
	var use_physics_frame := false
	var timeout_seconds := -1.0
	var _started_at_seconds := 0.0
	var _frame_signal = null

	func start() -> void:
		if owner == null or source == null:
			return
		if cancel_token != null and cancel_token.is_canceled():
			source.cancel(cancel_token.get_reason())
			_cleanup()
			return
		if predicate == null or not predicate.is_valid():
			source.fail("TaskSystem: wait_until requires a valid predicate.")
			_cleanup()
			return

		_started_at_seconds = Time.get_ticks_usec() / 1000000.0
		if cancel_token != null:
			cancel_token.canceled.connect(_on_canceled, CONNECT_ONE_SHOT)
		_schedule_next_tick()

	func _on_tick() -> void:
		if owner == null or source == null or source.task.is_finished():
			_cleanup()
			return

		if timeout_seconds >= 0.0:
			var elapsed := (Time.get_ticks_usec() / 1000000.0) - _started_at_seconds
			if elapsed >= timeout_seconds:
				source.fail("TaskSystem: wait_until timed out.")
				_cleanup()
				return

		var value = predicate.call()
		if bool(value):
			source.resolve(value)
			_cleanup()
			return

		_schedule_next_tick()

	func _on_canceled(reason := "") -> void:
		if source != null:
			source.cancel(reason)
		_cleanup()

	func _schedule_next_tick() -> void:
		var tree : SceneTree = owner._get_tree()
		if tree == null:
			source.fail("TaskSystem: wait_until requires WooApp to be inside the SceneTree.")
			_cleanup()
			return
		_frame_signal = tree.physics_frame if use_physics_frame else tree.process_frame
		_frame_signal.connect(_on_tick, CONNECT_ONE_SHOT)

	func _cleanup() -> void:
		if _frame_signal != null and _frame_signal.is_connected(_on_tick):
			_frame_signal.disconnect(_on_tick)
		if cancel_token != null and cancel_token.canceled.is_connected(_on_canceled):
			cancel_token.canceled.disconnect(_on_canceled)
		if owner != null:
			owner._release_watcher(self)


class _TaskAllWatcher:
	extends RefCounted

	var owner
	var source: WooTaskCompletionSource
	var tasks: Array[WooTask] = []
	var results: Array = []
	var cancel_token: WooCancellationToken
	var _remaining := 0
	var _task_connections: Array = []

	func start() -> void:
		if owner == null or source == null:
			return
		if cancel_token != null and cancel_token.is_canceled():
			source.cancel(cancel_token.get_reason())
			_cleanup()
			return
		if tasks.is_empty():
			source.resolve([])
			_cleanup()
			return

		results.resize(tasks.size())
		_remaining = tasks.size()
		if cancel_token != null:
			cancel_token.canceled.connect(_on_canceled, CONNECT_ONE_SHOT)

		for index in range(tasks.size()):
			_attach_task(index, tasks[index])

	func _attach_task(index: int, task: WooTask) -> void:
		if task == null:
			source.fail({
				"index": index,
				"reason": "TaskSystem: when_all received a null task.",
			})
			_cleanup()
			return
		if task.is_finished():
			_on_task_finished(task, index)
			return
		var callback := _on_task_finished.bind(index)
		task.finished.connect(callback, CONNECT_ONE_SHOT)
		_task_connections.append({
			"task": task,
			"callback": callback,
		})

	func _on_task_finished(task: WooTask, index: int) -> void:
		if source == null or source.task.is_finished():
			_cleanup()
			return

		if task.is_failed():
			source.fail({
				"index": index,
				"task": task,
				"error": task.get_error(),
			})
			_cleanup()
			return

		if task.is_canceled():
			source.cancel(task.get_cancel_reason())
			_cleanup()
			return

		results[index] = task.get_result()
		_remaining -= 1
		if _remaining <= 0:
			source.resolve(results.duplicate())
			_cleanup()

	func _on_canceled(reason := "") -> void:
		if source != null:
			source.cancel(reason)
		_cleanup()

	func _cleanup() -> void:
		for entry in _task_connections:
			var task: WooTask = entry.get("task")
			var callback: Callable = entry.get("callback")
			if task != null and task.finished.is_connected(callback):
				task.finished.disconnect(callback)
		_task_connections.clear()
		if cancel_token != null and cancel_token.canceled.is_connected(_on_canceled):
			cancel_token.canceled.disconnect(_on_canceled)
		if owner != null:
			owner._release_watcher(self)


class _TaskAnyWatcher:
	extends RefCounted

	var owner
	var source: WooTaskCompletionSource
	var tasks: Array[WooTask] = []
	var cancel_token: WooCancellationToken
	var _task_connections: Array = []

	func start() -> void:
		if owner == null or source == null:
			return
		if cancel_token != null and cancel_token.is_canceled():
			source.cancel(cancel_token.get_reason())
			_cleanup()
			return
		if tasks.is_empty():
			source.resolve({})
			_cleanup()
			return

		if cancel_token != null:
			cancel_token.canceled.connect(_on_canceled, CONNECT_ONE_SHOT)

		for index in range(tasks.size()):
			_attach_task(index, tasks[index])
			if source.task.is_finished():
				return

	func _attach_task(index: int, task: WooTask) -> void:
		if task == null:
			source.resolve({
				"index": index,
				"task": null,
				"status": "failed",
				"error": "TaskSystem: when_any received a null task.",
			})
			_cleanup()
			return
		if task.is_finished():
			_on_task_finished(task, index)
			return
		var callback := _on_task_finished.bind(index)
		task.finished.connect(callback, CONNECT_ONE_SHOT)
		_task_connections.append({
			"task": task,
			"callback": callback,
		})

	func _on_task_finished(task: WooTask, index: int) -> void:
		if source == null or source.task.is_finished():
			_cleanup()
			return

		var payload := {
			"index": index,
			"task": task,
			"status": task.get_status_name(),
			"result": task.get_result(),
			"error": task.get_error(),
			"cancel_reason": task.get_cancel_reason(),
		}
		source.resolve(payload)
		_cleanup()

	func _on_canceled(reason := "") -> void:
		if source != null:
			source.cancel(reason)
		_cleanup()

	func _cleanup() -> void:
		for entry in _task_connections:
			var task: WooTask = entry.get("task")
			var callback: Callable = entry.get("callback")
			if task != null and task.finished.is_connected(callback):
				task.finished.disconnect(callback)
		_task_connections.clear()
		if cancel_token != null and cancel_token.canceled.is_connected(_on_canceled):
			cancel_token.canceled.disconnect(_on_canceled)
		if owner != null:
			owner._release_watcher(self)


var app
var enable_logging := false
var _watchers: Array = []


func _init(owner_app = null) -> void:
	app = owner_app


func set_app(owner_app) -> void:
	app = owner_app


func create_source() -> WooTaskCompletionSource:
	var source := WooTaskCompletionSource.new()
	_track_task(source.task)
	return source


func completed(result = null) -> WooTask:
	var source := create_source()
	source.resolve(result)
	return source.task


func failed(error = null) -> WooTask:
	var source := create_source()
	source.fail(error)
	return source.task


func canceled(reason := "") -> WooTask:
	var source := create_source()
	source.cancel(reason)
	return source.task


func create_cancellation_source() -> WooCancellationSource:
	return WooCancellationSource.new()


func as_task(value) -> WooTask:
	if value is WooTask:
		return value as WooTask
	return completed(value)


func delay(
	seconds: float,
	cancel_token: WooCancellationToken = null,
	process_in_physics := false,
	process_always := true,
	ignore_time_scale := false
) -> WooTask:
	var source := create_source()
	var tree := _get_tree()
	if tree == null:
		source.fail("TaskSystem: delay requires WooApp to be inside the SceneTree.")
		return source.task

	var timer := tree.create_timer(max(seconds, 0.0), process_always, process_in_physics, ignore_time_scale)
	var watcher := _TaskSignalWatcher.new()
	watcher.owner = self
	watcher.source = source
	watcher.signal_ref = timer.timeout
	watcher.cancel_token = cancel_token
	_track_watcher(watcher)
	watcher.start()
	return source.task


func next_frame(cancel_token: WooCancellationToken = null) -> WooTask:
	return from_signal(_get_frame_signal(false), cancel_token)


func next_physics_frame(cancel_token: WooCancellationToken = null) -> WooTask:
	return from_signal(_get_frame_signal(true), cancel_token)


func from_signal(
	signal_ref,
	cancel_token: WooCancellationToken = null,
	capture_first_arg := false
) -> WooTask:
	var source := create_source()
	if signal_ref == null:
		source.fail("TaskSystem: from_signal requires a valid signal.")
		return source.task

	var watcher := _TaskSignalWatcher.new()
	watcher.owner = self
	watcher.source = source
	watcher.signal_ref = signal_ref
	watcher.cancel_token = cancel_token
	watcher.capture_first_arg = capture_first_arg
	_track_watcher(watcher)
	watcher.start()
	return source.task


func wait_until(
	predicate: Callable,
	cancel_token: WooCancellationToken = null,
	use_physics_frame := false,
	timeout_seconds := -1.0
) -> WooTask:
	var source := create_source()
	var watcher := _TaskConditionWatcher.new()
	watcher.owner = self
	watcher.source = source
	watcher.predicate = predicate
	watcher.cancel_token = cancel_token
	watcher.use_physics_frame = use_physics_frame
	watcher.timeout_seconds = timeout_seconds
	_track_watcher(watcher)
	watcher.start()
	return source.task


func when_all(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask:
	var source := create_source()
	var normalized_tasks: Array[WooTask] = []
	for task_value in tasks:
		normalized_tasks.append(as_task(task_value))

	var watcher := _TaskAllWatcher.new()
	watcher.owner = self
	watcher.source = source
	watcher.tasks = normalized_tasks
	watcher.cancel_token = cancel_token
	_track_watcher(watcher)
	watcher.start()
	return source.task


func when_any(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask:
	var source := create_source()
	var normalized_tasks: Array[WooTask] = []
	for task_value in tasks:
		normalized_tasks.append(as_task(task_value))

	var watcher := _TaskAnyWatcher.new()
	watcher.owner = self
	watcher.source = source
	watcher.tasks = normalized_tasks
	watcher.cancel_token = cancel_token
	_track_watcher(watcher)
	watcher.start()
	return source.task


func race(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask:
	return when_any(tasks, cancel_token)


func join(task_value):
	var task := as_task(task_value)
	if not task.is_finished():
		await task.finished

	if task.is_failed():
		push_error("TaskSystem.join failed: %s" % str(task.get_error()))
		return null

	if task.is_canceled():
		push_error("TaskSystem.join canceled: %s" % task.get_cancel_reason())
		return null

	return task.get_result()


func _get_tree() -> SceneTree:
	var resolved_app := _ensure_app()
	if resolved_app == null:
		return null
	return resolved_app.get_tree()


func _get_frame_signal(use_physics_frame: bool):
	var tree := _get_tree()
	if tree == null:
		return null
	return tree.physics_frame if use_physics_frame else tree.process_frame


func _ensure_app() -> WooApp:
	if app == null:
		app = WooApp.get_instance()
	return app


func _track_task(task: WooTask) -> void:
	if task == null:
		return
	task_created.emit(task)
	if enable_logging:
		print("TaskSystem created task: ", task)
	task.finished.connect(_on_task_finished, CONNECT_ONE_SHOT)


func _on_task_finished(task: WooTask) -> void:
	if enable_logging:
		print("TaskSystem finished task: ", task.get_status_name())
	task_finished.emit(task)


func _track_watcher(watcher: RefCounted) -> void:
	if watcher == null:
		return
	_watchers.append(watcher)


func _release_watcher(watcher: RefCounted) -> void:
	var index := _watchers.find(watcher)
	if index >= 0:
		_watchers.remove_at(index)
