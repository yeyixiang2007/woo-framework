# Core Runtime API (English)

This document covers the runtime core APIs under `core/`.

## 1. App entry points

## `Woo` (`core/app/woo.gd`)

Global static accessor (global script class).

Methods:
- `set_app(instance: WooApp) -> void`
- `clear_app() -> void`
- `get_app() -> WooApp`

---

## `WooApp` (`core/app/woo_app.gd`)

Main runtime container aggregating modules, models, buses, and systems.

Signals:
- `bootstrapped(app: WooApp)`
- `root_scene_changed(root_scene: Node)`
- `state_changed(key: StringName, value: Variant)`
- `shutting_down()`

Static:
- `get_instance() -> WooApp`

Methods:
- `boot(owner: Node) -> void`
- `mount_root_scene(scene: Node) -> void`
- `shutdown() -> void`
- `has_started() -> bool`
- `set_state_value(key: StringName, value: Variant) -> void`
- `get_state_value(key: StringName, default_value: Variant = null) -> Variant`
- `get_runtime_snapshot() -> Dictionary`

Key properties:
- `modules: ModuleRegistry`
- `models: ModelStore`
- `events: EventBus`
- `commands: CommandBus`
- `queries: QueryService`
- `systems: SystemRegistry`
- `runtime_state: Dictionary`

---

## `WooBootstrap` (`core/app/woo_bootstrap.gd`)

Runtime bootstrap node for main scene startup.

Signals:
- `startup_scene_loaded(scene: Node)`
- `modules_booted(module_ids)`

Exported fields:
- `startup_scene_path: String`
- `auto_boot_modules: bool`
- `module_root_paths: PackedStringArray`
- `enable_debug_panel: bool`
- `debug_panel_script_path: String`

Behavior:
- `_ready()` runs `boot -> optional module boot -> startup scene mount -> optional debug panel mount`.

## 2. Buses and registries

## `EventBus` (`core/bus/event_bus.gd`)

Event ID based pub/sub.

Signals:
- `event_declared(event_id: StringName)`
- `listener_added(event_id: StringName)`
- `listener_removed(event_id: StringName)`
- `event_emitted(event_id: StringName, payload)`

Methods:
- `declare_event(event_id: StringName) -> void`
- `has_event(event_id: StringName) -> bool`
- `on(event_id: StringName, listener: Callable) -> void`
- `once(event_id: StringName, listener: Callable) -> void`
- `off(event_id: StringName, listener: Callable) -> void`
- `emit_event(event_id: StringName, args: Array = []) -> void`
- `clear() -> void`

Note:
- Listeners are called by `callv(args)`, so `args` is the argument list.

---

## `CommandBus` (`core/command/command_bus.gd`)

Command dispatcher (side-effect oriented).

Signals:
- `command_registered(command_id: StringName)`
- `command_executed(command_id: StringName, payload, result)`
- `command_failed(command_id: StringName, payload, reason: String)`

Methods:
- `register_definition(id: StringName, handler_ref: Variant, owner_module_id: StringName = &"") -> bool`
- `execute(command_id: StringName, payload = null, context_override: CommandContext = null)`
- `has_command(id: StringName) -> bool`
- `clear() -> void`

Handler forms:
- `Callable(context, payload)`
- `Script` with `execute(context, payload)`
- `Object` with `execute(context, payload)`

---

## `QueryService` (`core/query/query_service.gd`)

Query dispatcher (read-oriented).

Signals:
- `query_registered(query_id: StringName)`
- `query_executed(query_id: StringName, payload, result)`
- `query_failed(query_id: StringName, payload, reason: String)`

Methods:
- `register_definition(id: StringName, handler_ref: Variant, owner_module_id: StringName = &"") -> bool`
- `query(query_id: StringName, payload = null, context_override: QueryContext = null)`
- `has_query(id: StringName) -> bool`
- `clear() -> void`

---

## `ModelStore` (`core/model/model_store.gd`)

Model definition and instance store (`Resource` models).

Signals:
- `model_registered(id: StringName)`
- `model_built(id: StringName, instance: Resource)`
- `model_replaced(id: StringName, instance: Resource)`

Methods:
- `register_definition(id: StringName, script_ref: Variant, default_resource: Variant = null, owner_module_id: StringName = &"") -> bool`
- `has_model(id: StringName) -> bool`
- `get_model_ids() -> Array`
- `get_model(id: StringName) -> Resource`
- `set_model(id: StringName, instance: Resource) -> bool`
- `get_definition(id: StringName) -> Dictionary`
- `clear() -> void`

Behavior:
- First `get_model()` call lazily builds the instance.
- If default resource exists, it is cloned via `duplicate(true)`.

---

## `SystemRegistry` (`core/system/system_registry.gd`)

System definition and lazy instance registry.

Signals:
- `system_registered(system_id: StringName)`
- `system_built(system_id: StringName, instance: Object)`
- `system_replaced(system_id: StringName, instance: Object)`

Methods:
- `register_definition(id: StringName, script_ref: Variant, owner_module_id: StringName = &"") -> bool`
- `has_system(id: StringName) -> bool`
- `get_system(id: StringName) -> Object`
- `set_system(id: StringName, instance: Object) -> bool`
- `clear() -> void`

Injection rules:
- If instance has `set_app(app)`, call it first.
- Otherwise set writable `app` property when available.

## 3. Context types

## `CommandContext` (`core/command/command_context.gd`)

Command execution context.

Properties:
- `app`
- `models: ModelStore`
- `events: EventBus`
- `queries: QueryService`
- `command_id: StringName`
- `payload`
- `metadata: Dictionary`

Methods:
- `get_model(id: StringName) -> Resource`
- `set_state(key: StringName, value: Variant) -> void`
- `get_state(key: StringName, default_value: Variant = null) -> Variant`
- `emit_event(event_id: StringName, args: Array = []) -> void`

---

## `QueryContext` (`core/query/query_context.gd`)

Query execution context.

Properties:
- `app`
- `models: ModelStore`
- `query_id: StringName`
- `payload`

Methods:
- `get_model(id: StringName) -> Resource`
- `get_state(key: StringName, default_value: Variant = null) -> Variant`

## 4. Presentation base classes

## `ControllerBase` (`core/presentation/controller_base.gd`)

Methods:
- `on_app_ready(_app: WooApp) -> void`
- `bind() -> void`
- `unbind() -> void`
- `execute_command(command_id: StringName, payload = null)`
- `query_state(query_id: StringName, payload = null)`
- `emit_event(event_id: StringName, args: Array = []) -> void`

---

## `PresenterBase` (`core/presentation/presenter_base.gd`)

Methods:
- `set_view(view_node: Node) -> void`
- `on_app_ready(_app: WooApp) -> void`
- `on_view_ready(_view: Node) -> void`
- `bind() -> void`
- `unbind() -> void`

---

## `ViewBase` (`core/presentation/view_base.gd`)

Methods:
- `set_presenter(presenter_instance: Node) -> void`
- `on_view_ready() -> void`

## 5. Built-in systems

## `TaskSystem` (`core/system/task_system.gd`)

Signals:
- `task_created(task: WooTask)`
- `task_finished(task: WooTask)`

Methods:
- `set_app(owner_app) -> void`
- `create_source() -> WooTaskCompletionSource`
- `completed(result = null) -> WooTask`
- `failed(error = null) -> WooTask`
- `canceled(reason := "") -> WooTask`
- `create_cancellation_source() -> WooCancellationSource`
- `as_task(value) -> WooTask`
- `delay(seconds: float, cancel_token: WooCancellationToken = null, process_in_physics := false, process_always := true, ignore_time_scale := false) -> WooTask`
- `next_frame(cancel_token: WooCancellationToken = null) -> WooTask`
- `next_physics_frame(cancel_token: WooCancellationToken = null) -> WooTask`
- `from_signal(signal_ref, cancel_token: WooCancellationToken = null, capture_first_arg := false) -> WooTask`
- `wait_until(predicate: Callable, cancel_token: WooCancellationToken = null, use_physics_frame := false, timeout_seconds := -1.0) -> WooTask`
- `when_all(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask`
- `when_any(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask`
- `race(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask`
- `join(task_value)`

Helper types:
- `WooTask`
- `WooTaskCompletionSource`
- `WooCancellationSource`
- `WooCancellationToken`

Usage notes:
- Prefer `await task.finished`, then inspect `task.is_succeeded()` / `task.is_failed()` / `task.is_canceled()`.
- `join()` returns the success value. Failed or canceled tasks push an error and return `null`.

---

## `TweenSystem` (`core/system/tween_system.gd`)

Signals:
- `playback_started(playback: WooTweenPlayback)`
- `playback_finished(playback: WooTweenPlayback)`

Methods:
- `set_app(owner_app) -> void`
- `sequence() -> WooTweenSequence`
- `to(target: Object, property_path, target_value, duration: float) -> WooTweenStep`
- `value(target_callable: Callable, from_value, to_value, duration: float) -> WooTweenStep`
- `callback(target_callable: Callable) -> WooTweenStep`
- `interval(duration: float) -> WooTweenStep`
- `play(sequence_or_step) -> WooTweenPlayback`
- `get_task_system() -> TaskSystem`
- `get_active_playbacks() -> Array`
- `kill_all() -> void`

Helper types:
- `WooTweenStep`
- `WooTweenSequence`
- `WooTweenPlayback`

Chaining support:
- `WooTweenStep` supports `set_delay()` / `set_trans()` / `set_ease()` / `from_step()` / `from_current()` / `as_relative()`
- `WooTweenSequence` supports `append()` / `join()` / `insert()` / `append_interval()` / `append_callback()` / `append_sequence()`
- `WooTweenSequence` supports `bind_node()` / `set_default_trans()` / `set_default_ease()` / `set_loops()` / `set_infinite_loops()`

Usage notes:
- `WooTweenPlayback.task` is a `WooTask`, so it composes directly with `TaskSystem`.
- Prefer `await playback.finished`, or use `await task_system.join(playback.task)` for success values.

---

## `SceneSystem` (`core/system/scene_system.gd`)

Signals:
- `transition_started(scene_path: String, payload)`
- `transition_finished(scene_path: String, scene: Node, payload)`
- `scene_preloaded(scene_path: String)`
- `scene_cache_cleared()`

Methods:
- `preload_scene(scene_path: String, cache := true) -> PackedScene`
- `has_cached_scene(scene_path: String) -> bool`
- `get_cached_scene(scene_path: String) -> PackedScene`
- `clear_cache() -> void`
- `add_before_change_hook(hook: Callable) -> void`
- `remove_before_change_hook(hook: Callable) -> void`
- `add_after_change_hook(hook: Callable) -> void`
- `remove_after_change_hook(hook: Callable) -> void`
- `change_scene(scene_path: String, payload = null, options: Dictionary = {}) -> Node`
- `change_scene_packed(scene: PackedScene, scene_path: String = "", payload = null, options: Dictionary = {}) -> Node`

---

## `SaveSystem` (`core/system/save_system.gd`)

Signals:
- `slot_saved(slot_id: StringName, metadata: Dictionary)`
- `slot_loaded(slot_id: StringName, metadata: Dictionary)`
- `slot_deleted(slot_id: StringName)`
- `save_failed(slot_id: StringName, reason: String)`
- `load_failed(slot_id: StringName, reason: String)`

Methods:
- `set_app(owner_app) -> void`
- `list_slots() -> PackedStringArray`
- `slot_exists(slot_id: StringName) -> bool`
- `save_slot(slot_id: StringName, options: Dictionary = {}) -> bool`
- `load_slot(slot_id: StringName, options: Dictionary = {}) -> bool`
- `delete_slot(slot_id: StringName) -> bool`
- `get_slot_metadata(slot_id: StringName) -> Dictionary`

Default save root:
- `save_root = "user://saves"`

---

## `ConfigSystem` (`core/system/config_system.gd`)

Signals:
- `config_registered(config_id: StringName)`
- `config_loaded(config_id: StringName, resource: Resource)`
- `config_cleared(config_id: StringName)`

Methods:
- `set_app(owner_app) -> void`
- `register_config(config_id: StringName, config_ref: Variant) -> bool`
- `preload_config(config_id: StringName, config_path: String) -> Resource`
- `get_config(config_id: StringName) -> Resource`
- `has_config(config_id: StringName) -> bool`
- `clear_config(config_id: StringName) -> void`
- `clear_all() -> void`

---

## `LogSystem` (`core/system/log_system.gd`)

Signals:
- `log_added(entry: Dictionary)`
- `log_cleared()`

Methods:
- `set_app(owner_app) -> void`
- `bind() -> void`
- `unbind() -> void`
- `log_info(message: String, payload = null) -> void`
- `log_error(message: String, payload = null) -> void`
- `clear() -> void`
- `get_entries() -> Array`

## 6. Debug panel

## `WooDebugPanel` (`core/debug/woo_debug_panel.gd`)

Type:
- `CanvasLayer`

Features:
- `F3` toggle
- runtime module status + model snapshot + recent command/event logs
- explicit app binding through `attach_app(owner_app)`
