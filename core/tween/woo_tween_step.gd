class_name WooTweenStep
extends RefCounted

enum Kind {
	PROPERTY,
	METHOD,
	CALLBACK,
	INTERVAL,
}

var kind := Kind.PROPERTY
var duration := 0.0
var target: Object = null
var property_path = NodePath("")
var final_value = null
var method_callable: Callable
var callback_callable: Callable
var start_value = null
var end_value = null
var from_value = null
var has_from_value := false
var use_from_current := false
var relative := false
var trans := -1
var ease := -1
var delay := 0.0
var metadata: Dictionary = {}


static func make_property(
	target_object: Object,
	target_property,
	target_value,
	step_duration: float
) -> WooTweenStep:
	var step := WooTweenStep.new()
	step.kind = Kind.PROPERTY
	step.target = target_object
	step.property_path = target_property
	step.final_value = target_value
	step.duration = max(step_duration, 0.0)
	return step


static func make_method(
	target_callable: Callable,
	from_step_value,
	to_step_value,
	step_duration: float
) -> WooTweenStep:
	var step := WooTweenStep.new()
	step.kind = Kind.METHOD
	step.method_callable = target_callable
	step.start_value = from_step_value
	step.end_value = to_step_value
	step.duration = max(step_duration, 0.0)
	return step


static func make_callback(target_callable: Callable) -> WooTweenStep:
	var step := WooTweenStep.new()
	step.kind = Kind.CALLBACK
	step.callback_callable = target_callable
	return step


static func make_interval(step_duration: float) -> WooTweenStep:
	var step := WooTweenStep.new()
	step.kind = Kind.INTERVAL
	step.duration = max(step_duration, 0.0)
	return step


func clone() -> WooTweenStep:
	var copy := WooTweenStep.new()
	copy.kind = kind
	copy.duration = duration
	copy.target = target
	copy.property_path = property_path
	copy.final_value = final_value
	copy.method_callable = method_callable
	copy.callback_callable = callback_callable
	copy.start_value = start_value
	copy.end_value = end_value
	copy.from_value = from_value
	copy.has_from_value = has_from_value
	copy.use_from_current = use_from_current
	copy.relative = relative
	copy.trans = trans
	copy.ease = ease
	copy.delay = delay
	copy.metadata = metadata.duplicate(true)
	return copy


func get_kind_name() -> String:
	match kind:
		Kind.METHOD:
			return "method"
		Kind.CALLBACK:
			return "callback"
		Kind.INTERVAL:
			return "interval"
		_:
			return "property"


func get_total_duration() -> float:
	return max(delay, 0.0) + max(duration, 0.0)


func set_delay(seconds: float) -> WooTweenStep:
	delay = max(seconds, 0.0)
	return self


func set_trans(trans_type: int) -> WooTweenStep:
	trans = trans_type
	return self


func set_ease(ease_type: int) -> WooTweenStep:
	ease = ease_type
	return self


func from_step(value) -> WooTweenStep:
	from_value = value
	has_from_value = true
	use_from_current = false
	return self


func from_current() -> WooTweenStep:
	use_from_current = true
	has_from_value = false
	return self


func as_relative() -> WooTweenStep:
	relative = true
	return self


func with_metadata(key: StringName, value) -> WooTweenStep:
	metadata[key] = value
	return self
