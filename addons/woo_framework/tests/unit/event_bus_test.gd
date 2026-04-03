extends RefCounted


class EventListener:
	extends RefCounted

	var calls := 0
	var last_value := -1

	func on_event(value: int) -> void:
		calls += 1
		last_value = value


static func run(runner) -> void:
	var bus := EventBus.new()
	bus.declare_event(&"unit_event")
	runner.expect_true(bus.has_event(&"unit_event"), "EventBus should store declared events.")

	var listener := EventListener.new()
	var listener_callable := Callable(listener, "on_event")

	bus.on(&"unit_event", listener_callable)
	bus.emit_event(&"unit_event", [7])
	runner.expect_equal(listener.calls, 1, "EventBus should call registered listeners.")
	runner.expect_equal(listener.last_value, 7, "EventBus should pass payload arguments.")

	bus.once(&"unit_event", listener_callable)
	bus.emit_event(&"unit_event", [9])
	bus.emit_event(&"unit_event", [11])
	runner.expect_equal(listener.calls, 4, "EventBus once listeners should run only for one emit.")
	runner.expect_equal(listener.last_value, 11, "EventBus should continue notifying normal listeners.")

	bus.off(&"unit_event", listener_callable)
	bus.emit_event(&"unit_event", [13])
	runner.expect_equal(listener.calls, 4, "EventBus off should remove listeners.")
