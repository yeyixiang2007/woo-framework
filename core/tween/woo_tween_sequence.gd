class_name WooTweenSequence
extends RefCounted

var system = null
var _entries: Array = []
var _cursor := 0.0
var _last_start_time := 0.0
var _duration := 0.0
var _default_trans := -1
var _default_ease := -1
var _process_mode := -1
var _pause_mode := -1
var _speed_scale := 1.0
var _ignore_time_scale := false
var _loops := 1
var _bound_node: Node = null
var metadata: Dictionary = {}


func attach_system(owner_system) -> WooTweenSequence:
	system = owner_system
	return self


func bind_node(node: Node) -> WooTweenSequence:
	_bound_node = node
	return self


func set_default_trans(trans_type: int) -> WooTweenSequence:
	_default_trans = trans_type
	return self


func set_default_ease(ease_type: int) -> WooTweenSequence:
	_default_ease = ease_type
	return self


func set_process_mode(mode: int) -> WooTweenSequence:
	_process_mode = mode
	return self


func set_pause_mode(mode: int) -> WooTweenSequence:
	_pause_mode = mode
	return self


func set_speed_scale(scale: float) -> WooTweenSequence:
	_speed_scale = max(scale, 0.0001)
	return self


func set_ignore_time_scale(enabled: bool) -> WooTweenSequence:
	_ignore_time_scale = enabled
	return self


func set_loops(loop_count: int) -> WooTweenSequence:
	_loops = max(loop_count, 1)
	return self


func set_infinite_loops() -> WooTweenSequence:
	_loops = -1
	return self


func append(step: WooTweenStep) -> WooTweenSequence:
	var prepared := _prepare_step(step)
	if prepared == null:
		return self

	var start_time := _cursor
	_add_entry(start_time, prepared)
	_last_start_time = start_time
	_cursor = max(_cursor, start_time + prepared.get_total_duration())
	_duration = max(_duration, _cursor)
	return self


func join(step: WooTweenStep) -> WooTweenSequence:
	var prepared := _prepare_step(step)
	if prepared == null:
		return self

	var start_time := 0.0 if _entries.is_empty() else _last_start_time
	_add_entry(start_time, prepared)
	_cursor = max(_cursor, start_time + prepared.get_total_duration())
	_duration = max(_duration, _cursor)
	return self


func insert(at_time: float, step: WooTweenStep) -> WooTweenSequence:
	var prepared := _prepare_step(step)
	if prepared == null:
		return self

	var start_time := max(at_time, 0.0)
	_add_entry(start_time, prepared)
	_last_start_time = start_time
	_duration = max(_duration, start_time + prepared.get_total_duration())
	_cursor = max(_cursor, _duration)
	return self


func append_interval(seconds: float) -> WooTweenSequence:
	return append(WooTweenStep.make_interval(seconds))


func join_interval(seconds: float) -> WooTweenSequence:
	return join(WooTweenStep.make_interval(seconds))


func insert_interval(at_time: float, seconds: float) -> WooTweenSequence:
	return insert(at_time, WooTweenStep.make_interval(seconds))


func append_callback(callback: Callable) -> WooTweenSequence:
	return append(WooTweenStep.make_callback(callback))


func join_callback(callback: Callable) -> WooTweenSequence:
	return join(WooTweenStep.make_callback(callback))


func insert_callback(at_time: float, callback: Callable) -> WooTweenSequence:
	return insert(at_time, WooTweenStep.make_callback(callback))


func append_property(
	target: Object,
	property_path,
	target_value,
	step_duration: float
) -> WooTweenSequence:
	return append(WooTweenStep.make_property(target, property_path, target_value, step_duration))


func join_property(
	target: Object,
	property_path,
	target_value,
	step_duration: float
) -> WooTweenSequence:
	return join(WooTweenStep.make_property(target, property_path, target_value, step_duration))


func insert_property(
	at_time: float,
	target: Object,
	property_path,
	target_value,
	step_duration: float
) -> WooTweenSequence:
	return insert(at_time, WooTweenStep.make_property(target, property_path, target_value, step_duration))


func append_method(
	target_callable: Callable,
	from_value,
	to_value,
	step_duration: float
) -> WooTweenSequence:
	return append(WooTweenStep.make_method(target_callable, from_value, to_value, step_duration))


func join_method(
	target_callable: Callable,
	from_value,
	to_value,
	step_duration: float
) -> WooTweenSequence:
	return join(WooTweenStep.make_method(target_callable, from_value, to_value, step_duration))


func insert_method(
	at_time: float,
	target_callable: Callable,
	from_value,
	to_value,
	step_duration: float
) -> WooTweenSequence:
	return insert(at_time, WooTweenStep.make_method(target_callable, from_value, to_value, step_duration))


func append_sequence(sequence: WooTweenSequence) -> WooTweenSequence:
	return _merge_sequence(_cursor, sequence)


func join_sequence(sequence: WooTweenSequence) -> WooTweenSequence:
	var start_time := 0.0 if _entries.is_empty() else _last_start_time
	return _merge_sequence(start_time, sequence)


func insert_sequence(at_time: float, sequence: WooTweenSequence) -> WooTweenSequence:
	return _merge_sequence(max(at_time, 0.0), sequence)


func play() -> WooTweenPlayback:
	if system == null:
		var playback := WooTweenPlayback.new()
		playback.fail("WooTweenSequence: no TweenSystem is attached.")
		return playback
	return system.play(self)


func is_empty() -> bool:
	return _entries.is_empty()


func clear() -> WooTweenSequence:
	_entries.clear()
	_cursor = 0.0
	_last_start_time = 0.0
	_duration = 0.0
	return self


func get_total_duration() -> float:
	return _duration


func get_effective_duration() -> float:
	if _loops < 0:
		return -1.0
	return _duration * max(_loops, 1)


func get_loop_count() -> int:
	return _loops


func get_bound_node() -> Node:
	return _bound_node


func get_process_mode() -> int:
	return _process_mode


func get_pause_mode() -> int:
	return _pause_mode


func get_speed_scale() -> float:
	return _speed_scale


func get_ignore_time_scale() -> bool:
	return _ignore_time_scale


func get_default_trans() -> int:
	return _default_trans


func get_default_ease() -> int:
	return _default_ease


func duplicate_sequence() -> WooTweenSequence:
	var copy := WooTweenSequence.new()
	copy.system = system
	copy._cursor = _cursor
	copy._last_start_time = _last_start_time
	copy._duration = _duration
	copy._default_trans = _default_trans
	copy._default_ease = _default_ease
	copy._process_mode = _process_mode
	copy._pause_mode = _pause_mode
	copy._speed_scale = _speed_scale
	copy._ignore_time_scale = _ignore_time_scale
	copy._loops = _loops
	copy._bound_node = _bound_node
	copy.metadata = metadata.duplicate(true)
	for entry in _entries:
		copy._entries.append({
			"start": float(entry.get("start", 0.0)),
			"step": (entry.get("step") as WooTweenStep).clone(),
		})
	return copy


func get_timeline_snapshot() -> Array:
	var snapshot: Array = []
	for entry in _get_sorted_entries():
		var step: WooTweenStep = entry.get("step")
		snapshot.append({
			"start_time": float(entry.get("start", 0.0)),
			"delay": 0.0 if step == null else step.delay,
			"duration": 0.0 if step == null else step.duration,
			"total_duration": 0.0 if step == null else step.get_total_duration(),
			"kind": "" if step == null else step.get_kind_name(),
		})
	return snapshot


func _get_sorted_entries() -> Array:
	var sorted_entries := _entries.duplicate()
	sorted_entries.sort_custom(_sort_entries_by_start)
	return sorted_entries


func _prepare_step(step: WooTweenStep) -> WooTweenStep:
	if step == null:
		return null
	var prepared := step.clone()
	if prepared.trans < 0 and _default_trans >= 0:
		prepared.set_trans(_default_trans)
	if prepared.ease < 0 and _default_ease >= 0:
		prepared.set_ease(_default_ease)
	return prepared


func _merge_sequence(at_time: float, sequence: WooTweenSequence) -> WooTweenSequence:
	if sequence == null:
		return self
	if sequence.get_loop_count() < 0:
		push_error("WooTweenSequence: nested infinite loops are not supported.")
		return self

	var repeat_count: int = max(sequence.get_loop_count(), 1)
	var single_duration: float = sequence.get_total_duration()
	for repeat_index in range(repeat_count):
		var loop_offset: float = at_time + (single_duration * float(repeat_index))
		for entry in sequence._entries:
			var step: WooTweenStep = entry.get("step")
			if step == null:
				continue
			_add_entry(loop_offset + float(entry.get("start", 0.0)), _inherit_step_defaults(step, sequence))

	var merged_duration: float = at_time + (single_duration * float(repeat_count))
	_last_start_time = at_time
	_duration = max(_duration, merged_duration)
	_cursor = max(_cursor, merged_duration)
	return self


func _inherit_step_defaults(step: WooTweenStep, sequence: WooTweenSequence) -> WooTweenStep:
	var inherited := step.clone()
	if inherited.trans < 0 and sequence.get_default_trans() >= 0:
		inherited.set_trans(sequence.get_default_trans())
	if inherited.ease < 0 and sequence.get_default_ease() >= 0:
		inherited.set_ease(sequence.get_default_ease())
	return inherited


func _add_entry(start_time: float, step: WooTweenStep) -> void:
	_entries.append({
		"start": max(start_time, 0.0),
		"step": step,
	})


func _sort_entries_by_start(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("start", 0.0)) < float(right.get("start", 0.0))
