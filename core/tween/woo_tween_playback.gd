class_name WooTweenPlayback
extends RefCounted

signal started(playback: WooTweenPlayback)
signal paused(playback: WooTweenPlayback)
signal resumed(playback: WooTweenPlayback)
signal completed(playback: WooTweenPlayback)
signal killed(playback: WooTweenPlayback)
signal failed(playback: WooTweenPlayback, message: String)
signal finished(playback: WooTweenPlayback)
signal loop_finished(loop_index: int)
signal step_finished(step_index: int)

enum State {
	READY,
	RUNNING,
	PAUSED,
	COMPLETED,
	KILLED,
	FAILED,
}

var sequence: WooTweenSequence = null
var tween: Tween = null
var task: WooTask = null
var error_message := ""
var state := State.READY

var _source: WooTaskCompletionSource = null


func _init(task_source: WooTaskCompletionSource = null) -> void:
	_source = task_source if task_source != null else WooTaskCompletionSource.new()
	task = _source.task


func is_running() -> bool:
	return state == State.RUNNING


func is_finished() -> bool:
	return state == State.COMPLETED or state == State.KILLED or state == State.FAILED


func start(tween_instance: Tween, sequence_ref: WooTweenSequence, _owner_system = null) -> WooTweenPlayback:
	sequence = sequence_ref
	tween = tween_instance
	if tween == null:
		return fail("WooTweenPlayback: cannot start without a Tween instance.")

	state = State.RUNNING
	tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)
	tween.step_finished.connect(_on_step_finished)
	tween.loop_finished.connect(_on_loop_finished)
	started.emit(self)
	return self


func complete_immediately(sequence_ref: WooTweenSequence, _owner_system = null) -> WooTweenPlayback:
	sequence = sequence_ref
	state = State.RUNNING
	started.emit(self)
	state = State.COMPLETED
	completed.emit(self)
	finished.emit(self)
	_source.resolve(self)
	return self


func fail(message: String) -> WooTweenPlayback:
	if is_finished():
		return self

	error_message = message
	state = State.FAILED
	failed.emit(self, message)
	finished.emit(self)
	_source.fail(message)
	return self


func pause() -> WooTweenPlayback:
	if tween == null or not is_instance_valid(tween) or state != State.RUNNING:
		return self
	tween.pause()
	state = State.PAUSED
	paused.emit(self)
	return self


func resume() -> WooTweenPlayback:
	if tween == null or not is_instance_valid(tween) or state != State.PAUSED:
		return self
	tween.play()
	state = State.RUNNING
	resumed.emit(self)
	return self


func kill(reason := "Tween killed.") -> WooTweenPlayback:
	if is_finished():
		return self
	if tween != null and is_instance_valid(tween):
		tween.kill()

	state = State.KILLED
	killed.emit(self)
	finished.emit(self)
	_source.cancel(reason)
	return self


func _on_tween_finished() -> void:
	if is_finished():
		return
	state = State.COMPLETED
	completed.emit(self)
	finished.emit(self)
	_source.resolve(self)


func _on_step_finished(step_index: int) -> void:
	step_finished.emit(step_index)


func _on_loop_finished(loop_index: int) -> void:
	loop_finished.emit(loop_index)
